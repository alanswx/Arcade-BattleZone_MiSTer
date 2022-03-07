
// Anything sound related goes into this file
// Reference can be found in:
// https://arcarc.xmission.com/PDF_Arcade_Atari_Kee/Battlezone/Battlezone_DP-156-2nd-03B.pdf
// pokey probably should also include the output latch, condluded by comparing the above to:
// https://i.imgur.com/CTNZr9q.png
// it seems that the K outputs on the pokey are the output latch outputs
module sound
  (
   input rst,
   input clk,
   input clk_3MHz,
   input clk_3MHz_en,
   input clk_12KHz_en,
   input clk_48KHz_en,
   input mod_redbaron,
   input[24:0] dl_addr,
   input[7:0] dl_data,
   input should_read, 
   input[7:0] buttons,
   input[15:0] addr_to_bram, 
   input[7:0] data_to_bram,
   output audiosel,
   output[7:0] data_from_bram,
   output[15:0] audio
   );
  
  logic pokeyEn;
  logic pokeyEnRB;
  logic pokeyEnBZ;

  wire[3:0] pokey_audio;
  wire[7:0] outputLatch;
  wire output_latch_should_read = should_read && (addr_to_bram == 16'h1840 || addr_to_bram == 16'h1808);
  
  // Red Baron has the pokey in a different position
  assign pokeyEnBZ = ~(addr_to_bram >= 16'h1820 && addr_to_bram < 16'h1830);
  assign pokeyEnRB = ~(addr_to_bram >= 16'h1810 && addr_to_bram < 16'h1820);
  assign pokeyEn = mod_redbaron ? pokeyEnRB : pokeyEnBZ;
  assign audiosel = outputLatch[0];

  POKEY pokey
    (
     .Din(data_to_bram),
     .Dout(data_from_bram),
     .A(addr_to_bram[3:0]),
     .P(buttons),
     .phi2(clk_3MHz),
     .readHighWriteLow(~should_read),
     .cs0Bar(pokeyEn),
     .audio(pokey_audio),
     .clk(clk)
     );

  output_latch output_latch
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .should_read(output_latch_should_read),
     .data_to_pokey_bram(data_to_bram),
     .out(outputLatch)
     );

  audio_output audio_output
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_12KHz_en(clk_12KHz_en),
     .clk_48KHz_en(clk_48KHz_en),
     .dl_addr(dl_addr),
     .dl_data(dl_data),
     .mod_redbaron(mod_redbaron),
     .pokey_audio(pokey_audio),
     .output_latch(outputLatch),
     .out(audio)
     );

endmodule
