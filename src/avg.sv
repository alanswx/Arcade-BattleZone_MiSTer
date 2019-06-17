`timescale 1ns / 1ps

module avg_core(output logic [12:0] startX, startY, endX, endY, 
                output logic [3:0]  intensity, 
                output logic        lrWrite,
                output logic [15:0] pcOut,
                output logic        halt, 
                input  logic [15:0] inst,  
                input  logic        clk_in, rst_in, vggo);

    logic zWrEn, scalWrEn, center, jump, jsr, ret;
    logic useZReg, blank, vector;
    logic [15:0] jumpAddr, retAddr; 
    logic signed [12:0] dX, dY;
    logic signed [21:0] dX_buf, dY_buf, nextX_scaled, nextY_scaled, linScale_buf;
    logic [2:0] pcOffset;
    logic [3:0] zVal, decZVal;
    logic signed [7:0] linScale, decLinScale;
    logic signed [2:0] binScale, decBinScale;
    logic [15:0] nextPC, pc;

    logic retValid;

    logic run;
    logic [3:0] color;

    logic decHalt;

    logic [2:0] countOut, countIn, instLength;

    logic rst;

    //WARNING: don't know how many bits this should be
    //         could cause errors from 2's comp
    logic signed [13:0] currX, nextX, currY, nextY; 

    logic [3:0] clkCount;

    logic vggoCap;

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

    logic [15:0] inst1Out, inst2Out;
    logic instEn;
    assign instEn = (countOut == 7);

    register #(16) ir(inst1Out, inst, 1'b1, clk, rst || vggoCap);

    register #(16) ir2(inst2Out, inst, instEn, clk, rst || vggoCap);
    
    //register #(16, 8192) pcReg(pc, nextPC, (countOut == 2 && ~halt), clk, rst_b);
    register #(16, 16'h2000) pcReg(pc, nextPC, (countOut == 2 && ~halt) || vggoCap, clk, rst || vggoCap);

    //assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr + 16'h2000 : retAddr);
	assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr : retAddr);

    logic [15:0] oldPC;
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
    logic [7:0] rawIntensity;

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

    always_comb begin
        if(center) begin
            nextX_scaled = ((currX + ((((dX_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));
            nextY_scaled = ((currY + ((((dY_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));
            nextX = 0;
            nextY = 0;
        end
        else begin //DEMO: multiplied dx/dy by 2
            nextX_scaled = ((currX + ((((dX_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));
            nextY_scaled = ((currY + ((((dY_buf * 2 * (21'd256 - linScale_buf)) / 21'd256) >> binScale) * 1) / 1));
                        
            nextX = nextX_scaled[13:0];
            nextY = nextY_scaled[13:0];
        end
    end
    always_comb begin
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

module register(Q, D, enable, clk, rst);

    parameter WIDTH = 8, startVal = 0;

    output logic [WIDTH-1:0] Q;
    input logic [WIDTH-1:0] D;
    input logic enable, clk, rst;

    always_ff @(posedge clk) begin
        if(rst) Q <= startVal;
        else if(enable) Q <= D;
    end
                

endmodule

module retStack(output logic [15:0] retAddr, 
                output logic        retValid, 
                input  logic [15:0] writeAddr, 
                input  logic        writeEn,
                input  logic        readEn, 
                input  logic        clk, rst);
   
    logic [3:0] [15:0] stack;
    logic [2:0] top;

    always_ff @(posedge clk) begin
        if(rst) begin
            top <= 0;   
            stack <= 0;  
        end
        else begin
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
               input  logic [12:0] DStartX, DEndX, DStartY, DEndY, 
               input  logic [3:0]  DIntensity, 
               input  logic        writeEn, clk, rst);

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
                    input  logic [12:0] DStartX, DEndX, DStartY, DEndY, 
                    input  logic [3:0]  DIntensity, 
                    input  logic read,  currWrite, clk, rst);

    parameter DEPTH = 32;


    logic [DEPTH-1:0] [12:0] startX, startY, endX, endY; 
    logic [DEPTH-1:0] valid;
    logic [DEPTH-1:0] writeEn;
    logic [DEPTH-1:0] [3:0] intensity;

    logic [$clog2(DEPTH)-1:0] wrIndex, reIndex;
    logic [$clog2(DEPTH):0] numFilled;

    genvar i;
    generate 
        for(i = 0; i < DEPTH; i++) begin: loop
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

