module rasterFSM
  (input logic readyIn,
   input logic [12:0] denominator, majCnt,
   input logic 	      clk, rst,
   output logic       loopEn, good, done, rastReady, idleReady, pipe1
   );

   typedef enum       {IDLE, ITER, DONE, PIPE} state;

   state next, current;
   
   assign rastReady = (current == IDLE);
   
   always_ff @(posedge clk)
     begin
	if(rst)
	  current <= IDLE;
	else
	  current <= next;
	
     end

always @(clk)
 //  always_comb
     begin
	case(current)
	  IDLE:
	    begin
	       if(readyIn)
             begin
                next = PIPE;
                idleReady = 1'b1;
             end
	       else
             begin
                next = IDLE;
                idleReady = 1'b0;
             end
           done = 1'b0;
           loopEn = 1'b0;
           good = 1'b0;
           pipe1 = 1'b0;
	    end
	  PIPE:
	   begin
	       next = ITER;
	       pipe1 = 1'b1;
	       done = 1'b0;
	       loopEn = 1'b0;
	       good = 1'b0;
	       idleReady = 1'b0;
	   end
	  ITER:
	    begin
	       if(denominator == majCnt)begin
              next = DONE;
              loopEn = 1'b0;
              good = 1'b1;
              
	       end
	       else begin
              next = ITER;
              loopEn = 1'b1;
              good = 1'b1;
              idleReady = 1'b0;
	       end
	       
	       done = 1'b0;
	       pipe1 = 1'b0;
	       
	    end
	  DONE:
	    begin
	       next = IDLE;
	       
	       done = 1'b1;
	       loopEn = 1'b0;
	       good = 1'b0;
	       idleReady = 1'b0;
	       pipe1=1'b0;
	       
	    end
	endcase // case (current)
     end

endmodule 