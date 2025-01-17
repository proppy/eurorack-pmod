// Driver for AK4619 ADC/DAC
//
// Currently assumes the device is configured in the audio
// interface mode specified in ak4619-cfg.hex.
//
// Currently 93.75KHz/16bit samples.

`default_nettype none

module ak4619 #(
    parameter W = 16 // sample width, bits
)(
    input  clk,   // Assumed 12MHz
    input  rst,
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,

    output sample_clk,
    output reg signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3,
    input  signed [W-1:0] sample_in0,
    input  signed [W-1:0] sample_in1,
    input  signed [W-1:0] sample_in2,
    input  signed [W-1:0] sample_in3
);

localparam int N_CHANNELS = 4;

logic signed [(W*N_CHANNELS)-1:0] dac_words;
logic signed [W-1:0] adc_words [N_CHANNELS];

logic sdout1_latched    = 1'b0;
logic [7:0] clkdiv      = 8'd0;
logic [1:0] channel;
logic [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clk;
assign mclk        = clk;
assign lrck        = clkdiv[6];   // 12MHz >> 7 == 93.75KHz

assign channel     = clkdiv[6:5]; // 0 == L (Ch0), 1 == R (Ch1)
assign bit_counter = clkdiv[4:0];
assign sample_clk  = lrck;

always_ff @(negedge sample_clk) begin
    dac_words = {sample_in3, sample_in2,
                 sample_in1, sample_in0};
    sample_out0  <= adc_words[0];
    sample_out1  <= adc_words[1];
    sample_out2  <= adc_words[2];
    sample_out3  <= adc_words[3];
end

always_ff @(negedge clk) begin
    // Clock out 16 bits
    if (bit_counter <= (W-1)) begin
        case (channel)
            0: sdin1 <= dac_words[(1*W)-1-bit_counter];
            1: sdin1 <= dac_words[(2*W)-1-bit_counter];
            2: sdin1 <= dac_words[(3*W)-1-bit_counter];
            3: sdin1 <= dac_words[(4*W)-1-bit_counter];
        endcase
    end else begin
        sdin1 <= 0;
    end
    // Clock in 16 bits
    if (bit_counter == 0) begin
        adc_words[channel] <= 0;
    end
    if (bit_counter <= W) begin
        adc_words[channel][W - bit_counter] <= sdout1_latched;
    end

    clkdiv <= clkdiv + 1;
end

always_ff @(posedge clk) begin
    sdout1_latched <= sdout1;
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
