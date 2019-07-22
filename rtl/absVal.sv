module absVal
  #(parameter BUSWIDTH = 13)
   (input logic [BUSWIDTH-1:0] valIn,
    output logic [BUSWIDTH-1:0] valOut
    );

   logic [BUSWIDTH-1:0] 	valMid;
   
   
   always_comb
     begin
	if(valIn[BUSWIDTH-1])
	  valMid = ~valIn;
	else
	  valMid = valIn;
	
     end
   
   
   assign valOut = valMid + valIn[BUSWIDTH-1];
   
   

endmodule 