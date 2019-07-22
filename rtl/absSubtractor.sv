module absSubtractor
  #(parameter BUSWIDTH = 13)
   (input logic [BUSWIDTH-1:0] A, B,
    output logic [BUSWIDTH-1:0] absDiff
    );

   logic [BUSWIDTH-1:0] 	negB, diff;
   
   
   negator #(BUSWIDTH) bNegator(.valIn(B), .valOut(negB));
   m_adder #(BUSWIDTH) subtraction(diff,, A, negB, 1'b0);
   absVal #(BUSWIDTH) magnitude(.valIn(diff), .valOut(absDiff));
   


endmodule 