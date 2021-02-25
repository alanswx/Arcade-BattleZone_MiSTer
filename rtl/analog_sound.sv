module analog_sound
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input motor_en,
   input engine_rev_en,
   input shell_ls,
   input shell_en,
   input explo_ls,
   input explo_en,
   output shortint out
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
  
  assign out = engine_mixed;
  
endmodule