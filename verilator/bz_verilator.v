//
// top end ff for verilator
//

//`define sdl_display
`define USE_VGA
//`define USE_CGA

module top(VGA_R,VGA_B,VGA_G,VGA_HS,VGA_VS,reset,clk_sys,clk_vid,ioctl_download,ioctl_addr,ioctl_dout,ioctl_index,ioctl_wait,ioctl_wr,start);

   input clk_sys/*verilator public_flat*/;
   input clk_vid/*verilator public_flat*/;
   input reset/*verilator public_flat*/;

   output [7:0] VGA_R/*verilator public_flat*/;
   output [7:0] VGA_G/*verilator public_flat*/;
   output [7:0] VGA_B/*verilator public_flat*/;
   
   output VGA_HS;
   output VGA_VS;
   
   input        ioctl_download;
   input        ioctl_wr;
   input [24:0] ioctl_addr;
   input [7:0] ioctl_dout;
   input [7:0]  ioctl_index;
   output  reg     ioctl_wait=1'b0;
   input        start;
 
   

   
   //-------------------------------------------------------------------

wire cart_download = ioctl_download & (ioctl_index != 8'd0);
wire bios_download = ioctl_download & (ioctl_index == 8'd0);


reg old_cart_download;
reg initial_pause = 1'b1;

always @(posedge clk_sys) begin
	old_cart_download <= cart_download;
	if (old_cart_download & ~cart_download) initial_pause <= 1'b0;
end

////////////////////////////  HPS I/O  //////////////////////////////////

wire  [1:0] buttons;
wire [31:0] status;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire        ioctl_wr;
wire [7:0]  ioctl_index;

wire [15:0] joy0,joy1;

reg [3:0]red;
reg [3:0]green;
reg [3:0]blue;
assign VGA_R = {red , red };
assign VGA_G = {green, green };
assign VGA_B = {blue , blue };
   

bzonetop bzonetop(
	.clk(clk_vid),
	.rst_l(~reset),
	.sw(),
	.JB(),
	.JD(),
   	.vgaRed(red),
   	.vgaGreen(green),
   	.vgaBlue(blue),
   .Hsync(VGA_HS),
   .Vsync(VGA_VS),
   .ampPWM(),
   .ampSD(),
        .en_r()
        );




endmodule // ff_cpu_test

