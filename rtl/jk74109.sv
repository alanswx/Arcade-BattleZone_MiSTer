module jk74109
  (
   input rst,
   input clk,
   input clk_en,
   input j,
   input k,
   output logic q,
   output logic q_
   );

  
  always @ (posedge clk) begin
    if(rst)begin
      q <= 0;      
    end else if(clk_en)begin
      casez ({j,k})  
	2'b00 :  ;
	2'b01 :  q <= 1'b0;
	2'b10 :  q <= 1'b1;
	2'b11 :  q <= !q;  
      endcase
      q_ <= !q;
    end
  end
  
endmodule
