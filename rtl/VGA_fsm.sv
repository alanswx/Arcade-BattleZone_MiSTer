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
    
    wire[9:0] H_MAX = 800;
    wire[9:0] V_MAX = 525;
    wire[9:0] H_PULSE = 95;
    wire[9:0] H_FP = 16;
    wire[9:0] H_BP = 48;
    wire[9:0] V_PULSE = 2;
    wire[9:0] V_FP = 10;
    wire[9:0] V_BP = 32;
   
    logic clearH, clearV, enH, enV, h_sync_val, v_sync_val, clk_50, clk_25;
    bit[9:0] hCount;
    bit[9:0] vCount;
    logic[9:0] row_out;
    logic[3:0] R, G, B;
    
    /*vga_counter #(10) hCounter(clk_25, clearH, enH, rst_l, hCount);
    vga_counter #(10) vCounter(clk_25, clearV, enV, rst_l, vCount);
    vga_register #(1) hReg(h_sync_val, clk_25, rst_l, 1'b1, Hsync);
    vga_register #(1) vReg(v_sync_val, clk_25, rst_l, 1'b1, Vsync);
    */
    m_counter #(10) hCounter(.Q(hCount), .D(10'd0), .clk(clk_25), .clr(rst), .load(clearH), .up(1'b1), .en(enH));
    m_counter #(10) vCounter(.Q(vCount), .D(10'd0), .clk(clk_25), .clr(rst), .load(clearV), .up(1'b1), .en(enV));

    
    m_register #(1) hReg(.Q(Hsync), .D(h_sync_val), .clr(rst), .en(1'b1), .clk(clk_25));
    m_register #(1) vReg(.Q(Vsync), .D(v_sync_val), .clr(rst), .en(1'b1), .clk(clk_25));
    
    
            
    assign enH = 1'b1;
    assign row = row_out[8:0];
    
    //counter v and h sync
    always_comb begin
        if(hCount >= H_MAX) begin
            clearH = 1'b1;
            h_sync_val = 1'b1;
            enV = 1'b0;
        end  
        else if(hCount > H_FP+H_PULSE) begin
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
    
    assign en_r = (hCount >= H_FP+H_PULSE+H_BP) && (vCount >= V_FP+V_PULSE+V_BP);
    
    //pixel
    always_comb begin
        if(hCount >= H_FP+H_PULSE+H_BP) begin
            col = hCount - (H_FP+H_PULSE+H_BP);
        end
        else begin
            col = 0;
        end
    
        if(vCount >= V_FP+V_PULSE+V_BP) begin
            row_out = vCount - (V_FP+V_PULSE+V_BP);
        end 
        else begin
            row_out = 0;
        end
    end 
    /*
    always_ff @(posedge clk, negedge rst_l) begin
        if(~rst_l) clk_50 <= 0;
        else clk_50 <= ~clk_50;
    end
    
        
    always_ff @(posedge clk_50, negedge rst_l) begin
        if(~rst_l) clk_25 <= 0;
        else clk_25 <= ~clk_25;
    end
    */
    always_ff @(posedge clk, posedge rst) begin
         if(rst) clk_50 <= 1;
         else clk_50 <= ~clk_50;
     end
     
         
     always_ff @(posedge clk_50, posedge rst) begin
         if(rst) clk_25 <= 1;
         else clk_25 <= ~clk_25;
     end
    

endmodule 