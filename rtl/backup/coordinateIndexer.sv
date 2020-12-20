module coordinateIndexer(
	input 	[9:0] 	x,
   input 	[8:0]   	y,
   output  [18:0] 	index
);
   
assign index = ({{9{1'b0}},{x}}) + ({{1'b0},{y},{9{1'b0}}}) + ({{3{1'b0}},{y},{7{1'b0}}});
   
endmodule 