`timescale 1ns / 1ps
`default_nettype none
`include "coreInterface.vh"
module memStoreQueue(output logic [7:0]  dataOut,
                     output logic [15:0] addrOut,
                     output logic        dataValid,
                     output logic        full, empty,
                     input  wire [7:0]  dataIn,
                     input  wire [15:0] addrIn,
                     input  wire        canWrite, writeEn, clk, rst);

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

module addrDecoder
  (output logic  [7:0]       dataToCore,
   output logic [4:0] [15:0] addrToBram,
   output logic [4:0] [7:0]  dataToBram,
   output logic [4:0]        weEnBram,
   output logic              vggo,
   output logic              vgrst,

   input wire [7:0]         dataFromCore,
   input wire [15:0]        addr,
   input wire [4:0] [7:0]   dataFromBram,
   input wire               we,
   input wire               halt,
   input wire               clk,
   input wire               clk_3KHz,
   input wire               clk_en,
   input wire               self_test,
   input wire [7:0]         DSW0,
   input wire [7:0]         DSW1,
	input wire [7:0]         REDBARONBUTTONS,
   input wire               coin,
	input wire               mod_redbaron
	);

    logic [2:0] bramNum, outBramNum;

    logic [15:0] outBramAddr;

  logic          sound_access;
  always_ff @(posedge clk) begin
    if (clk_en) begin
      outBramNum <= bramNum;
      outBramAddr <= addr;
    end
  end

    assign vggo  = (addr == 16'h1200) && we;
    assign vgrst = (addr == 16'h1600) && we;

    always_comb begin
        sound_access = 1'b0;
		  
        if (mod_redbaron) begin
			  if(addr >= 16'h0 && addr < 16'h0800) bramNum = `BRAM_PROG_RAM;
			  else if(16'h2000 <= addr && addr < 16'h4000) bramNum = `BRAM_VECTOR;
			  else if(16'h4000 <= addr && addr < 16'h8000) bramNum = `BRAM_PROG_ROM;
			  else if(16'h1810 <= addr && addr < 16'h1820) bramNum = `BRAM_POKEY;
			  else if(16'h1808 == addr) begin
					bramNum = `BRAM_POKEY;
					sound_access = 1'b1;
			  end
			  else if(addr == 16'h1800 || addr == 16'h1804 || addr == 16'h1806 || (16'h1860 <= addr && addr <= 16'h187f)) bramNum = `BRAM_MATH;
			  else bramNum = 5; //error code
			  end

			else begin
			  if(addr >= 16'h0 && addr < 16'h0800) bramNum = `BRAM_PROG_RAM;
			  else if(16'h2000 <= addr && addr < 16'h4000) bramNum = `BRAM_VECTOR;
			  else if(16'h4000 <= addr && addr < 16'h8000) bramNum = `BRAM_PROG_ROM;
			  else if(16'h1820 <= addr && addr < 16'h1830) bramNum = `BRAM_POKEY;
			  else if(16'h1840 == addr) begin
					bramNum = `BRAM_POKEY;
					sound_access = 1'b1;
			  end
			  else if(addr == 16'h1800 || addr == 16'h1810 || addr == 16'h1818 || (16'h1860 <= addr && addr <= 16'h187f)) bramNum = `BRAM_MATH;
			  else bramNum = 5; //error code
			end
			
		end

		  

    logic unmappedAccess, vramWrite, unmappedRead, mathboxAccess;

    always_comb begin
        mathboxAccess = bramNum == `BRAM_MATH;
        addrToBram[0] = 'd0;
        addrToBram[1] = 'd0;
        addrToBram[2] = 'h4000;
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
                16'h800: dataToCore = {clk_3KHz, halt, 1'b1, self_test, 2'b11,1'b1, coin};
                16'h1802: dataToCore = REDBARONBUTTONS;
                16'ha00: dataToCore = DSW0;//dataToCore = 8'b0001_0101;
                16'hc00: dataToCore = DSW1;
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
`default_nettype wire
