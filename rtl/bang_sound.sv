module bang_sound
  (
   input clk,
   input clk_48KHz_en,
   input[3:0] crsh,
   output logic[15:0] out = 0
   );

  // localparam longint double_cos_omega_32 = 8589026053;
  // // dampening_per_wave = 1 / 1.3
  // localparam longint dampening_ratio_per_sample_32 = 4292359648; 

  logic signed[48:0] double_cos_omega_20 = 2096930;
  // dampening_per_wave = 1 / 1.3
  logic signed[47:0] dampening_ratio_per_sample_20 = 1047939;  // (dampening_per_wave**(1/samples_per_wave_length))**6
  
  logic signed[27:0] current_sample_12 = 0;
  logic signed[27:0] last_sample_12 = 0;
  logic signed[27:0] pre_last_sample_12 = 0;

  logic[3:0] last_crsh = 0;
  
  logic signed[21:0] change = 0;

  logic[1:0] step = 0;
  
  always_ff @(posedge clk)begin
    if(clk_48KHz_en)begin
      step <= 1;
      change <= (last_crsh - crsh) <<< 17;
      last_crsh <= crsh;
      pre_last_sample_12 <= dampen(last_sample_12);
      if(current_sample_12 < -(2**24)) begin
        out <= 2**15 - 2**12;
      end else begin
        out <= (current_sample_12 >>> 12) + 2**15;
      end
    end
    if(step)begin
      casex (step)
        1: last_sample_12 <= current_sample_12;
        2: current_sample_12 <= change + continue_sine();
        3: current_sample_12 <= dampen(current_sample_12);
      endcase
      step <= step + 1;
    end
    
  end

  function automatic logic signed[27:0] continue_sine();
    return ((double_cos_omega_20*last_sample_12) >>> 20)-pre_last_sample_12;
  endfunction

  function  automatic logic signed[27:0] dampen(logic signed[27:0] sample);
    return (sample*dampening_ratio_per_sample_20) >>> 20;
  endfunction
endmodule
