module audio_output
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input[3:0] pokey_audio,
   input[7:0] output_latch,
   output shortint out
   );

  wire[15:0] pokey_amplified = {{1'b0}, {pokey_audio}, {11'b0}};

  wire start_led = output_latch[6];
  wire sound_enable = output_latch[5];
  
  wire[15:0] analog_audio;
  
  analog_sound analog_sound
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .motor_en(output_latch[7]),
     .engine_rev_en(output_latch[4]),
     .shell_ls(output_latch[3]),
     .shell_en(output_latch[2]),
     .explo_ls(output_latch[1]),
     .explo_en(output_latch[0]),
     .out(analog_audio)
     );
  
  always @(posedge clk) begin
    if (clk_3MHz_en) begin
      if(rst || !sound_enable)begin
	out <= 0;
      end else begin
      	mix_sound();
      end
    end
  end

  task mix_sound;
    out <= pokey_amplified + analog_audio;
  endtask // mix_sound
  
endmodule
