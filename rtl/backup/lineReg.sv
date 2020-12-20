module lineReg(
	output 	[12:0] 	QStartX, 
	output 	[12:0] 	QEndX, 
	output 	[12:0] 	QStartY, 
	output 	[12:0] 	QEndY, 
   output    [3:0]   QIntensity, 
   output 				valid,
   input    [12:0] 	DStartX, 
	input    [12:0] 	DEndX, 
	input    [12:0] 	DStartY, 
	input    [12:0] 	DEndY, 
   input     [3:0]   DIntensity, 
   input 				writeEn, 
	input 				clk, 
	input 				rst
);

    always_ff @(posedge clk) begin
        if(rst) begin
            QStartX <= 0;
            QEndX <= 0;
            QStartY <= 0;
            QEndY <= 0;
            valid <= 0;
            QIntensity <= 0;
        end
        else begin
            if(writeEn) begin
                QStartX <= DStartX;
                QEndX <= DEndX;
                QStartY <= DStartY;
                QEndY <= DEndY;
                valid <= 1;
                QIntensity <= DIntensity;
            end
        end
    end
endmodule