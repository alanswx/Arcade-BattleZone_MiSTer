module addrDecoder(output logic  [7:0] dataToCore, 
                   output logic  [4:0] [15:0] addrToBram, 
                   output logic  [4:0] [7:0] dataToBram,
                   output logic  [4:0] weEnBram,
                   output logic        vggo, vgrst, 
                   
                   input  logic  [7:0] dataFromCore,
                   input  logic [15:0] addr,
                   input  logic  [4:0] [7:0] dataFromBram,
                   input  logic        we, halt, clk_3KHz, clk, self_test,
                   input  logic [15:0] option_switch,
                   input  logic        coin);

    logic [2:0] bramNum, outBramNum;

    logic [15:0] outBramAddr;

    logic sound_access;
    always_ff @(posedge clk) begin
        outBramNum <= bramNum;
        outBramAddr <= addr;
    end

    assign vggo = (addr == 16'h1200) && we;
    assign vgrst = (addr == 16'h1600) && we;

    always_comb begin
        sound_access = 1'b0;
        if(addr >= 16'h0 && addr < 16'h0400) bramNum = 3'b000;
        else if(16'h2000 <= addr && addr < 16'h4000) bramNum = 3'b001;
        else if(16'h5000 <= addr && addr < 16'h8000) bramNum = 3'b010;
        else if(16'h1820 <= addr && addr < 16'h1830) bramNum = 3'b011;  
        else if(16'h1840 == addr) begin 
            bramNum = 3'b011;
            sound_access = 1'b1;
        end
        else if(addr == 16'h1800 || addr == 16'h1810 || addr == 16'h1818 || (16'h1860 <= addr && addr <= 16'h187f)) bramNum = 3'b100;  
        else bramNum = 5; //error code
    end

    logic unmappedAccess, vramWrite, unmappedRead, mathboxAccess;

    always_comb begin
        mathboxAccess = bramNum == 3'b100;
        addrToBram[0] = 'd0;
        addrToBram[1] = 'd0;
        addrToBram[2] = 'h5000;
        addrToBram[3] = 'd0;
        addrToBram[4] = 'd0;
        dataToBram[0] = 'd0;
        dataToBram[1] = 'd0;
        dataToBram[2] = 'd0;
        dataToBram[3] = 'd0;
        dataToBram[4] = 'd0;
        unmappedAccess = 1'b0;
        vramWrite = 1'b0;
        unmappedRead = 1'b0;
        //dataToCore = dataFromBram[outBramNum];
        weEnBram = (we << bramNum);
        dataToBram[bramNum] = dataFromCore;
        addrToBram[bramNum] = addr;
    
        if(outBramNum < 5) begin
            dataToCore = dataFromBram[outBramNum];
        end
        else begin
            case(outBramAddr)
                16'h800: dataToCore = {clk_3KHz, halt, 1'b1, self_test, 3'b111, coin};
                16'ha00: dataToCore = option_switch[7:0];//dataToCore = 8'b0001_0101;
                16'hc00: dataToCore = option_switch[15:8];
                //16'h1800: dataToCore = 8'b11111111;
                default: begin
                    if(outBramAddr != 16'h1400) unmappedAccess = 1;
                    if(~we) unmappedRead = 1'b1;
                    dataToCore = 8'd0;
                end
            endcase
        end
        
        if(bramNum == 3'b001 && dataFromCore != 'd0 && we) vramWrite = 1'b1;
    
    end

endmodule 