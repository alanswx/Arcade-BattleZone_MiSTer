module SquealSound
  (
   input clk,
   input clk_48KHz_en,
   input play,
   output reg[15:0] audio
   );
  
  reg[15:0] squeal_samples[48000];
  int sample_counter = 0;

  always @(posedge clk) begin
    if (~play) begin
      sample_counter <= 0;
      audio <= 0;
    end else if (clk_48KHz_en && sample_counter < 48000) begin
      audio <= squeal_samples[sample_counter];
      sample_counter <= sample_counter + 1;
    end
  end
  
  initial begin
`include "squeal_samples.sv"
  end

endmodule

