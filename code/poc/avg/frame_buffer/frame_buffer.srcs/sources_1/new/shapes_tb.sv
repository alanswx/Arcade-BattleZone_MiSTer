`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2015 02:32:30 PM
// Design Name: 
// Module Name: shapes_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shapes_tb(
    output logic[10:0] startX, endX,
    output logic[10:0] startY, endY,
    output logic readyLine,
    output logic[3:0] color,
    input logic rastReady,
    input logic clk, rst, readyFrame);
    
    logic[27:0] count;
    logic[18:0] pixelCount;
    logic clr, switch, validPixel, refresh;
    
    enum logic {WAIT = 1'b0, SEND = 1'b1} state, nextState;
    
    counter #(19) countPixel(clk, refresh, readyLine, ~rst, pixelCount);
    counter #(28) countFrames(clk, clr, 1'b1, ~rst, count);
    
    assign refresh = readyFrame | clr;
    
    always_comb begin
        case (state)
            WAIT: begin
                if(rastReady && validPixel) 
                    nextState = SEND;
                else
                    nextState = WAIT;
            end
            SEND: begin
                nextState = WAIT;
            end
        endcase
    end
    
    always_comb begin
        if(state == SEND && nextState == WAIT)
            readyLine= 1'b1;
        else
            readyLine = 1'b0;
    end
    
       
    always_comb begin
        //if(state) begin //send points for tri
            case(pixelCount)
                0: begin
                       startX = 0;
                       startY = -120;
                       endX = -160;
                       endY = 120;
                       color = 4'b0001;
                       validPixel = 1'b1;
                     end    
                1: begin
                         startX = 0;
                         startY = -120;
                         endX = 160;
                         endY = 120;
                         color = 4'b0010;
                         validPixel = 1'b1;
                     end    
                2: begin
                         startX = -160;
                         startY = 120;
                         endX = 160;
                         endY = 120;
                         color = 4'b0100;
                         validPixel = 1'b1;
                     end    
                default:  begin
                            startX = 'b0;
                            endX = 'b0;
                            startY = 'b0;
                            endY = 'b0;
                            color = 4'b0000;
                            validPixel = 1'b0;
                          end    
            endcase
        //end

        /*else begin
            case(pixelCount)
                0: begin
                       startX = 160;
                       startY = 120;
                       endX = 160;
                       endY = 360;
                       validPixel = 1'b1;
                     end    
                1: begin
                         startX = 160;
                         startY = 360;
                         endX = 480;
                         endY = 360;
                         validPixel = 1'b1;
                     end    
                2: begin
                         startX = 480;
                         startY = 360;
                         endX = 480;
                         endY = 120;
                         validPixel = 1'b1;
                     end    
                3: begin
                         startX = 480;
                         startY = 120;
                         endX = 160;
                         endY = 120;
                         validPixel = 1'b1;
                     end   
                default:  begin
                            startX = 'b0;
                            endX = 'b0;
                            startY = 'b0;
                            endY = 'b0;
                            validPixel = 1'b0;
                          end    
            endcase
        end //send points for square*/
            
        if (count >= 200000000) 
            clr = 1'b1;
        else
            clr = 1'b0;
    end
    
    always_ff@(posedge clk, posedge rst) begin
        if(rst) begin
            switch <= 0;
            state <= WAIT;
        end
        else begin
            state <= nextState;
            if(count >= 200000000) 
                switch <= ~switch;
            else
                switch <= switch;
        end
    end
    
    
endmodule
