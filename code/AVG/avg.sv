

module avg_core(output logic [10:0] startX, startY, endX, endY, 
                output logic [2:0]  color, 
                output logic        lrWrite,
                output logic [15:0] pcOut,
                input  logic [15:0] inst,  
                input  logic        clk_in, rst, vggo);

    logic zWrEn, scalWrEn, center, jump, jsr, ret;
    logic useZReg, blank, halt, vector;
    logic [15:0] jumpAddr, retAddr; 
    logic [12:0] dX, dY;
    logic [2:0] pcOffset;
    logic [3:0] zVal, decZVal;
    logic [7:0] linScale, decLinScale;
    logic [2:0] binScale, decBinScale;
    logic [15:0] nextPC, pc;

    logic retValid;

    logic run;

    logic decHalt;

    logic [2:0] countOut, countIn, instLength;

    register #(3, 0) countReg(countOut, countIn, countEn, clk, rst);

    assign run = (countOut == 1 && ~halt);
    assign countEn = ~halt;
    assign countIn = (countOut == 0 ? instLength : countOut - 1);

    //WARNING: don't know how many bits this should be
    //         could cause errors from 2's comp
    logic [10:0] currX, nextX, currY, nextY; 

    logic [3:0] clkCount;

    logic vggoCap;

    always_ff @(posedge clk_in) begin
        if(rst) begin
            clkCount <= 0;
        end
        else begin
            clkCount <= clkCount + 1;
            if(vggo) vggoCap <= 1;
            if(clkCount == 15) vggoCap <= 0;
        end
    end
    
    assign clk = clkCount > 7;
        

    /***********************************/
    /*             FETCH               */
    /***********************************/
   
    assign pcOut = (countIn == 7 || countIn == 6 || halt ? pc+2 : pc);

    logic [15:0] inst1Out, inst2Out;
    logic instEn;
    assign instEn = (countOut == 7);

    register #(16) ir(inst1Out, inst, 1'b1, clk, rst);

    register #(16) ir2(inst2Out, inst, instEn, clk, rst);
    
    //register #(16, 8192) pcReg(pc, nextPC, (countOut == 2 && ~halt), clk, rst_b);
    register #(16, 0) pcReg(pc, nextPC, (countOut == 2 && ~halt) || vggoCap, clk, rst);

    //assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr + 16'h2000 : retAddr);
	assign nextPC = !(jump || ret) ? pc + pcOffset : (jump ? jumpAddr : retAddr);

    logic [15:0] oldPC;
    register #(16) oldPCReg(oldPC, pc, 1'b1, clk, rst);
    
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

    register #(11) xReg(currX, nextX, (center || vector) && run, clk, rst);
    register #(11) yReg(currY, nextY, (center || vector) && run, clk, rst);

    retStack rs(retAddr, retValid, oldPC + 2, jsr && run, ret && run, clk, rst);
    
    register #(4) zReg(zVal, decZVal, zWrEn && run, clk, rst);

    register #(8, 0) linScaleReg(linScale, decLinScale, scalWrEn && run, clk, rst);
    register #(3) binScaleReg(binScale, decBinScale, scalWrEn && run, clk, rst);

    always_comb begin
        if(center) begin
            nextX = 0;
            nextY = 0;
        end
        else begin
            nextX = currX + ((dX * (256 - linScale)) / 256);
            nextY = currY + ((dY * (256 - linScale)) / 256);
        end
    end

    /***********************************/
    /*           WRITEBACK             */
    /***********************************/

    assign lrWrite = vector && ~blank && run;
    assign startX = currX;
    assign endX = nextX;
    assign startY = currY;
    assign endY = nextY;

    always_ff @(posedge clk) begin
        if(rst)
            halt <= 0;
        else begin
            if(vggoCap) halt <= 0;
            else if(decHalt) halt <= 1;
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
        end
        else begin
            if(writeEn && readEn) stack[top] <= writeAddr;
            else if(writeEn) begin
                top <= top+1;
                stack[top] <= writeAddr;
            end
            else if(readEn) begin
                top <= top-1;
            end
        end
    end

    always_comb begin
        retAddr = stack[top-1];
        retValid = top != 0;
    end

endmodule

module lineReg(output logic [10:0] QStartX, QEndX, QStartY, QEndY, 
               output logic [2:0]  QColor, 
               output logic        valid,
               input  logic [10:0] DStartX, DEndX, DStartY, DEndY, 
               input  logic [2:0]  DColor, 
               input  logic        writeEn, clk, rst);

    always_ff @(posedge clk) begin
        if(rst) begin
            QStartX <= 0;
            QEndX <= 0;
            QStartY <= 0;
            QEndY <= 0;
            valid <= 0;
            QColor <= 0;
        end
        else begin
            if(writeEn) begin
                QStartX <= DStartX;
                QEndX <= DEndX;
                QStartY <= DStartY;
                QEndY <= DEndY;
                valid <= 1;
                QColor <= DColor;
            end
        end
    end
endmodule



module lineRegQueue(output logic [10:0] QStartX, QEndX, QStartY, QEndY, 
                    output logic [2:0]  QColor, 
                    output logic full, empty,  
                    input  logic [10:0] DStartX, DEndX, DStartY, DEndY, 
                    input  logic [2:0]  DColor, 
                    input  logic read,  currWrite, clk, rst);

    parameter DEPTH = 8;


    logic [DEPTH-1:0] [10:0] startX, startY, endX, endY; 
    logic [DEPTH-1:0] valid;
    logic [DEPTH-1:0] writeEn;
    logic [DEPTH-1:0] [2:0] color;

    logic [$clog2(DEPTH)-1:0] wrIndex, reIndex;
    logic [$clog2(DEPTH):0] numFilled;

    genvar i;
    generate
        for(i = 0; i < DEPTH; i++) begin
            lineReg l1(startX[i], endX[i], startY[i], endY[i], 
                       color[i], 
                       valid[i], 
                       DStartX, DEndX, DStartY, DEndY,
                       DColor,  
                       writeEn[i], clk, rst);
        end
    endgenerate 

    logic lastWrite, write;

    assign write = currWrite && !lastWrite;

    always_ff @(posedge clk) begin
        if(rst) begin
            wrIndex <= 0;
            reIndex <= 0;
            lastWrite <= 0;
            numFilled <= 0;
        end
        else begin
            lastWrite <= currWrite;
            if(write && read && !empty) begin
                wrIndex <= wrIndex + 1;
                reIndex <= reIndex + 1;
            end
            else if(write && !full) begin
                wrIndex <= wrIndex + 1;
                numFilled <= numFilled + 1;
            end
            else if(read && !empty) begin
                reIndex <= reIndex + 1;
                numFilled <= numFilled - 1;
            end
        end
    end

    assign full = (numFilled == DEPTH);
    assign empty = (numFilled == 0);

    assign QStartX = startX[reIndex];
    assign QEndX = endX[reIndex];
    assign QStartY = startY[reIndex];
    assign QEndY = endY[reIndex];
    assign QColor = color[reIndex];

    always_comb begin
        writeEn = 0;
        writeEn[wrIndex] = write;
    end

endmodule

