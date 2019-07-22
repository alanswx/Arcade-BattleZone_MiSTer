`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2015 07:05:50 PM
// Design Name: 
// Module Name: VGA_fsm
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

module VGA_fsm(
    input logic clk, rst,
    output logic[8:0] row,
    output logic[9:0] col,
    output logic Hsync, Vsync, en_r
    //input[3:0] pixel,
    //output[18:0] addr,
    );
    
    wire[9:0] H_MAX = 799;
    wire[9:0] V_MAX = 522;
    wire[9:0] H_PULSE = 96;
    wire[9:0] V_PULSE = 2;
    wire[9:0] H_FP = 16;
    wire[9:0] V_FP = 10;
    wire[9:0] H_BP = 48;
    wire[9:0] V_BP = 29;
   
    logic clearH, clearV, enH, enV, h_sync_val, v_sync_val, clk_50, clk_25;
    logic[9:0] hCount;
    logic[9:0] vCount;
    logic[1:0] clockCount;
/*    
    vga_counter #(10) hCounter(clk_25, clearH, enH, rst_l, hCount);
    vga_counter #(10) vCounter(clk_25, clearV, enV, rst_l, vCount);

    vga_register #(1) hReg(h_sync_val, clk_25, rst_l, 1'b1, Hsync);
    vga_register #(1) vReg(v_sync_val, clk_25, rst_l, 1'b1, Vsync);

    vga_register #(4) redReg(R, clk_25, rst_l, 1'b1, vgaRed);
    vga_register #(4) greenReg(G, clk_25, rst_l, 1'b1, vgaGreen);
    vga_register #(4) blueReg(B, clk_25, rst_l, 1'b1, vgaBlue);
  */  
  

    //m_counter #(10) hCounter(.Q(hCount), .D(11'd0), .clk(clk_25), .clr(rst), .load(clearH), .en(enH), .up(1'b1));
    //m_counter #(10) vCounter(.Q(vCount), .D(11'd0), .clk(clk_25), .clr(rst), .load(clearV), .en(enV), .up(1'b1));
    

    m_counter #(10) hCounter(.Q(hCount), .D(10'd0), .clk(clk_25), .clr(rst), .load(clearH), .up(enH), .en(1'b1));
    m_counter #(11) vCounter(.Q(vCount), .D(10'd0), .clk(clk_25), .clr(rst), .load(clearV), .up(enV), .en(1'b1));

    
    m_register #(1) hReg(.Q(Hsync), .D(h_sync_val), .clr(rst), .en(1'b1), .clk(clk_25));
    m_register #(1) vReg(.Q(Vsync), .D(v_sync_val), .clr(rst), .en(1'b1), .clk(clk_25));
      
    //m_register #(4) redReg(.Q(vgaRed), .D(R), .clr(rst), .en(1'b1), .clk(clk_25));
    //m_register #(4) redGreen(.Q(vgaGreen), .D(G), .clr(rst), .en(1'b1), .clk(clk_25));
    //m_register #(4) redBlue(.Q(vgaBlue), .D(B), .clr(rst), .en(1'b1), .clk(clk_25));

    assign enH = 1'b1;
    
    //counter v and h sync
    always_comb begin
        if(hCount >= H_MAX) begin
            clearH = 1'b1;
            h_sync_val = 1'b1;
            enV = 1'b0;
        end  
        else if(hCount >= H_FP+H_PULSE) begin
            clearH = 1'b0;
            h_sync_val = 1'b1;
            enV = 1'b0;
        end
        else if(hCount == H_FP+H_PULSE) begin
            clearH = 1'b0;
            h_sync_val = 1'b0;
            enV = 1'b1;
        end
        else if(hCount >= H_FP) begin
            clearH = 1'b0;
            h_sync_val = 1'b0;
            enV = 1'b0;
        end                   
        else begin
            clearH = 1'b0;
            h_sync_val = 1'b1;
            enV = 1'b0;
        end
        
        
        if(vCount >= V_MAX) begin
            clearV = 1'b1;
            v_sync_val = 1'b1;
        end              
        else if(vCount >= V_FP+V_PULSE) begin
            clearV = 1'b0;
            v_sync_val = 1'b1;
        end           
        else if(vCount >= V_FP) begin
            clearV = 1'b0;
            v_sync_val = 1'b0;
        end           
        else begin
            clearV = 1'b0;
            v_sync_val = 1'b1;
        end
        
        
            
    end
    
    assign en_r = 1'b1;//(hCount >= H_FP+H_PULSE+H_BP) && (vCount >= V_FP+V_PULSE+V_BP);
    
    //pixel
    always_comb begin
        if(hCount >= H_FP+H_PULSE+H_BP) begin
            col = hCount - (H_FP+H_PULSE+H_BP);
        end
        else begin
            col = 0;
        end
    
        if(vCount >= V_FP+V_PULSE+V_BP) begin
            row = vCount - (V_FP+V_PULSE+V_BP);
        end 
        else begin
            row = 0;
        end
    end 
    
   always_ff @(posedge clk, posedge rst) begin
        if(rst) clk_50 <= 0;
        else clk_50 <= ~clk_50;
    end
    
        
    always_ff @(posedge clk_50, posedge rst) begin
        if(rst) clk_25 <= 0;
        else clk_25 <= ~clk_25;
    end
    /*
    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            clockCount <= 0;
        end
        else begin
            clockCount <= clockCount + 1;
        end
    end
    
    assign clk_25 = clockCount > 1;*/
    

endmodule: VGA_fsm
/*
module vga_counter
  #(parameter WIDTH = 8)
  (input  bit clk, clear, en, rst_L,
   output bit [WIDTH-1:0] Q);

  always_ff@(posedge clk, negedge rst_L)
    if(~rst_L)
      Q <= 0;
    else if (clear)
      Q <= 0;
    else if (en)
      Q <= Q + 1;
endmodule: vga_counter



module vga_register
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] D,
    input logic clk, clr, en,
    output logic [WIDTH-1:0] Q );

   always_ff @(posedge clk, negedge clr)
     if(~clr)
       Q <= 0;
     else if(en) Q <= D;
   
endmodule: vga_register*/