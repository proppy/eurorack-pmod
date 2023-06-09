// Copyright 2023 The XLS Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module apu_chord #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3,
    input [7:0] jack
);
   wire [10:0] 	period = sample_in0[W-1:W-11];
   wire 	period_valid = 1'b1;
   wire 	period_ready;

   wire [1:0] 	duty = sample_in1[W-2:W-3];
   wire 	duty_valid = 1'b1;
   wire 	duty_ready;

   wire 	signal0;
   wire 	signal0_valid;
   wire 	signal0_ready = 1'b1;

   wire		signal1;
   wire		signal1_valid;
   wire		signal1_ready = 1'b1;

   wire		signal2;
   wire		signal2_valid;
   wire		signal2_ready = 1'b1;

   wire		signal3;
   wire		signal3_valid;
   wire		signal3_ready = 1'b1;

   assign sample_out0 = signal0 ? 16'b0111111111111111 : 16'b1000000000000000;
   assign sample_out1 = signal1 ? 16'b0111111111111111 : 16'b1000000000000000;
   assign sample_out2 = signal2 ? 16'b0111111111111111 : 16'b1000000000000000;
   
   wire signed [2:0] mixed = signal0 + signal1 + signal2 + signal3 - 4;
   assign sample_out3 = mixed <<< 13;
   
   apu_pulse apu_pulse0(.clk(sample_clk),
			.reset(rst),
			.apu__period_r(period),
			.apu__period_r_vld(period_valid),
			.apu__period_r_rdy(period_ready),
			.apu__duty_r(duty),
			.apu__duty_r_vld(duty_valid),
			.apu__duty_r_rdy(duty_ready),
			.apu__output_s(signal0),
			.apu__output_s_vld(signal0_valid),
			.apu__output_s_rdy(signal0_ready));

   apu_pulse apu_pulse1(.clk(sample_clk),
			.reset(rst),
			.apu__period_r(period << 1),
			.apu__period_r_vld(period_valid),
			.apu__period_r_rdy(period_ready),
			.apu__duty_r(duty),
			.apu__duty_r_vld(duty_valid),
			.apu__duty_r_rdy(duty_ready),
			.apu__output_s(signal1),
			.apu__output_s_vld(signal1_valid),
			.apu__output_s_rdy(signal1_ready));

   apu_pulse apu_pulse2(.clk(sample_clk),
			.reset(rst),
			.apu__period_r(period >> 1),
			.apu__period_r_vld(period_valid),
			.apu__period_r_rdy(period_ready),
			.apu__duty_r(duty),
			.apu__duty_r_vld(duty_valid),
			.apu__duty_r_rdy(duty_ready),
			.apu__output_s(signal2),
			.apu__output_s_vld(signal2_valid),
			.apu__output_s_rdy(signal2_ready));

   apu_pulse apu_pulse3(.clk(sample_clk),
			.reset(rst),
			.apu__period_r(period >> 2),
			.apu__period_r_vld(period_valid),
			.apu__period_r_rdy(period_ready),
			.apu__duty_r(duty),
			.apu__duty_r_vld(duty_valid),
			.apu__duty_r_rdy(duty_ready),
			.apu__output_s(signal3),
			.apu__output_s_vld(signal3_valid),
			.apu__output_s_rdy(signal3_ready));
endmodule
