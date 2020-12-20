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
    input logic lineDone, lrqEmpty,
    input logic halt, vggo, clk, rst,
    input logic[8:0] row,
    input logic[9:0] col,
    input logic[3:0] color_in,
    output logic[3:0] red_out,
    output logic[3:0] blue_out,
    output logic[3:0] green_out,
    output logic ready
    );
    
    enum logic[1:0] {READ_A = 2'b00, READ_B = 2'b01, WRITE_A = 2'b10, WRITE_B = 2'b11} state, nextState;
    enum logic[1:0] {HALTED = 2'b01, WAIT = 2'b00, HALT_EMPTY = 2'b10} switchState, nextSwitchState;
    
    logic[18:0] addr_a, addr_b, r_addr, clear_addr;
    logic[3:0] color_in_a, color_in_b, color_out_a, color_out_b, color_out;
    logic en_a, en_b, wen_a, wen_b, clearCC;
    logic read_switch, vggolastDone, haltlastDone;
    /* alanswx
fbRAM_wrapper bramA(
	.addr_a(addr_a), 
	.clk(clk), 
	.color_in(color_in_a), 
	.color_out(color_out_a), 
   .en(en_a),
	.write_en(wen_a)
);*/
  gen_ram #(
	.dWidth(4),
	.aWidth(19))
bRamA(
	.clk(clk),
	.we(wen_a),
	.addr(addr_a),
	.d(color_in_a), 
	.q(color_out_a) 
	);
        
/*		  
fbRAM_wrapper bramB(
	.addr_a(addr_b), 
	.clk(clk), 
	.color_in(color_in_b), 
	.color_out(color_out_b), 
   .en(en_b), 
	.write_en(wen_b)
);
  */ 
  gen_ram #(
	.dWidth(4),
	.aWidth(19))
bRamB(
	.clk(clk),
	.we(wen_b),
	.addr(addr_b),
	.d(color_in_b), 
	.q(color_out_b) 
	);
    m_counter #(19) clearCounter(.Q(clear_addr), .D(19'd0), .clk(clk), .clr(rst), .load(clearCC), .up(1'b1), .en(1'b1));

    //catches edge of vggo/vgreset signals
    always_ff@(posedge clk)
      if(rst) begin
        vggolastDone <= 1'b0;
        haltlastDone <= 1'b0;
      end
      else begin
          vggolastDone <= vggo;
          haltlastDone <= halt;
      end
    //m_register #(1) vggoEdgeCatcher(.Q(vggolastDone), .D(vggodone), .clr(rst), .en(1'b1), .clk(clk));
    //m_register #(1) haltEdgeCatcher(.Q(haltlastDone), .D(haltdone), .clr(rst), .en(1'b1), .clk(clk));
    
    
    assign vggo_switch = (vggolastDone == 1'b0 && vggo == 1'b1);
    assign halt_switch = (haltlastDone == 1'b0 && halt == 1'b1);
    assign read_switch = (switchState == HALT_EMPTY && nextSwitchState == WAIT);
    
    //clear counter when all addresses are cleared
    assign clearCC = (clear_addr > 19'd307200);

    //Calc addr from row/col
    assign r_addr = row*640 + col;
    
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
    //clear to b read from a, write to b read from a, clear to a read from b, write to a read from b
        case(state)
            READ_A: begin //clear to b read from a
                //mux
                color_in_a = 4'd0;
                addr_a = r_addr;
                wen_a = 1'b0;
                en_a = en_r;                
                
                color_in_b = 4'd0;
                addr_b = clear_addr;
                wen_b = 1'b1;
                en_b = 1'b1;

                //demux
                color_out = color_out_a;
            end
            WRITE_B: begin //write to b read from a,
                //mux
                color_in_a = 4'd0;
                addr_a = r_addr;
                wen_a = 1'b0;
                en_a = en_r;
                            
                color_in_b = color_in;
                addr_b = w_addr;
                wen_b = 1'b1;
                en_b = en_w;
                
                //demux
                color_out = color_out_a;
            end
            READ_B: begin //sclear to a read from b
               //mux
                color_in_b = 4'd0;
                addr_b = r_addr;
                wen_b = 1'b0;
                en_b = en_r;                
                
                color_in_a = 4'd0;
                addr_a = clear_addr;
                wen_a = 1'b1;
                en_a = 1'b1;
   
               //demux
               color_out = color_out_b;
           end
           WRITE_A: begin //write to a read from b
              //mux
               color_in_b = 4'd0;
               addr_b = r_addr;
               wen_b = 1'b0;
               en_b = en_r;
                           
               color_in_a = color_in;
               addr_a = w_addr;
               wen_a = 1'b1;
               en_a = en_w;
  
              //demux
              color_out = color_out_b;
          end
        endcase
        
    end
    
    
    //switching state
	 always @ ( clk) begin
 //   always_comb begin
        if(switchState == WAIT && halt_switch == 1'b1) begin
            nextSwitchState = HALTED;
        end
        else if (switchState == HALTED && lrqEmpty == 1'b1) begin
            nextSwitchState = HALT_EMPTY;
        end
        else if (switchState == HALT_EMPTY && lineDone == 1'b1) begin
            nextSwitchState = WAIT;
        end
    end
    
    
    always_ff@(posedge clk)
      if(rst) begin
        switchState <= WAIT;
      end
      else begin
        switchState <= nextSwitchState;
      end
      
   
    
    //DEPRECATED
    always_comb begin
        ready = 1'b0; //done state and changing
    end
    
    //bram nextState logic
    always_comb begin
        case(state)
            READ_A: begin
                if(vggo_switch == 1'b1) begin
                    nextState = WRITE_B;
                end
                else begin
                    nextState = READ_A;
                end
            end
            WRITE_B: begin
                if(read_switch == 1'b1) begin
                    nextState = READ_B;
                end
                else begin
                    nextState = WRITE_B;
                end
            end
            READ_B: begin
                if(vggo_switch == 1'b1) begin
                    nextState = WRITE_A;
                end
                else begin
                    nextState = READ_B;
                end
            end
            WRITE_A: begin
                if(read_switch == 1'b1) begin
                    nextState = READ_A;
                end
                else begin
                    nextState = WRITE_A;
                end
            end
        endcase
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