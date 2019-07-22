`timescale 1ns / 1ps




`define HALF_WIDTH 13'd320
`define HALF_HEIGHT 13'd240
`define FULL_WIDTH 13'd640
`define FULL_HEIGHT 13'd480



module rasterizer
  (input logic signed [12:0]  startX, endX,
   input logic signed [12:0]  startY, endY,
   input logic [3:0]   lineColor,
   input logic 	       clk, rst, readyIn,
   output logic [18:0] addressOut,
   output logic [12:0] pixelX, pixelY,
   output logic [3:0]  pixelColor,
   output logic        goodPixel, done, rastReady);

   logic 	       inc, xZone, bZone, yZone;
   logic 	       xNeg, yNeg, cntNet;
   logic 	       loopEn;
   
   logic signed [13:0]        adjStartX, adjEndX;
   logic signed [13:0]        adjStartY, adjEndY;

  logic signed [13:0]        truncStartX, truncEndX; //EDIT: truncate if out of bounds
  logic signed [13:0]        truncStartY, truncEndY;//EDIT: truncate if out of bounds
  
   logic [13:0]        absDeltaX, absDeltaY, numerator, denominator, numeratorPrime, denominatorPrime;

   logic [13:0]        majCnt, minCnt;

   logic [13:0]        leftX, topY;

   logic 	       goodTime, goodX, goodY;

   logic 	       idleReady;
   
   logic pipe1;
   
   wire signed [12:0] halfWidth;
   wire signed [12:0] halfHeight;
   
   assign halfWidth = `HALF_WIDTH;
   assign halfHeight = `HALF_HEIGHT;
   
   //EDIT: truncate if > 320 or < -320 for X, > 240 < -240 for Y
   /*always_comb begin
      if(startX >= halfWidth)
        truncStartX = halfWidth - 1;
      else if(startX < - halfWidth)
        truncStartX = -halfWidth;
      else
        truncStartX = startX;
        
      if(endX >= halfWidth)
        truncEndX = halfWidth - 1;
      else if(endX < -halfWidth)
        truncEndX = -halfWidth;
      else
        truncEndX = endX;
      
      if(startY >= halfHeight)
        truncStartY = halfHeight - 1;
      else if(startY < -halfHeight)
        truncStartY = -halfHeight;
      else
        truncStartY= startY;
      
      if(endY >= halfHeight)
        truncEndY = halfHeight - 1;
      else if(endY < -halfHeight)
        truncEndY = -halfHeight;
      else
        truncEndY = endY;
   end*/ // UNMATCHED !!

   assign truncStartX = startX;
   assign truncEndX = endX;
   assign truncStartY = startY;
   assign truncEndY = endY;

   m_register #(4) colorBank(pixelColor, lineColor, rst, idleReady, clk);
   //assign pixelColor = 4'b0111;
   
   m_register #(14) startXBank(adjStartX, truncStartX + `FULL_WIDTH, rst, idleReady, clk);
   m_register #(14) endXBank(adjEndX, truncEndX + `FULL_WIDTH, rst, idleReady, clk);
   m_register #(14) startYBank(adjStartY, -truncStartY + `FULL_HEIGHT, rst, idleReady, clk);
   m_register #(14) endYBank(adjEndY, -truncEndY + `FULL_HEIGHT, rst, idleReady, clk);
   

   absSubtractor #(14) xSub(.A(adjEndX), .B(adjStartX), .absDiff(absDeltaX));
   absSubtractor #(14) ySub(.A(adjEndY), .B(adjStartY), .absDiff(absDeltaY));
   
   m_comparator #(14) slopePicker(.A(absDeltaX), .B(absDeltaY), .AgtB(xZone), .AeqB(bZone), .AltB(yZone));

   m_comparator #(14) xDirCmp(.A(adjStartX), .B(adjEndX), .AltB(xNeg)); //fanout
   m_comparator #(14) yDirCmp(.A(adjStartY), .B(adjEndY), .AltB(yNeg)); //fanout
   xor xorNeg(cntNeg, xNeg, yNeg);
   
   
   m_register #(14) numerBank(.Q(numerator), .D(numeratorPrime), .clk(clk), .clr(rst), .en(pipe1));
   m_register #(14) denomBank(.Q(denominator), .D(denominatorPrime), .clk(clk), .clr(rst), .en(pipe1));
   
   
   switchMux #(14) recipSwitch(.U(numeratorPrime), .V(denominatorPrime), .Sel(yZone), .A(absDeltaY), .B(absDeltaX));

   m_counter #(14) majorCounter(.Q(majCnt), .D(14'd0), .clk(clk), .clr(rst), .load(idleReady), .up(1'b1), .en(loopEn));
   m_counter #(14) minorCounter(.Q(minCnt), .D(14'd0), .clk(clk), .clr(rst), .load(idleReady), .up(~cntNeg), .en(inc));


   bresenhamCore rasterCore(.numerator(numerator), .denominator(denominator), .clk(clk), .rst(rst|idleReady), .en(loopEn), .inc(inc));

   rasterFSM rasterControl(.readyIn(readyIn), .denominator(denominator), .majCnt(majCnt), .clk(clk), .rst(rst), .loopEn(loopEn), .done(done), .good(goodTime), .rastReady(rastReady), .idleReady(idleReady), .pipe1(pipe1));


   m_mux2to1 #(14) leftXMux(.Y(leftX), .Sel((bZone|xZone) ? xNeg : yNeg), .I0(adjEndX), .I1(adjStartX));
   m_mux2to1 #(14) topYMux(.Y(topY), .Sel(yZone ? yNeg : xNeg), .I0(adjEndY), .I1(adjStartY));
   

   assign pixelX = leftX + ((bZone|xZone) ? majCnt : minCnt) - `HALF_WIDTH;
   assign pixelY = topY + (yZone ? majCnt : minCnt) - `HALF_HEIGHT;
   
   coordinateIndexer addresser(.x(pixelX[9:0]), .y(pixelY[8:0]), .index(addressOut));


   
   m_range_check #(14) xRangeCheck(.val(pixelX), .low(14'd0), .high(14'd640), .is_between(goodX));
   m_range_check #(14) yRangeCheck(.val(pixelY), .low(14'd0), .high(14'd480), .is_between(goodY));

   assign goodPixel = goodX & goodY & goodTime;
   
				   
   
   
endmodule 