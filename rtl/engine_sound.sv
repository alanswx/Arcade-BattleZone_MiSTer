// FIXME: improve shape of LFO, currently it is a triangle, in reality it is somewhere between triangle and sine
// FIXME: improve accuracy of the iir by analysing the analog filter on the schematic

module engine_sound
  (
   input rst,
   input clk,
   input clk_3MHz_en,
   input engine_rev_en,
   input motor_en,
   output[15:0] out
   );

  wire[7:0] lfo_value;
  wire[31:0] wave_length;  
  int after_counters = 0;

  lfo lfo
    (
     .rst(rst),
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .engine_rev_en(engine_rev_en),
     .out(lfo_value)
     );
  
  control_voltage_to_555_out_wavelength cont_to_wave
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .control_voltage(lfo_value),
     .wave_length(wave_length)
     );
  
  iir #(8,32) iir
    (
     .clk(clk),
     .clk_3MHz_en(clk_3MHz_en),
     .in(after_counters),
     .out(out)
     );

  int counter = 0;

  byte counter1 = 4;
  byte counter2 = 6;
  logic last_motor_en = 0;
  
  always @(posedge clk) begin
    if(rst)begin
      // out <= 0;
    end else if(clk_3MHz_en)begin
      last_motor_en <= motor_en;
      if(motor_en && !last_motor_en)begin
          counter1 <= 0;
          counter2 <= 0;
      end else if(counter >= wave_length)begin
        counter <= 0;
        if(counter1 == 15)begin
          counter1 <= 9;
        end else begin
          counter1 <= counter1 + 1;
        end

        if(counter2 == 15)begin
          counter2 <= 11;
        end else begin
          counter2 <= counter2 + 1;
        end

      end else begin
      	counter <= counter + 1;
      end
    end
    after_counters <= (counter1 + counter2) <<< 11;
  end
  
endmodule
