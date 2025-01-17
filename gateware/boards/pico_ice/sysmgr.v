`default_nettype none

module sysmgr (
	input  wire rst_in,
	output wire clk_12m,
	output wire rst_out
);

    wire clk_12m;
	wire rst_i;
	reg [7:0] rst_cnt = 8'h80;

`ifndef VERILATOR_LINT_ONLY
	// The Pico-Ice V3 examples seem to use the internal ICE40 HFOSC
    SB_HFOSC #(
        .CLKHF_DIV("0b10") // /4 == 12MHz
    ) internal_osc (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_12m)
    );
`endif

	// Logic reset generation
	always @(posedge clk_12m or posedge rst_in)
		if (rst_in)
			rst_cnt <= 8'h80;
		else if (rst_cnt[7])
			rst_cnt <= rst_cnt + 1;

	assign rst_i = rst_cnt[7];

`ifndef VERILATOR_LINT_ONLY
	SB_GB rst_gbuf_I (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(rst_i),
		.GLOBAL_BUFFER_OUTPUT(rst_out)
	);
`endif

endmodule // sysmgr
