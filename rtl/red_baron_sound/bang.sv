module bang
  (
   input clk,
   input clk_en_48KHz,
   input[3:0] crsh,
   output shortint out
   );

  localparam sample_rate = 48000;
  localparam samples_per_wave_length = 432; // 48000 * 0.009
  localparam dampening_per_wave_length = 788; // (1<<10)/1.3
  localparam dampening_ratio_per_sample = (dampening_per_wave_length << 10)  / samples_per_wave_length;
  localparam crsh_to_opamp_top_out_ratio = -46;//(4.994520 - 5.667248) / 15 * 2**10
  localparam pi = 3216; //pi * 2 ** 10
  
  shortint current_sample = 0;
  shortint last_sample = 0;
  logic[8:0] current_index = 0;

  shortint sine[samples_per_wave_length-1:0];
  logic[8:0] angles_to_sine_index[samples_per_wave_length-1:0];
  logic[3:0] last_crsh;
  
  always @(posedge clk)begin
    if(clk_en_48KHz)begin
      last_crsh <= crsh;
      last_sample <= current_sample;
      current_index <= get_next_sine_index();
      current_sample <= (sine[current_index] * current_sample * dampening_ratio_per_sample) >>> 10;
      out <= current_sample; // TODO: add minimum value for current sample, distortion for loud sounds
    end
  end

  function get_next_sine_index;
    shortint amplitude = current_sample / sin(2pi/0.009*x)
    shortint delta = current_sample - last_sample;
    return (current_sample << 10) / delta;
  endfunction

endmodule
