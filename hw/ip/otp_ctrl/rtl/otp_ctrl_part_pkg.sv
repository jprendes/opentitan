// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Package partition metadata.
//
// DO NOT EDIT THIS FILE DIRECTLY.
// It has been generated with
// $ ./util/design/gen-otp-mmap.py --seed 10556718629619452145
//

package otp_ctrl_part_pkg;

  import prim_util_pkg::vbits;
  import otp_ctrl_reg_pkg::*;
  import otp_ctrl_pkg::*;

  ////////////////////////////////////
  // Scrambling Constants and Types //
  ////////////////////////////////////

  parameter int NumScrmblKeys = 3;
  parameter int NumDigestSets = 4;

  parameter int ScrmblKeySelWidth = vbits(NumScrmblKeys);
  parameter int DigestSetSelWidth = vbits(NumDigestSets);
  parameter int ConstSelWidth = (ScrmblKeySelWidth > DigestSetSelWidth) ?
                                ScrmblKeySelWidth :
                                DigestSetSelWidth;

  typedef enum logic [ConstSelWidth-1:0] {
    StandardMode,
    ChainedMode
  } digest_mode_e;

  typedef logic [NumScrmblKeys-1:0][ScrmblKeyWidth-1:0] key_array_t;
  typedef logic [NumDigestSets-1:0][ScrmblKeyWidth-1:0] digest_const_array_t;
  typedef logic [NumDigestSets-1:0][ScrmblBlockWidth-1:0] digest_iv_array_t;

  typedef enum logic [ConstSelWidth-1:0] {
    Secret0Key,
    Secret1Key,
    Secret2Key
  } key_sel_e;

  typedef enum logic [ConstSelWidth-1:0] {
    CnstyDigest,
    FlashDataKey,
    FlashAddrKey,
    SramDataKey
  } digest_sel_e;

  // SEC_CM: SECRET.MEM.SCRAMBLE
  parameter key_array_t RndCnstKey = {
    128'h64824C61F1EB6AB6879F8EFA78522377,
    128'hA421AEC54CAB821DF597822E4B39C87C,
    128'h9C274174149E2B57DAEE5A6398EA3A04
  };

  // SEC_CM: PART.MEM.DIGEST
  // Note: digest set 0 is used for computing the partition digests. Constants at
  // higher indices are used to compute the scrambling keys.
  parameter digest_const_array_t RndCnstDigestConst = {
    128'h5F2C075769000C39CDA36EAB93CD263D,
    128'hA824CFA99A1E179488280A4961B1644D,
    128'h26CE77C1EF8AB1D5E029DA11526F75B,
    128'h30FAA0C47E3809585A24109FBC53E920
  };

  parameter digest_iv_array_t RndCnstDigestIV = {
    64'hF2DAE31D857D1D39,
    64'h6AFB25D55069C52B,
    64'hB198D9A2A7D9B85,
    64'hAF12B341A53780AB
  };


  /////////////////////////////////////
  // Typedefs for Partition Metadata //
  /////////////////////////////////////

  typedef enum logic [1:0] {
    Unbuffered,
    Buffered,
    LifeCycle
  } part_variant_e;

  typedef struct packed {
    part_variant_e variant;
    // Offset and size within the OTP array, in Bytes.
    logic [OtpByteAddrWidth-1:0] offset;
    logic [OtpByteAddrWidth-1:0] size;
    // Key index to use for scrambling.
    key_sel_e key_sel;
    // Attributes
    logic secret;     // Whether the partition is secret (and hence scrambled)
    logic hw_digest;  // Whether the partition has a hardware digest
    logic write_lock; // Whether the partition is write lockable (via digest)
    logic read_lock;  // Whether the partition is read lockable (via digest)
    logic ecc_fatal;  // Whether the an ECC uncorrectable error leads to a fatal alert
  } part_info_t;

  parameter part_info_t PartInfoDefault = '{
      variant:    Unbuffered,
      offset:     '0,
      size:       OtpByteAddrWidth'('hFF),
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b0,
      write_lock: 1'b0,
      read_lock:  1'b0,
      ecc_fatal:  1'b0
  };

  ////////////////////////
  // Partition Metadata //
  ////////////////////////

  localparam part_info_t PartInfo [NumPart] = '{
    // VENDOR_TEST
    '{
      variant:    Unbuffered,
      offset:     11'd0,
      size:       64,
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b0,
      write_lock: 1'b1,
      read_lock:  1'b0,
      ecc_fatal:  1'b0
    },
    // CREATOR_SW_CFG
    '{
      variant:    Unbuffered,
      offset:     11'd64,
      size:       800,
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b0,
      write_lock: 1'b1,
      read_lock:  1'b0,
      ecc_fatal:  1'b1
    },
    // OWNER_SW_CFG
    '{
      variant:    Unbuffered,
      offset:     11'd864,
      size:       800,
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b0,
      write_lock: 1'b1,
      read_lock:  1'b0,
      ecc_fatal:  1'b1
    },
    // HW_CFG
    '{
      variant:    Buffered,
      offset:     11'd1664,
      size:       80,
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b1,
      write_lock: 1'b1,
      read_lock:  1'b0,
      ecc_fatal:  1'b1
    },
    // SECRET0
    '{
      variant:    Buffered,
      offset:     11'd1744,
      size:       40,
      key_sel:    Secret0Key,
      secret:     1'b1,
      hw_digest:  1'b1,
      write_lock: 1'b1,
      read_lock:  1'b1,
      ecc_fatal:  1'b1
    },
    // SECRET1
    '{
      variant:    Buffered,
      offset:     11'd1784,
      size:       88,
      key_sel:    Secret1Key,
      secret:     1'b1,
      hw_digest:  1'b1,
      write_lock: 1'b1,
      read_lock:  1'b1,
      ecc_fatal:  1'b1
    },
    // SECRET2
    '{
      variant:    Buffered,
      offset:     11'd1872,
      size:       88,
      key_sel:    Secret2Key,
      secret:     1'b1,
      hw_digest:  1'b1,
      write_lock: 1'b1,
      read_lock:  1'b1,
      ecc_fatal:  1'b1
    },
    // LIFE_CYCLE
    '{
      variant:    LifeCycle,
      offset:     11'd1960,
      size:       88,
      key_sel:    key_sel_e'('0),
      secret:     1'b0,
      hw_digest:  1'b0,
      write_lock: 1'b0,
      read_lock:  1'b0,
      ecc_fatal:  1'b1
    }
  };

  typedef enum {
    VendorTestIdx,
    CreatorSwCfgIdx,
    OwnerSwCfgIdx,
    HwCfgIdx,
    Secret0Idx,
    Secret1Idx,
    Secret2Idx,
    LifeCycleIdx,
    // These are not "real partitions", but in terms of implementation it is convenient to
    // add these at the end of certain arrays.
    DaiIdx,
    LciIdx,
    KdiIdx,
    // Number of agents is the last idx+1.
    NumAgentsIdx
  } part_idx_e;

  parameter int NumAgents = int'(NumAgentsIdx);

  // Breakout types for easier access of individual items.
  typedef struct packed {
    logic [63:0] hw_cfg_digest;
      logic [31:0] unallocated;
    prim_mubi_pkg::mubi8_t en_entropy_src_fw_over;
    prim_mubi_pkg::mubi8_t en_entropy_src_fw_read;
    prim_mubi_pkg::mubi8_t en_csrng_sw_app_read;
    prim_mubi_pkg::mubi8_t en_sram_ifetch;
    logic [255:0] manuf_state;
    logic [255:0] device_id;
  } otp_hw_cfg_data_t;

  // default value used for intermodule
  parameter otp_hw_cfg_data_t OTP_HW_CFG_DATA_DEFAULT = '{
    hw_cfg_digest: 64'hD2BF0E2CFC07120E,
    unallocated: 32'h0,
    en_entropy_src_fw_over: prim_mubi_pkg::mubi8_t'(8'h69),
    en_entropy_src_fw_read: prim_mubi_pkg::mubi8_t'(8'h69),
    en_csrng_sw_app_read: prim_mubi_pkg::mubi8_t'(8'h69),
    en_sram_ifetch: prim_mubi_pkg::mubi8_t'(8'h69),
    manuf_state: 256'h55BE0BF60F328302F6008FEDD015995F818E6D5088A5CDF93C0F42DCF28BBDCA,
    device_id: 256'h39D3131745015730931F5DA9AF1C3AACE93BC3CE277DADEF07D7A8934EE34FBD
  };

  typedef struct packed {
    // This reuses the same encoding as the life cycle signals for indicating valid status.
    lc_ctrl_pkg::lc_tx_t valid;
    otp_hw_cfg_data_t data;
  } otp_hw_cfg_t;

  // default value for intermodule
  parameter otp_hw_cfg_t OTP_HW_CFG_DEFAULT = '{
    valid: lc_ctrl_pkg::Off,
    data: OTP_HW_CFG_DATA_DEFAULT
  };

  // OTP invalid partition default for buffered partitions.
  parameter logic [16383:0] PartInvDefault = 16384'({
    704'({
      320'hBCEE0EAF635CC94C13341B2009F127B06D6A802324A832B510525C360F4D65C7B4D832618CCF4986,
      384'h813C1F50880EDCF619237C65265AB0F0C7BE3EA7E34C01040DEFD9C319666A73808EC748F9D19EC735CF8C381C8C5AFE
    }),
    704'({
      64'h9EBCF683C0FC7778,
      256'h7FDBA3FABBB202307AE064132CE3E678577E62959EFB89B7A2059F462D20F72,
      256'h27D331CD45A0EF7756EC4F708F6120840D5F33333CE062950E21D4D55ADB2645,
      128'hC20EEF44B66C882A67F85AFE2A82CBE0
    }),
    704'({
      64'hA8DEB8ABE2DA8416,
      128'h5ACC5965CAAD333087782B16192CB31F,
      256'h8C2B4F3535255D0B9EE36806F4741D1FF361DABDEC71147847CFC21F565393A4,
      256'h88EFD6E008A8D1E756E1E07F5EBCD245FA43D4382195A330424EDF34DF61C686
    }),
    320'({
      64'hBFD510D7D174D3C2,
      128'h827AA3F6BBFB187728C1F8823EC901A4,
      128'hEA922083D08D74C031E0F4A706AC2F4C
    }),
    640'({
      64'hD2BF0E2CFC07120E,
      32'h0, // unallocated space
      8'h69,
      8'h69,
      8'h69,
      8'h69,
      256'h55BE0BF60F328302F6008FEDD015995F818E6D5088A5CDF93C0F42DCF28BBDCA,
      256'h39D3131745015730931F5DA9AF1C3AACE93BC3CE277DADEF07D7A8934EE34FBD
    }),
    6400'({
      64'hA8184B94FC7A6455,
      2144'h0, // unallocated space
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      512'h0,
      128'h0,
      128'h0,
      512'h0,
      2560'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0
    }),
    6400'({
      64'h74501C921B4BAE3A,
      4032'h0, // unallocated space
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      32'h0,
      64'h0,
      32'h0,
      64'h0,
      32'h0,
      32'h0,
      32'h0,
      1248'h0
    }),
    512'({
      64'hE24632038254ADF2,
      448'h0
    })});

endpackage : otp_ctrl_part_pkg
