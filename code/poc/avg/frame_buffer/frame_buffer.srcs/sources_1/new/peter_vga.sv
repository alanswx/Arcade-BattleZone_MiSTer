`timescale 1ns / 1ps
module vga
  (input logic clk, reset,
   output logic HS, VS, blank,
   output logic [8:0] row,
   output logic [9:0] col);

   logic [10:0] hClockCount;
   logic       rolloverH, hdisp, colInc, hblank, CLOCK_50;

   logic [9:0] lines;
   logic       rolloverV, vdisp, vblank;
   
   m_counter #(11) clockCounterH(hClockCount,, CLOCK_50, reset | rolloverH,
			      1'b0, 1'b1, 1'b1);
   m_comparator #(11) hRolloverCheck(, rolloverH,, 11'd1599, hClockCount);
   m_offset_check #(11) hdispCheck(hClockCount, 11'd288, 11'd1279, hdisp);
   m_comparator #(11) hpulseCheck(,, HS, hClockCount, 11'd191);
   m_counter #(1) colIncTracker(colInc,, CLOCK_50, reset | rolloverH,
			      1'b0, hdisp, 1'b1);
   m_counter #(10) colTracker(col,, CLOCK_50, reset | rolloverH,
			    1'b0, colInc, 1'b1);

   m_counter #(10) lineCounter(lines,, CLOCK_50, reset | (rolloverH & rolloverV),
			     1'b0, rolloverH, 1'b1);
   m_comparator #(10) vRolloverCheck(, rolloverV,, 10'd520, lines);
   m_offset_check #(10) vdispCheck(lines, 10'd31, 10'd479, vdisp);
   m_comparator #(10) vpulseCheck(,, VS, lines, 10'd1);
   m_counter #(9) rowTracker(row,, CLOCK_50, reset | rolloverV,
			   1'b0, rolloverH & vdisp, 1'b1);

   assign blank = ~(hdisp & vdisp);
   
   always_ff @(posedge clk, posedge reset) begin
       if(reset) CLOCK_50 <= 0;
       else CLOCK_50 <= ~CLOCK_50;
   end
     
endmodule: vga