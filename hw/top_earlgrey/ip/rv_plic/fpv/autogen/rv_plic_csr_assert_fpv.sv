// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// FPV CSR read and write assertions auto-generated by `reggen` containing data structure
// Do Not Edit directly

`include "prim_assert.sv"

// Block: rv_plic
module rv_plic_csr_assert_fpv import tlul_pkg::*; (
  input clk_i,
  input rst_ni,

  //tile link ports
  input tl_h2d_t h2d,
  input tl_d2h_t d2h
);

  parameter int DWidth = 32;
  // mask register to convert byte to bit
  logic [DWidth-1:0] a_mask_bit;

  assign a_mask_bit[7:0]   = h2d.a_mask[0] ? '1 : '0;
  assign a_mask_bit[15:8]  = h2d.a_mask[1] ? '1 : '0;
  assign a_mask_bit[23:16] = h2d.a_mask[2] ? '1 : '0;
  assign a_mask_bit[31:24] = h2d.a_mask[3] ? '1 : '0;

  // declare common read and write sequences
  sequence device_wr_S(logic [9:0] addr);
    h2d.a_address == addr && h2d.a_opcode inside {PutFullData, PutPartialData} &&
        h2d.a_valid && h2d.d_ready && !d2h.d_valid;
  endsequence

  // this sequence is used for reg_field which has access w1c or w0c
  // it returns true if the `index` bit of a_data matches `exp_bit`
  // this sequence is under assumption - w1c/w0c will only use one bit per field
  sequence device_wc_S(logic [9:0] addr, bit exp_bit, int index);
    h2d.a_address == addr && h2d.a_opcode inside {PutFullData, PutPartialData} && h2d.a_valid &&
        h2d.d_ready && !d2h.d_valid && ((h2d.a_data[index] & a_mask_bit[index]) == exp_bit);
  endsequence

  sequence device_rd_S(logic [9:0] addr);
    h2d.a_address == addr && h2d.a_opcode inside {Get} && h2d.a_valid && h2d.d_ready &&
        !d2h.d_valid;
  endsequence

  // declare common read and write properties
  property wr_P(bit [9:0] addr, bit [DWidth-1:0] act_data, bit regen,
                bit [DWidth-1:0] mask);
    logic [DWidth-1:0] id, exp_data;
    (device_wr_S(addr), id = h2d.a_source, exp_data = h2d.a_data & a_mask_bit & mask) ##1
        first_match(##[0:$] d2h.d_valid && d2h.d_source == id) |->
        (d2h.d_error || act_data == exp_data || !regen);
  endproperty

  // external reg will use one clk cycle to update act_data from external
  property wr_ext_P(bit [9:0] addr, bit [DWidth-1:0] act_data, bit regen,
                    bit [DWidth-1:0] mask);
    logic [DWidth-1:0] id, exp_data;
    (device_wr_S(addr), id = h2d.a_source, exp_data = h2d.a_data & a_mask_bit & mask) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || $past(act_data) == exp_data || !regen);
  endproperty

  // For W1C or W0C, first scenario: write 1(W1C) or 0(W0C) that clears the value
  property wc0_P(bit [9:0] addr, bit act_data, bit regen, int index, bit clear_bit);
    logic [DWidth-1:0] id;
    (device_wc_S(addr, clear_bit, index), id = h2d.a_source) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || act_data == 1'b0 || !regen);
  endproperty

  // For W1C or W0C, second scenario: write 0(W1C) or 1(W0C) that won't clear the value
  property wc1_P(bit [9:0] addr, bit act_data, bit regen, int index, bit clear_bit);
    logic [DWidth-1:0] id;
    (device_wc_S(addr, !clear_bit, index), id = h2d.a_source) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || $stable(act_data) || !regen);
  endproperty

  property rd_P(bit [9:0] addr, bit [DWidth-1:0] act_data);
    logic [DWidth-1:0] id, exp_data;
    (device_rd_S(addr), id = h2d.a_source, exp_data = $past(act_data)) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || d2h.d_data == exp_data);
  endproperty

  property rd_ext_P(bit [9:0] addr, bit [DWidth-1:0] act_data);
    logic [DWidth-1:0] id, exp_data;
    (device_rd_S(addr), id = h2d.a_source, exp_data = act_data) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || d2h.d_data == exp_data);
  endproperty

  // read a WO register, always return 0
  property r_wo_P(bit [9:0] addr);
    logic [DWidth-1:0] id;
    (device_rd_S(addr), id = h2d.a_source) ##1
        first_match(##[0:$] (d2h.d_valid && d2h.d_source == id)) |->
        (d2h.d_error || d2h.d_data == 0);
  endproperty

  property wr_regen_stable_P(bit regen, bit [DWidth-1:0] exp_data);
    (!regen && $stable(regen)) |-> $stable(exp_data);
  endproperty

// for all the regsters, declare assertion

  // define local fpv variable for the multi_reg
  logic [79:0] ip_d_fpv;
  for (genvar s = 0; s <= 79; s++) begin : gen_ip_d
    assign ip_d_fpv[s] = i_rv_plic.hw2reg.ip[s].d;
  end

  `ASSERT(ip0_rd_A, rd_P(10'h0, ip_d_fpv[31:0]))

  `ASSERT(ip1_rd_A, rd_P(10'h4, ip_d_fpv[63:32]))

  `ASSERT(ip2_rd_A, rd_P(10'h8, ip_d_fpv[79:64]))

  // define local fpv variable for the multi_reg
  logic [79:0] le_q_fpv;
  for (genvar s = 0; s <= 79; s++) begin : gen_le_q
    assign le_q_fpv[s] = 1 ?
        i_rv_plic.reg2hw.le[s].q : le_q_fpv[s];
  end

  `ASSERT(le0_wr_A, wr_P(10'hc, le_q_fpv[31:0], 1, 'hffffffff))
  `ASSERT(le0_rd_A, rd_P(10'hc, le_q_fpv[31:0]))

  `ASSERT(le1_wr_A, wr_P(10'h10, le_q_fpv[63:32], 1, 'hffffffff))
  `ASSERT(le1_rd_A, rd_P(10'h10, le_q_fpv[63:32]))

  `ASSERT(le2_wr_A, wr_P(10'h14, le_q_fpv[79:64], 1, 'hffff))
  `ASSERT(le2_rd_A, rd_P(10'h14, le_q_fpv[79:64]))

  `ASSERT(prio0_wr_A, wr_P(10'h18, i_rv_plic.reg2hw.prio0.q, 1, 'h3))
  `ASSERT(prio0_rd_A, rd_P(10'h18, i_rv_plic.reg2hw.prio0.q))

  `ASSERT(prio1_wr_A, wr_P(10'h1c, i_rv_plic.reg2hw.prio1.q, 1, 'h3))
  `ASSERT(prio1_rd_A, rd_P(10'h1c, i_rv_plic.reg2hw.prio1.q))

  `ASSERT(prio2_wr_A, wr_P(10'h20, i_rv_plic.reg2hw.prio2.q, 1, 'h3))
  `ASSERT(prio2_rd_A, rd_P(10'h20, i_rv_plic.reg2hw.prio2.q))

  `ASSERT(prio3_wr_A, wr_P(10'h24, i_rv_plic.reg2hw.prio3.q, 1, 'h3))
  `ASSERT(prio3_rd_A, rd_P(10'h24, i_rv_plic.reg2hw.prio3.q))

  `ASSERT(prio4_wr_A, wr_P(10'h28, i_rv_plic.reg2hw.prio4.q, 1, 'h3))
  `ASSERT(prio4_rd_A, rd_P(10'h28, i_rv_plic.reg2hw.prio4.q))

  `ASSERT(prio5_wr_A, wr_P(10'h2c, i_rv_plic.reg2hw.prio5.q, 1, 'h3))
  `ASSERT(prio5_rd_A, rd_P(10'h2c, i_rv_plic.reg2hw.prio5.q))

  `ASSERT(prio6_wr_A, wr_P(10'h30, i_rv_plic.reg2hw.prio6.q, 1, 'h3))
  `ASSERT(prio6_rd_A, rd_P(10'h30, i_rv_plic.reg2hw.prio6.q))

  `ASSERT(prio7_wr_A, wr_P(10'h34, i_rv_plic.reg2hw.prio7.q, 1, 'h3))
  `ASSERT(prio7_rd_A, rd_P(10'h34, i_rv_plic.reg2hw.prio7.q))

  `ASSERT(prio8_wr_A, wr_P(10'h38, i_rv_plic.reg2hw.prio8.q, 1, 'h3))
  `ASSERT(prio8_rd_A, rd_P(10'h38, i_rv_plic.reg2hw.prio8.q))

  `ASSERT(prio9_wr_A, wr_P(10'h3c, i_rv_plic.reg2hw.prio9.q, 1, 'h3))
  `ASSERT(prio9_rd_A, rd_P(10'h3c, i_rv_plic.reg2hw.prio9.q))

  `ASSERT(prio10_wr_A, wr_P(10'h40, i_rv_plic.reg2hw.prio10.q, 1, 'h3))
  `ASSERT(prio10_rd_A, rd_P(10'h40, i_rv_plic.reg2hw.prio10.q))

  `ASSERT(prio11_wr_A, wr_P(10'h44, i_rv_plic.reg2hw.prio11.q, 1, 'h3))
  `ASSERT(prio11_rd_A, rd_P(10'h44, i_rv_plic.reg2hw.prio11.q))

  `ASSERT(prio12_wr_A, wr_P(10'h48, i_rv_plic.reg2hw.prio12.q, 1, 'h3))
  `ASSERT(prio12_rd_A, rd_P(10'h48, i_rv_plic.reg2hw.prio12.q))

  `ASSERT(prio13_wr_A, wr_P(10'h4c, i_rv_plic.reg2hw.prio13.q, 1, 'h3))
  `ASSERT(prio13_rd_A, rd_P(10'h4c, i_rv_plic.reg2hw.prio13.q))

  `ASSERT(prio14_wr_A, wr_P(10'h50, i_rv_plic.reg2hw.prio14.q, 1, 'h3))
  `ASSERT(prio14_rd_A, rd_P(10'h50, i_rv_plic.reg2hw.prio14.q))

  `ASSERT(prio15_wr_A, wr_P(10'h54, i_rv_plic.reg2hw.prio15.q, 1, 'h3))
  `ASSERT(prio15_rd_A, rd_P(10'h54, i_rv_plic.reg2hw.prio15.q))

  `ASSERT(prio16_wr_A, wr_P(10'h58, i_rv_plic.reg2hw.prio16.q, 1, 'h3))
  `ASSERT(prio16_rd_A, rd_P(10'h58, i_rv_plic.reg2hw.prio16.q))

  `ASSERT(prio17_wr_A, wr_P(10'h5c, i_rv_plic.reg2hw.prio17.q, 1, 'h3))
  `ASSERT(prio17_rd_A, rd_P(10'h5c, i_rv_plic.reg2hw.prio17.q))

  `ASSERT(prio18_wr_A, wr_P(10'h60, i_rv_plic.reg2hw.prio18.q, 1, 'h3))
  `ASSERT(prio18_rd_A, rd_P(10'h60, i_rv_plic.reg2hw.prio18.q))

  `ASSERT(prio19_wr_A, wr_P(10'h64, i_rv_plic.reg2hw.prio19.q, 1, 'h3))
  `ASSERT(prio19_rd_A, rd_P(10'h64, i_rv_plic.reg2hw.prio19.q))

  `ASSERT(prio20_wr_A, wr_P(10'h68, i_rv_plic.reg2hw.prio20.q, 1, 'h3))
  `ASSERT(prio20_rd_A, rd_P(10'h68, i_rv_plic.reg2hw.prio20.q))

  `ASSERT(prio21_wr_A, wr_P(10'h6c, i_rv_plic.reg2hw.prio21.q, 1, 'h3))
  `ASSERT(prio21_rd_A, rd_P(10'h6c, i_rv_plic.reg2hw.prio21.q))

  `ASSERT(prio22_wr_A, wr_P(10'h70, i_rv_plic.reg2hw.prio22.q, 1, 'h3))
  `ASSERT(prio22_rd_A, rd_P(10'h70, i_rv_plic.reg2hw.prio22.q))

  `ASSERT(prio23_wr_A, wr_P(10'h74, i_rv_plic.reg2hw.prio23.q, 1, 'h3))
  `ASSERT(prio23_rd_A, rd_P(10'h74, i_rv_plic.reg2hw.prio23.q))

  `ASSERT(prio24_wr_A, wr_P(10'h78, i_rv_plic.reg2hw.prio24.q, 1, 'h3))
  `ASSERT(prio24_rd_A, rd_P(10'h78, i_rv_plic.reg2hw.prio24.q))

  `ASSERT(prio25_wr_A, wr_P(10'h7c, i_rv_plic.reg2hw.prio25.q, 1, 'h3))
  `ASSERT(prio25_rd_A, rd_P(10'h7c, i_rv_plic.reg2hw.prio25.q))

  `ASSERT(prio26_wr_A, wr_P(10'h80, i_rv_plic.reg2hw.prio26.q, 1, 'h3))
  `ASSERT(prio26_rd_A, rd_P(10'h80, i_rv_plic.reg2hw.prio26.q))

  `ASSERT(prio27_wr_A, wr_P(10'h84, i_rv_plic.reg2hw.prio27.q, 1, 'h3))
  `ASSERT(prio27_rd_A, rd_P(10'h84, i_rv_plic.reg2hw.prio27.q))

  `ASSERT(prio28_wr_A, wr_P(10'h88, i_rv_plic.reg2hw.prio28.q, 1, 'h3))
  `ASSERT(prio28_rd_A, rd_P(10'h88, i_rv_plic.reg2hw.prio28.q))

  `ASSERT(prio29_wr_A, wr_P(10'h8c, i_rv_plic.reg2hw.prio29.q, 1, 'h3))
  `ASSERT(prio29_rd_A, rd_P(10'h8c, i_rv_plic.reg2hw.prio29.q))

  `ASSERT(prio30_wr_A, wr_P(10'h90, i_rv_plic.reg2hw.prio30.q, 1, 'h3))
  `ASSERT(prio30_rd_A, rd_P(10'h90, i_rv_plic.reg2hw.prio30.q))

  `ASSERT(prio31_wr_A, wr_P(10'h94, i_rv_plic.reg2hw.prio31.q, 1, 'h3))
  `ASSERT(prio31_rd_A, rd_P(10'h94, i_rv_plic.reg2hw.prio31.q))

  `ASSERT(prio32_wr_A, wr_P(10'h98, i_rv_plic.reg2hw.prio32.q, 1, 'h3))
  `ASSERT(prio32_rd_A, rd_P(10'h98, i_rv_plic.reg2hw.prio32.q))

  `ASSERT(prio33_wr_A, wr_P(10'h9c, i_rv_plic.reg2hw.prio33.q, 1, 'h3))
  `ASSERT(prio33_rd_A, rd_P(10'h9c, i_rv_plic.reg2hw.prio33.q))

  `ASSERT(prio34_wr_A, wr_P(10'ha0, i_rv_plic.reg2hw.prio34.q, 1, 'h3))
  `ASSERT(prio34_rd_A, rd_P(10'ha0, i_rv_plic.reg2hw.prio34.q))

  `ASSERT(prio35_wr_A, wr_P(10'ha4, i_rv_plic.reg2hw.prio35.q, 1, 'h3))
  `ASSERT(prio35_rd_A, rd_P(10'ha4, i_rv_plic.reg2hw.prio35.q))

  `ASSERT(prio36_wr_A, wr_P(10'ha8, i_rv_plic.reg2hw.prio36.q, 1, 'h3))
  `ASSERT(prio36_rd_A, rd_P(10'ha8, i_rv_plic.reg2hw.prio36.q))

  `ASSERT(prio37_wr_A, wr_P(10'hac, i_rv_plic.reg2hw.prio37.q, 1, 'h3))
  `ASSERT(prio37_rd_A, rd_P(10'hac, i_rv_plic.reg2hw.prio37.q))

  `ASSERT(prio38_wr_A, wr_P(10'hb0, i_rv_plic.reg2hw.prio38.q, 1, 'h3))
  `ASSERT(prio38_rd_A, rd_P(10'hb0, i_rv_plic.reg2hw.prio38.q))

  `ASSERT(prio39_wr_A, wr_P(10'hb4, i_rv_plic.reg2hw.prio39.q, 1, 'h3))
  `ASSERT(prio39_rd_A, rd_P(10'hb4, i_rv_plic.reg2hw.prio39.q))

  `ASSERT(prio40_wr_A, wr_P(10'hb8, i_rv_plic.reg2hw.prio40.q, 1, 'h3))
  `ASSERT(prio40_rd_A, rd_P(10'hb8, i_rv_plic.reg2hw.prio40.q))

  `ASSERT(prio41_wr_A, wr_P(10'hbc, i_rv_plic.reg2hw.prio41.q, 1, 'h3))
  `ASSERT(prio41_rd_A, rd_P(10'hbc, i_rv_plic.reg2hw.prio41.q))

  `ASSERT(prio42_wr_A, wr_P(10'hc0, i_rv_plic.reg2hw.prio42.q, 1, 'h3))
  `ASSERT(prio42_rd_A, rd_P(10'hc0, i_rv_plic.reg2hw.prio42.q))

  `ASSERT(prio43_wr_A, wr_P(10'hc4, i_rv_plic.reg2hw.prio43.q, 1, 'h3))
  `ASSERT(prio43_rd_A, rd_P(10'hc4, i_rv_plic.reg2hw.prio43.q))

  `ASSERT(prio44_wr_A, wr_P(10'hc8, i_rv_plic.reg2hw.prio44.q, 1, 'h3))
  `ASSERT(prio44_rd_A, rd_P(10'hc8, i_rv_plic.reg2hw.prio44.q))

  `ASSERT(prio45_wr_A, wr_P(10'hcc, i_rv_plic.reg2hw.prio45.q, 1, 'h3))
  `ASSERT(prio45_rd_A, rd_P(10'hcc, i_rv_plic.reg2hw.prio45.q))

  `ASSERT(prio46_wr_A, wr_P(10'hd0, i_rv_plic.reg2hw.prio46.q, 1, 'h3))
  `ASSERT(prio46_rd_A, rd_P(10'hd0, i_rv_plic.reg2hw.prio46.q))

  `ASSERT(prio47_wr_A, wr_P(10'hd4, i_rv_plic.reg2hw.prio47.q, 1, 'h3))
  `ASSERT(prio47_rd_A, rd_P(10'hd4, i_rv_plic.reg2hw.prio47.q))

  `ASSERT(prio48_wr_A, wr_P(10'hd8, i_rv_plic.reg2hw.prio48.q, 1, 'h3))
  `ASSERT(prio48_rd_A, rd_P(10'hd8, i_rv_plic.reg2hw.prio48.q))

  `ASSERT(prio49_wr_A, wr_P(10'hdc, i_rv_plic.reg2hw.prio49.q, 1, 'h3))
  `ASSERT(prio49_rd_A, rd_P(10'hdc, i_rv_plic.reg2hw.prio49.q))

  `ASSERT(prio50_wr_A, wr_P(10'he0, i_rv_plic.reg2hw.prio50.q, 1, 'h3))
  `ASSERT(prio50_rd_A, rd_P(10'he0, i_rv_plic.reg2hw.prio50.q))

  `ASSERT(prio51_wr_A, wr_P(10'he4, i_rv_plic.reg2hw.prio51.q, 1, 'h3))
  `ASSERT(prio51_rd_A, rd_P(10'he4, i_rv_plic.reg2hw.prio51.q))

  `ASSERT(prio52_wr_A, wr_P(10'he8, i_rv_plic.reg2hw.prio52.q, 1, 'h3))
  `ASSERT(prio52_rd_A, rd_P(10'he8, i_rv_plic.reg2hw.prio52.q))

  `ASSERT(prio53_wr_A, wr_P(10'hec, i_rv_plic.reg2hw.prio53.q, 1, 'h3))
  `ASSERT(prio53_rd_A, rd_P(10'hec, i_rv_plic.reg2hw.prio53.q))

  `ASSERT(prio54_wr_A, wr_P(10'hf0, i_rv_plic.reg2hw.prio54.q, 1, 'h3))
  `ASSERT(prio54_rd_A, rd_P(10'hf0, i_rv_plic.reg2hw.prio54.q))

  `ASSERT(prio55_wr_A, wr_P(10'hf4, i_rv_plic.reg2hw.prio55.q, 1, 'h3))
  `ASSERT(prio55_rd_A, rd_P(10'hf4, i_rv_plic.reg2hw.prio55.q))

  `ASSERT(prio56_wr_A, wr_P(10'hf8, i_rv_plic.reg2hw.prio56.q, 1, 'h3))
  `ASSERT(prio56_rd_A, rd_P(10'hf8, i_rv_plic.reg2hw.prio56.q))

  `ASSERT(prio57_wr_A, wr_P(10'hfc, i_rv_plic.reg2hw.prio57.q, 1, 'h3))
  `ASSERT(prio57_rd_A, rd_P(10'hfc, i_rv_plic.reg2hw.prio57.q))

  `ASSERT(prio58_wr_A, wr_P(10'h100, i_rv_plic.reg2hw.prio58.q, 1, 'h3))
  `ASSERT(prio58_rd_A, rd_P(10'h100, i_rv_plic.reg2hw.prio58.q))

  `ASSERT(prio59_wr_A, wr_P(10'h104, i_rv_plic.reg2hw.prio59.q, 1, 'h3))
  `ASSERT(prio59_rd_A, rd_P(10'h104, i_rv_plic.reg2hw.prio59.q))

  `ASSERT(prio60_wr_A, wr_P(10'h108, i_rv_plic.reg2hw.prio60.q, 1, 'h3))
  `ASSERT(prio60_rd_A, rd_P(10'h108, i_rv_plic.reg2hw.prio60.q))

  `ASSERT(prio61_wr_A, wr_P(10'h10c, i_rv_plic.reg2hw.prio61.q, 1, 'h3))
  `ASSERT(prio61_rd_A, rd_P(10'h10c, i_rv_plic.reg2hw.prio61.q))

  `ASSERT(prio62_wr_A, wr_P(10'h110, i_rv_plic.reg2hw.prio62.q, 1, 'h3))
  `ASSERT(prio62_rd_A, rd_P(10'h110, i_rv_plic.reg2hw.prio62.q))

  `ASSERT(prio63_wr_A, wr_P(10'h114, i_rv_plic.reg2hw.prio63.q, 1, 'h3))
  `ASSERT(prio63_rd_A, rd_P(10'h114, i_rv_plic.reg2hw.prio63.q))

  `ASSERT(prio64_wr_A, wr_P(10'h118, i_rv_plic.reg2hw.prio64.q, 1, 'h3))
  `ASSERT(prio64_rd_A, rd_P(10'h118, i_rv_plic.reg2hw.prio64.q))

  `ASSERT(prio65_wr_A, wr_P(10'h11c, i_rv_plic.reg2hw.prio65.q, 1, 'h3))
  `ASSERT(prio65_rd_A, rd_P(10'h11c, i_rv_plic.reg2hw.prio65.q))

  `ASSERT(prio66_wr_A, wr_P(10'h120, i_rv_plic.reg2hw.prio66.q, 1, 'h3))
  `ASSERT(prio66_rd_A, rd_P(10'h120, i_rv_plic.reg2hw.prio66.q))

  `ASSERT(prio67_wr_A, wr_P(10'h124, i_rv_plic.reg2hw.prio67.q, 1, 'h3))
  `ASSERT(prio67_rd_A, rd_P(10'h124, i_rv_plic.reg2hw.prio67.q))

  `ASSERT(prio68_wr_A, wr_P(10'h128, i_rv_plic.reg2hw.prio68.q, 1, 'h3))
  `ASSERT(prio68_rd_A, rd_P(10'h128, i_rv_plic.reg2hw.prio68.q))

  `ASSERT(prio69_wr_A, wr_P(10'h12c, i_rv_plic.reg2hw.prio69.q, 1, 'h3))
  `ASSERT(prio69_rd_A, rd_P(10'h12c, i_rv_plic.reg2hw.prio69.q))

  `ASSERT(prio70_wr_A, wr_P(10'h130, i_rv_plic.reg2hw.prio70.q, 1, 'h3))
  `ASSERT(prio70_rd_A, rd_P(10'h130, i_rv_plic.reg2hw.prio70.q))

  `ASSERT(prio71_wr_A, wr_P(10'h134, i_rv_plic.reg2hw.prio71.q, 1, 'h3))
  `ASSERT(prio71_rd_A, rd_P(10'h134, i_rv_plic.reg2hw.prio71.q))

  `ASSERT(prio72_wr_A, wr_P(10'h138, i_rv_plic.reg2hw.prio72.q, 1, 'h3))
  `ASSERT(prio72_rd_A, rd_P(10'h138, i_rv_plic.reg2hw.prio72.q))

  `ASSERT(prio73_wr_A, wr_P(10'h13c, i_rv_plic.reg2hw.prio73.q, 1, 'h3))
  `ASSERT(prio73_rd_A, rd_P(10'h13c, i_rv_plic.reg2hw.prio73.q))

  `ASSERT(prio74_wr_A, wr_P(10'h140, i_rv_plic.reg2hw.prio74.q, 1, 'h3))
  `ASSERT(prio74_rd_A, rd_P(10'h140, i_rv_plic.reg2hw.prio74.q))

  `ASSERT(prio75_wr_A, wr_P(10'h144, i_rv_plic.reg2hw.prio75.q, 1, 'h3))
  `ASSERT(prio75_rd_A, rd_P(10'h144, i_rv_plic.reg2hw.prio75.q))

  `ASSERT(prio76_wr_A, wr_P(10'h148, i_rv_plic.reg2hw.prio76.q, 1, 'h3))
  `ASSERT(prio76_rd_A, rd_P(10'h148, i_rv_plic.reg2hw.prio76.q))

  `ASSERT(prio77_wr_A, wr_P(10'h14c, i_rv_plic.reg2hw.prio77.q, 1, 'h3))
  `ASSERT(prio77_rd_A, rd_P(10'h14c, i_rv_plic.reg2hw.prio77.q))

  `ASSERT(prio78_wr_A, wr_P(10'h150, i_rv_plic.reg2hw.prio78.q, 1, 'h3))
  `ASSERT(prio78_rd_A, rd_P(10'h150, i_rv_plic.reg2hw.prio78.q))

  `ASSERT(prio79_wr_A, wr_P(10'h154, i_rv_plic.reg2hw.prio79.q, 1, 'h3))
  `ASSERT(prio79_rd_A, rd_P(10'h154, i_rv_plic.reg2hw.prio79.q))

  // define local fpv variable for the multi_reg
  logic [79:0] ie0_q_fpv;
  for (genvar s = 0; s <= 79; s++) begin : gen_ie0_q
    assign ie0_q_fpv[s] = 1 ?
        i_rv_plic.reg2hw.ie0[s].q : ie0_q_fpv[s];
  end

  `ASSERT(ie00_wr_A, wr_P(10'h200, ie0_q_fpv[31:0], 1, 'hffffffff))
  `ASSERT(ie00_rd_A, rd_P(10'h200, ie0_q_fpv[31:0]))

  `ASSERT(ie01_wr_A, wr_P(10'h204, ie0_q_fpv[63:32], 1, 'hffffffff))
  `ASSERT(ie01_rd_A, rd_P(10'h204, ie0_q_fpv[63:32]))

  `ASSERT(ie02_wr_A, wr_P(10'h208, ie0_q_fpv[79:64], 1, 'hffff))
  `ASSERT(ie02_rd_A, rd_P(10'h208, ie0_q_fpv[79:64]))

  `ASSERT(threshold0_wr_A, wr_P(10'h20c, i_rv_plic.reg2hw.threshold0.q, 1, 'h3))
  `ASSERT(threshold0_rd_A, rd_P(10'h20c, i_rv_plic.reg2hw.threshold0.q))

  `ASSERT(cc0_wr_A, wr_ext_P(10'h210, i_rv_plic.reg2hw.cc0.q, 1, 'h7f))
  `ASSERT(cc0_rd_A, rd_ext_P(10'h210, i_rv_plic.hw2reg.cc0.d))

  `ASSERT(msip0_wr_A, wr_P(10'h214, i_rv_plic.reg2hw.msip0.q, 1, 'h1))
  `ASSERT(msip0_rd_A, rd_P(10'h214, i_rv_plic.reg2hw.msip0.q))

endmodule
