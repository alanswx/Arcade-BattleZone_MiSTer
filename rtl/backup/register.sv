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