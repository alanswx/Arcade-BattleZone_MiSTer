module noise_shifters
  (
   input rst,
   input clk,
   input clk_12KHz_en,
   input sound_enable,
   output shell,
   output explo
   );

  wire q_;
  wire ab_bottom;
  wire[7:0] Q_top;
  wire[7:0] Q_bottom;

  assign ab_bottom = !(Q_bottom[3] ^ Q_top[6]);
  assign explo = !
			   (
			    Q_top[6] 
			    && Q_top[5] 
			    && Q_top[4] 
			    && Q_top[3]
			    );
  assign shell = Q_top[7];

  jk74109 fk_flipflop
    (
     .rst(rst),
     .clk(clk),
     .clk_en(clk_12KHz_en),
     .j(q_),
     .k(~q_),
     .q(),
     .q_(q_)
     );


  ls164 ls164_top
    (
     .rst(~sound_enable),
     .clk(clk),
     .clk_en(q_),
     .a(Q_bottom[7]),
     .b(Q_bottom[7]),
     .Q(Q_top)
     );
 
  ls164 ls164_bottom
    (
     .rst(~sound_enable),
     .clk(clk),
     .clk_en(q_),
     .a(ab_bottom),
     .b(ab_bottom),
     .Q(Q_bottom)
     );
  
endmodule
  
