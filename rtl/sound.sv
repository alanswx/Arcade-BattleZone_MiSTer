module sound(
  input rst,
  input clk,
  input clk_6KHz_en,
  input mod_redbaron,
  input should_read, 
  input[7:0] buttons,
  input[7:0] addr_to_bram, 
  input[7:0] data_to_bram,
  output audiosel, 
  output[7:0] data_from_bram,
  output[3:0] audio
);

  logic      pokeyEn;
  logic      pokeyEnRB;
  logic      pokeyEnBZ;
  
  // Red Baron has the pokey in a different position
  assign pokeyEnBZ = ~(addr_to_bram >= 16'h1820 && addr_to_bram < 16'h1830);
  assign pokeyEnRB = ~(addr_to_bram >= 16'h1810 && addr_to_bram < 16'h1820);
  assign pokeyEn = mod_redbaron ? pokeyEnRB : pokeyEnBZ;

  POKEY pokey
    (
     .Din              (data_to_bram ),
     .Dout             (data_from_bram),
     .A                (addr_to_bram[3:0]),
     .P                (buttons),
     .phi2             (clk_3MHz),
     .readHighWriteLow (~should_read),
     .cs0Bar           (pokeyEn),
     .aud              (ampPWM),
	  .audio (audio),
     .clk              (clk)
     );

  wire[7:0] outputLatch;
  wire output_latch_should_read = should_read
                                  && 
                                  (
                                      addr_to_bram == 16'h1840 
                                      || addr_to_bram == 16'h1808
                                  );
  output_latch output_latch(
    .rst(rst),
    .clk(clk),
    .clk_3MHz_en(clk_3MHz_en),
    .should_read(),
    .data_to_pokey_bram(data_to_bram),
    .out(outputLatch)
  );
  assign audiosel = outputLatch[0];

  audio_output audio_output(
    .rst(rst),
    .clk(clk),
    .clk_6KHz_en(clk_6KHz_en),
    .ampSD(outputLatch[5])
  );

endmodule