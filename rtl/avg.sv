`timescale 1ns / 1ps
`default_nettype none
module avg_core
  #
  (
   parameter CLK_DIV = "TRUE",
   parameter CLK_COUNT = CLK_DIV == "TRUE" ? 2 : 3
   )
  (
   output logic [12:0] startX,
   output logic [12:0] startY,
   output logic [12:0] endX,
   output logic [12:0] endY,
   output logic [3:0]  intensity,
   output logic        lrWrite,
   output logic [15:0] pcOut,
   output logic        halt,
   input wire [15:0]   inst,
   input wire          clk_in,
   input wire          clk_6MHz_en,
   input wire          rst_in,
   input wire          vggo
   );

  logic                clk_edge;

  logic                zWrEn, scalWrEn, center, jump, jsr, ret;
  logic                useZReg, blank, vector;
  logic [15:0]         jumpAddr, retAddr;
  logic signed [12:0]  dX, dY;
  logic signed [21:0]  dX_buf, dY_buf, nextX_scaled, nextY_scaled, linScale_buf;
  logic [2:0]          pcOffset;
  logic [3:0]          zVal, decZVal;
  logic signed [7:0]   linScale, decLinScale;
  logic signed [2:0]   binScale, decBinScale;
  logic [15:0]         nextPC, pc;

  logic                retValid;

  logic                run;
  logic [3:0]          color;

  logic                decHalt;

  logic [2:0]          countOut, countIn, instLength;

  logic                rst;
  wire                 clk;

  //WARNING: don't know how many bits this should be
  //         could cause errors from 2's comp
  logic signed [13:0]  currX, nextX, currY, nextY;

  // Change the clock edge divider based upoin frequency
  logic [CLK_COUNT:0]  clkCount;

  logic                vggoCap;
  logic                rst_int;

  assign rst_int = rst | vggoCap;
  //assign clk_edge = &clkCount;
  //assign clk_edge = clk_6MHz_en;
  always @(posedge clk_in) clk_edge <= clk_6MHz_en;

  always @(posedge clk_in) begin
    if (rst_int)               countOut <= '0;
    else if (clk_edge & ~halt) countOut <= countIn;
  end

  assign run = (countOut == 1 && ~halt);
  assign countIn = (countOut == 0 ? instLength : countOut - 3'b1);

  always_ff @(posedge clk_in) begin
    if(rst_in)  rst <= 1;
    else        rst <= 0;
  end

  always_ff @(posedge clk_in) begin
    if(rst) begin
      clkCount <= 0;
    end
    else begin
      clkCount <= clkCount + 3'b1;
      if(vggo) vggoCap <= 1;
      else if(clk_edge) vggoCap <= 0; //DEMO: changed to else if, and == 0
    end
  end

  //assign clk = DIV_CLK == "TRUE" ? ~(clkCount > 3) : ~(clkCount > 7);

  /***********************************/
  /*             FETCH               */
  /***********************************/

  assign pcOut = (countIn == 7 || countIn == 6 ? pc+2 : pc);

  logic [15:0] inst1Out, inst2Out;
  logic        instEn;
  assign instEn = (countOut == 7);

  always @(posedge clk_in) begin
    if (rst_int)       inst1Out <= '0;
    else if (clk_edge) inst1Out <= inst;
  end

  always @(posedge clk_in) begin
    if (rst_int)                inst2Out <= '0;
    else if (clk_edge & instEn) inst2Out <= inst;
  end

  always @(posedge clk_in) begin
    if (rst_int)                                 pc <= 16'h2000;
    else if (clk_edge & (countOut == 2 & ~halt)) pc <= nextPC;
  end

  //assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr + 16'h2000 : retAddr);
  assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr : retAddr);

  logic [15:0] oldPC;
  always @(posedge clk_in) begin
    if (rst_int)       oldPC <= '0;
    else if (clk_edge) oldPC <= pc;
  end

  /***********************************/
  /*             DECODE              */
  /***********************************/
  avg_decode idu
    (
     .zWrEn       (zWrEn),
     .scalWrEn    (scalWrEn),
     .center      (center),
     .jmp         (jump),
     .jsr         (jsr),
     .ret         (ret),
     .useZReg     (useZReg),
     .blank       (blank),
     .halt        (decHalt),
     .vector      (vector),
     .jumpAddr    (jumpAddr),
     .pcOffset    (pcOffset),
     .dX          (dX),
     .dY          (dY),
     .zVal        (decZVal),
     .linScale    (decLinScale),
     .binScale    (decBinScale),
     .color       (color[2:0]),
     .instLength  (instLength),
     .inst        ({inst1Out, inst2Out})
     );

  /***********************************/
  /*             EXECUTE             */
  /***********************************/

  assign intensity = (useZReg && ~blank) ? zVal : decZVal;

  always @(posedge clk_in) begin
    if (rst_int) begin
      currX <= '0;
      currY <= '0;
    end else if (clk_edge & (center || vector) & run) begin
      currX <= nextX;
      currY <= nextY;
    end
  end

  retStack rs
    (
     .retAddr     (retAddr),
     .retValid    (retValid),
     .writeAddr   (oldPC + 16'd2),
     .writeEn     (jsr & run),
     .readEn      (ret & run),
     .clk         (clk_in),
     .clk_en      (clk_edge),
     .rst         (rst_int)
     );

  always @(posedge clk_in) begin
    if (rst_int)                     zVal <= '0;
    else if (clk_edge & zWrEn & run) zVal <= decZVal;
  end

  always @(posedge clk_in) begin
    if (rst_int) begin
      linScale <= '0;
      binScale <= '0;
    end else if (clk_edge & scalWrEn & run) begin
      linScale <= decLinScale;
      binScale <= decBinScale;
    end
  end

  always_comb begin
    if(center) begin
      nextX = 0;
      nextY = 0;
// ajs ajs ajs		
		    dX_buf=22'b0;
    dY_buf=22'b0;
    linScale_buf=22'b0;
    nextX_scaled=22'b0;
    nextY_scaled=22'b0;
// ajs ajs ajs
		
    end
    else begin //DEMO: multiplied dx/dy by 2
      if(dX[12] == 1'b1)
        dX_buf[21:13] = 9'b111111111;
      else
        dX_buf[21:13] = 9'b000000000;
      if(dY[12] == 1'b1)
        dY_buf[21:13] = 9'b111111111;
      else
        dY_buf[21:13] = 9'b000000000;
      dX_buf[12:0] = dX;
      dY_buf[12:0] = dY;
      linScale_buf[21:8] = 14'd0;
      linScale_buf[7:0] = linScale;
      nextX_scaled = ((currX + ((((dX_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));
      nextY_scaled = ((currY + ((((dY_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));

      nextX = nextX_scaled[13:0];
      nextY = nextY_scaled[13:0];
    end
  end

  /***********************************/
  /*           WRITEBACK             */
  /***********************************/

  assign lrWrite = vector && ~blank && run;
  assign startX = currX[13:1];
  assign endX = nextX[13:1];
  assign startY = currY[13:1];
  assign endY = nextY[13:1];

  always_ff @(posedge clk_in) begin
    if(rst)
      halt <= 1;
    else if (clk_edge) begin
      if(vggoCap) halt <= 0;
      else if(decHalt && run) halt <= 1;
    end
  end
endmodule

module retStack
  (
   output logic [15:0] retAddr,
   output logic        retValid,
   input wire [15:0]   writeAddr,
   input wire          writeEn,
   input wire          readEn,
   input wire          clk,
   input wire          clk_en,
   input wire          rst
   );

  logic [3:0] [15:0]   stack;
  logic [2:0]          top;

  always_ff @(posedge clk) begin
    if(rst) begin
      top <= 0;
      stack <= 0;
    end else if (clk_en) begin
      if(writeEn && readEn) begin
        top <= top;
        stack <= stack;
        stack[top] <= writeAddr;
      end
      else if(writeEn) begin
        top <= top+1;
        stack <= stack;
        stack[top] <= writeAddr;
      end
      else if(readEn) begin
        top <= top-1;
        stack <= stack;
      end
      else begin
        top <= top;
        stack <= stack;
      end
    end
  end

  always_comb begin
    retAddr = stack[top-1];
    retValid = top != 0;
  end

endmodule

module lineReg(output logic [12:0] QStartX, QEndX, QStartY, QEndY,
               output logic [3:0]  QIntensity,
               output logic        valid,
               input  wire [12:0] DStartX, DEndX, DStartY, DEndY,
               input  wire [3:0]  DIntensity,
               input  wire        writeEn, clk, rst);

    always_ff @(posedge clk) begin
        if(rst) begin
            QStartX <= 0;
            QEndX <= 0;
            QStartY <= 0;
            QEndY <= 0;
            valid <= 0;
            QIntensity <= 0;
        end
        else begin
            if(writeEn) begin
                QStartX <= DStartX;
                QEndX <= DEndX;
                QStartY <= DStartY;
                QEndY <= DEndY;
                valid <= 1;
                QIntensity <= DIntensity;
            end
        end
    end
endmodule



module lineRegQueue(output logic [12:0] QStartX, QEndX, QStartY, QEndY,
                    output logic [3:0]  QIntensity,
                    output logic full, empty,
                    input  wire [12:0] DStartX, DEndX, DStartY, DEndY,
                    input  wire [3:0]  DIntensity,
                    input  wire read,  currWrite, clk, rst);

    parameter DEPTH = 32;


    logic [DEPTH-1:0] [12:0] startX, startY, endX, endY;
    logic [DEPTH-1:0] valid;
    logic [DEPTH-1:0] writeEn;
    logic [DEPTH-1:0] [3:0] intensity;

    logic [$clog2(DEPTH)-1:0] wrIndex, reIndex;
    logic [$clog2(DEPTH):0] numFilled;

    genvar i;
    generate
        for(i = 0; i < DEPTH; i++) begin : linequeueblock 
            lineReg l1(startX[i], endX[i], startY[i], endY[i],
                       intensity[i],
                       valid[i],
                       DStartX, DEndX, DStartY, DEndY,
                       DIntensity,
                       writeEn[i], clk, rst);
        end
    endgenerate

    logic lastWrite, write;

    assign write = currWrite && !lastWrite;

    always_ff @(posedge clk) begin
        if(rst) begin
            wrIndex <= 'd0;
            reIndex <= 'd0;
            lastWrite <= 'd0;
            numFilled <= 'd0;
        end
        else begin
            lastWrite <= currWrite;
            if(write && read && !empty) begin
                wrIndex <= wrIndex + 'd1;
                reIndex <= reIndex + 'd1;
            end
            else if(write && !full) begin
                wrIndex <= wrIndex + 'd1;
                numFilled <= numFilled + 'd1;
            end
            else if(read && !empty) begin
                reIndex <= reIndex + 'd1;
                numFilled <= numFilled - 'd1;
            end
        end
    end

    assign full = (numFilled == DEPTH);
    assign empty = (numFilled == 'd0);

    assign QStartX = startX[reIndex];
    assign QEndX = endX[reIndex];
    assign QStartY = startY[reIndex];
    assign QEndY = endY[reIndex];
    assign QIntensity = intensity[reIndex];

    always_comb begin
        writeEn = 'd0;
        writeEn[wrIndex] = write;
    end

endmodule
`default_nettype wire
