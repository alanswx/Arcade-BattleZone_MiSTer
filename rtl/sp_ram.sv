`timescale 1ns / 1ps

module sp_ram
  #
  (
   parameter DATA = 8,
   parameter ADDR = 10
   )
  (
   // Port A
   input wire              clk,
   input wire              clk_en,
   input wire              wr,
   input wire [ADDR-1:0]   addr,
   input wire [DATA-1:0]   din,
   output logic [DATA-1:0] dout
   );

  // Shared memory
  logic [DATA-1:0]         mem [2**ADDR];

  initial begin
    mem = '{default: '0};
  end

  // Port A
  always @(posedge clk) begin
    if (clk_en) begin
      dout      <= mem[addr];
      if(wr) begin
        //dout      <= din;
        mem[addr] <= din;
      end
    end
  end
endmodule
