module noise_shifters_red_baron
  (
   input rst,
   input clk,
   input clk_12KHz_en,
   output rnoise
   );

  wire ab_left;
  wire[7:0] Q_left;
  wire[7:0] Q_right;

  assign ab_left = !Q_right[6] ^ Q_left[0];
  assign rnoise = Q_right[7];

  ls164 ls164_left
    (
     .rst(rst),
     .clk(clk),
     .clk_en(clk_12KHz_en),
     .a(ab_left),
     .b(ab_left),
     .Q(Q_left)
     );
 
  ls164 ls164_right
    (
     .rst(rst),
     .clk(clk),
     .clk_en(clk_12KHz_en),
     .a(Q_left[7]),
     .b(Q_left[7]),
     .Q(Q_right)
     );

  
endmodule
  
