module audio_output
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input clk_12KHz_en,
   input clk_48KHz_en,
   input mod_redbaron,
   input[24:0] dl_addr,
   input[7:0] dl_data,
   input[3:0] pokey_audio,
   input[7:0] output_latch, // output_latch[6] is unused, it is the start_led
   output logic[15:0] out
   );

  wire[15:0] pokey_filtered;

  wire sound_enable = output_latch[5];
  
  wire[15:0] analog_audio;
  
  analog_sound analog_sound
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_12KHz_en(clk_12KHz_en),
     .clk_48KHz_en(clk_48KHz_en),
     .mod_redbaron(mod_redbaron),
     .dl_addr(dl_addr),
     .dl_data(dl_data),
     .sound_enable(sound_enable),
     .motor_en(output_latch[7]),
     .engine_rev_en(output_latch[4]),
     .shell_ls(output_latch[3]),
     .shell_en(output_latch[2]),
     .explo_ls(output_latch[1]),
     .explo_en(output_latch[0]),
     .crsh({output_latch[7], output_latch[6], output_latch[5], output_latch[4]}),
     .out(analog_audio)
     );

  iir #(6,16) iir_pokey // FIXME: calculate the needed depth of this filter, and do there need to be multiple iirs stacked?
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in({{2'b0}, {pokey_audio}, {10'b0}}),
     .out(pokey_filtered)
     );

  iir #(2,20) iir_out
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in(out_unfiltered),
     .out(out)
     );

  logic[15:0] out_unfiltered;
  always @(posedge clk) begin
    if (clk_3MHz_en) begin
      if(rst || (!mod_redbaron && !sound_enable))begin
	      out_unfiltered <= 0;
      end else begin
      	mix_sound();
      end
    end
  end

  task mix_sound;
    out_unfiltered <= pokey_filtered + analog_audio;
  endtask
  
endmodule
