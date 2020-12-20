module switchMux
  #(parameter BUSWIDTH = 13)
   (output logic [BUSWIDTH-1:0] U, V,
    input logic [BUSWIDTH-1:0] A, B,
    input logic 	       Sel
    );
   

   m_mux2to1 #(BUSWIDTH) uMux(.Y(U), .I0(A), .I1(B), .Sel(Sel));
   m_mux2to1 #(BUSWIDTH) vMux(.Y(V), .I0(B), .I1(A), .Sel(Sel));
   
   

endmodule 