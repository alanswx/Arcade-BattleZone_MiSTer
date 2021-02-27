module jk74109
  (
   input clk,
   input clk_6KHz_en,
   input pre,
   input clr,
   input j,
   input k,
   output logic q,
   output logic q_
   );

  logic clk_is_up;
  
  always @ (posedge clk) begin
    if(clk_6KHz_en)begin
      clk_is_up <= !clk_is_up;
      if(clk_is_up)begin
	casez ({pre,clr,clk_is_up,j,k})  
	  5'b01??? :  begin q <= 1; q_ <= 0; end
	  5'b10??? :  begin q <= 0; q_ <= 1; end
	  5'b00??? :  begin q <= 1; q_<=1; end //TODO: nonstable
	  5'b11100 :  begin q <= 0; q_ <= 1; end   
	  5'b11110 :  begin q <= !q; q_ <= !q_; end //toggle
	  5'b11101 :  ;  
	  5'b11111 :  begin q <= 1; q_ <=0; end  
	  5'b110?? :  ;  
	endcase
      end else begin
	if({pre,clr,j,k} == 4'b1110)begin   //toggle
	  q <= !q;
	  q_ <= !q_;
	end  
      end
    end
  end
  
endmodule
