module pulse_generator
  (
   input rst, 
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output logic out
   );
  
  wire[31:0] lfo_length;
  int triangle_counter_direction = 1;
  localparam start_value = 1 << 8; // to make the highest fequency 256 times lower
  int triangle_counter = start_value + 1;
  logic was_set = 0;
  
  find_wave_length find_wave_length
    (
     .rst(rst), 
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .wave_length(lfo_length)
     );

  
  always @(posedge clk) begin  
    if (rst) begin
      triangle_counter_direction <= 1;
    end else if(clk_3MHz_en)begin
      if(triangle_counter == start_value || triangle_counter > lfo_length + start_value) begin
       	triangle_counter_direction <= triangle_counter_direction * -1;
	triangle_counter <= triangle_counter + triangle_counter_direction * -1;
      end else begin
	triangle_counter <= triangle_counter + triangle_counter_direction;
      end      
      if(triangle_counter[31 - get_high_bit_location(triangle_counter) - 2] && !was_set)begin
	out <= 1;
	was_set <= 1;
      end else begin
	if(!triangle_counter[31 - get_high_bit_location(triangle_counter) - 2])begin
	  was_set <= 0;
	end
	out <= 0;
      end
    end
  end

  
  function logic[4:0] get_high_bit_location(int number);
    logic[4:0] location;
    logic found;
    found = 0;
    for(logic[4:0] i = 0; i < 31; i++)begin
      if(!found && number[31-i])begin
	location = i;
	found = 1;
      end
    end
    return location;
  endfunction

endmodule
