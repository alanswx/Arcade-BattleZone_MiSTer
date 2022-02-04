module analog_sound(
  input rst,
  input clk,
  input clk_3MHz_en,
  input clk_12KHz_en,
  input clk_48KHz_en,
  input mod_redbaron,
  input ioctl_wr,
  input ioctl_index,
  input[24:0] dl_addr,
  input[7:0] dl_data,
  input sound_enable,
  input motor_en,
  input engine_rev_en,
  input shell_ls,
  input shell_en,
  input explo_ls,
  input explo_en,
  input[3:0] crsh,
  input[15:0] ioctl_addr,
  output logic[15:0] out,
  SdramSamplePlayerInterface sdramSamplePlayerBus
);

  sdram_sample_player sdram_sample_player(
    .bus(sdramSamplePlayerBus)
  );

  wire[15:0] explo,shell;
  assign sdramSamplePlayerBus.play_squeel = explo_ls;

  noise_source_shell_explo noise_source_shell_explo(
    .clk(clk),
    .clk_3MHz_en(clk_3MHz_en),
    .clk_12KHz_en(clk_12KHz_en),
    .sound_enable(sound_enable),
    .shell_en(shell_en),
    .shell_ls(shell_ls),
    .explo_en(explo_en),
    .explo_ls(explo_ls),
    .noise_explo(explo),
    .noise_shell(shell)
  );
  
  wire[15:0] engine;
  engine_sound engine_sound(
    .rst(rst),
    .clk(clk),
    .clk_3MHz_en(clk_3MHz_en),
    .engine_rev_en(engine_rev_en),
    .motor_en(motor_en),
    .out(engine)
  );

  wire[15:0] engine_mixed = engine & {16{motor_en}};


  wire [15:0] bang;
  wire [15:0] squeal;

  wire rnoise;

  noise_shifters_red_baron noise_shifters_red_baron(
   .rst(rst),
   .clk(clk),
   .clk_12KHz_en(clk_12KHz_en),
   .rnoise(rnoise)
  );

  bang_sound bang_sound(
    .clk(clk),
    .clk_48KHz_en(clk_48KHz_en),
    .crsh((crsh & {4{rnoise}})),
    .out(bang)
  );

  wire [15:0] shot_filtered;
  iir #(10,16) iir_shot(
    .clk(clk),
    .clk_3MHz_en(clk_3MHz_en),
    .in({{2{'0}}, {14{(rnoise && shell_en)}}}),
    .out(shot_filtered)
  );

  
  always @(posedge clk) begin
    if(clk_3MHz_en)begin
      if (mod_redbaron) begin
        out <= (bang >> 1) + (shot_filtered >> 2) + (sdramSamplePlayerBus.audio_out >> 2);
      end else begin
        out <= (engine_mixed >> 1) + (explo >> 1) + (shell >> 1);
      end
    end 
  end
  
endmodule
