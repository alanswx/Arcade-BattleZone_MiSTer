module engine_sound_tb;

  logic rst = 0;
  logic clk;
  logic engine_rev_en;
  logic[3:0] out;
  
  engine_sound engine_sound
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(1'b1),
     .engine_rev_en(engine_rev_en),
     .out(out)
     );

  logic[3:0] expected_value  = 0;
  task run_times(int times);
    for(int i = 0; i < times; i++) begin
      #(i*4);
      #1 clk = 1;
      #1 clk = 0;
      #1;
      $display(out);
      //assert(out == expected_value) else begin
      //   $error("expected %d, actual %d",expected_value, out);      
      //end
    end
  endtask

  initial begin
    engine_rev_en = 1;
    run_times(1);
    engine_rev_en = 0;
    run_times(4000);
    engine_rev_en = 1;
    run_times(1);
    engine_rev_en = 0;
    run_times(100000);
  end
    
endmodule
