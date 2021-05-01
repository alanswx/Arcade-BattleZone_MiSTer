module iir
  #(
    parameter GAIN = 8,
    parameter WIDTH = 16
    ) (
       input clk,
       input clk_3MHz_en,
       input[WIDTH-1:0] in,
       output logic[WIDTH-1:0] out
       );
  
  reg signed [WIDTH+GAIN-1:0] accumulator = 0;
  
  always @(posedge clk) begin
    if (clk_3MHz_en) begin
      accumulator <= accumulator + {{GAIN{1'b0}},{in - out}};
    end
  end
  assign out = accumulator[WIDTH+GAIN-1:GAIN];
  
endmodule
