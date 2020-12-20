`timescale 1ns / 1ps
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


module bzonetop(   
	input 			clk, 
	input 			rst_l,
   input   [15:0] sw,
   input 	[7:0] JB,
   output 	[7:0] JD,
   output 	[3:0] vgaRed, 
	output 	[3:0] vgaBlue, 
	output 	[3:0] vgaGreen,
   output			Hsync, 
   output			Vsync,
   output			ampPWM, 
   output			ampSD,
	output			en_r
	);
              

reg [8:0] row;
reg [9:0] col;
reg [18:0] w_addr, w_addr_pipe;
reg [3:0] color_in, lineColor, color_in_pipe;
reg [12:0] startX, endX, startY, endY, dStartX, dStartY, dEndX, dEndY;
reg done, en_w,/* en_r, */readyFrame, readyLine, rastReady, blank, en_w_pipe;
reg lineDone, lineDone_pipe;
reg lrWrite, full, empty;
reg [15:0] pc;
reg [15:0] inst;
reg [3:0] dIntensity;
reg [12:0] pixelX, pixelY;
reg vggo, vgrst;

wire rst = ~rst_l;
assign readyLine = ~empty;
reg [15:0] address;
reg [7:0] dataIn, dataOut;
reg WE, IRQ, NMI, RDY;

wire [4:0] [7:0] dataToBram, dataFromBram;
wire [4:0] [15:0] addrToBram;
wire [4:0] weEnBram;

reg [2:0] counter3MHz;
reg [12:0] counter3KHz;
reg [11:0] counter6KHz;

wire clk_3MHz, clk_3KHz, clk_6KHz;

reg coreReset;
                       
wire [7:0] vecRamWrData;
wire [15:0] vecRamWrAddr;
wire vecRamWrEn, qCanWrite;

wire [15:0] vecRamAddr2, prog_rom_addr;
assign prog_rom_addr = addrToBram[3'b010]-16'h5000;

wire avg_halt, self_test;

    
assign self_test = 1'b1;
/*
    always_ff @(posedge clk) begin
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
*/
// 100, 25 -- div by 4

    always_ff @(posedge clk) begin
        if(rst) begin
            counter3MHz <= 'd4;
            counter3KHz <= 'd4096;
            counter6KHz <= 'd2048;
        end else begin
            counter3MHz <= counter3MHz + 'd1;
            counter3KHz <= counter3KHz + 'd1;
            counter6KHz <= counter6KHz + 'd1;
        end
    end

assign clk_3MHz = (counter3MHz > 'd3);
assign clk_3KHz = (counter3KHz > 'd4095);
assign clk_6KHz = (counter6KHz > 'd2048);


    always_ff @(posedge clk) begin
        if(rst) coreReset <= 1'b1;
        else if(clk_3MHz) coreReset <= 1'b0;
    end

cpu core(
	.clk(clk_3MHz), 
	.reset(coreReset), 
	.AB(address), 
	.DI(dataIn), 
	.DO(dataOut), 
	.WE(WE), 
	.IRQ(IRQ), 
	.NMI(NMI), 
	.RDY(RDY)
);

addrDecoder ad(
	dataIn, 
	addrToBram, 
	dataToBram, 
	weEnBram, 
	vggo, 
	vgrst, 
	dataOut, 
	{1'b0, address[14:0]}, 
   dataFromBram, 
	WE, 
	avg_halt, 
	clk_3KHz, 
	clk_3MHz, 
	self_test, 
	sw, 
	JB[7:7]
);

/* GEHSTOCK
prog_ROM_wrapper progRom(
	prog_rom_addr[13:0], 
	clk_3MHz, 
	dataFromBram[3'b010]
);*/

prog rom(
	.clk(clk_3MHz),
	.addr(prog_rom_addr[13:0]),
	.data(dataFromBram[3'b010])
);

/* GEHSTOCK
prog_RAM_wrapper progRam(
	addrToBram[3'b000][9:0], 
	clk_3MHz, 
	dataToBram[3'b000], 
   dataFromBram[3'b000], 
	weEnBram[3'b000]
);*/

gen_ram #(
	.dWidth(8),
	.aWidth(10))
ram(
	.clk(clk_3MHz),
	.we(weEnBram[3'b000]),
	.addr(addrToBram[3'b000][9:0]),
	.d(dataToBram[3'b000]),
	.q(dataFromBram[3'b000])
	);
	
/* GEHSTOCK
vram_2_wrapper vecRam2(
	.addr(addrToBram[3'b001][12:0]), 
	.clk(clk_3MHz), 
	.dataIn(dataToBram[3'b001]), 
	.dataOut(dataFromBram[3'b001]), 
	.we(weEnBram[3'b001])
);*/

gen_ram #(
	.dWidth(8),
	.aWidth(13))
vecram2(
	.clk(clk_3MHz),
	.we(weEnBram[3'b001]),
	.addr(addrToBram[3'b001][12:0]),
	.d(dataToBram[3'b001]), 
	.q(dataFromBram[3'b001]) 
	);
   
    /*
assign qCanWrite = avg_halt;
assign vecRamAddr2 = qCanWrite ? vecRamWrAddr : pc + 1;
    vector_ram_wrapper vecRam(pc-16'h2000, vecRamAddr2-16'h2000, clk, 16'h0, vecRamWrData, inst[15:8], inst[7:0], 1'b0, vecRamWrEn);                               
    */
    
    /*logic lastVecWrite, vecWrite;
    always_ff @(posedge clk) begin
        if(rst) lastVecWrite <= 1'b0;
        else lastVecWrite <= weEnBram[`BRAM_VECTOR];
    end*/
    
    //assign vecWrite = (weEnBram[`BRAM_VECTOR] && !lastVecWrite);
    /* alanswx
vector_ram_diffPorts_wrapper vecRam(
	.clock(clk), 
	.writeAddr(addrToBram[3'b001]-16'h2000), 
	.writeData(dataToBram[3'b001]), 
	.writeEnable(weEnBram[3'b001]), 
   .readAddr((pc-16'h2000) >> 1'b1), 
	.dataOut({inst[7:0], inst[15:8]})
);*/
   vecramnew vecram(
	.clock(clk),
	.data(dataToBram[3'b001]),
	.rdaddress((pc-16'h2000) >> 1'b1),
	.wraddress(addrToBram[3'b001]-16'h2000),
	.wren(weEnBram[3'b001]),
	.q({inst[7:0], inst[15:8]}));

	/*
  gen_ram #(
	.dWidth(16),
	.aWidth(13))
vecRam(
	.clk(clk),
	.we(weEnBram[3'b001]),
	.addr(weEnBram[3'b001]?addrToBram[3'b001]-16'h2000:(pc-16'h2000) >> 1'b1),
	.d(dataToBram[3'b001]), 
	.q({inst[7:0], inst[15:8]}) 
	);
*/
	
    /*
    memStoreQueue memQ(.dataOut(vecRamWrData), .addrOut(vecRamWrAddr), .dataValid(vecRamWrEn), 
                       .full(memStoreFull), .empty(memStoreEmpty), 
                       .dataIn(dataToBram[`BRAM_VECTOR]), .addrIn(addrToBram[`BRAM_VECTOR]), 
                       .canWrite(qCanWrite), .writeEn(weEnBram[`BRAM_VECTOR]), .clk(clk), .rst(rst));       
    */
    /*
wire lastVecWrite;
    always_ff @(posedge clk) begin
        if(rst) lastVecWrite <= 1'b0;
        else lastVecWrite <= weEnBram[`BRAM_VECTOR];
    end
    
assign vecRamWrData = dataToBram[`BRAM_VECTOR];
assign vecRamWrAddr = addrToBram[`BRAM_VECTOR];
assign vecRamWrEn = weEnBram[`BRAM_VECTOR] && !lastVecWrite;
    */

NMICounter nmiC(
	NMI, 
	clk_3KHz, 
	rst, 
	self_test
);

assign IRQ = 0;
assign RDY = 1;

avg_core avgc(
	.startX(dStartX), 
	.startY(dStartY), 
	.endX(dEndX), 
	.endY(dEndY), 
   .intensity(dIntensity), 
	.lrWrite(lrWrite), 
	.pcOut(pc), 
	.halt(avg_halt), 
	.inst(inst), 
	.clk_in(clk), 
   .rst_in(rst || vgrst), 
	.vggo(vggo)
);
                    
    lineRegQueue lrq(.QStartX(startX), .QStartY(startY), .QEndX(endX), .QEndY(endY), 
                     .QIntensity(lineColor), .full(full), .empty(empty), 
                     .DStartX(dStartX), .DStartY(dStartY), .DEndX(dEndX), .DEndY(dEndY),
                                     .DIntensity(dIntensity), .read(lineDone), .currWrite(lrWrite), 
                                     .clk(clk), .rst(rst));

    
    rasterizer rast(.startX(startX), .endX(endX), .startY(startY), .endY(endY), .lineColor(lineColor), 
                    .clk(clk), .rst(rst), .readyIn(readyLine), .addressOut(w_addr), 
                    .pixelX(pixelX), .pixelY(pixelY), .pixelColor(color_in), 
                    .goodPixel(en_w), .done(lineDone), .rastReady(rastReady));
                    
    VGA_fsm vfsm(.clk(clk), .rst(rst), .row(row), .col(col), .Hsync(Hsync), .Vsync(Vsync), .en_r(en_r));

    fb_controller fbc(.w_addr(w_addr_pipe), .en_w(en_w_pipe), .en_r(en_r), 
                      .halt(avg_halt), .vggo(vggo), .lineDone(lineDone_pipe), .lrqEmpty(empty), 
                      .clk(clk), .rst(rst), 
                      .row(row), .col(col), .color_in(color_in_pipe),
                      .red_out(vgaRed), .blue_out(vgaBlue), .green_out(vgaGreen), .ready(readyFrame));
    
   //fb_temp fbt(.w_addr(w_addr_pipe), .en_w(en_w_pipe), .en_r(en_r), .done(avg_halt), .clk(clk), .rst(rst), 
     //                   .row(row), .col(col), .color_in(color_in_pipe),
       //                 .red_out(vgaRed), .blue_out(vgaBlue), .green_out(vgaGreen), .ready(readyFrame));
      
      
      //mathbox
      //logic[4:0] unmappedMBLatch;
		
/*GEHSTOCK      */
/*
mathBox mb(
	addrToBram[3'b100][7:0], 
	dataToBram[3'b100], 
	weEnBram[3'b100], 
	clk_3MHz, 
	rst, 
   dataFromBram[3'b100]
);
*/
      
      always_ff @(posedge clk) begin
              if(rst) begin
                  w_addr_pipe <= 'd0;
                  color_in_pipe <= 'd0;
                  en_w_pipe <= 'd0;
                  lineDone_pipe <= 'd0;
              end
              else begin
                  w_addr_pipe <= w_addr;
                  color_in_pipe <= color_in;
                  en_w_pipe <= en_w;
                  lineDone_pipe <= lineDone;
              end  
       end
       
      //assign led[11:8] = unmappedMBLatch;
      //m_register #(1) mbLatch_0(.Q(led[8]), .D(unmappedMBLatch[0]), .clr(rst), .en(unmappedMBLatch[0]), .clk(clk));
      //m_register #(1) mbLatch_1(.Q(led[9]), .D(unmappedMBLatch[1]), .clr(rst), .en(unmappedMBLatch[1]), .clk(clk));
      //m_register #(1) mbLatch_2(.Q(led[10]), .D(unmappedMBLatch[2]), .clr(rst), .en(unmappedMBLatch[2]), .clk(clk));
      //m_register #(1) mbLatch_3(.Q(led[11]), .D(unmappedMBLatch[3]), .clr(rst), .en(unmappedMBLatch[3]), .clk(clk));
      //m_register #(1) mbLatch_4(.Q(led[12]), .D(unmappedMBLatch[4]), .clr(rst), .en(unmappedMBLatch[4]), .clk(clk));
      
  reg [7:0] outputLatch, buttons;
       
      //sound
  assign buttons = {{2'b00},{JB[6]},{|JB[5:4]},{JB[3:0]}};
      //assign buttons = 8'b0000_0000;
  wire pokeyEn;
  assign pokeyEn = ~(addrToBram[3'b011] >= 16'h1820 && addrToBram[3'b011] < 16'h1830);
      
      //output latch for POKEY
      always_ff @(posedge clk_3MHz) begin
        if(rst) begin
            outputLatch <= 'd0;
        end
        if(addrToBram[3'b011] == 16'h1840 && weEnBram[3'b011]) begin
            outputLatch <= dataToBram[3'b011];
        end
        else begin
            outputLatch <= outputLatch;
        end
      end
  assign ampSD = outputLatch[5];
      
      /*
      always_ff @(posedge clk_3MHz) begin
        if(rst) begin
            JD[7:0] <= 'b0;
        end
        else begin
            JD[7:0] <= outputLatch;
        end
      end
      */
    
POKEY pokey(
	.Din(dataToBram[3'b011] ), 
	.Dout(dataFromBram[3'b011]), 
	.A(addrToBram[3'b011][3:0]), 
	.P(buttons), 
	.phi2(clk_3MHz), 
	.readHighWriteLow(~weEnBram[3'b011]),
   .cs0Bar(pokeyEn), 
	.aud(ampPWM), 
	.clk(clk)
);
   
logic [15:0] extAud;
logic feedbackAlpha;
logic lfsrOut0, lfsrOut1;
logic otherAud0, otherAud1;
xnor xnor0(feedbackAlpha, extAud[3], extAud[14]);
assign lfsrOut0 = extAud[15];
assign lfsrOut1 = !(&extAud[14:11]);
                       
m_shift_register #(16) extAudLFSR (
	.Q(extAud), 
	.clk(clk_6KHz), 
	.en(ampSD), 
	.left(1'b1), 
	.s_in(feedbackAlpha), 
	.clr(rst | !ampSD)
);
                          
m_register #(1) freqDiv0(.Q(otherAud0), .D(!otherAud0), .clk(clk_6KHz), .en(lfsrOut0), .clr(rst));
m_register #(1) freqDiv1(.Q(otherAud1), .D(!otherAud1), .clk(clk_6KHz), .en(lfsrOut1), .clr(rst));
        
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
