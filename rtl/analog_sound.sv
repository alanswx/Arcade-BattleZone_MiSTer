module analog_sound
  (
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
   output shortint out
   );


  wire[15:0] explo,shell;

  noise_source_shell_explo noise_source_shell_explo
    (
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


  wire [15:0] bang;
  wire [15:0] shot;
  wire [15:0] squeal;

  wire rnoise;
  assign shot = {16{rnoise && shell_en}};

  noise_shifters_red_baron noise_shifters_red_baron(
   .rst(rst),
   .clk(clk),
   .clk_12KHz_en(clk_12KHz_en),
   .rnoise(rnoise)
  );

  dpram #(16,8) rom
  (
    .clock_a(clk),
    .wren_a(ioctl_wr && ioctl_index == 2),
    .address_a(dl_addr[15:0]),
    .data_a(dl_data),// TODO +4096?
    .clock_b(clk),
    .address_b(rom_a),
    .q_b(rom_d)
  );

  reg    [15:0]rom_a;
  wire   [16:0]rom_d;


  wave_sound wave_sound
  (
    .I_CLK(clk),
    .I_CLK_SPEED('d24000000),
    .I_RSTn(explo_ls),
    .I_H_CNT(hcnt[3:0]), // used to interleave data reads
    .I_DMA_TRIG(explo_ls),
    .I_DMA_STOP(~explo_ls),
    .I_DMA_CHAN(3'b1), // 8 channels
    .I_DMA_ADDR(16'b0),
    .I_DMA_DATA(rom_a), // Data coming back from wave ROM
    .O_DMA_ADDR(rom_d), // output address to wave ROM
    .O_SND(squeal)
  );

  bang_sound bang_sound(
   .clk(clk),
   .clk_en_48KHz(clk_en_48KHz),
   .crsh(crsh && {4{rnoise}}),
   .out(bang)
   );

  always @(posedge clk) begin
    if(clk_3MHz_en)begin
      if (mod_redbaron) begin
        out <= (bang >> 3) + (shot >> 3) + ((squeal && explo_ls)>> 3);
      end else begin
        out <= (engine_mixed >> 3) + (explo >> 3) + (shell >> 3);
      end
    end
  end
  
endmodule
