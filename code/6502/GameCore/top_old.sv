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
              input logic[7:0] sw,
              output logic[3:0] vgaRed, vgaBlue, vgaGreen,
              output logic[1:0] led,
              output logic Hsync, Vsync,
              output logic ampPWM, ampSD);
              

    logic[8:0] row;
    logic[9:0] col;
    logic[18:0] w_addr;
    logic[3:0] color_in, lineColor;
    logic[12:0] startX, endX, startY, endY, dStartX, dStartY, dEndX, dEndY;
    logic done, en_w, en_r, readyFrame, readyLine, rastReady, blank;
    logic lrWrite, full, empty, rst; 
    logic[15:0] pc;
    logic[15:0] inst;
    logic[3:0] dColor;
    logic[12:0] pixelX, pixelY;
    logic rst_l;
    logic vggo, vgrst;


    //m_register #(1) vggolatch(.Q(led[0]), .D(vggo), .clr(1'b0), .en(vggo), .clk(clk));
    //m_register #(1) vgrstlatch(.Q(led[1]), .D(vgrst), .clr(1'b0), .en(vgrst), .clk(clk));
    assign led[0] = vggo;
    assign led[1] = vgrst;
    assign rst = ~rst_l;
    assign readyLine = ~empty;

    m_register #(1) syncRstRegA(.Q(rst_unstable), .D(btnCpuReset), .clr(1'b0), .en(1'b1), .clk(clk));
    m_register #(1) syncRstRegB(.Q(rst_l), .D(rst_unstable), .clr(1'b0), .en(1'b1), .clk(clk));
    
    logic [15:0] address;
    logic [7:0] dataIn, dataOut;
    logic WE, IRQ, NMI, RDY;

    logic [3:0] [7:0] dataToBram, dataFromBram;
    logic [3:0] [15:0] addrToBram;
    logic [3:0] weEnBram;

    logic [4:0] counter3MHz;
    logic [14:0] counter3KHz;

    logic clk_3MHz, clk_3KHz;

    logic coreReset;
                       
    logic [7:0] vecRamWrData;
    logic [15:0] vecRamWrAddr;
    logic vecRamWrEn, qCanWrite;

    logic [15:0] vecRamAddr2;

    logic avg_halt;

    logic pokeyEn;

    always_ff @(posedge clk) begin
        if(rst) begin
            counter3MHz <= 16;
            counter3KHz <= 16384;
        end else begin
            counter3MHz <= counter3MHz + 1;
            counter3KHz <= counter3KHz + 1;
        end
    end

    assign clk_3MHz = (counter3MHz > 15);
    assign clk_3KHz = (counter3KHz > 16383);

    always_ff @(posedge clk) begin
        if(rst) coreReset <= 1'b1;
        else if(clk_3MHz) coreReset <= 1'b0;
    end

    cpu core(.clk(clk_3MHz), .reset(coreReset), .AB(address), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(IRQ), .NMI(NMI), .RDY(RDY));

    addrDecoder ad(dataIn, addrToBram, dataToBram, weEnBram, vggo, vgrst, pokeyEn, dataOut, {1'b0, address[14:0]}, dataFromBram, WE, avg_halt, clk_3KHz, clk_3MHz);  

    prog_ROM_wrapper progRom(addrToBram[`BRAM_PROG_ROM]-16'h5000, clk_3MHz, dataFromBram[`BRAM_PROG_ROM]);

    prog_RAM_wrapper progRam(addrToBram[`BRAM_PROG_RAM], clk_3MHz, dataToBram[`BRAM_PROG_RAM], 
                             dataFromBram[`BRAM_PROG_RAM], weEnBram[`BRAM_PROG_RAM]); 
    vram_2_wrapper vecRam2(.addr(addrToBram[`BRAM_VECTOR]-16'h2000), .clk(clk_3MHz), .dataIn(dataToBram[`BRAM_VECTOR]), .dataOut(dataFromBram[`BRAM_VECTOR]), .we(weEnBram[`BRAM_VECTOR]));

    //logic [7:0] mathboxData; // hook up this and second read port to mathbox...

    //mathBoxROM_wrapper mathRom(.addr_a(addrToBram[`BRAM_MATH_ROM]-16'h3000), .addr_b(16'h0), .clk(clk), .data_a(dataFromBram[`BRAM_MATH_ROM]), .data_b(mathboxData)); 

    assign qCanWrite = avg_halt;
    assign vecRamAddr2 = qCanWrite ? vecRamWrAddr : pc + 1;
    vector_ram_wrapper vecRam(pc-16'h2000, vecRamAddr2-16'h2000, clk, 16'h0, vecRamWrData, inst[15:8], inst[7:0], 1'b0, vecRamWrEn);                               

    memStoreQueue memQ(vecRamWrData, vecRamWrAddr, vecRamWrEn, dataToBram[`BRAM_VECTOR], addrToBram[`BRAM_VECTOR], qCanWrite, weEnBram[`BRAM_VECTOR], clk, rst);                 

    NMICounter nmiC(NMI, clk_3KHz, rst);

    assign IRQ = 0;
    assign RDY = 1;

    avg_core avgc(.startX(dStartX), .startY(dStartY), .endX(dEndX), .endY(dEndY), 
                  .color(dColor), .lrWrite(lrWrite), .pcOut(pc), .halt(avg_halt), .inst(inst), .clk_in(clk), 
                  .rst_in(rst || vgrst), .vggo(vggo));
                    
    lineRegQueue lrq(.QStartX(startX), .QStartY(startY), .QEndX(endX), .QEndY(endY), 
                     .QColor(lineColor), .full(full), .empty(empty), 
                     .DStartX(dStartX), .DStartY(dStartY), .DEndX(dEndX), .DEndY(dEndY),
                                     .DColor(dColor), .read(lineDone), .currWrite(lrWrite), 
                                     .clk(clk), .rst(rst));

    
    rasterizer rast(.startX(startX), .endX(endX), .startY(startY), .endY(endY), .lineColor(lineColor), 
                    .clk(clk), .rst(rst), .readyIn(readyLine), .addressOut(w_addr), 
                    .pixelX(pixelX), .pixelY(pixelY), .pixelColor(color_in), 
                    .goodPixel(en_w), .done(lineDone), .rastReady(rastReady));
                    
    VGA_fsm vfsm(.clk(clk), .rst(rst), .row(row), .col(col), .Hsync(Hsync), .Vsync(Vsync), .en_r(en_r));

    fb_controller fbc(.w_addr(w_addr), .en_w(en_w), .en_r(en_r), .done(vgrst), .clk(clk), .rst(rst), 
                      .row(row), .col(col), .color_in(color_in),
                      .red_out(vgaRed), .blue_out(vgaBlue), .green_out(vgaGreen), .ready(readyFrame));
    
   // fb_temp fbt(.w_addr(w_addr), .en_w(en_w), .en_r(en_r), .done(vggo||vgrst), .clk(clk), .rst(rst), 
     //                    .row(row), .col(col), .color_in(color_in),
      //                   .red_out(vgaRed), .blue_out(vgaBlue), .green_out(vgaGreen), .ready(readyFrame));
      
     tri[7:0] datainout;
     logic[7:0] buttons;
      
     //sound
     /*
     assign buttons = sw;
     assign ampSD = 1'b0;
     assign datainout = (~weEnBram[`BRAM_PCB]) ? dataToBram[`BRAM_PCB] : 'bz;
     assign dataFromBram[`BRAM_PCB] = datainout;
     
     POKEY pokey(.D(datainout), .A(addrToBram[`BRAM_PCB][3:0]), .P(buttons), .phi2(clk_3MHz), .readHighWriteLow(~weEnBram[`BRAM_PCB]),
                 .cs0Bar(pokeyEn), .aud(ampPWM), .clk(clk));
     */
      
endmodule
