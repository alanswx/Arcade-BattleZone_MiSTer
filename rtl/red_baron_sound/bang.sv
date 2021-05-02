module bang
  (
   input clk,
   input clk_en_48KHz,
   input[3:0] crsh,
   output shortint out
   );

  localparam sample_rate_0 = 48000;
  localparam samples_per_wave_length_0 = 432; // 48000 / freq(111.1111hz)
  localparam omega_13 = 119; // = (freq(111.1111hz)*2*math.pi/sample_rate) * 2^13
  localparam double_cos_omega_6 = 128;
  // dampening_per_wave = 1 / 1.3
  localparam dampening_ratio_per_sample_6 = 64; // (dampening_per_wave**(1/samples_per_wave_length))**6
  localparam crsh_to_opamp_top_out_ratio_9 = -23;//(4.994520 - 5.667248) / 15 * 2**9
  localparam pi_5 = 306; //pi * 2 ** 5
  
  shortint current_sample = 0;
  shortint last_sample = 0;
  logic[8:0] current_index = 0;

  logic[3:0] last_crsh;
  
  shortint would_be = 0;
  shortint change = 0;

  always @(posedge clk)begin
    if(clk_en_48KHz)begin
      change <= last_crsh - crsh;
      last_crsh <= crsh;
      last_sample <= current_sample;

      if(change)begin
        would_be <= continue_sine();
        last_sample <= current_sample * dampening_ratio_per_sample_6 >>> 6;
        current_sample <= change + would_be * dampening_ratio_per_sample_6 >>> 6;
      end else begin
        current_sample <= continue_sine();
        last_sample <= current_sample * dampening_ratio_per_sample_6 >>> 6;
      end

      out <= current_sample; // TODO: add minimum value for current sample, distortion for loud sounds
    end
  end

  function reg[15:0] continue_sine;
    return double_cos_omega_6*current_sample-last_sample >>> 6;
  endfunction

endmodule
