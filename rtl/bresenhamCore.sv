module bresenhamCore
  (input logic [12:0] numerator, denominator,
   input logic 	clk, rst, en,
   output logic inc
   );

   logic [12:0] errSum, errDiff, errCurr, absErr, subtrahend, negDenom;

   negator #(13) denomNegator(.valIn(denominator), .valOut(negDenom));
   

   m_register #(13) errBank(.Q(errCurr), .D(errDiff), .clr(rst), .clk(clk), .en(en));
   
   absVal #(13) errMagnitude(.valIn(errSum), .valOut(absErr));

   m_mux2to1 #(13) subSelect(.Y(subtrahend), .I0(13'd0), .I1(negDenom), .Sel(inc));
   
   m_comparator #(13) comp   (,, inc, absErr, {{1'b0}, {denominator[12:1]}});

   m_adder #(13) errAdder(errSum,, errCurr, numerator, 1'b0);

   m_adder #(13) errSubtract(errDiff,, errSum, subtrahend, 1'b0);
   


endmodule 