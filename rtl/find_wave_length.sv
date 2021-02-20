module find_wave_length
  (
   input rst, 
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output int wave_length
   );

  int counter = 0;  
  logic was_set = 0;
  
  always @(posedge clk) begin
    if (rst) begin
      counter <= 0;
      wave_length <= 0;
    end else if (clk_3MHz_en) begin    
      counter <= counter + 1;
      if(engine_rev_en && counter != 0 && !was_set)begin
	wave_length <= counter - 1;
	counter <= 0;
	was_set <= 1;
      end
      if(!engine_rev_en)begin
	was_set <= 0;
      end
    end
  end

endmodule
