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
`include "coreInterface.vh"

module top(   input logic clk, btnCpuReset,
              input logic [15:0] sw,
              input logic [7:0] JB,
              output logic [7:0] JD,
              output logic[3:0] vgaRed, vgaBlue, vgaGreen,
              output logic Hsync, Vsync,
              output logic ampPWM, ampSD);
              

    logic[8:0] row;
    logic[9:0] col;
    logic[18:0] w_addr, w_addr_pipe;
    logic[3:0] color_in, lineColor, color_in_pipe;
    logic[12:0] startX, endX, startY, endY, dStartX, dStartY, dEndX, dEndY;
    logic done, en_w, en_r, readyFrame, readyLine, rastReady, blank, en_w_pipe;
    logic lineDone, lineDone_pipe;
    logic lrWrite, full, empty, rst; 
    logic[15:0] pc;
    logic[15:0] inst;
    logic[3:0] dIntensity;
    logic[12:0] pixelX, pixelY;
    logic rst_l;
    logic vggo, vgrst;

    assign rst = ~rst_l;
    assign readyLine = ~empty;

    m_register #(1) syncRstRegA(.Q(rst_unstable), .D(btnCpuReset), .clr(1'b0), .en(1'b1), .clk(clk));
    m_register #(1) syncRstRegB(.Q(rst_l), .D(rst_unstable), .clr(1'b0), .en(1'b1), .clk(clk));
    
    logic [15:0] address;
    logic [7:0] dataIn, dataOut;
    logic WE, IRQ, NMI, RDY;

    logic [4:0] [7:0] dataToBram, dataFromBram;
    logic [4:0] [15:0] addrToBram;
    logic [4:0] weEnBram;

    logic [4:0] counter3MHz;
    logic [14:0] counter3KHz;
    logic [13:0] counter6KHz;

    logic clk_3MHz, clk_3KHz, clk_6KHz;

    logic coreReset;
                       
    logic [7:0] vecRamWrData;
    logic [15:0] vecRamWrAddr;
    logic vecRamWrEn, qCanWrite;

    logic [15:0] vecRamAddr2, prog_rom_addr;
    assign prog_rom_addr = addrToBram[`BRAM_PROG_ROM]-16'h5000;

    logic avg_halt, self_test;
    
    assign self_test = 1'b1;

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

    always_ff @(posedge clk) begin
        if(rst) coreReset <= 1'b1;
        else if(clk_3MHz) coreReset <= 1'b0;
    end

    cpu core(.clk(clk_3MHz), .reset(coreReset), .AB(address), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(IRQ), .NMI(NMI), .RDY(RDY));

    addrDecoder ad(dataIn, addrToBram, dataToBram, weEnBram, vggo, vgrst, dataOut, {1'b0, address[14:0]}, 
                    dataFromBram, WE, avg_halt, clk_3KHz, clk_3MHz, self_test, sw, JB[7:7]);  

    prog_ROM_wrapper progRom(prog_rom_addr[13:0], clk_3MHz, dataFromBram[`BRAM_PROG_ROM]);

    prog_RAM_wrapper progRam(addrToBram[`BRAM_PROG_RAM][9:0], clk_3MHz, dataToBram[`BRAM_PROG_RAM], 
                             dataFromBram[`BRAM_PROG_RAM], weEnBram[`BRAM_PROG_RAM]); 
    vram_2_wrapper vecRam2(.addr(addrToBram[`BRAM_VECTOR][12:0]), .clk(clk_3MHz), .dataIn(dataToBram[`BRAM_VECTOR]), .dataOut(dataFromBram[`BRAM_VECTOR]), .we(weEnBram[`BRAM_VECTOR]));

   
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
    
    vector_ram_diffPorts_wrapper vecRam(.clock(clk), .writeAddr(addrToBram[`BRAM_VECTOR]-16'h2000), .writeData(dataToBram[`BRAM_VECTOR]), .writeEnable(weEnBram[`BRAM_VECTOR]), 
                                        .readAddr((pc-16'h2000) >> 1'b1), .dataOut({inst[7:0], inst[15:8]}));

    
    
    /*
    memStoreQueue memQ(.dataOut(vecRamWrData), .addrOut(vecRamWrAddr), .dataValid(vecRamWrEn), 
                       .full(memStoreFull), .empty(memStoreEmpty), 
                       .dataIn(dataToBram[`BRAM_VECTOR]), .addrIn(addrToBram[`BRAM_VECTOR]), 
                       .canWrite(qCanWrite), .writeEn(weEnBram[`BRAM_VECTOR]), .clk(clk), .rst(rst));       
    */
    /*
    logic lastVecWrite;
    always_ff @(posedge clk) begin
        if(rst) lastVecWrite <= 1'b0;
        else lastVecWrite <= weEnBram[`BRAM_VECTOR];
    end
    
    assign vecRamWrData = dataToBram[`BRAM_VECTOR];
    assign vecRamWrAddr = addrToBram[`BRAM_VECTOR];
    assign vecRamWrEn = weEnBram[`BRAM_VECTOR] && !lastVecWrite;
    */

    NMICounter nmiC(NMI, clk_3KHz, rst, self_test);

    assign IRQ = 0;
    assign RDY = 1;

    avg_core avgc(.startX(dStartX), .startY(dStartY), .endX(dEndX), .endY(dEndY), 
                  .intensity(dIntensity), .lrWrite(lrWrite), .pcOut(pc), .halt(avg_halt), .inst(inst), .clk_in(clk), 
                  .rst_in(rst || vgrst), .vggo(vggo));
                    
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
      
      mathBox mb(addrToBram[`BRAM_MATH][7:0], dataToBram[`BRAM_MATH], weEnBram[`BRAM_MATH], clk_3MHz, rst, 
              dataFromBram[`BRAM_MATH]);
      
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
      
      logic[7:0] outputLatch, buttons;
       
      //sound
      assign buttons = {{2'b00},{JB[6]},{|JB[5:4]},{JB[3:0]}};
      //assign buttons = 8'b0000_0000;
      assign pokeyEn = ~(addrToBram[`BRAM_POKEY] >= 16'h1820 && addrToBram[`BRAM_POKEY] < 16'h1830);
      
      //output latch for POKEY
      always_ff @(posedge clk_3MHz) begin
        if(rst) begin
            outputLatch <= 'd0;
        end
        if(addrToBram[`BRAM_POKEY] == 16'h1840 && weEnBram[`BRAM_POKEY]) begin
            outputLatch <= dataToBram[`BRAM_POKEY];
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
    
      
      POKEY pokey(.Din(dataToBram[`BRAM_POKEY] ), .Dout(dataFromBram[`BRAM_POKEY]), .A(addrToBram[`BRAM_POKEY][3:0]), .P(buttons), .phi2(clk_3MHz), .readHighWriteLow(~weEnBram[`BRAM_POKEY]),
                  .cs0Bar(pokeyEn), .aud(ampPWM), .clk(clk));
   
        logic [15:0] extAud;
        logic feedbackAlpha;
        logic lfsrOut0, lfsrOut1;
                          
        logic otherAud0, otherAud1;
                       
        xnor xnor0(feedbackAlpha, extAud[3], extAud[14]);
                       
        assign lfsrOut0 = extAud[15];
        assign lfsrOut1 = !(&extAud[14:11]);
                       
        m_shift_register #(16) extAudLFSR (.Q(extAud), .clk(clk_6KHz), .en(ampSD), .left(1'b1), .s_in(feedbackAlpha), .clr(rst | !ampSD));
                          
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
