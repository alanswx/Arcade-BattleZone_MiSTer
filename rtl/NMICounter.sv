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