// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use std::fs;
use std::path::PathBuf;
use std::rc::Rc;
use std::str::FromStr;
use std::time::Duration;

use anyhow::Result;
use serde::{Deserialize, Serialize};
use structopt::StructOpt;
use thiserror::Error;

use crate::impl_serializable_error;
use crate::io::jtag::{Jtag, RiscvCsr, RiscvGpr, RiscvReg};
use crate::util::parse_int::ParseInt;
use crate::util::vmem::Vmem;

use top_earlgrey::top_earlgrey_memory;

/// Command-line parameters.
#[derive(Debug, StructOpt, Clone)]
pub struct SramProgramParams {
    /// Path to the VMEM file to load.
    #[structopt(long)]
    pub vmem: PathBuf,

    /// Address where to load the VMEM file.
    #[structopt(long, parse(try_from_str = ParseInt::from_str))]
    pub load_addr: u32,

    /// Address of the top of the stack.
    #[structopt(long, parse(try_from_str = ParseInt::from_str))]
    pub stack_pointer: u32,

    /// Size of the stack.
    #[structopt(long, parse(try_from_str = ParseInt::from_str))]
    pub stack_size: u32,

    /// Value of the global pointer
    #[structopt(long, parse(try_from_str = ParseInt::from_str))]
    pub global_pointer: u32,
}

impl SramProgramParams {
    pub fn load_and_execute(
        &self,
        jtag: &Rc<dyn Jtag>,
        exec_mode: ExecutionMode,
    ) -> Result<ExecutionResult> {
        load_and_execute_sram_program(
            jtag,
            &self.vmem,
            self.load_addr,
            self.stack_pointer,
            self.stack_size,
            self.global_pointer,
            exec_mode,
        )
    }
}

/// Execution mode for a SRAM program.
pub enum ExecutionMode {
    /// Jump to the loading address and let the program run forever.
    Jump,
    /// Jump at the loading address and immediately halt execution.
    JumpAndHalt,
    /// Make a "call" to the loading address and wait until the function returns
    /// (or wait forever if None)
    Call(Duration),
}

/// Result of execution of a SRAM program.
#[derive(Debug, Deserialize, Serialize)]
pub enum ExecutionResult {
    /// (JumpAndHalt only) Execution is halted at the beginning.
    HaltedAtStart,
    /// (Jump only) Execution is ongoing.
    Executing,
    /// (Call only) Execution successfully returned.
    CallReturned,
    /// (Call only) Execution halted before returning to the caller or because of the timeout.
    CallFailed,
}

/// Errors related to loading an SRAM program.
#[derive(Error, Debug, Deserialize, Serialize)]
pub enum LoadSramProgramError {
    #[error("SRAM program execution timed out")]
    Executiontimeout,
    #[error("Generic error {0}")]
    Generic(String),
}
impl_serializable_error!(LoadSramProgramError);

/// Load a program into SRAM using JTAG.
pub fn load_sram_program(jtag: &Rc<dyn Jtag>, vmem: &Vmem, addr: u32) -> Result<()> {
    for section in vmem.sections() {
        log::info!(
            "Load {} words at address {:x}",
            section.data.len(),
            addr + section.addr
        );
        jtag.write_memory32(addr + section.addr, &section.data)?;
    }
    Ok(())
}

/// Set up the ePMP to enable read/write/execute from SRAM.
/// This function will set the PMP entry 15 to NAPOT to cover the SRAM as RWX
/// This follows the memory layout used by the ROM [0].
///
/// The Ibex core is initialized with a default ePMP configuration [3]
/// when it starts. This configuration has no PMP entry for the RAM
/// and mseccfg.mmwp is set to 1 so accesses that don't match a PMP entry will
/// be denied.
///
/// Before transferring the SRAM program to the device, we must configure
/// the PMP unit to enable reading, writing to and executing from SRAM. Due to
/// implementation details of OpenTitan's hardware debug module, it is important
/// that the RV_ROM remains accessible at all times [1]. It uses entry 13 of the
/// PMP on boot so we want to preserve that. However, we can safely
/// modify the other PMP configuration registers.
///
/// In more detail, the problem is that our debug module implements the
/// "Access Register" abstract command by assembling instructions in the
/// program buffer and then executing the buffer. If one of those
/// instructions clobbers the PMP configuration register that allows
/// execution from the program buffer (PMP entry 13),
/// subsequent instruction fetches will generate exceptions.
///
/// Debug module concepts like abstract commands and the program buffer
/// buffer are defined in "RISC-V External Debug Support Version 0.13.2"
/// [2]. OpenTitan's (vendored-in) implementation lives in
/// hw/vendor/pulp_riscv_dbg.
///
/// [0]: https://opentitan.org/book/sw/device/silicon_creator/rom/doc/memory_protection.html
/// [1]: https://github.com/lowRISC/opentitan/issues/14978
/// [2]: https://riscv.org/wp-content/uploads/2019/03/riscv-debug-release.pdf
/// [3]: https://github.com/lowRISC/opentitan/blob/master/hw/ip/rv_core_ibex/rtl/ibex_pmp_reset.svh
pub fn prepare_epmp_for_sram(jtag: &Rc<dyn Jtag>) -> Result<()> {
    log::info!("Configure ePMP for SRAM execution");
    let pmpcfg3 = jtag.read_riscv_reg(&RiscvReg::CsrByName(RiscvCsr::PMPCFG3))?;
    log::info!("Old value of pmpcfg3: {:x}", pmpcfg3);
    // write "L NAPOT X W R" to pmp3cfg in pmpcfg3
    let pmpcfg3 = (pmpcfg3 & 0x00ffffffu32) | 0x9f000000;
    log::info!("New value of pmpcfg3: {:x}", pmpcfg3);
    jtag.write_riscv_reg(&RiscvReg::CsrByName(RiscvCsr::PMPCFG3), pmpcfg3)?;
    // write pmpaddr15 to map the SRAM range
    // hex((0x10000000 >> 2) | ((0x20000 - 1) >> 3)) = 0x4003fff
    let base = top_earlgrey_memory::TOP_EARLGREY_SRAM_CTRL_MAIN_RAM_BASE_ADDR as u32;
    let size = top_earlgrey_memory::TOP_EARLGREY_SRAM_CTRL_MAIN_RAM_SIZE_BYTES as u32;
    // make sure that this is a power of two
    assert!(size & (size - 1) == 0);
    let pmpaddr15 = (base >> 2) | ((size - 1) >> 3);
    log::info!("New value of pmpaddr15: {:x}", pmpaddr15);
    jtag.write_riscv_reg(&RiscvReg::CsrByName(RiscvCsr::PMPADDR15), pmpaddr15)?;
    Ok(())
}

/// Fills the stack with a known value (0xdeadbeef). This can be useful if SRAM scrambling
/// is enabled to make sure that the core can read from the stack without errors.
pub fn setup_stack(jtag: &Rc<dyn Jtag>, stack_pointer: u32, stack_size: u32) -> Result<()> {
    // the stack size must be a multiple of 4
    assert_eq!(0, stack_size % 4);
    log::info!(
        "Setting up stack at [{:x}:{:x}]",
        stack_pointer - stack_size,
        stack_pointer
    );
    // it's much more efficient to write all the data at once
    let stack = vec![0xdeadbeefu32; (stack_size / 4) as usize];
    jtag.write_memory32(stack_pointer - stack_size, &stack)
}

/// This function loads and execute a SRAM program. It takes care of all the details regarding
/// the ePMP, the stack and the global pointer. It starts the execution at the beginning of the
/// SRAM program.
pub fn load_and_execute_sram_program(
    jtag: &Rc<dyn Jtag>,
    vmem_filename: &PathBuf,
    sram_load_addr: u32,
    stack_pointer: u32,
    stack_size: u32,
    global_pointer: u32,
    exec_mode: ExecutionMode,
) -> Result<ExecutionResult> {
    log::info!("Loading VMEM file {}", vmem_filename.display());
    let vmem_content = fs::read_to_string(vmem_filename)?;
    let mut vmem = Vmem::from_str(&vmem_content)?;
    vmem.merge_sections();
    log::info!("Uploading program to SRAM at {:x}", sram_load_addr);
    load_sram_program(jtag, &vmem, sram_load_addr)?;
    log::info!("Preparing ePMP for execution");
    prepare_epmp_for_sram(jtag)?;
    setup_stack(jtag, stack_pointer, stack_size)?;
    log::info!("set SP to {:x}", stack_pointer);
    jtag.write_riscv_reg(&RiscvReg::GprByName(RiscvGpr::SP), stack_pointer)?;
    log::info!("set GP to {:x}", global_pointer);
    jtag.write_riscv_reg(&RiscvReg::GprByName(RiscvGpr::GP), global_pointer)?;
    // to avoid unexpected behaviors, we always make sure that the return addreess
    // points to the bottom of the stack where we insert a ebreak instruction
    let ret_addr = stack_pointer - stack_size;
    log::info!("set RA to {:x}", ret_addr);
    jtag.write_riscv_reg(&RiscvReg::GprByName(RiscvGpr::RA), ret_addr)?;
    log::info!("write EBEREAK at {:x}", ret_addr);
    jtag.write_memory32(ret_addr, &[0x100073])?;
    // OpenOCD takes care of invalidating the cache when resuming execution
    match exec_mode {
        ExecutionMode::Jump => {
            log::info!("resume execution at {:x}", sram_load_addr);
            jtag.resume_at(sram_load_addr)?;
            Ok(ExecutionResult::Executing)
        }
        ExecutionMode::JumpAndHalt => {
            log::info!("set DPC to {:x}", sram_load_addr);
            jtag.write_riscv_reg(&RiscvReg::CsrByName(RiscvCsr::DPC), sram_load_addr)?;
            Ok(ExecutionResult::HaltedAtStart)
        }
        ExecutionMode::Call(tmo) => {
            log::info!("resume execution at {:x}", sram_load_addr);
            jtag.resume_at(sram_load_addr)?;
            jtag.wait_halt(tmo)?;
            jtag.halt()?;
            // read PC to see if it returned or not
            let pc = jtag.read_riscv_reg(&RiscvReg::CsrByName(RiscvCsr::DPC))?;
            if pc == ret_addr {
                Ok(ExecutionResult::CallReturned)
            } else {
                Ok(ExecutionResult::CallFailed)
            }
        }
    }
}
