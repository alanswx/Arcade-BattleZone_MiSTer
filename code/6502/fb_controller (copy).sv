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
    
    enum logic[1:0] {READ_A = 2'b01, READ_B = 2'b10, READ_C = 2'b11} state, nextState;
    
    logic[18:0] addr_a, addr_b, addr_c, r_addr, clear_addr;
    logic[3:0] color_in_a, color_in_b, color_in_c, color_out_a, color_out_b, color_out_c, color_out;
    logic en_a, en_b, en_c, wen_a, wen_b, wen_c, clearCC;
    logic switch, lastDone, clearDoneLatch, startClearLatch;
    
    fbRAM_wrapper bramA(.addr_a(addr_a), .clk(clk), .color_in(color_in_a), .color_out(color_out_a), 
                            .en(en_a), .write_en(wen_a));
                            
    fbRAM_wrapper bramB(.addr_a(addr_b), .clk(clk), .color_in(color_in_b), .color_out(color_out_b), 
                            .en(en_b), .write_en(wen_b));
    fbRAM_wrapper bramC(.addr_a(addr_c), .clk(clk), .color_in(color_in_c), .color_out(color_out_c), 
                            .en(en_c), .write_en(wen_c));


    m_counter #(19) clearCounter(.Q(clear_addr), .D(19'd0), .clk(clk), .clr(rst), .load(clearCC), .up(1'b1), .en(1'b1));

    //catches edge of vggo/vgreset signals
    m_register #(1) edgeCatcher(.Q(lastDone), .D(done), .clr(rst), .en(1'b1), .clk(clk));
    
    //assign switch = (lastDone == 1'b0 && done == 1'b1);
    assign switch = clearDoneLatch && row == 'd0 && col == 'd0;
    
    //clear counter when all addresses are cleared
    assign clearCC = (clear_addr > 19'd307200);

    //Calc addr from row/col
    assign r_addr = row*'d640 + col;
    
    //assign colors       
    /*assign red_out[0] = color_out[2]; 
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
    */
    //switch between brams
    always_comb begin
        if(row >= 0 && row <= 120) begin
            red_out = color_out;
            green_out = 4'b0000;
            blue_out = 4'b0000;
        end
        else begin
            red_out = 4'b0000;
            green_out = color_out;
            blue_out = 4'b0000;
        end
    
        case(state)
            READ_A: begin //sel A for read, B for write, C for clear
                //mux
                color_in_a = 4'd0;
                addr_a = r_addr;
                wen_a = 1'b0;
                en_a = en_r;
                            
                color_in_b = color_in;
                addr_b = w_addr;
                wen_b = 1'b1;
                en_b = en_w;
                
                
                color_in_c = 4'd0;
                addr_c = clear_addr;
                wen_c = 1'b1;
                en_c = 1'b1;

                //demux
                color_out = color_out_a;
            end
            READ_B: begin //sel B for read, C for write, A for clear
               //mux
                color_in_b = 4'd0;
                addr_b = r_addr;
                wen_b = 1'b0;
                en_b = en_r;
                            
                color_in_c = color_in;
                addr_c = w_addr;
                wen_c = 1'b1;
                en_c = en_w;
                
                
                color_in_a = 4'd0;
                addr_a = clear_addr;
                wen_a = 1'b1;
                en_a = 1'b1;
   
               //demux
               color_out = color_out_b;
           end
           READ_C: begin //sel C for read, A for write, B for clear
              //mux
              color_in_c = 4'd0;
              addr_c = r_addr;
              wen_c = 1'b0;
              en_c = en_r;
                          
              color_in_a = color_in;
              addr_a = w_addr;
              wen_a = 1'b1;
              en_a = en_w;
              
              
              color_in_b = 4'd0;
              addr_b = clear_addr;
              wen_b = 1'b1;
              en_b = 1'b1;
              
              
              //demux
              color_out = color_out_c;
          end
        endcase
        
    end
    
    //DEPRECATED
    always_comb begin
        ready = 1'b0; //done state and changing
    end
    
    //bram nextState logic
    always_comb begin
        case(state)
            READ_A: begin
                if(switch == 1'b1) begin
                    nextState = READ_B;
                end
                else begin
                    nextState = READ_A;
                end
            end
            READ_B: begin
                if(switch == 1'b1) begin
                    nextState = READ_C;
                end
                else begin
                    nextState = READ_B;
                end
            end
            READ_C: begin
                if(switch == 1'b1) begin
                    nextState = READ_A;
                end
                else begin
                    nextState = READ_C;
                end
            end
        endcase
    end
    
   always_ff@(posedge clk)
      if(rst) begin
        clearDoneLatch <= 1'b0;
      end
      else begin
        if(row == 'd479 && col == 'd639) begin
            clearDoneLatch <= 1'b1;
        end
        else begin
            clearDoneLatch <= 1'b0;
        end
      end
    
    //bram state
    always_ff@(posedge clk)
      if(rst) begin
        state <= READ_A;
      end
      else begin
        state <= nextState;
      end
        
endmodule
