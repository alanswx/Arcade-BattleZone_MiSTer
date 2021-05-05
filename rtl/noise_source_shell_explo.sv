module noise_source_shell_explo
  (
   input clk,
   input clk_3MHz_en,
   input clk_12KHz_en,
   input sound_enable,
   input shell_en,
   input shell_ls,
   input explo_en,
   input explo_ls,
   output[15:0] noise_explo,
   output[15:0] noise_shell
   );

  logic explo,shell;
  logic last_explo,last_shell;
  logic explo_clk_en, shell_clk_en;

  noise_shifters noise_shifters
    (
     .clk(clk),
     .clk_12KHz_en(clk_12KHz_en),
     .sound_enable(sound_enable),
     .shell(shell),
     .explo(explo)
     );
  
  noise_sound #(5, 2) shell_noise
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_en(shell_clk_en),
     .noise_en(shell_en),
     .loud_soft(shell_ls),
     .out(noise_shell)
     );

  noise_sound #(6, 1) explo_noise
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_en(explo_clk_en),
     .noise_en(explo_en),
     .loud_soft(explo_ls),
     .out(noise_explo)
     );

  always @(clk) begin
    if(clk_3MHz_en)begin
      explo_clk_en <= explo != last_explo && explo;
      shell_clk_en <= shell != last_shell && shell;
      last_explo <= explo;
      last_shell <= shell;
    end
  end

endmodule 
