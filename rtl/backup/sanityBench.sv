//NOTE: Outdated, need to change 10:0 to 12:0
module sanityBench();

   logic [10:0]  startX, endX;
   logic [10:0]  startY, endY;
   logic 	 clk, rst, readyIn;
   logic [18:0]  addressOut;
   logic [10:0]  pixelX, pixelY;
   
   logic 	 goodPixel, done;


   logic [2:0] 	 valIn, valOut;


   logic [10:0]  numerator, denominator;
   logic 	 inc;
   
   
   logic 	 en;
   
   

   rasterizer testee(.*);


   absVal #(3) testee2(.*);
   

   bresenhamCore testee3(.*);
   
   initial begin
      clk = 0;
      forever #10 clk = ~clk;
   end

   
   initial begin

      $monitor("%d: (%d, %d) - %b", $time, pixelX, pixelY, goodPixel);
      
      startY = 11'd50;
      endY = 11'd250;
      startX = -11'd25;
      endX = 11'd75;
      readyIn = 0;
      rst = 1;
      @(posedge clk);

      rst = 0;
      @(posedge clk);
      
      readyIn = 1;
      @(posedge clk);
      readyIn = 0;
      
      $display("Denominator: %d", testee.denominator);
      
      
      do begin
	 @(posedge clk);
	 
      end while(!done);
      
      
      $finish;
      
      
      
   end
   

   

   
endmodule: sanityBench