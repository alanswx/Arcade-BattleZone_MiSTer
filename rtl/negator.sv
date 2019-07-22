module negator
  #(parameter BUSWIDTH = 13)
   (input logic [BUSWIDTH-1:0] valIn,
    output logic [BUSWIDTH-1:0] valOut
    );

   assign valOut = 1'b1 + ~valIn;
   


endmodule