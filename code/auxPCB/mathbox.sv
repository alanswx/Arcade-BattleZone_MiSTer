module mathbox
  (
   inout logic [7:0] EDB,
   input logic [6:0] EAB,
   input logic e3Mhz, e6Mhz, ePhi2, eioBar, eReadHighWriteLow,
   output logic switchesBar, outputLatchBar
   );


   single139Mux c3_1(.gBar(eioBar), .A(EAB[6]), .B(EAB[5]), );
   

endmodule: mathbox

module single139Mux
  (
   input logic gBar,
   input logic A, B,
   output logic Y0, Y1, Y2, Y3
   );

   logic [3:0] 	Y;
   
   always_comb
     begin
	{{Y3},{Y2},{Y1},{Y0}} = Y;
	
	if(gBar)
	  begin
	     Y = 4'hF;
	  end
	else
	  begin
	     case({{A},{B}})
	       2'h0: Y = 4'hE;
	       2'h1: Y = 4'hD;
	       2'h2: Y = 4'hB;
	       2'h3: Y = 4'h7;
	     endcase // case ({{A},{B}})
	  end
     end

endmodule: single139Mux
