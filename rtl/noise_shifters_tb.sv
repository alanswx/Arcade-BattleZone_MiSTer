module noise_shifters_tb;

  logic clk;
  logic sound_enable = 0;
  logic rst = 0;
  wire explo_noise, shell_noise;

  noise_shifters noise_shifters
    (
     .rst(rst),
     .clk(clk),
     .clk_12KHz_en(1'b1),
     .sound_enable(sound_enable),
     .shell(shell_noise),
     .explo(explo_noise)
     );

  int shell_file, explo_file;
  
  task run_times(int times);
    for(int i = 0; i < times; i++) begin
      #(i*4);
      #1 clk = 1;
      #1 clk = 0;
      #1;

      $fwrite(shell_file,"%d\n", shell_noise);
      $fwrite(explo_file,"%d\n", explo_noise);
    end
  endtask

  initial begin
    shell_file = $fopen("shell_noise.csv","wb");
    explo_file = $fopen("explo_noise.csv","wb");
    $fwrite(shell_file,"%s\n", "value");
    $fwrite(explo_file,"%s\n", "value");    
    rst = 0;
    run_times(1);
    rst = 0;
    run_times(5);
    #1; 
    sound_enable = 1;
    run_times(500);
    $fclose(shell_file);
    $fclose(explo_file);
  end
  
endmodule
