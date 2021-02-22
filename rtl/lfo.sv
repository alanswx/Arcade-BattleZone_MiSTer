module lfo
  (
   input rst, 
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output wire[31:0] out
   );
  
  wire[31:0] lfo_length;
  int triangle_counter_direction = 1;
  localparam min_value = 1 <<< 14;
  localparam max_value = 1 <<< 15;
  localparam int range = (max_value - min_value);
  int triangle_counter = min_value;
  assign out = triangle_counter;
  
  find_wave_length find_wave_length
    (
     .rst(rst), 
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .wave_length(lfo_length)
     );

  int step = 0;
  
  always @(posedge clk) begin  
    if (rst) begin
      triangle_counter_direction <= 1;
    end else if(clk_3MHz_en)begin
      
      if (triangle_counter < min_value) begin
       	triangle_counter_direction <= 1;
	triangle_counter <= min_value;
      end if (triangle_counter > max_value) begin
       	triangle_counter_direction <= -1;
	triangle_counter <= max_value;
      end else begin
	triangle_counter <= triangle_counter + step;
      end
      
      step <= range / lfo_length * triangle_counter_direction;      
    end
  end

endmodule
