`timescale 1ns / 1ps
`include "coreInterface.vh"
module memStoreQueue(output logic [7:0]  Q, 
                     output logic [15:0] writeAddr, 
                     output logic        writeOut, 
                     input  logic [7:0]  D, 
                     input  logic [15:0] addr,
                     input  logic        canWrite, we, clk, rst);
    
    parameter DEPTH = 8; //must be power of 2

    logic [DEPTH-1:0] [7:0] queue;
    logic [DEPTH-1:0] [15:0] addrQueue;
    logic [DEPTH-1:0] valid;

    logic [$clog2(DEPTH)-1:0] wrIndex, reIndex;
    logic [$clog2(DEPTH):0] numFilled;

    logic lastWrite;

    logic empty, full;

    always_ff @(posedge clk) begin
        if(rst) begin
            valid <= 'd0;
            wrIndex <= 'd0;
            reIndex <= 'd0;
            numFilled <= 'd0;
            lastWrite <= 1'b0;
        end else begin
            lastWrite <= we;
            if(!empty && canWrite && we && !lastWrite) begin
                queue[wrIndex] <= D;
                addrQueue[wrIndex] <= addr;
                wrIndex <= wrIndex + 1;
                valid[reIndex] <= 'd0;
                reIndex <= reIndex + 1;
            end else if(canWrite && !empty) begin
                valid[reIndex] <= 1'b0;
                reIndex <= reIndex + 1;
                numFilled <= numFilled - 1;
            end else if(we && !lastWrite && !full) begin
                queue[wrIndex] <= D;
                wrIndex <= wrIndex + 1;
                valid[wrIndex] <= 1'b1;
                numFilled <= numFilled + 1;
                addrQueue[wrIndex] <= addr;
            end
        end
    end

    assign full = (numFilled == DEPTH);
    assign empty = (numFilled == 0);
    assign writeOut = canWrite && (!empty);

    assign Q = queue[reIndex];
    assign writeAddr = addrQueue[reIndex];

endmodule

module addrDecoder(output logic  [7:0] dataToCore, 
                   output logic  [4:0] [15:0] addrToBram, 
                   output logic  [4:0] [7:0] dataToBram,
                   output logic  [4:0] weEnBram,
                   output logic        vggo, vgrst, 
                   
                   input  logic  [7:0] dataFromCore,
                   input  logic [15:0] addr,
                   input  logic  [4:0] [7:0] dataFromBram,
                   input  logic        we, halt, clk_3KHz, clk, self_test);

    logic [2:0] bramNum, outBramNum;

    logic [15:0] outBramAddr;

    logic sound_access;
    always_ff @(posedge clk) begin
        outBramNum <= bramNum;
        outBramAddr <= addr;
    end

    assign vggo = (addr == 16'h1200) && we;
    assign vgrst = (addr == 16'h1600) && we;

    always_comb begin
        sound_access = 1'b0;
        if(addr >= 16'h0 && addr < 16'h0400) bramNum = `BRAM_PROG_RAM;
        else if(16'h2000 <= addr && addr < 16'h4000) bramNum = `BRAM_VECTOR;
        else if(16'h5000 <= addr && addr < 16'h8000) bramNum = `BRAM_PROG_ROM;
        else if(16'h1820 <= addr && addr < 16'h1830) bramNum = `BRAM_POKEY;  
        else if(16'h1840 == addr) begin 
            bramNum = `BRAM_POKEY;
            sound_access = 1'b1;
        end
        else if(addr == 16'h1800 || addr == 16'h1810 || addr == 16'h1818 || (16'h1860 <= addr && addr <= 16'h187f)) bramNum = `BRAM_MATH;  
        else bramNum = 5; //error code
    end

    logic unmappedAccess, vramWrite, unmappedRead, mathboxAccess;

    always_comb begin
        mathboxAccess = bramNum == `BRAM_MATH;
        addrToBram[0] = 'd0;
        addrToBram[1] = 'd0;
        addrToBram[2] = 'd0;
        addrToBram[3] = 'd0;
        addrToBram[4] = 'd0;
        dataToBram[0] = 'd0;
        dataToBram[1] = 'd0;
        dataToBram[2] = 'd0;
        dataToBram[3] = 'd0;
        dataToBram[4] = 'd0;
        unmappedAccess = 1'b0;
        vramWrite = 1'b0;
        unmappedRead = 1'b0;
        //dataToCore = dataFromBram[outBramNum];
        weEnBram = (we << bramNum);
        dataToBram[bramNum] = dataFromCore;
        addrToBram[bramNum] = addr;
    
        if(outBramNum < 5) begin
            dataToCore = dataFromBram[outBramNum];
        end
        else begin
            case(outBramAddr)
                16'h800: dataToCore = {clk_3KHz, halt, 1'b1, self_test, 4'b1111};
                16'ha00: dataToCore = 8'b0001_0101;
                16'hc00: dataToCore = 8'b0000_0000;
                //16'h1800: dataToCore = 8'b11111111;
                default: begin
                    if(outBramAddr != 16'h1400) unmappedAccess = 1;
                    if(~we) unmappedRead = 1'b1;
                    dataToCore = 8'd0;
                end
            endcase
        end
        
        if(bramNum == `BRAM_VECTOR && dataFromCore != 'd0 && we) vramWrite = 1'b1;
    
    end

endmodule

module NMICounter(output logic NMI, 
                  input  logic clk, rst, en);
    
    logic [3:0] count;
    
    always_ff @(posedge clk) begin
        if(rst) count <= 'd0;
        else begin
            if(en) begin
                if(count == 'd13) count <= 'd0;
                else count <= count + 'd1;
            end
        end
    end

    assign NMI = (count == 'd13);
endmodule








