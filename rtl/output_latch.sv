module output_latch
  (
   input rst, 
   input clk, 
   input clk_3MHz_en, 
   input should_read, 
   input[7:0] data_to_pokey_bram, 
   output logic[7:0] out
   );

  always_ff @(posedge clk) begin
    if (clk_3MHz_en) begin
      if(rst) begin
        out <= 'd0;
      end
      if(should_read) begin
        out <= data_to_pokey_bram;
      end
    end
  end
  
endmodule
