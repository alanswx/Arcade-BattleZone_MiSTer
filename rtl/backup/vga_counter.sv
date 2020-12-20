module vga_counter
  #(parameter WIDTH = 8)
  (input  bit clk, clear, en, rst_L,
   output bit [WIDTH-1:0] Q);

  always_ff@(posedge clk, negedge rst_L)
    if(~rst_L)
      Q <= 0;
    else if (clear)
      Q <= 0;
    else if (en)
      Q <= Q + 1;
endmodule 