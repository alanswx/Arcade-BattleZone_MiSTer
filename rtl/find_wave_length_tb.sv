module find_wave_length_tb;
  int expected_value  = 0;
  int wave_length;
  logic clk = 0;
  logic engine_rev_en = 0;
  
  find_wave_length find_wave_length
    (
     .rst(1'b0),
     .clk(clk),
     .clk_3MHz_en(1'b1),
     .engine_rev_en(engine_rev_en),
     .wave_length(wave_length)
     );
  
  task run_times(int times);
    for(int i = 0; i < times; i++) begin
      #(i*4);
      #1 clk = 1;
      #1 clk = 0;
      #1;

      assert(wave_length == expected_value) else begin
      	$error("expected %d, actual %d",expected_value, wave_length);      
      end
    end
  endtask

  initial begin
    engine_rev_en = 0;
    run_times(1);
    engine_rev_en = 1;
    run_times(1);
    engine_rev_en = 0;
    run_times(99);
    engine_rev_en = 1;
    expected_value = 100;
    run_times(1);
    engine_rev_en = 0;
    run_times(1);
  end
  
endmodule
