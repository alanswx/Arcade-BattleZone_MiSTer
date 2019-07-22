`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2015 05:22:20 PM
// Design Name: 
// Module Name: fb_temp
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


module fb_temp(


    input logic[18:0] w_addr,
    input logic en_w, en_r,
    input logic done, clk, rst,
    input logic[8:0] row,
    input logic[9:0] col,
    input logic[3:0] color_in,
    output logic[3:0] red_out,
    output logic[3:0] blue_out,
    output logic[3:0] green_out,
    output logic ready
    );
    
    logic[3:0] color_out;
    logic[18:0] r_addr;

    //Calc addr from row/col
    assign r_addr = row*640 + col;
    
    //assign colors       
    assign red_out[0] = color_out[2]; 
    assign red_out[1] = color_out[2];
    assign red_out[2] = color_out[2];
    assign red_out[3] = color_out[2];
    assign green_out[0] = color_out[1];
    assign green_out[1] = color_out[1];
    assign green_out[2] = color_out[1];
    assign green_out[3] = color_out[1];
    assign blue_out[0] = color_out[0];
    assign blue_out[1] = color_out[0];
    assign blue_out[2] = color_out[0];
    assign blue_out[3] = color_out[0];
        
     bramDualPort_wrapper dp(.addra(w_addr), .addrb(r_addr), .clk(clk), 
                              .color_in(color_in), .color_out(color_out), 
                              .en_a(en_w), .en_b(en_r), .wen_a(1'b1), .wen_b(1'b0));
                              
     
    
endmodule