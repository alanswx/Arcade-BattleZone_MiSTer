`include "avg_defines.vh"
module avg_decode
  (
   output logic        zWrEn,
   output logic        scalWrEn,
   output logic        center,
   output logic        jmp,
   output logic        jsr,
   output logic        ret,
   output logic        useZReg,
   output logic        blank,
   output logic        halt,
   output logic        vector,
   output logic [15:0] jumpAddr,
   output logic [2:0]  pcOffset,
   output logic [12:0] dX, dY,
   output logic [3:0]  zVal,
   output logic [7:0]  linScale,
   output logic [2:0]  binScale,
   output logic [2:0]  color,
   output logic [2:0]  instLength,
   input logic [31:0]  inst
   );

  logic [2:0]          dcd_op;
  assign dcd_op = inst[23:21];

  always_comb begin
    zWrEn      = 1'b0;
    scalWrEn   = 1'b0;
    center     = 1'b0;
    jmp        = 1'b0;
    jsr        = 1'b0;
    ret        = 1'b0;
    useZReg    = 1'b0;
    blank      = 1'b0;
    halt       = 1'b0;
    vector     = 1'b0;
    jumpAddr   = 16'h0;
    pcOffset   = 3'h0;
    dX         = 0; dY = 0;
    linScale   = 0; binScale = 0;
    color      = 3'b010;
    instLength = 0;
    zVal       = 4'b0000;
    case(dcd_op)
      `OP_VCTR: begin
        //DEMO
        dY = ({inst[20:16], inst[31:24]});
        dX = ({inst[4:0], inst[15:8]});
        vector = 1;
        if(inst[7:5] == 3'b000) blank = 1'b1;
        else if(inst[7:5] == 3'b001) useZReg = 1'b1;
        else zVal = {1'b0, inst[7:5]} << 1;
        pcOffset = 3'h4;
        instLength = 7;
      end
      `OP_HALT: begin
        halt = 1'b1;
        pcOffset = 3'h2;
        instLength = 1;
      end

      `OP_SVEC: begin
        dY[0] = 1'b0;
        dY[5:1] = (inst[20:16]); //>> 1; //DEMO: removed the right shift
        //DEMO: added a sign extension check
        if(inst[20] == 1'b1)
          dY[12:6] = 7'b1111111;
        else
          dY[12:6] = 7'b0000000;

        dX[0] = 1'b0;
        dX[5:1] = (inst[28:24]);// >> 1; //DEMO: removed the right shift
        //DEMO: added a sign extension check
        if(inst[28] == 1'b1)
          dX[12:6] = 7'b1111111;
        else
          dX[12:6] = 7'b0000000;

        vector = 1;
        if(inst[31:29] == 3'b000) blank = 1'b1;
        else if(inst[31:29] == 3'b001) useZReg = 1'b1;
        else zVal = {1'b0, inst[31:29]} << 1;
        pcOffset = 3'h2;
        instLength = 5;
      end

      `OP_STORE: begin
        pcOffset = 3'h2;
        case(inst[20])
          1'b0: begin//STAT
            zWrEn = 1'b1;
            zVal = inst[31:28];
            color = inst[19:16];
            instLength = 6;
          end
          1'b1: begin //SCAL
            linScale = inst[31:24];
            binScale = inst[18:16];
            scalWrEn = 1'b1;
            instLength = 2;
          end
        endcase
      end

      `OP_CNTR: begin
        center = 1'b1;
        pcOffset = 3'h2;
        instLength = 4;
      end

      `OP_JSR: begin
        jmp = 1'b1;
        jsr = 1'b1;
        jumpAddr = {inst[19:16], inst[31:24]} << 1;
        pcOffset = 3'h2;
        instLength = 4;
      end

      `OP_JMP: begin
        jmp = 1'b1;
        jumpAddr = {inst[19:16], inst[31:24]} << 1;
        pcOffset = 3'h2;
        instLength = 4;
      end

      `OP_RTS: begin
        ret = 1'b1;
        pcOffset = 3'h2;
        instLength = 3;
      end
    endcase
  end
endmodule
