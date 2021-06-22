module bang_sound_tb;

  logic rst = 0;
  logic clk;
  logic engine_rev_en;
  wire[15:0]  out;

  logic clk_en = 1;
  logic [3:0] crsh = 10;

  bang_sound bang_sound (
   .clk(clk),
   .clk_48KHz_en('1),
   .crsh(crsh),
   .out(out)
   );

  int expected_value  = 0;
  
  int file, i;
  
  task run_times(int times);
    for(int i = 0; i < times; i++) begin

      #(i*(times/16));
      #1 clk = 1;
      #1 clk = 0;
      #1;
      if(i % 4 ==0)begin
        crsh = $urandom%(2) * (16 - 1 - i*16/times);
      end
      $display(crsh);
      $fwrite(file,"%d\n", out);
      //assert(out == expected_value) else begin
      //   $error("expected %d, actual %d",expected_value, out);      
      //end
    end
  endtask

  initial begin
    file = $fopen("bang.csv","wb");
    $fwrite(file,"%s\n", "value");
    
    run_times(48000);

    $fclose(file);
  end
    
endmodule
