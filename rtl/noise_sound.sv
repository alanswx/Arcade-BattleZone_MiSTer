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

  wire[15:0] unfiltered;

  iir #(FILTER_STRENGTH,16) iir
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in(unfiltered),
     .out(out)
     );

  
  logic[31:0] amp = 0;

  assign unfiltered = ({{17{1'b0}}, {15{noise}}} * amp ) >> 16;
  logic[6:0] amp_divider = 0;

  always @(posedge clk) begin
    if(clk_3MHz_en)begin
      amp_divider = amp_divider +1;
      if(noise_en)begin
        if(loud_soft)begin
          amp <= 1 <<< 15;          
        end else begin
          amp <= (1 <<< 15) - (1 << 13);
        end
      end else if(amp > 4) begin
        if(amp_divider == 0)begin
          amp <= (amp * (65536 - DECAY)) >>> 16;
        end
      end else begin
        amp <= 0;
      end
    end
  end
endmodule
