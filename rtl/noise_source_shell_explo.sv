module noise_source_shell_explo
  (
   input clk,
   input clk_3MHz_en,
   input clk_6KHz_en,
   input sound_enable,
   input shell_en,
   input shell_ls,
   input explo_en,
   input explo_ls,
   output[15:0] noise_explo,
   output[15:0] noise_shell
   );

  wire explo,shell;

  noise_shifters noise_shifters
    (
     .clk(clk),
     .clk_6KHz_en(clk_6KHz_en),
     .sound_enable(sound_enable),
     .shell(shell),
     .explo(explo)
     );
  
  noise_sound #(6) shell_noise
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_en(shell),
     .noise_en(shell_en),
     .loud_soft(shell_ls),
     .out(noise_shell)
     );

  noise_sound #(8) explo_noise
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_en(explo),
     .noise_en(explo_en),
     .loud_soft(explo_ls),
     .out(noise_explo)
     );

endmodule 
