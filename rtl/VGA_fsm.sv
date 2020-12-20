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

module VGA_fsm
  (
   input wire         clk, rst,
   output logic [8:0] row,
   output logic [9:0] col,
   output logic       Hsync, Vsync, en_r, hBlank, vBlank
   );

  wire [9:0]          H_MAX = 800;
  wire [9:0]          V_MAX = 525;
  wire [9:0]          H_PULSE = 95;
  wire [9:0]          H_FP = 16;
  wire [9:0]          H_BP = 48;
  wire [9:0]          V_PULSE = 2;
  wire [9:0]          V_FP = 10;
  wire [9:0]          V_BP = 32;

  logic               clearH, clearV, enH, enV, h_sync_val, v_sync_val, clk_50, clk_25;
  bit [9:0]           hCount;
  bit [9:0]           vCount;
  logic [9:0]         row_out;
  logic [3:0]         R, G, B;

    assign clk_50=clk;

  always_ff @(posedge clk) begin
    if (clk_25) begin
      if (rst) begin
        hCount <= '0;
        vCount <= '0;
      end else begin
        if (clearH)   hCount <= '0;
        else if (enH) hCount <= hCount + 1'b1;
        if (clearV)   vCount <= '0;
        else if (enV) vCount <= vCount + 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (clk_25) begin
      if (rst) begin
        Hsync <= '0;
        Vsync <= '0;
      end else begin
        Hsync <= h_sync_val;
        Vsync <= v_sync_val;
      end
    end
  end

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
    assign hBlank = ~(hCount >= H_FP+H_PULSE+H_BP);
    assign vBlank = ~(vCount >= V_FP+V_PULSE+V_BP);

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

  always_ff @(posedge clk_50, posedge rst) begin
    if(rst) clk_25 <= 1;
    else clk_25 <= ~clk_25;
  end


endmodule
