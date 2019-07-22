`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2015 05:03:50 PM
// Design Name: 
// Module Name: fb_controller
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


module fb_controller(

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
    
    enum logic[1:0] {WRITE_A = 2'b00, WRITE_B = 2'b01, DONE_A = 2'b10, DONE_B = 2'b11} state, nextState;
    
    logic[18:0] addr_a, addr_b, r_addr, addr_a_next, addr_b_next;
    logic[3:0] color_in_a, color_in_b, color_out_a, color_out_b, color_out, color_out_next_b, color_out_next_a;
    logic en_a, en_b, wen_a, wen_b, wen_clear_a, wen_clear_b, en_clear_a, en_clear_b;
    
    blockRam_wrapper bramA(.addr_a(addr_a), .clk(clk), .color_in(color_in_a), .color_out(color_out_a), 
                            .en(en_a), .write_en(wen_a), .color_out_b(color_out_next_a), 
                            .addr_b(addr_a_next), .clear_in(4'b0000), .en_b(en_clear_a), .write_en_b(wen_clear_a));
                            
    blockRam_wrapper bramB(.addr_a(addr_b), .clk(clk), .color_in(color_in_b), .color_out(color_out_b), 
                            .en(en_b), .write_en(wen_b), .color_out_b(color_out_next_b),
                            .addr_b(addr_b_next), .clear_in(4'b0000), .en_b(en_clear_b), .write_en_b(wen_clear_b));

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
    
    //switch between brams
    always_comb begin
        case(state)
            WRITE_A: begin //sel A for write, B for read
                //mux
                color_in_a = color_in;
                addr_a = w_addr;
                wen_a = 1'b1;
                en_a = en_w;
                addr_a_next = 'b0;
                en_clear_a = 1'b0;
                wen_clear_a = 1'b0;
                
                color_in_b = 'b0;
                addr_b = r_addr;
                wen_b = 1'b0;
                en_b = en_r;
                addr_b_next = r_addr-1;
                en_clear_b = en_r;
                if(r_addr-1 >= 0 && r_addr-1<=307200)
                    wen_clear_b = 1'b1;
                else 
                    wen_clear_b = 1'b0;
                
                //demux
                color_out = color_out_b;
            end
            DONE_A: begin //wait for sync pulse to finish
                //mux
                color_in_a = color_in;
                addr_a = w_addr;
                wen_a = 1'b1;
                en_a = 1'b0;
                addr_a_next = 'b0;
                en_clear_a = 1'b0;
                wen_clear_a = 1'b0;
                
                color_in_b = 'b0;
                addr_b = r_addr;
                wen_b = 1'b0;
                en_b = en_r;
                addr_b_next = r_addr-1;
                en_clear_b = en_r;
                if(r_addr-1 >= 0 && r_addr-1<=307200)
                    wen_clear_b = 1'b1;
                else 
                    wen_clear_b = 1'b0;
                
                //demux
                color_out = color_out_b;
            end
            WRITE_B: begin //sel B for write, A for read
               //mux
               color_in_b = color_in;
               addr_b = w_addr;
               wen_b = 1'b1;
               en_b = en_w;
               addr_b_next = 'b0;
               en_clear_b = 1'b0;
               wen_clear_b = 1'b0;
               
               color_in_a = 'b0;
               addr_a = r_addr;
               wen_a = 1'b0;
               en_a = en_r;
               addr_a_next = r_addr-1;
               en_clear_a = en_r;
               if(r_addr-1 >= 0 && r_addr-1<=307200) 
                   wen_clear_a = 1'b1;
               else 
                   wen_clear_a = 1'b0;
               
               
               //demux
               color_out = color_out_a;
           end
            DONE_B: begin //wait for sync pulse to finish
              //mux
              color_in_b = color_in;
              addr_b = w_addr;
              wen_b = 1'b1;
              en_b = 1'b0;
              addr_b_next = 'b0;
              en_clear_b = 1'b0;
              wen_clear_b = 1'b0;
              
              color_in_a = 'b0;
              addr_a = r_addr;
              wen_a = 1'b0;
              en_a = en_r;
              addr_a_next = r_addr-1;
              en_clear_a = en_r;
              if(r_addr-1 >= 0 && r_addr-1<=307200)
                  wen_clear_a = 1'b1;
              else 
                  wen_clear_a = 1'b0;
              
              //demux
              color_out = color_out_a;
          end
        endcase
        
    end
    
    //bram state output
    always_comb begin
        ready = (state[1] == 1'b1) && (nextState[1] == 1'b0); //done state and changing
    end
    
    //bram nextState logic
    always_comb begin
        case(state)
            WRITE_A: begin
                if(done == 1'b1 ||  (row == 479 && col == 639)) begin
                    nextState = DONE_A;
                end
                else begin
                    nextState = WRITE_A;
                end
            end
            DONE_A: begin
                if( (row == 0 && col == 0)) begin
                    nextState = WRITE_B;
                end
                else begin
                    nextState = DONE_A;
                end
            end
            WRITE_B: begin
                if(done == 1'b1 || (row == 479 && col == 639)) begin
                    nextState = DONE_B;
                end
                else begin
                    nextState = WRITE_B;
                end
            end
            DONE_B: begin
                if( (row == 0 && col == 0)) begin
                    nextState = WRITE_A;
                end
                else begin
                    nextState = DONE_B;
                end
            end
        endcase
    end
    
    //bram state
    always_ff@(posedge clk)
      if(rst)
        state <= WRITE_A;
      else
        state <= nextState;
        
endmodule
