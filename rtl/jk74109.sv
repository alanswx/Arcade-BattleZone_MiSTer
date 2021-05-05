module jk74109
  (
   input rst,
   input clk,
   input clk_en,
   input j,
   input k,
   output logic q = 0,
   output logic q_
   );

  assign q_ = ~q;

  always @ (posedge clk) begin
    if(rst)begin
      q <= 0;      
    end else if(clk_en)begin
      case ({j,k})  
          2'b00 :  q <= q;  
          2'b01 :  q <= 0;  
          2'b10 :  q <= 1;  
          2'b11 :  q <= ~q;  
      endcase
    end
  end

endmodule
