module control_voltage_to_555_out_wavelength
  (
   input clk,
   input clk_3MHz_en,
   input[7:0] control_voltage,
   output int wave_length
   );
  
  int wave_lengths[256];

  always @(posedge clk) begin
    if (clk_3MHz_en) begin
      wave_length <= wave_lengths[control_voltage];
    end
  end
  
  initial begin
`include "frequencies.sv"
  end

endmodule
