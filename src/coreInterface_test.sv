module test;

    logic clk, rst;

    logic writeOut, canWrite, we;
    logic [7:0] D, Q;
    logic [15:0] addr, writeAddr;

    memStoreQueue msq(Q, writeAddr, writeOut, D, addr, canWrite, we, clk, rst);

    initial begin
        clk = 0;
        forever clk = #5 ~clk;
    end

    initial begin
        rst = 1;
        canWrite = 0;
        we = 0;
        D = 0;
        addr = 0;
        #10;
        rst = 0;

        @(posedge clk);
        we <= 1;
        D <= 8'ha1;
        addr <= 16'h0001;

        @(posedge clk);
        we <= 0;
        @(posedge clk);
        we <= 1;
        D <= 8'ha2;
        addr <= 16'h0002;
       
        @(posedge clk);
        we <= 0;
        @(posedge clk);
        we <= 1;
        D <= 8'ha3;
        addr <= 16'h0003;
       
        @(posedge clk);
        we <= 0;
        @(posedge clk);
        we <= 1;
        D <= 8'ha4;
        addr <= 16'h0004;
       
        @(posedge clk);
        we <= 0;
        @(posedge clk);
        we <= 1;
        D <= 8'ha5;
        addr <= 16'h0005;
       
       
        @(posedge clk);
        we <= 0;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        
        canWrite <= 1;

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $finish;
    end
endmodule
