module noise_source_shell_explo_tb;

  logic clk;
  logic clk_3MHz_en=1;
  logic clk_12KHz_en=1;
  logic sound_enable = 1;
  logic shell_en = 1;
  logic explo_en = 1;
  logic shell_ls = 0;
  logic explo_ls = 0;
  logic rst = 0;
  wire[15:0] explo_noise, shell_noise;

  noise_source_shell_explo noise_source_shell_explo(
    clk,
    clk_3MHz_en,
    clk_12KHz_en,
    sound_enable,
    shell_en,
    shell_ls,
    explo_en,
    explo_ls,
    explo_noise,
    shell_noise
  );

  int shell_file, explo_file;
  int cycle = 0;
  task run_times(int times);
    for(int i = 0; i < times; i++) begin
      #(i*4);
      cycle += 1;
      clk_12KHz_en = (cycle % 4) == 0;
      #1 clk = 1;
      #1 clk = 0;


      $fwrite(shell_file,"%d\n", shell_noise);
      $fwrite(explo_file,"%d\n", explo_noise);
    end
  endtask

  initial begin
    shell_file = $fopen("shell_noise.csv","wb");
    explo_file = $fopen("explo_noise.csv","wb");
    $fwrite(shell_file,"%s\n", "value");
    $fwrite(explo_file,"%s\n", "value");    
    run_times($urandom_range(800,1200));
    explo_en = 0;
    shell_en = 0;
    run_times(128000);
    explo_ls = 1;
    shell_ls = 1;
    explo_en = 1;
    shell_en = 1;
    run_times($urandom_range(800,1200));
    explo_en = 0;
    shell_en = 0;
    run_times(128000);
    $fclose(shell_file);
    $fclose(explo_file);
  end
  
endmodule
