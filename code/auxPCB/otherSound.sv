module otherSound
  (

   );

endmodule: otherSound


module lfsr
  (
   input logic e6khz,
   input logic soundEn,
   output logic sig1, sig2
   );

   always_ff@(posedge e6khz)
     begin
	
     end
   
   
   
endmodule: lfsr
