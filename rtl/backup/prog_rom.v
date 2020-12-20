module prog_rom(
	   input [13:0] addr,
	   input clk,
	   output [7:0] data
	   );

   reg [7:0] q;
   
 wire [13:0] a = addr;
always @(posedge clk )
`include "prog.v"

  assign data = q;

   
endmodule // rom
