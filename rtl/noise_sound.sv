module noise_sound
  #(
    parameter FILTER_STRENGTH = 7
    ) (
       input clk,
       input clk_3MHz_en,
       input clk_en,
       input noise_en,
       input loud_soft,
       output[15:0] out
       );

  wire noise;
  
  ls74 ls74_top
    (
     .clk(clk),
     .clk_en(clk_en),
     ._set(1),
     .clr(1),
     .D(noise),
     .q(),
     .q_(noise)
     );


  wire[15:0] filtered;
  
  iir #(FILTER_STRENGTH,16) iir
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in({{3{1'b0}}, noise, {12{1'b0}}}),
     .out(filtered)
     );

  
  shortint amp = 0;

  assign out = ((filtered >> 16'd10) * (amp  >> 16'd10));

  always @(posedge clk) begin
    if(clk_3MHz_en)begin
      if(noise_en)begin
	amp <= 1 <<< 20;
      end else if(amp > 0) begin
	amp <= amp - 64;
      end else begin
	amp <= 0;
      end
    end
  end
endmodule
