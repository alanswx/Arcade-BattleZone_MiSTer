module bang_sound
  (
   input clk,
   input clk_en_48KHz,
   input[3:0] crsh,
   output logic[16:0] out
   );

  localparam longint double_cos_omega_32 = 8589026053;
  // dampening_per_wave = 1 / 1.3
  localparam longint dampening_ratio_per_sample_32 = 4292359648; // (dampening_per_wave**(1/samples_per_wave_length))**6
  
  longint current_sample_12 = 0;
  longint last_sample_12 = 0;

  logic[3:0] last_crsh = 0;
  
  longint would_be_12 = 0;
  longint change = 0;

  always @(posedge clk)begin
    if(clk_en_48KHz)begin
      change = last_crsh - crsh;
      last_crsh = crsh;

      if(change)begin
        would_be_12 = continue_sine();
        last_sample_12 <= (current_sample_12 * dampening_ratio_per_sample_32) >>> 32;
        current_sample_12 <= (change <<< 17) + ((would_be_12 * dampening_ratio_per_sample_32) >>> 32);
      end else begin
        current_sample_12 <= (continue_sine() * dampening_ratio_per_sample_32) >>> 32;
        last_sample_12 <= (current_sample_12 * dampening_ratio_per_sample_32) >>> 32;
      end
      // end

      //TODO, not sure of this limit, in the circuit it's -5 volts from the middle of the sinusoid.
      if(current_sample_12 < -(2**24)) begin
        out <= 2**15 - 2**12;
      end else begin
        out <= (current_sample_12 >>> 12) + 2**15;
      end
    end
  end

  function longint continue_sine;
    return ((double_cos_omega_32*current_sample_12) >>> 32)-last_sample_12;
  endfunction

endmodule
