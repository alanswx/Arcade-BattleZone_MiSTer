module mymy
  (
   input logic [3:0]  addrA, addrB,
   input logic [8:0]  I,
   inout logic 	      Q3, Q0,
   inout logic 	      RAM3, RAM0,
   input logic [3:0]  D,
   output logic [3:0] Y,
   input logic 	      oeBar,
   output logic       gBar, pBar,
   output logic       ovf, fEq0, f3,
   input logic 	      cN,
   output logic       cNplus4,
   input logic 	      cp
   );

   logic [3:0] 	      F;
   logic [3:0] 	      R, S;
   logic [3:0] 	      A, choiceA, B, choiceB;
   logic [3:0] 	      Q, choiceQ;
   logic [3:0] 	      choiceRAM;
   logic [3:0] 	      choiceY;
   
   logic 	      QregEn;
   

   nor fNor(fEq0, F[3], F[2], F[1], F[0]);
   assign f3 = F[3];
   
   aelou coreCalc(.R(R), .S(S), .F(F), .I(I[5:3]), .cN(cN), .pBar(pBar), .gBar(gBar), .cNplus4(cNplus4), .ovf(ovf));
   aluInputSelector aluIS(.A(A), .B(B), .D(D), .Q(Q), .I(I[2:0]), .R(R), .S(S));
   qMux qm(.I(I[8:6]), .F(F), .Qin(Q), .Qout(choiceQ), .QregEn(QregEn), .eQ0(Q0), .eQ3(Q3));
   qRegister qr(.Qin(choiceQ), .Qout(Q), .cp(cp), .QregEn(QregEn));
   ramMux rm(.I(I[8:6]), .F(F), .RAMout(choiceRAM), .eRAM0(RAM0), .eRAM3(RAM3));
   ramFile rf(.addrA(addrA), .addrB(addrB), .ramDataIn(choiceRAM), .A(choiceA), .B(choiceB), .I(I[8:6]), .cp(cp));
   transparentLatch latchA(.D(choiceA), .Q(A), .E(~cp));
   transparentLatch latchB(.D(choiceB), .Q(B), .E(~cp));
   outputMux om(.I(I[8:6]), .F(F), .A(A), .Y(choiceY));
   tristateBuf outputBuf(.oeBar(oeBar), .inY(choiceY), .outY(Y));
   
endmodule: mymy

module transparentLatch
  #(parameter W = 4)
   (
    input logic [W-1:0]  D, 
    input logic 	 E,
    output logic [W-1:0] Q
    );

   assign Q = E ? D : Q;
   

endmodule: transparentLatch

module outputMux
  (
   input logic [8:6]  I,
   input logic [3:0]  F, A,
   output logic [3:0] Y
   );

   assign Y = (I == 3'b010) ? A : F;

endmodule: outputMux


module tristateBuf
  (
   input logic 	      oeBar,
   input logic [3:0]  inY,
   output logic [3:0] outY
   );

   assign outY = oeBar ? 4'bzzzz : inY;
   
endmodule: tristateBuf


module ramFile
  (
   input logic [3:0]  addrA, addrB,
   input logic [3:0]  ramDataIn,
   output logic [3:0] A, B,
   input logic [8:6]  I,
   input logic 	      cp
   );

   logic [15:0]       RAMen;

   logic [15:0][3:0]  dataOut;

   transparentLatch #(4) dataStorage[15:0](.D(ramDataIn), .E(RAMen), .Q(dataOut));

   always_comb
     begin
	A = dataOut[addrA];
	B = dataOut[addrB];

	RAMen[0] = (addrB == 4'h0) & (|I[8:7]) & (~cp);
	RAMen[1] = (addrB == 4'h1) & (|I[8:7]) & (~cp);
	RAMen[2] = (addrB == 4'h2) & (|I[8:7]) & (~cp); 
	RAMen[3] = (addrB == 4'h3) & (|I[8:7]) & (~cp); 
	RAMen[4] = (addrB == 4'h4) & (|I[8:7]) & (~cp);
	RAMen[5] = (addrB == 4'h5) & (|I[8:7]) & (~cp);
	RAMen[6] = (addrB == 4'h6) & (|I[8:7]) & (~cp); 
	RAMen[7] = (addrB == 4'h7) & (|I[8:7]) & (~cp); 
	RAMen[8] = (addrB == 4'h8) & (|I[8:7]) & (~cp);
	RAMen[9] = (addrB == 4'h9) & (|I[8:7]) & (~cp);
	RAMen[10] = (addrB == 4'hA) & (|I[8:7]) & (~cp); 
	RAMen[11] = (addrB == 4'hB) & (|I[8:7]) & (~cp); 
	RAMen[12] = (addrB == 4'hC) & (|I[8:7]) & (~cp);
	RAMen[13] = (addrB == 4'hD) & (|I[8:7]) & (~cp);
	RAMen[14] = (addrB == 4'hE) & (|I[8:7]) & (~cp); 
	RAMen[15] = (addrB == 4'hF) & (|I[8:7]) & (~cp); 
     end

endmodule: ramFile



module tristateDriver
  (
   input logic 	driveEn, txVal,
   output logic rxVal,
   inout logic 	busLine
   );

   assign rxVal = busLine;
   assign busLine = driveEn ? txVal, 1'bz;

endmodule: tristateDriver

module ramMux
  (
   input logic [8:6]  I,
   input logic [3:0]  F,
   output logic [3:0] RAMout,
   inout logic 	      eRAM0, eRAM3
   );

   logic 	      shiftUp, shiftDown;
   logic [3:0] 	      upRAM, downRAM;
   
   tristateDriver ram0Drv(.busLine(eRAM0), .driveEn(shiftDown), .txVal(F[0]), .rxVal(upRAM[0]));   
   tristateDriver ram3Drv(.busLine(eRAM3), .driveEn(shiftUp), .txVal(F[3]), .rxVal(downRAM[3]));

   always_comb
     begin
	downRAM[2:0] = F[3:1];
	upRAM[3:1] = F[2:0];
	case(I[8:6])
	  3'd0, 3'd1:
	    begin
	       RAMout = RAMout;
	       shiftDown = 1'b0;
	       shiftUp = 1'b0;
	    end
	  3'd2, 3'd3:
	    begin
	       RAMout = F;
	       shiftDown = 1'b0;
	       shiftUp = 1'b0;
	    end
	  3'd4, 3'd5:
	    begin
	       RAMout = downRAM;
	       shiftDown = 1'b1;
	       shiftUp = 1'b0;
	    end
	  3'd6, 3'd7:
	    begin
	       RAMout = upRAM;
	       shiftDown = 1'b0;
	       shiftUp = 1'b1;
	    end
	endcase // case (I[8:6])
     end

endmodule: ramMux

module qRegister
  (
   input logic [3:0]  Qin,
   output logic [3:0] Qout,
   input logic 	      cp, QregEn
   );

   always_ff@(posedge cp)
     begin
	if(QregEn)
	  Qout <= Qin;
	else
	  Qout <= Qout;
     end
   

endmodule: qRegister


module qMux
  (
   input logic [8:6] I,
   input logic [3:0] F, Qin,
   output logic      Qout, QregEn,
   inout logic 	     eQ0, eQ3
   );

   logic 	     shiftUp, shiftDown;
   logic [3:0] 	     upQ, downQ;
   
   tristateDriver q0Drv(.busLine(eQ0), .driveEn(shiftDown), .txVal(Qin[0]), .rxVal(upQ[0]));   
   tristateDriver q3Drv(.busLine(eQ3), .driveEn(shiftUp), .txVal(Qin[3]), .rxVal(downQ[3]));

   always_comb
     begin
	downQ[2:0] = Qin[3:1];
	upQ[3:1] = Qin[2:0];
	case(I[8:6])
	  3'd0:
	    begin
	       Qout = F;
	       shiftDown = 1'b0;
	       shiftUp = 1'b0;
	       QregEn = 1'b1;
	    end
	  3'd4:
	    begin
	       Qout = downQ;
	       shiftDown = 1'b1;
	       shiftUp = 1'b0;
	       QregEn = 1'b1;
	    end
	  3'd6:
	    begin
	       Qout = upQ;
	       shiftDown = 1'b0;
	       shiftUp = 1'b1;
	       QregEn = 1'b1;
	    end
	  default:
	    begin
	       Qout = Qin;
	       shiftDown = 1'b0;
	       shiftUp = 1'b0;
	       QregEn = 1'b0;
	    end
	endcase // case (I[8:6])
     end

endmodule: qMux

module aluInputSelector
  (
   input logic [3:0]  A, B, D, Q,
   input logic [2:0]  I,
   output logic [3:0] R, S
   );

   always_comb
     begin
	case(I)
	  3'd0:
	    begin
	       R = A;
	       S = Q;
	    end
	  3'd1:
	    begin
	       R = A;
	       S = B;
	    end
	  3'd2:
	    begin
	       R = 4'h0;
	       S = Q;
	    end
	  3'd3:
	    begin
	       R = 4'h0;
	       S = B;
	    end
	  3'd4:
	    begin
	       R = 4'h0;
	       S = A;
	    end
	  3'd5:
	    begin
	       R = D;
	       S = A;
	    end
	  3'd6:
	    begin
	       R = D;
	       S = Q;
	    end
	  3'd7:
	    begin
	       R = D;
	       S = 0;
	    end
	endcase // case (I)
     end

endmodule: aluInputSelector



module aelou
  (
   input logic [3:0]  R, S,
   output logic [3:0] F,
   input logic [5:3]  I,
   input logic 	      cN,
   output logic       pBar, gBar, cNplus4, ovf
   );

   logic [3:0] 	      P, G;
   logic 	      c3, c4;
   
   always_comb
     begin
	c3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & cN);
	c4 = G[3] | (P[3] & c3);
	case(I[5:3])
	  3'd0:
	    begin
	       F = R + S + {{3'd0},{cN}};
	       P = R | S;
	       G = R & S;

	       pBar = (P != 4'hF);
	       gBar = ~(G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & G[0]))))));
	       cNplus4 = c4;
	       ovf = (c3 ^ c4);
	    end
	  3'd1:
	    begin
	       F = (~R) + S + {{3'd0},{cN}};
	       P = (~R) | S;
	       G = (~R) & S;
	       
	       pBar = (P != 4'hF);
	       gBar = ~(G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & G[0]))))));
	       cNplus4 = c4;
	       ovf = (c3 ^ c4);
	    end
	  3'd2:
	    begin
	       F = R + (~S) + {{3'd0},{cN}};
	       P = R | (~S);
	       G = R & (~S);
	       
	       pBar = (P != 4'hF);
	       gBar = ~(G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & G[0]))))));
	       cNplus4 = c4;
	       ovf = (c3 ^ c4);
	    end
	  3'd3:
	    begin
	       F = R | S;
	       P = R | S;
	       G = R & S;

	       pBar = 1'b0;
	       gBar = (P == 4'hF);
	       cNplus4 = (cN | ~gBar);
	       ovf = cNplus4;
	    end
	  3'd4:
	    begin
	       F = R & S;
	       P = R | S;
	       G = R & S;

	       pBar = 1'b0;
	       gBar = ~(G != 4'h0);
	       cNplus4 = (|G) | cN;
	       ovf = cNplus4;
	    end
	  3'd5:
	    begin
	       F = (~R) & S;
	       P = (~R) | S;
	       G = (~R) & S;

	       pBar = 1'b0;
	       gBar = ~(G != 4'h0);
	       cNplus4 = (|G) | cN;
	       ovf = cNplus4;
	    end
	  3'd6:
	    begin
	       F = R ^ S;
	       P = (~R) | S;
	       G = (~R) & S;

	       pBar = |G;
	       gBar = G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & G[0])))));
	       cNplus4 = ~(G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & P[0] & (G[0] | ~cN)))))));
	       ovf = ~(((P[2]) & 
			(G[2] | P[1]) & 
			(G[2] | G[1] | P[0]) & 
			(G[2] | G[1] | G[0] | ~cN)) ^ 
		       ((P[3]) & 
			(G[3] | P[2]) & 
			(G[3] | G[2] | P[1]) & 
			(G[3] | G[2] | G[1] | P[0]) &
			(G[3] | G[2] | G[1] | G[0] | ~cN)));
	    end
	  3'd7:
	    begin
	       F = ~(R ^ S);
	       P = R | S;
	       G = R & S;

	       pBar = |G;
	       gBar = G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & G[0])))));
	       cNplus4 = ~(G[3] | (P[3] & (G[2] | (P[2] & (G[1] | (P[1] & P[0] & (G[0] | ~cN)))))));
	       ovf = ~(((P[2]) & 
			(G[2] | P[1]) & 
			(G[2] | G[1] | P[0]) & 
			(G[2] | G[1] | G[0] | ~cN)) ^ 
		       ((P[3]) & 
			(G[3] | P[2]) & 
			(G[3] | G[2] | P[1]) & 
			(G[3] | G[2] | G[1] | P[0]) &
			(G[3] | G[2] | G[1] | G[0] | ~cN)));
	    end
	endcase // case (I[5:3])
     end

endmodule: aelou
