// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

import i2c_agent_pkg::*;
import uvm_pkg::*;

interface i2c_if(
  input clk_i,
  input rst_ni,
  inout wire scl_io,
  inout wire sda_io
);

  // standard i2c interface pins
  logic scl_i;
  logic scl_o;
  logic sda_i;
  logic sda_o;

  assign scl_i = scl_io;
  assign sda_i = sda_io;
  assign scl_io = scl_o ? 1'bz : 1'b0;
  assign sda_io = sda_o ? 1'bz : 1'b0;

  string msg_id = "i2c_if";

  int scl_spinwait_timeout_ns = 10_000_000; // 10ms

  // Trace drivers' status
  drv_phase_e drv_phase;

  clocking cb @(posedge clk_i);
    input scl_i;
    input sda_i;
    output scl_o;
    output sda_o;
  endclocking
  //---------------------------------
  // common tasks
  //---------------------------------

  // This is literally same as '@(posedge scl_i)'
  // In target mode, @(posedge scl_i) gives some glitch,
  // so I have to use clocking block sampled signals.
  task automatic p_edge_scl();
    wait(cb.scl_i == 0);
    wait(cb.scl_i == 1);
  endtask

  task automatic sample_target_data(timing_cfg_t tc, output bit data);
    bit sample[$];
    wait(cb.scl_i == 0);
    while (cb.scl_i == 0) begin
      @(posedge clk_i);
      sample.push_front(cb.sda_i);
      // Pop queue to make sure size doesnt exceed tSetupBit
      if (sample.size() > tc.tSetupBit) sample.pop_back();
    end
    data = sample.pop_back();
  endtask // sample_target_data

  task automatic wait_for_dly(int dly);
    repeat (dly) @(posedge clk_i);
  endtask : wait_for_dly

  task automatic wait_for_host_start(ref timing_cfg_t tc);
    forever begin
      @(negedge sda_i);
      if (scl_i) begin
      wait_for_dly(tc.tHoldStart);
      end else continue;
      @(negedge scl_i);
      if (!sda_i) begin
      wait_for_dly(tc.tClockStart);
      break;
      end else continue;
    end
  endtask: wait_for_host_start

  task automatic wait_for_host_rstart(ref timing_cfg_t tc,
                                      output bit rstart);
    rstart = 1'b0;
    forever begin
      @(posedge scl_i && sda_i);
      wait_for_dly(tc.tSetupStart);
      @(negedge sda_i);
      if (scl_i) begin
        wait_for_dly(tc.tHoldStart);
        @(negedge scl_i) begin
          rstart = 1'b1;
          break;
        end
      end
    end
  endtask: wait_for_host_rstart

  task automatic wait_for_host_stop(ref timing_cfg_t tc,
                                    output bit stop);
    stop = 1'b0;
    forever begin
      @(posedge scl_i);
      @(posedge sda_i);
      if (scl_i) begin
        stop = 1'b1;
        break;
      end
    end
    wait_for_dly(tc.tHoldStop);
  endtask: wait_for_host_stop

  task automatic wait_for_host_stop_or_rstart(timing_cfg_t tc,
                                              output bit   rstart,
                                              output bit   stop);
    fork
      begin : iso_fork
        fork
          wait_for_host_stop(tc, stop);
          wait_for_host_rstart(tc, rstart);
        join_any
        disable fork;
      end : iso_fork
    join
  endtask: wait_for_host_stop_or_rstart

  task automatic wait_for_host_ack(ref timing_cfg_t tc);
    `uvm_info(msg_id, "Wait for host ack::Begin", UVM_HIGH)
    wait_for_dly(tc.tClockLow + tc.tSetupBit);
    forever begin
      @(posedge scl_i);
      if (!sda_i) begin
        wait_for_dly(tc.tClockPulse);
        break;
      end
    end
    wait_for_dly(tc.tHoldBit);
    `uvm_info(msg_id, "Wait for host ack::Ack received", UVM_HIGH)
  endtask: wait_for_host_ack

  task automatic wait_for_host_nack(ref timing_cfg_t tc);
    `uvm_info(msg_id, "Wait for host nack::Begin", UVM_HIGH)
    wait_for_dly(tc.tClockLow + tc.tSetupBit);
    forever begin
      @(posedge scl_i);
      if (sda_i) begin
        wait_for_dly(tc.tClockPulse);
        break;
      end
    end
    wait_for_dly(tc.tHoldBit);
    `uvm_info(msg_id, "Wait for host nack::nack received", UVM_HIGH)
  endtask: wait_for_host_nack

  task automatic wait_for_host_ack_or_nack(timing_cfg_t tc,
                                           output bit   ack,
                                           output bit   nack);
    ack = 1'b0;
    nack = 1'b0;
    fork
      begin : iso_fork
        fork
          begin
            wait_for_host_ack(tc);
            ack = 1'b1;
          end
          begin
            wait_for_host_nack(tc);
            nack = 1'b1;
          end
        join_any
        disable fork;
      end : iso_fork
    join
  endtask: wait_for_host_ack_or_nack

  task automatic wait_for_device_ack(ref timing_cfg_t tc);
    @(negedge sda_o && scl_o);
    wait_for_dly(tc.tSetupBit);
    forever begin
      @(posedge scl_i);
      if (!sda_o) begin
        wait_for_dly(tc.tClockPulse);
        break;
      end
    end
    wait_for_dly(tc.tHoldBit);
  endtask: wait_for_device_ack

  // the `sda_unstable` interrupt is asserted if, when receiving data or ,
  // ack pulse (device_send_ack) the value of the target sda signal does not
  // remain constant over the duration of the scl pulse.
  task automatic device_send_bit(ref timing_cfg_t tc,
                                 input bit bit_i);
    sda_o = 1'b1;
    wait_for_dly(tc.tClockLow);
    `uvm_info(msg_id, "device_send_bit::Drive bit", UVM_HIGH)
    sda_o = bit_i;
    wait_for_dly(tc.tSetupBit);
    @(posedge scl_i);
    `uvm_info(msg_id, "device_send_bit::Value sampled ", UVM_HIGH)
    // flip sda_target2host during the clock pulse of scl_host2target causes sda_unstable irq
    sda_o = ~sda_o;
    wait_for_dly(tc.tSdaUnstable);
    sda_o = ~sda_o;
    wait_for_dly(tc.tClockPulse + tc.tHoldBit - tc.tSdaUnstable);

    // not release/change sda_o until host clock stretch passes
    if (tc.enbTimeOut) wait(!scl_i);
    sda_o = 1'b1;
  endtask: device_send_bit

  task automatic device_send_ack(ref timing_cfg_t tc);
    device_send_bit(tc, 1'b0); // special case for ack bit
  endtask: device_send_ack

  // when the I2C module is in transmit mode, `scl_interference` interrupt
  // will be asserted if the IP identifies that some other device (host or target) on the bus
  // is forcing scl low and interfering with the transmission.
  task automatic device_stretch_host_clk(ref timing_cfg_t tc);
    int stretch_cycle = tc.tClockLow + tc.tSetupBit + tc.tStretchHostClock;
    int data_cycle = tc.tClockLow + tc.tSetupBit + tc.tClockPulse + tc.tHoldBit;

    if (tc.enbTimeOut && tc.tTimeOut > 0 &&
        stretch_cycle < data_cycle) begin // target can stretch only during data cycle
      wait_for_dly(tc.tClockLow + tc.tSetupBit + tc.tSclInterference - 1);
      scl_o = 1'b0;
      wait_for_dly(tc.tStretchHostClock - tc.tSclInterference + 1);
      scl_o = 1'b1;
    end
  endtask : device_stretch_host_clk

  // when the I2C module is in transmit mode, `sda_interference` interrupt
  // will be asserted if the IP identifies that some other device (host or target) on the bus
  // is forcing sda low and interfering with the transmission.
  task automatic get_bit_data(string src = "host",
                              ref timing_cfg_t tc,
                              output bit bit_o);
    @(posedge scl_i);
    if (src == "host") begin // host transmits data (addr/wr_data)
      bit_o = sda_i;
      `uvm_info(msg_id, $sformatf("get bit data %d", bit_o), UVM_HIGH)
      // force sda_target2host low during the clock pulse of scl_host2target
      sda_o = 1'b0;
      wait_for_dly(tc.tSdaInterference);
      sda_o = 1'b1;
      // The code below was originally written as
      // wait_for_dly(tc.tClockPulse + tc.tHoldBit - tc.tSdaInterference);
      // But this functionally should be identical to just waiting for the
      // the nedgedge and then proceeding.  Keep a reference to the original
      // just in case there is another test sequence that relied on this.
      @(negedge scl_i);
      wait_for_dly(tc.tHoldBit - tc.tSdaInterference);
    end else begin // target transmits data (rd_data)
      bit_o = sda_i;
      wait_for_dly(tc.tClockPulse + tc.tHoldBit);
    end
  endtask: get_bit_data

  task automatic host_start(ref timing_cfg_t tc);
    `DV_WAIT(scl_i === 1'b1,, scl_spinwait_timeout_ns, "host_start")
    sda_o = 1'b0;
    wait_for_dly(tc.tHoldStart);
    scl_o = 1'b0;
    wait_for_dly(tc.tClockStart);
  endtask: host_start

  task automatic host_rstart(ref timing_cfg_t tc);
    @(posedge scl_i && sda_i);
    wait_for_dly(tc.tSetupStart);
    sda_o = 1'b0;
    wait_for_dly(tc.tHoldStart);
    wait_for_dly(tc.tHoldBit);
  endtask: host_rstart

  task automatic host_data(ref timing_cfg_t tc, input bit bit_i);
    wait(scl_i === 1'b0);
    wait_for_dly(tc.tClockLow);
    sda_o = bit_i;
    wait_for_dly(tc.tSetupBit);
    wait(scl_i === 1'b1);
    wait_for_dly(tc.tClockPulse);
    wait(scl_i === 1'b0);
    wait_for_dly(tc.tHoldBit);
    sda_o = 1;
  endtask: host_data

  task automatic host_stop(ref timing_cfg_t tc);
    // Stop is an SDA low to high transition whilst SCL is high. If both are high we cannot indicate
    // a stop condition for this SCL pulse as that would require a high to low SDA transition which
    // is the start signal.
    if (scl_i === 1'b1 && sda_o === 1'b1) begin
      `uvm_fatal(msg_id, "Cannot begin host_stop when both scl and sda are high")
    end

    // Ensure SDA Is low before SCL positive edge so a low to high transition can be generated. If
    // SCL is high already SDA will be low already due to check above.
    sda_o = 1'b0;
    wait(scl_i === 1'b1);
    wait_for_dly(tc.tClockStop);
    scl_o = 1'b1;
    wait_for_dly(tc.tSetupStop);
    sda_o = 1'b1;
    wait_for_dly(tc.tHoldStop);
  endtask: host_stop

  task automatic host_nack(ref timing_cfg_t tc);
    sda_o = 1'b0;
    wait_for_dly(tc.tClockLow);
    sda_o = 1'b1;
    wait_for_dly(tc.tSetupBit);
    scl_o = 1'b1;
    wait_for_dly(tc.tClockPulse);
    scl_o = 1'b0;
    wait_for_dly(tc.tHoldBit);
  endtask: host_nack

  task automatic wait_scl(int iter = 1, timing_cfg_t tc);
    repeat(iter) begin
      @(posedge scl_i);
      wait_for_dly(tc.tClockPulse + tc.tHoldBit);
    end
  endtask // wait_scl
endinterface : i2c_if
