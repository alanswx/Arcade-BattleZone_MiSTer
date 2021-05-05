module bang
  (
   input clk,
   input clk_en_48KHz,
   input[3:0] crsh,
   output reg[15:0] out
   );

  localparam double_cos_omega_6 = 128;
  // dampening_per_wave = 1 / 1.3
  localparam dampening_ratio_per_sample_6 = 64; // (dampening_per_wave**(1/samples_per_wave_length))**6
  
  shortint current_sample_9 = 0;
  shortint last_sample_9 = 0;

  logic[3:0] last_crsh;
  
  shortint would_be_9 = 0;
  shortint change = 0;

  always @(posedge clk)begin
    if(clk_en_48KHz)begin
      change <= last_crsh - crsh;
      last_crsh <= crsh;
      last_sample_9 <= current_sample_9;

      if(change)begin
        would_be_9 <= continue_sine();
        last_sample_9 <= current_sample_9 * dampening_ratio_per_sample_6 >> 6;
        current_sample_9 <= (change << 9) + would_be_9 * dampening_ratio_per_sample_6 >> 6;
      end else begin
        current_sample_9 <= continue_sine();
        last_sample_9 <= current_sample_9 * dampening_ratio_per_sample_6 >> 6;
      end

      if(current_sample_9 <= 30208) begin //30208 = (2^15) - 5*2^9
        out <= 30208;
      end else begin
        out <= current_sample_9 + 2**15;
      end
    end
  end

  function reg[15:0] continue_sine;
    return double_cos_omega_6*current_sample_9-last_sample_9 >> 6;
  endfunction

endmodule
