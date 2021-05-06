module ls74
  (
   input clk,
   input D,
   output logic q = 0,
   output logic q_ = 0
   );

  always @ (posedge clk) begin
      casez ({D})  
        3'b1 :  begin q <= 1; q_ <= 0; end 
        3'b0 :  begin q <= 0; q_ <= 1; end
      endcase // casez ({_set,clr,D})
  end
  
endmodule
