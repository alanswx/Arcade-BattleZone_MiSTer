module gen_ram #(
    parameter dWidth = 8,
    parameter aWidth = 10
) (
    // Port A
    input   wire                clk,
    input   wire                we,
    input   wire    [aWidth-1:0]  addr,
    input   wire    [dWidth-1:0]  d,
    output  reg     [dWidth-1:0]  q,
     
    input wire cs
);
 
// Shared memory
reg [dWidth-1:0] mem [(2**aWidth)-1:0];
 
// Port A
always @(posedge clk) begin
    q      <= mem[addr];
    if(we) begin
        q      <= d;
        mem[addr] <= d;
    end
end
 
 
endmodule
