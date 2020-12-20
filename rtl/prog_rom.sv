module prog_rom
  (
   input wire [13:0]  addr,
   input wire         clk,
   input wire         clk_en,
   output logic [7:0] dout
   );

  (* ram_style = "block" *) logic [7:0] rom_store[12288];
  initial begin
    $readmemh("prog_clean.mem", rom_store, 0, 12287);
  end
  always @(posedge clk) begin
    if (clk_en) dout <= rom_store[addr];
  end
endmodule
