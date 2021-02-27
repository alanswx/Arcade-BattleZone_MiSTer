module analog_sound
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input clk_6KHz_en,
   input sound_enable,
   input motor_en,
   input engine_rev_en,
   input shell_ls,
   input shell_en,
   input explo_ls,
   input explo_en,
   output shortint out
   );


  wire[15:0] explo,shell;

  noise_source_shell_explo noise_source_shell_explo
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_6KHz_en(clk_6KHz_en),
     .sound_enable(sound_enable),
     .shell_en(shell_en),
     .shell_ls(shell_ls),
     .explo_en(explo_en),
     .explo_ls(explo_ls),
     .noise_explo(explo),
     .noise_shell(shell)
     );
  
  wire[15:0] engine;
  engine_sound engine_sound
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .motor_en(motor_en),
     .out(engine)
     );

  wire[15:0] engine_mixed = engine & {16{motor_en}};
  
  assign out = (engine_mixed >> 1) + (explo >> 1) + (shell >> 1);
  
endmodule
