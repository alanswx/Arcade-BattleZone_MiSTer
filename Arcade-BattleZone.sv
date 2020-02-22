//============================================================================
//  Arcade: Asteroids-Deluxe
//
//  Port to MiSTer
//  Copyright (C) 2018 
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;

`include "build_id.v" 
localparam CONF_STR = {
	"A.BATTLEZONE;;",
	"F,rom;", // allow loading of alternate ROMs
	"-;",
	"O1,Aspect Ratio,Original,Wide;",
//	"O2,Orientation,Vert,Horz;",
	"O34,Language,English,German,French,Spanish;",
//	"O56,Ships,2-4,3-5,4-6,5-7;", system locks up when activating above 3-5
	"-;",
	"R0,Reset;",
	"J1,Fire,Thrust,Shield,Start;",	
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_6, clk_25, clk_100;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_100),	
	.outclk_1(clk_25),	
	.outclk_2(clk_6),	
	.locked(pll_locked)
);


///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joy_0, joy_1;
wire [15:0] joy = joy_0 | joy_1;
wire        forced_scandoubler;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_25),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_25) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'h03a: btn_fire         <= pressed; // M
			'h005: btn_one_player   <= pressed; // F1
			'h006: btn_two_players  <= pressed; // F2
			'h01C: btn_left      	<= pressed; // A
			'h023: btn_right      	<= pressed; // D
			'h004: btn_coin  			<= pressed; // F3
			'h04b: btn_thrust  			<= pressed; // L
			'h042: btn_shield  			<= pressed; // K
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h014: btn_fire        <= pressed; // ctrl
			'h011: btn_thrust      <= pressed; // Lalt
			'h029: btn_shield      <= pressed; // space
			// JPAC/IPAC/MAME Style Codes
			'h016: btn_one_player  <= pressed; // 1
			'h01E: btn_two_players <= pressed; // 2
			'h02E: btn_coin        <= pressed; // 5
			'h036: btn_coin        <= pressed; // 6
			
		endcase
	end
end

reg btn_right = 0;
reg btn_left = 0;
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_fire = 0;
reg btn_coin = 0;
reg btn_thrust = 0;
reg btn_shield = 0;

wire [7:0] BUTTONS = {~btn_right & ~joy[0],~btn_left & ~joy[1],~btn_one_player & ~joy[7],~btn_two_players,~btn_fire & ~joy[4],~btn_coin & ~joy[7],~btn_thrust & ~joy[5],~btn_shield & ~joy[6]};

///////////////////////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid = 1; 
wire hs, vs;
wire rde, rhs, rvs;
wire [2:0] r,g,rr,rg;
wire [2:0] b,rb;

assign VGA_CLK  = clk_25; 
assign VGA_CE   = ce_vid;
assign VGA_R    = {r,r,r[2:1]};
assign VGA_G    = {g,g,g[2:1]};
assign VGA_B    = {b,b,b[2:1]};
assign VGA_HS   = ~hs;
assign VGA_VS   = ~vs;

assign HDMI_CLK = VGA_CLK;
assign HDMI_CE  = VGA_CE;
assign HDMI_R   = VGA_R ;
assign HDMI_G   = VGA_G ;
assign HDMI_B   = VGA_B ;
assign HDMI_DE  = VGA_DE;
assign HDMI_HS  = VGA_HS;
assign HDMI_VS  = VGA_VS;
//assign HDMI_SL  = status[2] ? 2'd0   : status[4:3];
assign HDMI_SL  = 2'd0;

wire reset = (RESET | status[0] | buttons[1] | ioctl_download);
wire [7:0] audio;
assign AUDIO_L = {audio, audio};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
wire [1:0] lang = status[4:3];
wire [1:0] ships = status[6:5];

bzonetop bzonetop (
.clk(clk_100),
.rst_l(~reset),
.sw(0),
.JB(BUTTONS),
.vgaRed(r),
.vgaGreen(g),
.vgaBlue(b),
.Hsync(hs),
.Vsync(vs),
.ampPWM(audio),
.ampSD(ampSD),
.en_r(VGA_DE)
        );
/*
ASTEROIDS_TOP ASTEROIDS_TOP
(
	.BUTTON(BUTTONS),
	.LANG(lang),
	.SHIPS(ships),
	.AUDIO_OUT(audio),
	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),	
	.VIDEO_R_OUT(r),
	.VIDEO_G_OUT(g),
	.VIDEO_B_OUT(b),
	.HSYNC_OUT(hs),
	.VSYNC_OUT(vs),
	.VGA_DE(VGA_DE),
	.RESET_L (~reset),	
	.clk_6(clk_6),
	.clk_25(clk_25)
);
*/
endmodule
