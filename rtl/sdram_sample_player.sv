interface SdramSamplePlayerInterface(
	input pll_locked,
	input clk_sys,
	input ioctl_download,
	input ioctl_wr,
	input[24:0] ioctl_addr,
	input[7:0] ioctl_index,
	input[15:0] SDRAM_DQ,
	input play_squeel,
	output[7:0] ioctl_dout,
	output SDRAM_CLK,
	output SDRAM_CKE,
	output[12:0] SDRAM_A,
	output[1:0] SDRAM_BA,
    output SDRAM_DQML,
	output SDRAM_DQMH,
	output SDRAM_nCS,
	output SDRAM_nCAS,
	output SDRAM_nRAS,
	output SDRAM_nWE,
	output[15:0] audio_out
);

endinterface

module sdram_sample_player(
    SdramSamplePlayerInterface bus
);

wire rom_download = bus.ioctl_download && !bus.ioctl_index;

wire [15:0] rom_addr;
wire  [7:0] rom_do;
wire [13:0] snd_addr;
wire [15:0] snd_do;
wire [14:0] sp_addr;
wire [31:0] sp_do;

// ROM structure:
// 00000 - 0DFFF  - Main ROM (8 bit)
// 0E000 - 11FFF - Super Sound board ROM (8 bit)
// 12000 - 31FFF - Sprite ROMs (32 bit)
// 32000 - 39FFF - BG ROMS

//wire [24:0] rom_ioctl_addr = ~ioctl_addr[16] ? ioctl_addr : // 8 bit ROMs
//                             {ioctl_addr[24:16], ioctl_addr[15], ioctl_addr[13:0], ioctl_addr[14]}; // 16 bit ROM

wire [24:0] sp_ioctl_addr = bus.ioctl_addr - 17'h12000; //SP ROM offset: 0x12000
wire [24:0] dl_addr = bus.ioctl_addr - 18'h32000; //background offset

reg port1_req, port2_req;
sdram sdram
(
	.*,
	.init_n        ( bus.pll_locked   ),
	.clk           ( bus.clk_sys      ),

	// port1 used for main + sound CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( bus.ioctl_addr[23:1] ),
	.port1_ds      ( {bus.ioctl_addr[0], ~bus.ioctl_addr[0]} ),
	.port1_we      ( rom_download ),
	.port1_d       ( {bus.ioctl_dout, bus.ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( rom_download ? 16'hffff : (16'h7000 + snd_addr[13:1]) ),
	.cpu1_q        ( snd_do ),
	.cpu2_addr     ( ),
	.cpu2_q        ( ),
	.cpu3_addr     ( ),
	.cpu3_q        ( ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {sp_ioctl_addr[18:17], sp_ioctl_addr[14:0], sp_ioctl_addr[16]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {sp_ioctl_addr[15], ~sp_ioctl_addr[15]} ),
	.port2_we      ( rom_download ),
	.port2_d       ( {bus.ioctl_dout, bus.ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( rom_download ? 15'h7fff : sp_addr ),
	.sp_q          ( sp_do ),

    .SDRAM_DQ(bus.SDRAM_DQ),   // 16 bit bidirectional data bus
	.SDRAM_A(bus.SDRAM_A),    // 13 bit multiplexed address bus
	.SDRAM_DQML(bus.SDRAM_DQML), // two byte masks
	.SDRAM_DQMH(bus.SDRAM_DQMH), // two byte masks
	.SDRAM_BA(bus.SDRAM_BA),   // two banks
	.SDRAM_nCS(bus.SDRAM_nCS),  // a single chip select
	.SDRAM_nWE(bus.SDRAM_nWE),  // write enable
	.SDRAM_nRAS(bus.SDRAM_nRAS), // row address select
	.SDRAM_nCAS(bus.SDRAM_nCAS), // columns address select
	.SDRAM_CKE(bus.SDRAM_CKE),
	.SDRAM_CLK(bus.SDRAM_CLK)
);


// ROM download controller
always @(posedge clk_sys) begin
	if (rom_download) begin
		if (bus.ioctl_wr && rom_download) begin
			port1_req <= ~port1_req;
		end
	end
end



////////////////////////////  WAV PLAYER  ///////////////////////////////////
//
//


wire wav_load = bus.ioctl_download && (bus.ioctl_index == 2);

wire [63:0] s_dout;
wire [24:0] s_addr = wav_addr[27:3];
wire        s_ack;
reg         s_rd;
reg         wav_data_ready;

always @(posedge clk_sys) begin
	reg old_wav_rd;
	reg old_ack;

	old_ack <= s_ack;
	if((old_ack ^ s_ack) | ~bus.play_squeel) wav_data_ready <= 1;

	old_wav_rd <= wav_rd;
	if(~old_wav_rd & wav_rd) begin
		s_rd <= ~s_rd;
		wav_data_ready <= 0;
	end
end

reg wav_loaded = 0;
always @(posedge clk_sys) begin
	reg old_load;
	
	old_load <= wav_load;
	if(old_load & ~wav_load) wav_loaded <= 1;
end

wire [27:0] wav_addr;
wire  [7:0] wav_data = s_dout[(wav_addr[2:0]*8) +:8];
wire        wav_rd;

wave_sound #(40000000) wave_sound
(
	.I_CLK(clk_sys),
	.I_RST(~bus.play_squeel | ~wav_loaded),

	.I_BASE_ADDR(0),
	.I_LOOP(0),
	.I_PAUSE(0),

	.O_ADDR(wav_addr),        // output address to wave ROM
	.O_READ(wav_rd),          // read a byte
	.I_DATA(wav_data),        // Data coming back from wave ROM
	.I_READY(wav_data_ready), // read a byte

	.O_PCM(bus.audio_out)
);




endmodule