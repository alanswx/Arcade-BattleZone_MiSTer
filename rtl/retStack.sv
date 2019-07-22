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