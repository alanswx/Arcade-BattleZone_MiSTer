module vga_register
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] D,
    input logic clk, clr, en,
    output logic [WIDTH-1:0] Q );

   always_ff @(posedge clk, negedge clr)
     if(~clr)
       Q <= 0;
     else if(en) Q <= D;
   
endmodule 