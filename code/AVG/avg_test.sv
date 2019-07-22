
module test;
    logic [7:0] memory [16'h2000:16'h4000];

    logic [31:0] testVal;

    logic [10:0] DStartX, DStartY, DEndX, DEndY;
    logic [10:0] QStartX, QStartY, QEndX, QEndY;
    logic lrWrite;
    logic clk, rst_b, clk_10x;

    logic [2:0] DColor, QColor;
    logic [15:0] pc;
    bit [15:0] inst;

    logic full, empty;
    logic read;

    logic [3:0] count;
    logic vggo;
    
    logic [15:0] inPC;


    avg_core core(DStartX, DStartY, DEndX, DEndY, DColor, lrWrite, pc, inst, clk_10x, rst_b, vggo);
    
    lineRegQueue q(QStartX, QEndX, QStartY, QEndY, QColor, full, empty, DStartX, DEndX, DStartY, DEndY, DColor, read, lrWrite, clk_10x, rst_b);

    register #(4) counter(count, count+1'b1, 1'b1, clk_10x, rst_b);
   
    assign read = (count == 15);
    
    always_comb begin
        if(pc < 16'h2000) inst = 0;
        else begin 
            inst <= #10 {memory[pc], memory[pc+1]}; 
        end
    end

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin
        clk_10x = 0;
        forever #5 clk_10x = ~clk_10x;
    end

    initial begin
        $readmemh("code.hex", memory, 16'h2000, 16'h4000);
        rst_b = 0;
        vggo = 0;
        #1 rst_b = 1; 

        #10000 vggo = 1;
        #10005 vggo = 0;

        #50000 $finish;

        /*
        while( !core.halt ) begin
            @(posedge clk);
        end 
        */  
    end
endmodule
