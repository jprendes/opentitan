# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("//rules:autogen.bzl", "autogen_hjson_header")
load(
    "//rules:otp.bzl",
    "STD_OTP_OVERLAYS",
    "STD_OTP_OVERLAYS_WITHOUT_SECRET_PARTITIONS",
    "otp_alert_digest",
    "otp_image",
    "otp_json",
    "otp_partition",
)
load("@rules_pkg//pkg:mappings.bzl", "pkg_files")
load("@bazel_skylib//rules:common_settings.bzl", "int_flag", "string_flag")

package(default_visibility = ["//visibility:public"])

# These configurations expose the OTP image generation tool's command line
# arguments to enable dvsim to pass this through Bazel to the underlying OTP
# image generation script. This is required to enable dvsim to invoke OTP image
# generation as part of the Bazel build process, while still enabling the use of
# multiple seeds needed to achieve DV coverage.
int_flag(
    name = "img_seed",
    build_setting_default = 0,
)

string_flag(
    name = "lc_seed",
    # Default must match value in hw/ip/lc_ctrl/data/lc_ctrl.hjson.
    build_setting_default = "10167336684108184581",
)

string_flag(
    name = "otp_seed",
    # Default must match value in hw/ip/otp_ctrl/data/otp_ctrl_mmap.hjson.
    build_setting_default = "10556718629619452145",
)

string_flag(
    name = "data_perm",
    build_setting_default = "",
)

# This package must be kept in sync with get_otp_images() from //rules:otp.bzl.
# That is, each OTP image referenced by the macro should have a definition in
# this BUILD file.

filegroup(
    name = "all_files",
    srcs = glob(["**"]),
)

exports_files(["otp_ctrl_img.h.tpl"])

autogen_hjson_header(
    name = "otp_ctrl_regs",
    srcs = [
        "otp_ctrl.hjson",
    ],
)

exports_files(["otp_ctrl_mmap.hjson"])

otp_json(
    name = "otp_json_creator_sw_cfg",
    partitions = [
        otp_partition(
            name = "CREATOR_SW_CFG",
            items = {
                # Use software mod_exp implementation for signature
                # verification. See the definition of `hardened_bool_t` in
                # sw/device/lib/base/hardened.h.
                "CREATOR_SW_CFG_SIGVERIFY_RSA_MOD_EXP_IBEX_EN": "0x739",
                # Mark the first three keys as valid and remaining as invalid
                # since we currently have only three keys. See the definition of
                # `hardened_byte_bool_t` in sw/device/lib/base/hardened.h.
                "CREATOR_SW_CFG_SIGVERIFY_RSA_KEY_EN": "0x4b4b4b4b4ba5a5a5",
                # Disable SPX+ signature verification. See the definitions of
                # `kSigverifySpxDisabledOtp` and `kSigverifySpxEnabledOtp` in
                # sw/device/silicon_creator/lib/sigverify/spx_verify.h.
                "CREATOR_SW_CFG_SIGVERIFY_SPX_EN": "0x8d6c8c17",
                # Enable use of entropy for countermeasures. See the definition
                # of `hardened_bool_t` in sw/device/lib/base/hardened.h.
                "CREATOR_SW_CFG_RNG_EN": "0x739",
                # ROM execution is enabled if this item is set to a non-zero
                # value.
                "CREATOR_SW_CFG_ROM_EXEC_EN": "0xffffffff",
                # Value to write to the cpuctrl CSR in `rom_init()`.
                # See:
                # https://ibex-core.readthedocs.io/en/latest/03_reference/cs_registers.html#cpu-control-register-cpuctrl
                "CREATOR_SW_CFG_CPUCTRL": "0x1",
                "CREATOR_SW_CFG_JITTER_EN": "0x9",
                # Value of the min_security_version_rom_ext field of the
                # default boot data.
                "CREATOR_SW_CFG_MIN_SEC_VER_ROM_EXT": "0x0",
                # Value of the min_security_version_bl0 field of the default
                # boot data.
                "CREATOR_SW_CFG_MIN_SEC_VER_BL0": "0x0",
                # Enable the default boot data in PROD and PROD_END life cycle
                # states. See the definition of `hardened_bool_t` in
                # sw/device/lib/base/hardened.h.
                "CREATOR_SW_CFG_DEFAULT_BOOT_DATA_IN_PROD_EN": "0x739",
                # Enable AST initialization.
                "CREATOR_SW_CFG_AST_INIT_EN": "0x6",
                # TODO: This enables a busyloop in the ROM to give time to
                # trigger an RMA lifecycle transition via JTAG.  The current
                # value of 10 cycles is useful for test code which verifies
                # the path through the ROM.  This value is not useful for a
                # real chip.
                "CREATOR_SW_CFG_RMA_SPIN_EN": "0x739",
                "CREATOR_SW_CFG_RMA_SPIN_CYCLES": "10",
                # Entropy source health check default values. This needs to be
                # populated when `CREATOR_SW_CFG_RNG_EN` is set to true.
                "CREATOR_SW_CFG_RNG_REPCNT_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_REPCNTS_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_ADAPTP_HI_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_ADAPTP_LO_THRESHOLDS": "0x0",
                "CREATOR_SW_CFG_RNG_BUCKET_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_MARKOV_HI_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_MARKOV_LO_THRESHOLDS": "0x0",
                "CREATOR_SW_CFG_RNG_EXTHT_HI_THRESHOLDS": "0xffffffff",
                "CREATOR_SW_CFG_RNG_EXTHT_LO_THRESHOLDS": "0x0",
                "CREATOR_SW_CFG_RNG_ALERT_THRESHOLD": "0xfffd0002",
                "CREATOR_SW_CFG_RNG_HEALTH_CONFIG_DIGEST": "0x8264cf75",
            },
        ),
    ],
)

# CREATOR_SW_CFG configuration for TEST_UNLOCKED lifecycle device states.
# Configures OTP values required to enable ROM execution. All other values are
# configured with the `otp_json_creator_sw_cfg` rule.
otp_json(
    name = "otp_json_creator_sw_cfg_test_unlocked",
    partitions = [
        otp_partition(
            name = "CREATOR_SW_CFG",
            items = {
                # ROM execution is enabled if this item is set to a non-zero
                # value.
                "CREATOR_SW_CFG_ROM_EXEC_EN": "0xffffffff",
            },
        ),
    ],
)

otp_json(
    name = "otp_json_owner_sw_cfg",
    partitions = [
        otp_partition(
            name = "OWNER_SW_CFG",
            items = {
                # Enable bootstrap. See `hardened_bool_t` in
                # sw/device/lib/base/hardened.h.
                "OWNER_SW_CFG_ROM_BOOTSTRAP_DIS": "0x1d4",
                # Set to 0x739 to use the ROM_EXT hash measurement as the key
                # manager attestation binding value.
                "OWNER_SW_CFG_ROM_KEYMGR_ROM_EXT_MEAS_EN": "0x0",
                # Report errors without any redaction.
                "OWNER_SW_CFG_ROM_ERROR_REPORTING": "0xe2290aa5",
                # Set the enables to kAlertEnableNone.
                # See `alert_enable_t` in
                # sw/device/silicon_creator/lib/drivers/alert.h
                "OWNER_SW_CFG_ROM_ALERT_CLASS_EN": "0xa9a9a9a9",
                # Set the esclation policies to kAlertEscalateNone.
                # See `alert_escalate_t` in
                # sw/device/silicon_creator/lib/drivers/alert.h
                "OWNER_SW_CFG_ROM_ALERT_ESCALATION": "0xd1d1d1d1",
                # Set the classifiactions to kAlertClassX.
                # See `alert_class_t` in
                # sw/device/silicon_creator/lib/drivers/alert.h
                "OWNER_SW_CFG_ROM_ALERT_CLASSIFICATION": ["0x94949494"] * 80,
                # Set the classifiactions to kAlertClassX. See `alert_class_t` in
                # sw/device/silicon_creator/lib/drivers/alert.h
                "OWNER_SW_CFG_ROM_LOCAL_ALERT_CLASSIFICATION": ["0x94949494"] * 16,
                # Set the alert accumulation thresholds to 0 per class.
                "OWNER_SW_CFG_ROM_ALERT_ACCUM_THRESH": ["0x00000000"] * 4,
                # Set the alert timeout cycles to 0 per class.
                "OWNER_SW_CFG_ROM_ALERT_TIMEOUT_CYCLES": ["0x00000000"] * 4,
                # Set the alert phase cycles to 0,10,10,0xFFFFFFFF for classes
                # A and B, and to all zeros for classes C and D.
                "OWNER_SW_CFG_ROM_ALERT_PHASE_CYCLES": [
                    "0x0",
                    "0xa",
                    "0xa",
                    "0xFFFFFFFF",
                    "0x0",
                    "0xa",
                    "0xa",
                    "0xFFFFFFFF",
                    "0x0",
                    "0x0",
                    "0x0",
                    "0x0",
                    "0x0",
                    "0x0",
                    "0x0",
                    "0x0",
                ],
            },
        ),
    ],
)

otp_json(
    name = "otp_json_hw_cfg",
    partitions = [
        otp_partition(
            name = "HW_CFG",
            items = {
                "DEVICE_ID": "<random>",
                # Cryptolib and chip-level tests require access to the CSRNG
                # software interfaces.
                "EN_CSRNG_SW_APP_READ": True,
                # Cryptolib and chip-level tests require access to the
                # entropy_src FW data interface.
                "EN_ENTROPY_SRC_FW_READ": True,
                # Cryptolib and chip-level tests require access to the
                # entropy_src FW override interface.
                "EN_ENTROPY_SRC_FW_OVER": True,
            },
            lock = True,
        ),
    ],
)

otp_json(
    name = "otp_json_secret0",
    partitions = [
        otp_partition(
            name = "SECRET0",
            items = {
                "TEST_UNLOCK_TOKEN": "<random>",
                "TEST_EXIT_TOKEN": "<random>",
            },
            lock = True,
        ),
    ],
)

otp_json(
    name = "otp_json_secret1",
    partitions = [
        otp_partition(
            name = "SECRET1",
            items = {
                "FLASH_ADDR_KEY_SEED": "<random>",
                "FLASH_DATA_KEY_SEED": "<random>",
                "SRAM_DATA_KEY_SEED": "<random>",
            },
            lock = True,
        ),
    ],
)

otp_json(
    name = "otp_json_secret2",
    partitions = [
        otp_partition(
            name = "SECRET2",
            items = {
                "RMA_TOKEN": "<random>",
                "CREATOR_ROOT_KEY_SHARE0": "<random>",
                "CREATOR_ROOT_KEY_SHARE1": "<random>",
            },
            lock = True,
        ),
    ],
)

otp_json(
    name = "otp_json_secret2_unlocked",
    partitions = [
        otp_partition(
            name = "SECRET2",
            items = {
                "RMA_TOKEN": "<random>",
                "CREATOR_ROOT_KEY_SHARE0": "<random>",
                "CREATOR_ROOT_KEY_SHARE1": "<random>",
            },
            lock = False,
        ),
    ],
)

# OTP LC STATE-SPECIFIC CONFIGS
otp_json(
    name = "otp_json_raw",
    partitions = [
        otp_partition(
            name = "SECRET1",
            items = {
                "FLASH_DATA_KEY_SEED": "<random>",
            },
            lock = False,
        ),
        otp_partition(
            name = "LIFE_CYCLE",
            count = 0,
            state = "RAW",
        ),
    ],
    seed = "01931961561863975174",
)

[
    otp_json(
        name = "otp_json_test_unlocked{}".format(i),
        partitions = [
            otp_partition(
                name = "LIFE_CYCLE",
                count = (i * 2) + 1,
                state = "TEST_UNLOCKED{}".format(i),
            ),
        ],
        seed = "01931961561863975174",
    )
    for i in range(0, 8)
]

[
    otp_json(
        name = "otp_json_test_locked{}".format(i),
        partitions = [
            otp_partition(
                name = "LIFE_CYCLE",
                count = (i + 1) * 2,
                state = "TEST_LOCKED{}".format(i),
            ),
        ],
        seed = "01931961561863975174",
    )
    for i in range(0, 7)
]

otp_json(
    name = "otp_json_dev",
    partitions = [
        otp_partition(
            name = "LIFE_CYCLE",
            count = "5",
            state = "DEV",
        ),
    ],
    seed = "94259314771464387",
)

otp_json(
    name = "otp_json_prod",
    partitions = [
        otp_partition(
            name = "LIFE_CYCLE",
            count = 5,
            state = "PROD",
        ),
    ],
    seed = "14555711126514784208",
)

otp_json(
    name = "otp_json_prod_end",
    partitions = [
        otp_partition(
            name = "LIFE_CYCLE",
            count = 5,
            state = "PROD_END",
        ),
    ],
    seed = "14555711126514784208",
)

otp_json(
    name = "otp_json_rma",
    partitions = [
        otp_partition(
            name = "LIFE_CYCLE",
            count = 8,
            state = "RMA",
        ),
    ],
    seed = "01931961561863975174",
)

# Create an overlay for the alert_handler digest.
otp_alert_digest(
    name = "otp_json_alert_digest_cfg",
    otp_img = ":otp_json_owner_sw_cfg",
)

# The RAW OTP image only contains the LIFE_CYCLE partition, which is set to RAW
# state. All other partitions are left with default values to ensure the state
# of OTP is representative of post-silicon scenarios.
otp_image(
    name = "img_raw",
    src = ":otp_json_raw",
)

[
    # TEST_UNLOCKED images are expected to only have the SECRET0 partition
    # configured, as well as ROM execution enabled in the CREATOR_SW partition.
    # All other partitions are left with default values to ensure the state of
    # OTP is representative of post-silicon scenarios.
    otp_image(
        name = "img_test_unlocked{}".format(i),
        src = ":otp_json_test_unlocked{}".format(i),
        overlays = [
            ":otp_json_secret0",
            ":otp_json_creator_sw_cfg_test_unlocked",
        ],
    )
    for i in range(0, 8)
]

[
    otp_image(
        name = "img_test_locked{}".format(i),
        src = ":otp_json_test_locked{}".format(i),
        overlays = [
            ":otp_json_secret0",
            ":otp_json_creator_sw_cfg_test_unlocked",
        ],
    )
    for i in range(0, 7)
]

# Represents a DEV state OTP image emulating the state of the device after the
# exit test token has been applied and before running individualization.
# The following partitions are missing to ensure the image is initialize with
# default values: SECRET1, SECRET2, HW_CFG.
# The following partitions are expected to be configured in previous lifecycle
# stages: SECRET0, CREATOR_SW, OWNER_SW.
otp_image(
    name = "img_dev_initial",
    src = ":otp_json_dev",
    overlays = [
        ":otp_json_secret0",
        ":otp_json_creator_sw_cfg",
        ":otp_json_owner_sw_cfg",
        ":otp_json_alert_digest_cfg",
    ],
)

# Represents a device in DEV state with the SECRET0 and SECRET1 partitions in
# locked state. SECRET2 partition is unlocked.
otp_image(
    name = "img_dev_individualized",
    src = ":otp_json_dev",
    overlays = [
        ":otp_json_secret0",
        ":otp_json_secret1",
    ] + STD_OTP_OVERLAYS_WITHOUT_SECRET_PARTITIONS,
)

otp_image(
    name = "img_dev",
    src = ":otp_json_dev",
    overlays = STD_OTP_OVERLAYS,
)

otp_image(
    name = "img_prod",
    src = ":otp_json_prod",
    overlays = STD_OTP_OVERLAYS,
)

otp_image(
    name = "img_prod_end",
    src = ":otp_json_prod_end",
    overlays = STD_OTP_OVERLAYS,
)

otp_image(
    name = "img_rma",
    src = ":otp_json_rma",
    overlays = STD_OTP_OVERLAYS,
)

# Create an execution-disabling overlay
otp_json(
    name = "otp_json_exec_disabled",
    partitions = [
        otp_partition(
            name = "CREATOR_SW_CFG",
            items = {"CREATOR_SW_CFG_ROM_EXEC_EN": "0x0"},
        ),
    ],
)

otp_image(
    name = "img_exec_disabled",
    src = ":otp_json_rma",
    overlays = STD_OTP_OVERLAYS + [":otp_json_exec_disabled"],
)

# Create a bootstrap-disabling overlay
otp_json(
    name = "otp_json_bootstrap_disabled",
    partitions = [
        otp_partition(
            name = "OWNER_SW_CFG",
            items = {"OWNER_SW_CFG_ROM_BOOTSTRAP_DIS": "0x739"},
        ),
    ],
)

otp_image(
    name = "img_bootstrap_disabled",
    src = ":otp_json_rma",
    overlays = STD_OTP_OVERLAYS + [":otp_json_bootstrap_disabled"],
)

filegroup(
    name = "otp_imgs",
    srcs = [
        ":img_dev",
        ":img_dev_individualized",
        ":img_dev_initial",
        ":img_prod",
        ":img_raw",
        ":img_rma",
        ":img_test_locked0",
        ":img_test_locked1",
        ":img_test_locked2",
        ":img_test_locked3",
        ":img_test_locked4",
        ":img_test_locked5",
        ":img_test_locked6",
        ":img_test_unlocked0",
        ":img_test_unlocked1",
        ":img_test_unlocked2",
        ":img_test_unlocked3",
        ":img_test_unlocked4",
        ":img_test_unlocked5",
        ":img_test_unlocked6",
        ":img_test_unlocked7",
    ],
)

pkg_files(
    name = "package",
    srcs = [":otp_imgs"],
    prefix = "earlgrey/otp",
)
