module audio_output(input rst, input clk, input clk_6KHz_en, input ampSD);

 logic [15:0] extAud;
  logic        feedbackAlpha;
  logic        lfsrOut0, lfsrOut1;

  logic        otherAud0, otherAud1;

  xnor xnor0(feedbackAlpha, extAud[3], extAud[14]);

  assign lfsrOut0 = extAud[15];
  assign lfsrOut1 = !(&extAud[14:11]);

  
  always_ff @(posedge clk)
    if (clk_6KHz_en) begin
      if (rst | !ampSD) begin
        extAud <= '0;
      end else if(ampSD) begin
        extAud <= (extAud << 1) | feedbackAlpha;
      end
    end

  always_ff @(posedge clk)
    if (clk_6KHz_en) begin
      if (rst) begin
        otherAud0 <= '0;
        otherAud1 <= '0;
      end else begin
        if (lfsrOut0) otherAud0 <= ~otherAud0;
        if (lfsrOut1) otherAud1 <= ~otherAud1;
      end
    end

endmodule