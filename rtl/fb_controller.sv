`timescale 1ns / 1ps
`default_nettype none
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


module fb_controller
  (
   input wire [18:0]  w_addr,
   input wire         en_w, en_r,
   input wire         lineDone, lrqEmpty,
   input wire         halt, vggo, clk, rst,
   input wire [8:0]   row,
   input wire [9:0]   col,
   input wire [3:0]   color_in,
	input wire         mod_battlezone,
   output logic [3:0] red_out,
   output logic [3:0] blue_out,
   output logic [3:0] green_out,
   output logic       ready
   );

  typedef enum        logic[1:0] {READ_A = 2'b00, READ_B = 2'b01, WRITE_A = 2'b10, WRITE_B = 2'b11} state_t;

  state_t state;
  state_t nextState;

  typedef enum        logic[1:0] {HALTED = 2'b01, WAIT = 2'b00, HALT_EMPTY = 2'b10} switchState_t;

  switchState_t switchState;
  switchState_t nextSwitchState;

  logic [18:0]        addr_a;
  logic [18:0]        addr_b;
  logic [18:0]        r_addr;
  logic [18:0]        clear_addr;
  logic [3:0]         color_in_a;
  logic [3:0]         color_in_b;
  logic [3:0]         color_out_a;
  logic [3:0]         color_out_b;
  logic [3:0]         color_out_a_int;
  logic [3:0]         color_out_b_int;
  logic [3:0]         color_out;
  logic               en_a;
  logic               en_b;
  logic               wen_a;
  logic               wen_b;
  logic               clearCC;
  logic               read_switch;
  logic               vggolastDone;
  logic               haltlastDone;

  logic [3:0]         brama_store[307200];
  logic [3:0]         bramb_store[307200];

  always @(posedge clk) begin
    if (en_a) begin
      if (wen_a) brama_store[addr_a] <= color_in_a;
      color_out_a <= brama_store[addr_a];
    end
    if (en_b) begin
      if (wen_b) bramb_store[addr_b] <= color_in_b;
      color_out_b <= bramb_store[addr_b];
    end
  end

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

  logic vggo_switch;
  logic halt_switch;

  assign vggo_switch = (~vggolastDone & vggo);
  assign halt_switch = (~haltlastDone & halt);

    //clear counter when all addresses are cleared
    assign clearCC = (clear_addr > 19'd307200);

    //Calc addr from row/col
    assign r_addr = row*640 + col;

    //switch between brams
    always_comb begin
	    if (mod_battlezone) begin	 
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
		 end
		 else begin
					red_out = color_out;
					green_out = color_out;
					blue_out = color_out;
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
  // This was modified as the original code created latches and never
  // worked as intended.
  always_comb begin
    read_switch = '0;
    case (switchState)
      WAIT: begin
        if (halt_switch) nextSwitchState = HALTED;
        else             nextSwitchState = WAIT;
      end
      HALTED: begin
        nextSwitchState = HALT_EMPTY;
      end
      HALT_EMPTY: begin
        nextSwitchState = WAIT;
        read_switch     = '1;
      end
      default: nextSwitchState = switchState;
    endcase // case (switchState)
  end

  always_ff@(posedge clk)
    if(rst) begin
      switchState <= WAIT;
    end else begin
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
                if(vggo_switch) begin
                    nextState = WRITE_B;
                end
                else begin
                    nextState = READ_A;
                end
            end
            WRITE_B: begin
                if(read_switch) begin
                    nextState = READ_B;
                end
                else begin
                    nextState = WRITE_B;
                end
            end
            READ_B: begin
                if(vggo_switch) begin
                    nextState = WRITE_A;
                end
                else begin
                    nextState = READ_B;
                end
            end
            WRITE_A: begin
                if(read_switch) begin
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
`default_nettype wire
