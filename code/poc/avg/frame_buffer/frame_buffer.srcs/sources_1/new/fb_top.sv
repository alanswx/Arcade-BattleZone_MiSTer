`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2015 11:44:23 AM
// Design Name: 
// Module Name: fb_top
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


module fb_top(
    input logic clk, btnCpuReset,
    output logic[3:0] vgaRed, vgaBlue, vgaGreen,
    output logic Hsync, Vsync
    );
    
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
    
    assign rst = ~rst_l;
    assign readyLine = ~empty;
    
    m_register #(1) syncRstRegA(.Q(rst_unstable), .D(btnCpuReset), .clr(1'b0), .en(1'b1), .clk(clk));
    m_register #(1) syncRstRegB(.Q(rst_l), .D(rst_unstable), .clr(1'b0), .en(1'b1), .clk(clk));

    VGA_fsm vfsm(.clk(clk), .rst(rst), .row(row), .col(col), .Hsync(Hsync), .Vsync(Vsync), .en_r(en_r));

    fb_controller fbc(.w_addr(w_addr), .en_w(en_w), .en_r(en_r), .done(done), .clk(clk), .rst(rst), 
                      .row(row), .col(col), .color_in(color_in),
                      .red_out(vgaRed), .blue_out(vgaBlue), .green_out(vgaGreen), .ready(readyFrame));
                        
    //animation_tb atb(.startX(startX), .endX(endX), .startY(startY), .endY(endY), .readyLine(readyLine), 
    //                    .color(lineColor), .rastReady(rastReady), .clk(clk), .rst(rst), 
    //                   .readyFrame(readyFrame), .vsync(Vsync));
                        
    rasterizer rast(.startX(startX), .endX(endX), .startY(startY), .endY(endY), .lineColor(lineColor), 
                    .clk(clk), .rst(rst), .readyIn(readyLine), .addressOut(w_addr), 
                    .pixelX(pixelX), .pixelY(pixelY), .pixelColor(color_in), 
                    .goodPixel(en_w), .done(lineDone), .rastReady(rastReady));
                    
    avg_core avgc(.startX(dStartX), .startY(dStartY), .endX(dEndX), .endY(dEndY), 
                  .color(dColor), .lrWrite(lrWrite), .pcOut(pc), .inst(inst), .clk_in(clk), 
                  .rst(rst), .vggo(readyFrame));
    lineRegQueue lrq(.QStartX(startX), .QStartY(startY), .QEndX(endX), .QEndY(endY), 
                     .QColor(lineColor), .full(full), .empty(empty), 
                     .DStartX(dStartX), .DStartY(dStartY), .DEndX(dEndX), .DEndY(dEndY),
                                     .DColor(dColor), .read(lineDone), .currWrite(lrWrite), 
                                     .clk(clk), .rst(rst));
    avgROM_wrapper avgRW (.addra(pc[13:0]), .addrb(pc[13:0] + 14'd1), .clk(clk), .dina(8'b0), .dinb(8'b0), 
                          .douta(inst[15:8]), .doutb(inst[7:0]), .ena(1'b1), .wea(1'b0));

endmodule


module fb_test(
    input logic clk, rst, ready,
    input logic[8:0] row,
    input logic[9:0] col,
    output logic[18:0] w_addr,
    output logic[3:0] color,
    output logic en_w,
    output logic done);

    logic clr, switch;
    logic[9:0] count;

    enum logic{RUN = 1'b0, DONE = 1'b1} state, nextState;

    always_comb begin
        if(col >= 160 && col < 320) begin
            color = 4'b0001;
            w_addr = row*640 + col;
            en_w = 1'b1;
        end
        else if(col >= 320 && col < 480 && switch == 1'b1) begin
            color = 4'b0100;
            w_addr = row*640 + col;
            en_w = 1'b1;
        end
        else begin
            color = 4'b0010;
            w_addr = row*640 + col;
            en_w = 1'b0;
        end
        
        if(state == RUN)
            if(row == 479 && col == 640)
                nextState = DONE;
            else
                nextState = RUN;
        else
            if(ready)
                nextState = RUN;
            else
                nextState = DONE;
            
        done = (state == RUN) && (nextState == DONE);
    
    end
    
    counter #(10) countFrame(clk, clr, 1'b1, ~clr, count);
    
    always_comb begin
        if(count >= 10000) begin
            clr = 1'b1;
        end
        else begin
            clr = 1'b0;
        end
    end
    
   always_ff @(posedge clk, posedge rst) begin
    if(rst)
        switch <= 1'b0;
    else if (done) 
        switch <= ~switch;
    else
        switch <= switch;
   end
   
   always_ff @(posedge clk, posedge rst) begin
        if(rst)
            state <= RUN;
        else
            state <= nextState;
   end

endmodule: fb_test

/*
module ChipInterface
	(input logic clk,
	input logic btnCpuReset,
	//input logic [17:0] SW,
	//output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
        output logic[3:0] vgaRed, vgaBlue, vgaGreen,
        output logic Hsync, Vsync);
	
	logic [8:0] row;
	logic [9:0] col;
	logic blank, clk_50;
	logic done, en_w;
	logic[3:0] color_in, redTD, blueTD, greenTD, redFB, blueFB, greenFB;
	logic[18:0] w_addr;
	
	vga display(clk_50, ~btnCpuReset, Hsync, Vsync, blank, row, col);
	//vgaTestDisplay colorBars(row, col, vgaRed, vgaGreen, vgaBlue);
    fb_controller fbc(w_addr, en_w, done, clk, ~btnCpuReset, row, col, color_in,
                  vgaRed, vgaBlue, vgaGreen, ready);
                    
    fb_test fbt(clk_50,~btnCpuReset, row, col, w_addr, color_in, en_w, done);
    
    always_ff @(posedge clk, negedge btnCpuReset) begin
        if(~btnCpuReset) clk_50 <= 0;
        else clk_50 <= ~clk_50;
    end
    
endmodule: ChipInterface


module vgaTestDisplay
	(input logic [8:0] row,
	input logic [9:0] col,
	output logic [7:0] r, g, b);
	
	logic isRed;
	logic [1:0] isGreen;
	logic [3:0] isBlue;
	
	range_check #(10) redCheck(col, 10'd320, 10'd639, isRed);
	range_check #(10) greenCheck0(col, 10'd160, 10'd319, isGreen[0]);
	range_check #(10) greenCheck1(col, 10'd480, 10'd639, isGreen[1]);
	offset_check #(10) blueCheck0(col, 10'd80, 10'd79, isBlue[0]);
	offset_check #(10) blueCheck1(col, 10'd240, 10'd79, isBlue[1]);
	offset_check #(10) blueCheck2(col, 10'd400, 10'd79, isBlue[2]);
	offset_check #(10) blueCheck3(col, 10'd560, 10'd79, isBlue[3]);
	
	assign r = (isRed ? 8'hFF : 8'h00);
	assign g = ((isGreen == 2'b0) ? 8'h00 : 8'hff);
	assign b = ((isBlue == 4'b0) ? 8'h00 : 8'hff);
	
endmodule: vgaTestDisplay

module range_check
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] val, low, high,
    output logic is_between);

   logic 	 smallEnough, largeEnough;
  
   comparator #(WIDTH) lc(,,largeEnough, low, val);
   comparator #(WIDTH) hc(,,smallEnough, val, high);

   assign is_between = ~smallEnough & ~largeEnough;
   
endmodule: range_check

module offset_check
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] val, low, delta,
    output logic is_between);

   logic 	 [WIDTH-1:0] high;
   
   adder #(WIDTH) add(high,, low, delta, 1'b0);
   range_check #(WIDTH) rc(.*);

endmodule: offset_check

module comparator
  #(parameter WIDTH = 6)
  (output logic AltB, AeqB, AgtB,
   input logic [WIDTH-1:0] A, B);

   assign AltB = (A < B);
   assign AeqB = (A == B);
   assign AgtB = (A > B);

endmodule: comparator
module adder
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Sum,
    output logic Cout,
    input logic [WIDTH-1:0] A, B,
    input logic Cin);
   
   assign {Cout, Sum} = A + B + Cin;

endmodule: adder
*/