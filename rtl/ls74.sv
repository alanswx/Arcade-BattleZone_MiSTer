module ls74
  (
   input clk,
   input clk_en,
   input D,
   output logic q = 0,
   output logic q_ = 0
   );


  reg last_clk_en;
  always @ (posedge clk) begin
    if(!last_clk_en && clk_en)begin
      casez ({D})  
        3'b1 :  begin q <= 1; q_ <= 0; end 
        3'b0 :  begin q <= 0; q_ <= 1; end
      endcase // casez ({_set,clr,D})
    end
    last_clk_en <= clk_en;
  end
  
endmodule