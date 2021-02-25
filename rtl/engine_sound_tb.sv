module engine_sound_tb;

  logic rst = 0;
  logic clk;
  logic engine_rev_en;
  int  out;

  logic clk_en = 0;
  
  engine_sound engine_sound
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(1),
     .engine_rev_en(engine_rev_en),
     .out(out)
     );

  int expected_value  = 0;
  
  int file, i;
  
  task run_times(int times);
    for(int i = 0; i < times; i++) begin
      #(i*4);
      #1 clk = 1;
      #1 clk = 0;
      #1;

      $fwrite(file,"%d\n", out);
      //assert(out == expected_value) else begin
      //   $error("expected %d, actual %d",expected_value, out);      
      //end
    end
  endtask

  initial begin
    file = $fopen("engine.csv","wb");
    $fwrite(file,"%s\n", "value");
    
    engine_rev_en = 1;
    run_times(100000);
    engine_rev_en = 0;
    run_times(100000);

    $fclose(file);
  end
    
endmodule
