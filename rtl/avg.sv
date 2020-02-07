`timescale 1ns / 1ps

module avg_core(
	output 	[12:0] 	startX, 
	output 	[12:0] 	startY, 
	output 	[12:0] 	endX, 
	output 	[12:0] 	endY, 
   output    [3:0]   intensity, 
   output       		lrWrite,
   output 	[15:0] 	pcOut,
   output       		halt, 
   input  	[15:0] 	inst,  
   input  				clk_in, 
	input  				rst_in, 
	input  				vggo
);

reg zWrEn, scalWrEn, center, jump, jsr, ret;
reg useZReg, blank, vector;
reg [15:0] jumpAddr, retAddr; 
reg signed [12:0] dX, dY;
reg signed [21:0] dX_buf, dY_buf, nextX_scaled, nextY_scaled, linScale_buf;
wire [2:0] pcOffset;
wire [3:0] zVal, decZVal;
wire signed [7:0] linScale, decLinScale;
wire signed [2:0] binScale, decBinScale;
wire [15:0] nextPC, pc;

wire retValid;

wire run;
wire [3:0] color;

wire decHalt;

wire [2:0] countOut, countIn, instLength;

reg rst;

    //WARNING: don't know how many bits this should be
    //         could cause errors from 2's comp
reg signed [13:0] currX, nextX, currY, nextY; 

reg [3:0] clkCount;

reg vggoCap;

    register #(3, 0) countReg(countOut, countIn, countEn, clk, rst || vggoCap);

    assign run = (countOut == 1 && ~halt);
    assign countEn = ~halt;
    assign countIn = (countOut == 0 ? instLength : countOut - 1);

    always_ff @(posedge clk_in) begin
        if(rst_in) rst <= 1;
        else if(clk) rst <= 0;
    end

    always_ff @(posedge clk_in) begin
        if(rst) begin
            clkCount <= 0;
        end
        else begin
            clkCount <= clkCount + 1;
            if(vggo) vggoCap <= 1;
            else if(clkCount == 0) vggoCap <= 0; //DEMO: changed to else if, and == 0
        end
    end
    
    assign clk = ~(clkCount > 7);
        

    /***********************************/
    /*             FETCH               */
    /***********************************/
   
    assign pcOut = (countIn == 7 || countIn == 6 ? pc+2 : pc);

wire [15:0] inst1Out, inst2Out;
wire instEn;
    assign instEn = (countOut == 7);

    register #(16) ir(inst1Out, inst, 1'b1, clk, rst || vggoCap);

    register #(16) ir2(inst2Out, inst, instEn, clk, rst || vggoCap);
    
    //register #(16, 8192) pcReg(pc, nextPC, (countOut == 2 && ~halt), clk, rst_b);
    register #(16, 16'h2000) pcReg(pc, nextPC, (countOut == 2 && ~halt) || vggoCap, clk, rst || vggoCap);

    //assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr + 16'h2000 : retAddr);
	assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr : retAddr);

wire [15:0] oldPC;
    register #(16) oldPCReg(oldPC, pc, 1'b1, clk, rst || vggoCap);
    
    /***********************************/
    /*             DECODE              */
    /***********************************/


    avg_decode idu(zWrEn, scalWrEn, center, jump, jsr, ret, 
                   useZReg, blank, decHalt, vector,  
                   jumpAddr, pcOffset, dX, dY, decZVal, decLinScale, decBinScale, color,  
                   instLength, {inst1Out, inst2Out});

    /***********************************/
    /*             EXECUTE             */
    /***********************************/

    assign intensity = (useZReg && ~blank) ? zVal : decZVal;

    /*
wire [7:0] rawIntensity;

    always_comb begin
        rawIntensity = (useZReg && ~blank) ? zVal : decZVal;
        intensity = (rawIntensity >= 4'b1111) ? 4'b1111 : rawIntensity[3:0];
    end
    */
    register #(14) xReg(currX, nextX, (center || vector) && run, clk, rst || vggoCap);
    register #(14) yReg(currY, nextY, (center || vector) && run, clk, rst || vggoCap);

    retStack rs(retAddr, retValid, oldPC + 16'd2, jsr && run, ret && run, clk, rst || vggoCap);
    
    register #(4) zReg(zVal, decZVal, zWrEn && run, clk, rst || vggoCap);

    register #(8, 0) linScaleReg(linScale, decLinScale, scalWrEn && run, clk, rst || vggoCap);
    register #(3) binScaleReg(binScale, decBinScale, scalWrEn && run, clk, rst || vggoCap);
always @(clk_in) begin
 //   always_comb begin  GEHSTOCK
        if(center) begin
            nextX = 0;
            nextY = 0;
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

    always_ff @(posedge clk) begin
        if(rst)
            halt <= 1;
        else begin
            if(vggoCap) halt <= 0;
            else if(decHalt && run) halt <= 1;
        end
    end


endmodule 
