module lineRegQueue(
	output [12:0] 	QStartX, 
	output [12:0] 	QEndX, 
	output [12:0] 	QStartY, 
	output [12:0] 	QEndY, 
   output  [3:0]  QIntensity, 
   output			full, 
   output			empty,  
   input  [12:0] 	DStartX, 
	input  [12:0] 	DEndX, 
	input  [12:0] 	DStartY, 
	input  [12:0] 	DEndY, 
   input   [3:0]  DIntensity, 
   input  			read,  
	input  			currWrite, 
	input  			clk, 
	input  			rst
);

reg [31:0] [12:0] startX, startY, endX, endY; 
reg [31:0] valid;
reg [31:0] writeEn;
reg [31:0] [3:0] intensity;

reg [31:0] wrIndex, reIndex;
reg [32:0] numFilled;

genvar i;
generate
	for(i = 0; i < 31; i++) begin: rasterizer
		lineReg l1(
			.QStartX(startX[i]), 
			.QEndX(endX[i]), 
			.QStartY(startY[i]), 
			.QEndY(endY[i]), 
			.QIntensity(intensity[i]), 
			.valid(valid[i]), 
			.DStartX(DStartX), 
			.DEndX(DEndX), 
			.DStartY(DStartY), 
			.DEndY(DEndY),
			.DIntensity(DIntensity),  
			.writeEn(writeEn[i]), 
			.clk(clk), 
			.rst(rst)
);
        end
endgenerate 

reg lastWrite, write;

assign write = currWrite && !lastWrite;

    always_ff @(posedge clk) begin
        if(rst) begin
            wrIndex <= 'd0;
            reIndex <= 'd0;
            lastWrite <= 'd0;
            numFilled <= 'd0;
        end
        else begin
            lastWrite <= currWrite;
            if(write && read && !empty) begin
                wrIndex <= wrIndex + 'd1;
                reIndex <= reIndex + 'd1;
            end
            else if(write && !full) begin
                wrIndex <= wrIndex + 'd1;
                numFilled <= numFilled + 'd1;
            end
            else if(read && !empty) begin
                reIndex <= reIndex + 'd1;
                numFilled <= numFilled - 'd1;
            end
        end
    end

assign full = (numFilled == 32);
assign empty = (numFilled == 'd0);

assign QStartX = startX[reIndex];
assign QEndX = endX[reIndex];
assign QStartY = startY[reIndex];
assign QEndY = endY[reIndex];
assign QIntensity = intensity[reIndex];

    always_comb begin
        writeEn = 'd0;
        writeEn[wrIndex] = write;
    end

endmodule 
