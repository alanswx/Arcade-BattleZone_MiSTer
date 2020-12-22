`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/28/2015 01:24:09 PM
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "coreInterface.vh"

module top
  #
  (
   parameter          CLK_DIV = "TRUE"
   )
  (
   input wire         clk_i, btnCpuReset,
   input wire [15:0]  sw,
   input wire [7:0]   JB,
   output logic [7:0] JD,
   output logic [3:0] vgaRed, vgaBlue, vgaGreen,
   output logic       Hsync, Vsync,
	output logic       en_r,
	output logic       hBlank, vBlank,
	output logic [3:0] audio,
   output logic       ampPWM, ampSD,
	input wire [24:0]  dl_addr,
	input wire [7:0]   dl_data,
	input wire         dl_wr
	);


  logic [8:0]         row;
  logic [9:0]         col;
  logic [18:0]        w_addr, w_addr_pipe;
  logic [3:0]         color_in, lineColor, color_in_pipe;
  logic [12:0]        startX, endX, startY, endY, dStartX, dStartY, dEndX, dEndY;
  logic               en_w, /*en_r,*/ readyFrame, readyLine, rastReady, en_w_pipe;
  logic               lineDone, lineDone_pipe;
  logic               full;
  logic               empty;
  logic               rst;
  logic               lrWrite;
  logic [15:0]        pc;
  logic [15:0]        inst;
  logic [3:0]         dIntensity;
  logic [12:0]        pixelX, pixelY;
  logic               rst_l;
  logic               vggo, vgrst;

  assign rst = ~rst_l;
  assign readyLine = ~empty;

  logic               rst_unstable;
  logic               clk;

  always @(posedge clk) begin
    rst_unstable <= btnCpuReset;
    rst_l        <= rst_unstable;
  end

  logic [15:0] address;
  logic [7:0]  dataIn, dataOut;
  logic        WE, IRQ, NMI, RDY;

  logic [4:0] [7:0] dataToBram, dataFromBram;
  logic [4:0] [15:0] addrToBram;
  logic [4:0]        weEnBram;
  logic              clk_3MHz, clk_3KHz, clk_6KHz;
  logic              clk_3MHz_en;
  logic              clk_6MHz_en;
  logic              clk_3KHz_en;
  logic              clk_6KHz_en;

  logic              coreReset;

  logic [15:0]       prog_rom_addr;
  assign prog_rom_addr = addrToBram[`BRAM_PROG_ROM]-16'h5000;

  logic              avg_halt;
  logic              self_test;

  assign self_test = 1'b1;

  logic              locked;

/*  main_clock clocks
    (
     .clk_out1  (clk),
     //.reset(rst),
     .reset     (1'b0),
     .locked    (locked),
     .clk_in1   (clk_i)
     );
	  */
assign clk=clk_i;

  generate
    if (CLK_DIV == "TRUE") begin : g_CLK_DIV
      logic [3:0]        counter3MHz;
      logic [13:0]       counter3KHz;
      logic [12:0]       counter6KHz;

      initial begin
        counter3MHz = 'd8;
        counter3KHz = 'd8192;
        counter6KHz = 'd4096;
      end
      always @(posedge clk) begin
        if(rst) begin
          counter3MHz <= 'd8;
          counter3KHz <= 'd8192;
          counter6KHz <= 'd4096;
        end else begin
          counter3MHz <= counter3MHz + 'd1;
          counter3KHz <= counter3KHz + 'd1;
          counter6KHz <= counter6KHz + 'd1;
        end
      end

      assign clk_3MHz = (counter3MHz > 'd7);
      assign clk_3KHz = (counter3KHz > 'd8191);
      assign clk_6KHz = (counter6KHz > 'd4096);
      assign clk_3MHz_en = counter3MHz == 'd7;
      assign clk_6MHz_en = counter3MHz[2:0] == 4'd7;
      assign clk_3KHz_en = counter3KHz == 'd8191;
      assign clk_6KHz_en = counter6KHz == 'd4096;

    end else begin : g_NO_CLK_DIV

      logic [4:0] counter3MHz;
      logic [14:0] counter3KHz;
      logic [13:0] counter6KHz;

      initial begin
        counter3MHz = 'd16;
        counter3KHz = 'd16384;
        counter6KHz = 'd8192;
      end
      always @(posedge clk) begin
        if(rst) begin
          counter3MHz <= 'd16;
          counter3KHz <= 'd16384;
          counter6KHz <= 'd8192;
        end else begin
          counter3MHz <= counter3MHz + 'd1;
          counter3KHz <= counter3KHz + 'd1;
          counter6KHz <= counter6KHz + 'd1;
        end
      end

      assign clk_3MHz = (counter3MHz > 'd15);
      assign clk_3KHz = (counter3KHz > 'd16383);
      assign clk_6KHz = (counter6KHz > 'd8192);
      assign clk_3MHz_en = counter3MHz == 'd15;
      assign clk_6MHz_en = counter3MHz[3:0] == 5'd15;
      assign clk_3KHz_en = counter3KHz == 'd16383;
      assign clk_6KHz_en = counter6KHz == 'd8192;

    end // else: !if(CLK_DIV == "TRUE")
  endgenerate

  always_ff @(posedge clk) begin
    if (rst)              coreReset <= 1'b1;
    else if (clk_3MHz_en) coreReset <= 1'b0;
  end

  cpu core
    (
     .clk            (clk),
     .clk_en         (clk_3MHz_en),
     .reset          (coreReset),
     .AB             (address),
     .DI             (dataIn),
     .DO             (dataOut),
     .WE             (WE),
     .IRQ            (IRQ),
     .NMI            (NMI),
     .RDY            (RDY)
     );

  addrDecoder ad
    (
     .dataToCore     (dataIn),
     .addrToBram     (addrToBram),
     .dataToBram     (dataToBram),
     .weEnBram       (weEnBram),
     .vggo           (vggo),
     .vgrst          (vgrst),
     .dataFromCore   (dataOut),
     .addr           ({1'b0, address[14:0]}),
     .dataFromBram   (dataFromBram),
     .we             (WE),
     .halt           (avg_halt),
     .clk            (clk),
     .clk_3KHz       (clk_3KHz),
     .clk_en         (clk_3MHz_en),
     .self_test      (self_test),
     .option_switch  (sw),
     .coin           (JB[7:7])
     );

wire prog_rom_cs = dl_addr < 'h3000;

  dpram #(.addr_width_g(14),.data_width_g(8)) progRom (
	.clock_a(clk),
	.address_a(dl_addr[13:0]),
	.data_a(dl_data),
	.wren_a(dl_wr & prog_rom_cs),
	
	.clock_b(clk),
	.enable_b(clk_3MHz_en),
	.address_b(prog_rom_addr[13:0]),
	.q_b(dataFromBram[`BRAM_PROG_ROM])
	);
/*	
  prog_rom progRom
    (
     .addr        (prog_rom_addr[13:0]),
     .clk         (clk),
     .clk_en      (clk_3MHz_en),
     .dout        (dataFromBram[`BRAM_PROG_ROM])
     );
	*/
	
  /*
  prog progRom
  (
	  .addr        (prog_rom_addr[13:0]),
     .clk         (clk),
     //.clk_en      (clk_3MHz_en),
     .data        (dataFromBram[`BRAM_PROG_ROM])
	);
*/
  sp_ram
    #
    (
     .DATA        (8),
     .ADDR        (10)
     )
  progRam
    (
     .clk         (clk),
     .clk_en      (clk_3MHz_en),
     .addr        (addrToBram[`BRAM_PROG_RAM][9:0]),
     .din         (dataToBram[`BRAM_PROG_RAM]),
     .dout        (dataFromBram[`BRAM_PROG_RAM]),
     .wr          (weEnBram[`BRAM_PROG_RAM])
     );

	  
	wire vec_rom_cs = dl_addr >= 'h3000 && dl_addr< 'h4000 ;

  dpram #(.addr_width_g(13),.data_width_g(8)) vecRam2 (
	.clock_a(clk),
	.address_a(dl_addr[11:0]+'d4096),
	.data_a(dl_data),
	.wren_a(dl_wr & vec_rom_cs),
	
	.clock_b(clk),
	.enable_b(clk_3MHz_en),
	.address_b(addrToBram[`BRAM_VECTOR][12:0]),
	.wren_b(weEnBram[`BRAM_VECTOR]),
	.data_b(dataToBram[`BRAM_VECTOR]),
	.q_b(dataFromBram[`BRAM_VECTOR])
	);
/*	  
  (* ram_style = "block" *) logic [7:0] vecram2_store[8192];
  initial begin
    $readmemh("avg_clean2.mem", vecram2_store, 0, 8191);
  end
  always @(posedge clk) begin
    if (clk_3MHz_en) begin
      if (weEnBram[`BRAM_VECTOR]) vecram2_store[addrToBram[`BRAM_VECTOR][12:0]] <= dataToBram[`BRAM_VECTOR];
      dataFromBram[`BRAM_VECTOR] <= vecram2_store[addrToBram[`BRAM_VECTOR][12:0]];
    end
  end
*/
  logic [15:0] vec_ram_write_addr;
  logic [15:0] vec_ram_read_addr;

  assign vec_ram_write_addr = addrToBram[`BRAM_VECTOR]-16'h2000;
  assign vec_ram_read_addr  = pc - 16'h2000;

  wire vecram_we;
  assign vecram_we = vec_rom_cs ? dl_wr : weEnBram[`BRAM_VECTOR];
  wire [12:0] vecram_addr;
  assign vecram_addr =  vec_rom_cs ? dl_addr[11:0]+'d4096 : vec_ram_write_addr[12:0];
  wire [7:0] vecram_data;
  assign vecram_data =  vec_rom_cs ? dl_data : dataToBram[`BRAM_VECTOR];
  
  (* ram_style = "block" *) logic [7:0] vecram_store[8192];
  logic [15:0] inst_pipe; // Original implementation had a pipe stage
  //initial begin
  //  $readmemh("avg_clean2.mem", vecram_store, 0, 8191);
  //end
  always @(posedge clk) begin
    if (vecram_we) begin
      vecram_store[vecram_addr] <= vecram_data;
    end
    inst_pipe[7:0]  <= vecram_store[{vec_ram_read_addr[12:1], 1'b1}];
    inst_pipe[15:8] <= vecram_store[{vec_ram_read_addr[12:1], 1'b0}];
    inst            <= inst_pipe;
  end

  logic [3:0]   nmi_counter;
  initial begin
    nmi_counter = '0;
  end
  always @(posedge clk) begin
    if (clk_3KHz_en) begin
      if (rst) nmi_counter <= 'd0;
      else begin
        NMI <= (nmi_counter == 'd12);
        if(nmi_counter == 'd13) nmi_counter <= 'd0;
        else nmi_counter <= nmi_counter + 1'd1;
      end
    end
  end

    assign IRQ = 0;
    assign RDY = 1;

  avg_core
    #
    (
     .CLK_DIV        (CLK_DIV)
     )
  avgc
    (
     .startX         (dStartX),
     .startY         (dStartY),
     .endX           (dEndX),
     .endY           (dEndY),
     .intensity      (dIntensity),
     .lrWrite        (lrWrite),
     .pcOut          (pc),
     .halt           (avg_halt),
     .inst           (inst),
     .clk_in         (clk),
     .clk_6MHz_en    (clk_6MHz_en),
     .rst_in         (rst || vgrst),
     .vggo           (vggo)
     );

  lineRegQueue lrq
    (
     .QStartX        (startX),
     .QStartY        (startY),
     .QEndX          (endX),
     .QEndY          (endY),
     .QIntensity     (lineColor),
     .full           (full),
     .empty          (empty),
     .DStartX        (dStartX),
     .DStartY        (dStartY),
     .DEndX          (dEndX),
     .DEndY          (dEndY),
     .DIntensity     (dIntensity),
     .read           (lineDone),
     .currWrite      (lrWrite),
     .clk            (clk),
     .rst            (rst)
     );

  rasterizer rast
    (
     .startX         (startX),
     .endX           (endX),
     .startY         (startY),
     .endY           (endY),
     .lineColor      (lineColor),
     .clk            (clk),
     .rst            (rst),
     .readyIn        (readyLine),
     .addressOut     (w_addr),
     .pixelX         (pixelX),
     .pixelY         (pixelY),
     .pixelColor     (color_in),
     .goodPixel      (en_w),
     .done           (lineDone),
     .rastReady      (rastReady)
     );

  VGA_fsm vfsm
    (
     .clk            (clk),
     .rst            (rst),
     .row            (row),
     .col            (col),
     .Hsync          (Hsync),
     .Vsync          (Vsync),
     .en_r           (en_r),
	  .vBlank         (vBlank),
	  .hBlank         (hBlank)
     );

  fb_controller fbc
    (
     .w_addr         (w_addr_pipe),
     .en_w           (en_w_pipe),
     .en_r           (en_r),
     .halt           (avg_halt),
     .vggo           (vggo),
     .lineDone       (lineDone_pipe),
     .lrqEmpty       (empty),
     .clk            (clk),
     .rst            (rst),
     .row            (row),
     .col            (col),
     .color_in       (color_in_pipe),
     .red_out        (vgaRed),
     .blue_out       (vgaBlue),
     .green_out      (vgaGreen),
     .ready          (readyFrame)
     );

  mathBox mb
    (
     .addr           (addrToBram[`BRAM_MATH][7:0]),
     .DI             (dataToBram[`BRAM_MATH]),
     .we             (weEnBram[`BRAM_MATH]),
     .clk            (clk),
     .clk_en         (clk_3MHz_en),
     .rst            (rst),
     .dataOut        (dataFromBram[`BRAM_MATH])
     );

  always_ff @(posedge clk) begin
    if(rst) begin
      w_addr_pipe   <= '0;
      color_in_pipe <= '0;
      en_w_pipe     <= '0;
      lineDone_pipe <= '0;
    end else begin
      w_addr_pipe   <= w_addr;
      color_in_pipe <= color_in;
      en_w_pipe     <= en_w;
      lineDone_pipe <= lineDone;
    end
  end

  logic[7:0] outputLatch, buttons;

  //sound
  assign buttons = {{2'b00},{JB[6]},{|JB[5:4]},{JB[3:0]}};
  logic      pokeyEn;
  assign pokeyEn = ~(addrToBram[`BRAM_POKEY] >= 16'h1820 && addrToBram[`BRAM_POKEY] < 16'h1830);

  //output latch for POKEY
  always_ff @(posedge clk) begin
    if (clk_3MHz_en) begin
      if(rst) begin
        outputLatch <= 'd0;
      end
      if(addrToBram[`BRAM_POKEY] == 16'h1840 && weEnBram[`BRAM_POKEY]) begin
        outputLatch <= dataToBram[`BRAM_POKEY];
      end
      else begin
        outputLatch <= outputLatch;
      end
    end // if (clk_3MHz_en)
  end
  assign ampSD = outputLatch[5];

  POKEY pokey
    (
     .Din              (dataToBram[`BRAM_POKEY] ),
     .Dout             (dataFromBram[`BRAM_POKEY]),
     .A                (addrToBram[`BRAM_POKEY][3:0]),
     .P                (buttons),
     .phi2             (clk_3MHz),
     .readHighWriteLow (~weEnBram[`BRAM_POKEY]),
     .cs0Bar           (pokeyEn),
     .aud              (ampPWM),
	  .audio (audio),
     .clk              (clk)
     );

  logic [15:0] extAud;
  logic        feedbackAlpha;
  logic        lfsrOut0, lfsrOut1;

  logic        otherAud0, otherAud1;

  xnor xnor0(feedbackAlpha, extAud[3], extAud[14]);

  assign lfsrOut0 = extAud[15];
  assign lfsrOut1 = !(&extAud[14:11]);

  always_ff @(posedge clk)
    if (clk_6KHz_en) begin
      if (rst | !ampSD) begin
        extAud <= '0;
      end else if(ampSD) begin
        extAud <= (extAud << 1) | feedbackAlpha;
      end
    end

  always_ff @(posedge clk)
    if (clk_6KHz_en) begin
      if (rst) begin
        otherAud0 <= '0;
        otherAud1 <= '0;
      end else begin
        if (lfsrOut0) otherAud0 <= ~otherAud0;
        if (lfsrOut1) otherAud1 <= ~otherAud1;
      end
    end

  assign JD[0] = ~outputLatch[3];
  assign JD[1] = ~outputLatch[2];
  assign JD[2] = ~otherAud0;
  assign JD[3] = ~outputLatch[1];
  assign JD[4] = ~outputLatch[0];
  assign JD[5] = ~otherAud1;

  always_comb begin
    //motoren
    if(outputLatch[5]) begin
      JD[6] = ~outputLatch[7];
      JD[7] = ~outputLatch[4];
    end
    else begin
      JD[6] = 1'b1;
      JD[7] = 1'b1;

    end
  end


endmodule
`default_nettype wire
