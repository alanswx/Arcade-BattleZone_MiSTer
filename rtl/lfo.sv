module lfo
  (
   input rst, 
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   output logic[7:0] out = 0
   );

  
  logic[13:0] counter = 0;
  always @(posedge clk) begin  
    if (rst) begin;
      out <= 0;
    end else if(clk_3MHz_en)begin
      counter <= counter + 1;
      if(counter == 0)begin
	if (!engine_rev_en) begin
	  if(out != 255)begin
	    out <= out + 1;
	  end
	end else begin
	  if (out != 0) begin
	    out <= out - 1;
	  end
	end
      end
    end
  end

endmodule
