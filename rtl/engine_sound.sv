module engine_sound
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output logic[3:0] out
   );

  logic[3:0] counter = 0;
  assign out = counter;

  wire should_count;
  pulse_generator pulse_generator
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .out(should_count)
     );
  
  always @(posedge clk) begin
    if(rst)begin
      counter <= 4'b0;
    end else if(clk_3MHz_en && should_count)begin
      counter <= counter + 1;
    end
  end

endmodule
