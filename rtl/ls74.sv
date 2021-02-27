module ls74
  (
   input clk,
   input clk_en,
   input _set,
   input clr,
   input D,
   output logic q,
   output logic q_
   );

  always @ (posedge clk) begin
    if(clk_en)begin
      casez ({_set,clr,D})  
	3'b01? :  begin q <= 1; q_ <= 0; end
	3'b10? :  begin q <= 0; q_ <= 1; end  
	3'b00? :  begin q <= 1; q_<=1; end   //TODO: nonstable
	3'b111 :  begin q <= 1; q_ <= 0; end 
	3'b110 :  begin q <= 0; q_ <= 1; end
      endcase // casez ({_set,clr,D})
    end
  end
  
endmodule
