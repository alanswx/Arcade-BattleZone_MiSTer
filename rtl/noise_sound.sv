module noise_sound
  #(
    parameter FILTER_STRENGTH = 7,
    parameter DECAY = 2
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
     .D(noise),
     .q(),
     .q_(noise)
     );


  wire[31:0] filtered;
  iir #(FILTER_STRENGTH,16) iir
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in({{1{1'b0}}, {15{noise}}}),
     .out(filtered)
     );

  
  logic[15:0] amp = 0;

  assign out = (filtered * amp ) >> 16;
  logic amp_divider = 0;
  always @(posedge clk) begin
    if(clk_3MHz_en)begin
      amp_divider = ~amp_divider;
      if(noise_en)begin
        if(loud_soft)begin
          amp <= 1 <<< 15;          
        end else begin
          amp <= 1 <<< 14;
        end
      end else if(amp > 4) begin
        if(amp_divider)begin
          amp <= amp -DECAY; // FIXME: this should probably be a curve, not linear
        end
      end else begin
        amp <= 0;
      end
    end
  end
endmodule
