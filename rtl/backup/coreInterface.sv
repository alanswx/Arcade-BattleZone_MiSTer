`timescale 1ns / 1ps


module memStoreQueue(output logic [7:0]  dataOut, 
                     output logic [15:0] addrOut, 
                     output logic        dataValid, 
                     output logic        full, empty, 
                     input  logic [7:0]  dataIn, 
                     input  logic [15:0] addrIn, 
                     input  logic        canWrite, writeEn, clk, rst);

    parameter DEPTH = 128;

    logic [DEPTH-1:0] [7:0] dataQueue;
    logic [DEPTH-1:0] [15:0] addrQueue;
    logic [DEPTH-1:0] valid;

    logic [$clog2(DEPTH)-1:0] writeIndex, readIndex;
    logic [$clog2(DEPTH):0] numFilled;
    
    logic writeEdge, lastWriteEn;

    register #(1) wrEnReg(lastWriteEn, writeEn, 1'b1, clk, rst);
    
    assign writeEdge = (!lastWriteEn && writeEn);
    
    assign full = (numFilled == DEPTH);
    assign empty = (numFilled == 'd0);

    always_ff @(posedge clk) begin
        if(rst) begin
            numFilled <= 'd0;
            writeIndex <= 'd0;
            readIndex <= 'd0;
            dataQueue <= 'd0;
            addrQueue <= 'd0;
            valid <= 'd0;
        end
        else begin
            if( (writeEdge && !full) && (canWrite && !empty) ) begin
                dataQueue[writeIndex] <= dataIn;
                addrQueue[writeIndex] <= addrIn;
                valid[writeIndex] <= 'd1;

                valid[readIndex] <= 'd0;

                writeIndex <= writeIndex + 'd1;
                readIndex <= readIndex + 'd1;
            end
            
            else if(writeEdge && !full) begin
                dataQueue[writeIndex] <= dataIn;
                addrQueue[writeIndex] <= addrIn;
                valid[writeIndex] <= 'd1;
                writeIndex <= writeIndex + 'd1;
                numFilled <= numFilled + 'd1;
            end

            else if(canWrite && !empty) begin
                valid[readIndex] <= 'd0;
                readIndex <= readIndex + 'd1;
                numFilled <= numFilled - 'd1;
            end

        end
    end

    assign dataOut = dataQueue[readIndex];
    assign addrOut = addrQueue[readIndex];
    assign dataValid = valid[readIndex] && canWrite;

endmodule

