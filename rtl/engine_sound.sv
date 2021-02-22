module engine_sound
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output int out
   );

  wire[31:0] lfo_value;
  
  lfo lfo
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .out(lfo_value)
     );

  iir #(7,32) iir
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in(sample),
     .out(out)
     );

  wire[31:0] frequency;
  assign frequency = (lfo_value * lfo_value) >> 20;

  int sample;
  int step_size;
  localparam clock_frequency = 48000;
  
  assign step_size = clock_frequency / frequency;

  always @(posedge clk) begin
    if(rst)begin
      sample <= 0;
    end else if(clk_3MHz_en)begin
      sample <= sample + step_size;
    end
  end

endmodule
