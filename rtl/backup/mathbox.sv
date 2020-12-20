

module mathBox(input  logic [7:0] addr, 
               input  logic [7:0] DI, 
               input  logic       we, clk, rst, 
               output logic [7:0] dataOut);

    logic [15:0] [15:0] mbRegD;
    logic [15:0] [1:0] mbRegEn;
    logic [15:0] [15:0] mbRegQ;

    logic [15:0] scratchRegQ, scratchRegD, mbOutQ, mbOutD;
    logic scratchRegEn, mbOutEn;

    mbReg r0(mbRegD[0][15:8],  mbRegD[0][7:0],  mbRegEn[0][1],  mbRegEn[0][0],  clk, rst, mbRegQ[0]);
    mbReg r1(mbRegD[1][15:8],  mbRegD[1][7:0],  mbRegEn[1][1],  mbRegEn[1][0],  clk, rst, mbRegQ[1]);
    mbReg r2(mbRegD[2][15:8],  mbRegD[2][7:0],  mbRegEn[2][1],  mbRegEn[2][0],  clk, rst, mbRegQ[2]);
    mbReg r3(mbRegD[3][15:8],  mbRegD[3][7:0],  mbRegEn[3][1],  mbRegEn[3][0],  clk, rst, mbRegQ[3]);
    mbReg r4(mbRegD[4][15:8],  mbRegD[4][7:0],  mbRegEn[4][1],  mbRegEn[4][0],  clk, rst, mbRegQ[4]);
    mbReg r5(mbRegD[5][15:8],  mbRegD[5][7:0],  mbRegEn[5][1],  mbRegEn[5][0],  clk, rst, mbRegQ[5]);
    mbReg r6(mbRegD[6][15:8],  mbRegD[6][7:0],  mbRegEn[6][1],  mbRegEn[6][0],  clk, rst, mbRegQ[6]);
    mbReg r7(mbRegD[7][15:8],  mbRegD[7][7:0],  mbRegEn[7][1],  mbRegEn[7][0],  clk, rst, mbRegQ[7]);
    mbReg r8(mbRegD[8][15:8],  mbRegD[8][7:0],  mbRegEn[8][1],  mbRegEn[8][0],  clk, rst, mbRegQ[8]);
    mbReg r9(mbRegD[9][15:8],  mbRegD[9][7:0],  mbRegEn[9][1],  mbRegEn[9][0],  clk, rst, mbRegQ[9]);
    mbReg ra(mbRegD[10][15:8], mbRegD[10][7:0], mbRegEn[10][1], mbRegEn[10][0], clk, rst, mbRegQ[10]);
    mbReg rb(mbRegD[11][15:8], mbRegD[11][7:0], mbRegEn[11][1], mbRegEn[11][0], clk, rst, mbRegQ[11]);
    mbReg rc(mbRegD[12][15:8], mbRegD[12][7:0], mbRegEn[12][1], mbRegEn[12][0], clk, rst, mbRegQ[12]);
    mbReg rd(mbRegD[13][15:8], mbRegD[13][7:0], mbRegEn[13][1], mbRegEn[13][0], clk, rst, mbRegQ[13]);
    mbReg re(mbRegD[14][15:8], mbRegD[14][7:0], mbRegEn[14][1], mbRegEn[14][0], clk, rst, mbRegQ[14]);
    mbReg rf(mbRegD[15][15:8], mbRegD[15][7:0], mbRegEn[15][1], mbRegEn[15][0], clk, rst, mbRegQ[15]);

    register #(16) sc(scratchRegQ, scratchRegD, scratchRegEn, clk, rst);

    register #(16) out(mbOutQ, mbOutD, mbOutEn, clk, rst);

    logic [7:0] status;

    enum {IDLE, C0B, S048A, S048B, C12A, C12B, C13, C14, S0BFA, S0BFB, S0BFC, C11, C1D, C1EA, C1EB} state, nextState;

    always_ff @(posedge clk) begin
        if(rst) state <= IDLE;
        else state <= nextState;
    end
    
    always_ff @(posedge clk) begin
        if(addr == 8'h00) dataOut <= status;
        else if(addr == 8'h10) dataOut <= mbOutQ[7:0];
        else if(addr == 8'h18) dataOut <= mbOutQ[15:8];
        else dataOut <= 8'hFF;
    end
    
    logic [7:0] dataIn;
    register #(8) dataReg(dataIn, DI, state == IDLE, clk, rst);

    logic [31:0] workRegA, workRegB, workRegC;

    always_comb begin
        mbRegD = 0;
        mbRegEn = 0;
        scratchRegD = 0;
        scratchRegEn = 0;
        status = 8'hFF;
        workRegA = 0;
        workRegB = 0;
        workRegC = 0;
        case(state)
            IDLE: begin
                status = 0;
                if(we) begin
                    case(addr)
                        16'h060: begin
                            mbRegD[0][7:0] = DI;
                            mbRegEn[0] = 2'b01;
                            mbOutD = {mbRegQ[0][15:8], mbRegD[0][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h61: begin
                            mbRegD[0][15:8] = DI;
                            mbRegEn[0] = 2'b10;
                            mbOutD = {DI, mbRegQ[0][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h62: begin
                            mbRegD[1][7:0] = DI;
                            mbRegEn[1] = 2'b01;
                            mbOutD = {mbRegQ[1][15:8], mbRegD[1][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h63: begin
                            mbRegD[1][15:8] = DI;
                            mbRegEn[1] = 2'b10;
                            mbOutD = {DI, mbRegQ[1][7:0]};
                            mbOutEn = 1'b1;

                        end
                        16'h64: begin
                            mbRegD[2][7:0] = DI;
                            mbRegEn[2] = 2'b01;
                            mbOutD = {mbRegQ[2][15:8], mbRegD[2][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h65: begin
                            mbRegD[2][15:8] = DI;
                            mbRegEn[2] = 2'b10;
                            mbOutD = {DI, mbRegQ[2][7:0]};
                            mbOutEn = 1'b1;

                        end
                        16'h66: begin
                            mbRegD[3][7:0] = DI;
                            mbRegEn[3] = 2'b01;
                            mbOutD = {mbRegQ[3][15:8], mbRegD[3][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h67: begin
                            mbRegD[3][15:8] = DI;
                            mbRegEn[3] = 2'b10;
                            mbOutD = {DI, mbRegQ[3][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h68: begin
                            mbRegD[4][7:0] = DI;
                            mbRegEn[4] = 2'b01;
                            mbOutD = {mbRegQ[4][15:8], mbRegD[4][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h69: begin
                            mbRegD[4][15:8] = DI;
                            mbRegEn[4] = 2'b10;
                            mbOutD = {DI, mbRegQ[4][7:0]};
                            mbOutEn = 1'b1;
                        
                        end
                        16'h6a: begin
                            mbRegD[5][7:0] = DI;
                            mbRegEn[5] = 2'b01;
                            mbOutD = {mbRegQ[5][15:8], mbRegD[5][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h6c: begin
                            mbRegD[6] = {8'h00, DI};
                            mbRegEn[6] = 2'b11;
                            mbOutD = {8'h00, DI};
                            mbOutEn = 1'b1;
                        end
                        16'h75: begin
                            mbRegD[7][7:0] = DI;
                            mbRegEn[7] = 2'b01;
                            mbOutD = {mbRegQ[7][15:8], mbRegD[7][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h76: begin
                            mbRegD[7][15:8] = DI;
                            mbRegEn[7] = 2'b10;
                            mbOutD = {DI, mbRegQ[7][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h7a: begin
                            mbRegD[8][7:0] = DI;
                            mbRegEn[8] = 2'b01;
                            mbOutD = {mbRegQ[8][15:8], mbRegD[8][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h7b: begin
                            mbRegD[8][15:8] = DI;
                            mbRegEn[8] = 2'b10;
                            mbOutD = {DI, mbRegQ[8][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h6d: begin
                            mbRegD[10][7:0] = DI;
                            mbRegEn[10] = 2'b01;
                            mbOutD = {mbRegQ[10][15:8], mbRegD[10][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h6e: begin
                            mbRegD[10][15:8] = DI;
                            mbRegEn[10] = 2'b10;
                            mbOutD = {DI, mbRegQ[10][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h6f: begin
                            mbRegD[11][7:0] = DI;
                            mbRegEn[11] = 2'b01;
                            mbOutD = {mbRegQ[11][15:8], mbRegD[11][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h70: begin
                            mbRegD[11][15:8] = DI;
                            mbRegEn[11] = 2'b10;
                            mbOutD = {DI, mbRegQ[11][7:0]};
                            mbOutEn = 1'b1;
                        end
                        16'h77: begin
                            mbOutD = mbRegQ[7];
                            mbOutEn = 1'b1;
                        end
                        16'h79: begin
                            mbOutD = mbRegQ[8];
                            mbOutEn = 1'b1;
                        end
                        16'h78: begin
                            mbOutD = mbRegQ[9];
                            mbOutEn = 1'b1;
                        end
                    endcase
                end
            end

            C0B: begin
                mbRegD[15] = 16'hFFFF;
                mbRegEn[15] = 2'b11;

                mbRegD[4] = mbRegQ[4] - mbRegQ[2];
                mbRegEn[4] = 2'b11;
                
                mbRegD[5] = {dataIn, mbRegQ[5][7:0]} - mbRegQ[3];
                mbRegEn[5] = 2'b11;
            end
        
            /*
            reg7 = (reg0 * reg4 + -reg1 * reg5)[31:16]
            */
            S048A: begin
                workRegA = $signed(mbRegQ[0]) * $signed(mbRegQ[4]);
                workRegB = -1*$signed(mbRegQ[1]) * $signed(mbRegQ[5]);
                
                workRegC = workRegA + workRegB;
                
                mbRegD[12] = (workRegB[15:0] >> 1);
                mbRegD[14] = (workRegA[15:0] >> 1);

                mbRegEn[12] = 2'b11;
                mbRegEn[14] = 2'b11;
                
                mbRegD[7] = workRegC[31:16];
                mbRegEn[7] = 2'b11;
            end

            S048B: begin
                if(mbRegQ[15][15] != 1'b1) begin
                    mbRegD[7] = mbRegQ[7] + mbRegQ[2];
                    mbRegEn[7] = 2'b11;
                end
                else begin
                    mbOutD = mbRegQ[7];
                    mbOutEn = 1'b1; 
                end 
            end

            C12A: begin

                workRegA = $signed(mbRegQ[1]) * $signed(mbRegQ[4]);
                workRegB = $signed(mbRegQ[0]) * $signed(mbRegQ[5]);
                
                workRegC = workRegA + workRegB;

                mbRegD[9] = (workRegA[15:0] + workRegB[15:0]) & 16'hFFFE;
                mbRegD[12] = workRegB[15:0] >> 1;

                mbRegEn[9] = 2'b11;
                mbRegEn[12] = 2'b11;

                mbRegD[8] = workRegC[31:16]; //reg8 + regC
                mbRegEn[8] = 2'b11;
            end

            C12B: begin
                if(mbRegQ[15][15] != 1'b1) begin
                    mbRegD[8] = mbRegQ[8] + mbRegQ[3];
                    mbRegD[9] = mbRegQ[9] & 16'hFF00;
                    mbRegEn[8] = 2'b11;
                    mbRegEn[9] = 2'b11;
                end
                else begin
                    mbOutD = mbRegQ[8];
                    mbOutEn = 1'b1;
                end
            end

            C13: begin
                mbRegD[12] = mbRegQ[9];
                scratchRegD = mbRegQ[8];
                mbRegEn[12] = 2'b11;
                scratchRegEn = 1'b1;
            end

            C14: begin
                mbRegD[12] = mbRegQ[10];
                scratchRegD = mbRegQ[11];
                mbRegEn[12] = 2'b11;
                scratchRegEn = 1'b1;
            end

            S0BFA: begin
                mbRegD[14] = mbRegQ[7] ^ scratchRegQ;
                mbRegEn[14] = 2'b11;
                if(scratchRegQ[15] == 0) begin
                    mbRegD[13] = scratchRegQ;
                    scratchRegD = mbRegQ[12];
                    mbRegEn[13] = 2'b11;
                    scratchRegEn = 1'b1;
                end
                else begin
                    scratchRegD = -1 * $signed(mbRegQ[12]);
                    scratchRegEn = 1'b1;
                    if($signed(mbRegQ[12]) > 0) begin
                        mbRegD[13] = -1*$signed(scratchRegQ);
                        mbRegEn[13] = 2'b11;
                    end
                    else begin
                        mbRegD[13] = -1*$signed(scratchRegQ) - 1;
                        mbRegEn[13] = 2'b11;
                    end
                end

                mbRegD[12] = (mbRegQ[7][15] == 0) ? mbRegQ[7] : -1*$signed(mbRegQ[7]);
                mbRegEn[12] = 2'b11;

                mbRegD[15] = mbRegQ[6];
                mbRegEn[15] = 2'b11;

            end

            S0BFB: begin
                if($signed(mbRegQ[13] - mbRegQ[12]) >= 0) begin
                    scratchRegD = (scratchRegQ << 1) + 1;
                    scratchRegEn = 1'b1;
                    mbRegD[13] = ((mbRegQ[13] - mbRegQ[12]) << 1) + scratchRegQ[15];
                    mbRegEn[13] = 2'b11;
                end
                else begin
                    scratchRegD = (scratchRegQ << 1);
                    scratchRegEn = 1'b1;
                    mbRegD[13] = (mbRegQ[13] << 1) + scratchRegQ[15];
                    mbRegEn[13] = 2'b11;
                end
                mbRegD[15] = mbRegQ[15] - 1;
                mbRegEn[15] = 2'b11;
            end

            S0BFC: begin
                mbOutEn = 1'b1;
                if(mbRegQ[14][15] == 1'b0) mbOutD = scratchRegQ;
                else mbOutD = -1 * $signed(scratchRegQ);
            end

            C11: begin
                mbRegD[5] = {dataIn, mbRegQ[5][7:0]};
                mbRegEn[5] = 2'b11;
                mbRegD[15] = 16'h00;
                mbRegEn[15] = 2'b11;
            end

            C1D: begin
                
                if($signed(mbRegQ[2] - mbRegQ[0]) < 0) begin
                    mbRegD[2] = mbRegQ[0] - mbRegQ[2]; //inverted for mult by neg 1
                    mbRegEn[2] = 2'b11;
                end
                else begin
                    mbRegD[2] = mbRegQ[2] - mbRegQ[0];
                    mbRegEn[2] = 2'b11;
                end

                if($signed({dataIn, mbRegQ[3][7:0]} - mbRegQ[1]) < 0) begin
                    mbRegD[3] = mbRegQ[1] - {dataIn, mbRegQ[3][7:0]}; //inverted for mult by neg 1
                    mbRegEn[3] = 2'b11;
                end
                else begin
                    mbRegD[3] = {dataIn, mbRegQ[3][7:0]} - mbRegQ[1];
                    mbRegEn[3] = 2'b11;
                end

            end

            C1EA: begin
                if($signed(mbRegQ[3]) >= $signed(mbRegQ[2])) begin
                    mbRegD[12] = mbRegQ[2];
                    mbRegEn[12] = 2'b11;

                    mbRegD[13] = mbRegQ[3];
                    mbRegEn[13] = 2'b11;
                end
                else begin
                    mbRegD[13] = mbRegQ[2];
                    mbRegEn[13] = 2'b11;
                    
                    mbRegD[12] = mbRegQ[3];
                    mbRegEn[12] = 2'b11;
                end
            end

            C1EB: begin
                mbRegD[12] = $signed(mbRegQ[12]) >>> 3;
                mbRegEn[12] = 2'b11;
                
                workRegA = $signed(mbRegQ[12]) >>> 2;
                workRegB = $signed(mbRegQ[12]) >>> 3;

                mbRegD[13] = ( mbRegQ[13] + workRegA + workRegB );

                mbRegEn[13] = 2'b11;

                mbOutD = mbRegD[13];
                mbOutEn = 1'b1;
            end

        endcase 
    end

    always_comb begin
        case(state)
            
            IDLE: begin
                if(we) begin
                    case(addr) 
                        8'h6b: nextState = C0B;
                        8'h72: nextState = C12A;
                        8'h73: nextState = C13;
                        8'h74: nextState = C14;
                        8'h71: nextState = C11;
                        8'h7D: nextState = C1D;
                        8'h7E: nextState = C1EA;
                        default: nextState = IDLE;
                    endcase
                end
                else nextState = IDLE;
            end

            C0B: nextState = S048A;
            S048A: nextState = S048B;
            S048B: nextState = (mbRegQ[15][15] == 1'b1) ? IDLE : C12A;
            C12A: nextState = C12B;
            C12B: nextState = (mbRegQ[15][15] == 1'b1) ? IDLE : C13;
            C13: nextState = S0BFA;
            C14: nextState = S0BFA;
            S0BFA: nextState = S0BFB;
            S0BFB: nextState = ($signed(mbRegQ[15]) > 0) ? S0BFB : S0BFC;
            S0BFC: nextState = IDLE;
            C11: nextState = S048A;
            C1D: nextState = C1EA;
            C1EA: nextState = C1EB;
            C1EB: nextState = IDLE;
        endcase
    end



endmodule


module mbReg(input  logic [7:0] dHigh, dLow, 
             input  logic       enHigh, enLow, clk, rst, 
             output logic [15:0] Q);

    always_ff @(posedge clk) begin
        if(rst) Q <= 0;
        else begin
            if(enHigh) Q[15:8] <= dHigh;
            if(enLow)  Q[7:0] <= dLow;
        end
    end

endmodule

/*module register(Q, D, enable, clk, rst);

    parameter WIDTH = 8, startVal = 0;

    output logic [WIDTH-1:0] Q;
    input logic [WIDTH-1:0] D;
    input logic enable, clk, rst;

    always_ff @(posedge clk) begin
        if(rst) Q <= startVal;
        else if(enable) Q <= D;
    end
                

endmodule


*/