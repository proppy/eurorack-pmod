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

module apu_pulse(
  input wire clk,
  input wire reset,
  input wire [1:0] apu__duty_r,
  input wire apu__duty_r_vld,
  input wire [10:0] apu__period_r,
  input wire apu__period_r_vld,
  input wire apu__output_s_rdy,
  output wire apu__output_s,
  output wire apu__output_s_vld,
  output wire apu__duty_r_rdy,
  output wire apu__period_r_rdy
);
  function automatic dynamic_bit_slice_w1_8b_3b (input reg [7:0] operand, input reg [2:0] start);
    reg [8:0] zexted_operand;
    begin
      zexted_operand = {1'h0, operand};
      dynamic_bit_slice_w1_8b_3b = start >= 4'h8 ? 1'h0 : zexted_operand[start +: 1];
    end
  endfunction
  wire [7:0] DUTY_WAVES[0:3];
  assign DUTY_WAVES[0] = 8'h80;
  assign DUTY_WAVES[1] = 8'hc0;
  assign DUTY_WAVES[2] = 8'hf0;
  assign DUTY_WAVES[3] = 8'h3f;
  reg [1:0] ____state_2;
  reg [2:0] ____state_3;
  reg [10:0] ____state_0;
  reg [10:0] ____state_1;
  reg [1:0] __apu__duty_r_reg;
  reg __apu__duty_r_valid_reg;
  reg [10:0] __apu__period_r_reg;
  reg __apu__period_r_valid_reg;
  reg __apu__output_s_reg;
  reg __apu__output_s_valid_reg;
  wire p0_all_active_inputs_valid;
  wire literal_130;
  wire apu__output_s_valid_inv;
  wire __apu__output_s_vld_buf;
  wire apu__output_s_valid_load_en;
  wire apu__output_s_load_en;
  wire p0_stage_done;
  wire [1:0] apu__duty_r_select;
  wire [10:0] apu__period_r_select;
  wire pipeline_enable;
  wire apu__duty_r_valid_inv;
  wire apu__period_r_valid_inv;
  wire [1:0] duty_;
  wire eq_115;
  wire [10:0] add_116;
  wire [10:0] period_;
  wire [2:0] add_118;
  wire apu__duty_r_valid_load_en;
  wire apu__period_r_valid_load_en;
  wire [10:0] timer_;
  wire [2:0] pos_;
  wire apu__duty_r_load_en;
  wire apu__period_r_load_en;
  wire sig;
  assign p0_all_active_inputs_valid = 1'h1 & 1'h1;
  assign literal_130 = 1'h1;
  assign apu__output_s_valid_inv = ~__apu__output_s_valid_reg;
  assign __apu__output_s_vld_buf = p0_all_active_inputs_valid & literal_130 & 1'h1;
  assign apu__output_s_valid_load_en = apu__output_s_rdy | apu__output_s_valid_inv;
  assign apu__output_s_load_en = __apu__output_s_vld_buf & apu__output_s_valid_load_en;
  assign p0_stage_done = literal_130 & p0_all_active_inputs_valid & apu__output_s_load_en;
  assign apu__duty_r_select = __apu__duty_r_valid_reg ? __apu__duty_r_reg : 2'h0;
  assign apu__period_r_select = __apu__period_r_valid_reg ? __apu__period_r_reg : 11'h000;
  assign pipeline_enable = p0_stage_done & p0_stage_done;
  assign apu__duty_r_valid_inv = ~__apu__duty_r_valid_reg;
  assign apu__period_r_valid_inv = ~__apu__period_r_valid_reg;
  assign duty_ = __apu__duty_r_valid_reg ? apu__duty_r_select : ____state_2;
  assign eq_115 = ____state_0 == 11'h000;
  assign add_116 = ____state_0 + 11'h7ff;
  assign period_ = __apu__period_r_valid_reg ? apu__period_r_select : ____state_1;
  assign add_118 = ____state_3 + 3'h7;
  assign apu__duty_r_valid_load_en = pipeline_enable | apu__duty_r_valid_inv;
  assign apu__period_r_valid_load_en = pipeline_enable | apu__period_r_valid_inv;
  assign timer_ = eq_115 ? period_ : add_116;
  assign pos_ = eq_115 ? add_118 : ____state_3;
  assign apu__duty_r_load_en = apu__duty_r_vld & apu__duty_r_valid_load_en;
  assign apu__period_r_load_en = apu__period_r_vld & apu__period_r_valid_load_en;
  assign sig = dynamic_bit_slice_w1_8b_3b(DUTY_WAVES[duty_], ____state_3);
  always @ (posedge clk) begin
    if (reset) begin
      ____state_2 <= 2'h0;
      ____state_3 <= 3'h0;
      ____state_0 <= 11'h000;
      ____state_1 <= 11'h000;
      __apu__duty_r_reg <= 2'h0;
      __apu__duty_r_valid_reg <= 1'h0;
      __apu__period_r_reg <= 11'h000;
      __apu__period_r_valid_reg <= 1'h0;
      __apu__output_s_reg <= 1'h0;
      __apu__output_s_valid_reg <= 1'h0;
    end else begin
      ____state_2 <= pipeline_enable ? duty_ : ____state_2;
      ____state_3 <= pipeline_enable ? pos_ : ____state_3;
      ____state_0 <= pipeline_enable ? timer_ : ____state_0;
      ____state_1 <= pipeline_enable ? period_ : ____state_1;
      __apu__duty_r_reg <= apu__duty_r_load_en ? apu__duty_r : __apu__duty_r_reg;
      __apu__duty_r_valid_reg <= apu__duty_r_valid_load_en ? apu__duty_r_vld : __apu__duty_r_valid_reg;
      __apu__period_r_reg <= apu__period_r_load_en ? apu__period_r : __apu__period_r_reg;
      __apu__period_r_valid_reg <= apu__period_r_valid_load_en ? apu__period_r_vld : __apu__period_r_valid_reg;
      __apu__output_s_reg <= apu__output_s_load_en ? sig : __apu__output_s_reg;
      __apu__output_s_valid_reg <= apu__output_s_valid_load_en ? __apu__output_s_vld_buf : __apu__output_s_valid_reg;
    end
  end
  assign apu__output_s = __apu__output_s_reg;
  assign apu__output_s_vld = __apu__output_s_valid_reg;
  assign apu__duty_r_rdy = apu__duty_r_load_en;
  assign apu__period_r_rdy = apu__period_r_load_en;
endmodule
