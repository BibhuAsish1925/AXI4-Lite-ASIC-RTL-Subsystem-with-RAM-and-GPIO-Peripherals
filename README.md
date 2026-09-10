# AXI4-Lite-ASIC-RTL-Subsystem-with-RAM-and-GPIO-Peripherals

[![Protocol](https://img.shields.io/badge/Protocol-AXI4--Lite-blue)](https://developer.arm.com/architectures/system-architectures/amba/amba-specifications)
[![HDL](https://img.shields.io/badge/HDL-SystemVerilog-purple)](#)
[![Data Width](https://img.shields.io/badge/Data%20Width-32--bit-blueviolet)](#)
[![RAM](https://img.shields.io/badge/RAM-1%20KB-green)](#)
[![GPIO](https://img.shields.io/badge/Peripheral-GPIO-green)](#)
[![Verification](https://img.shields.io/badge/Verification-11%2F11%20PASS-brightgreen)](#)
[![Lint](https://img.shields.io/badge/Verilator-0%20Warnings-brightgreen)](#)
[![Synthesis](https://img.shields.io/badge/Synthesis-Yosys-orange)](#)
[![Timing](https://img.shields.io/badge/Timing-100%20MHz-success)](#)

## Project Overview

- A **SystemVerilog RTL implementation of an AXI4-Lite based subsystem** with:
  - AXI4-Lite Master
  - AXI4-Lite Slave
  - Address Decoders
  - RAM Peripheral
  - GPIO Peripheral
  - Top-level transaction control
- Designed as an **ASIC-oriented RTL portfolio project**.
- The design was developed, functionally verified, linted, synthesized, and analyzed using both FPGA-oriented and open-source ASIC-oriented tools.

## Project Aim

- To design and verify a compact **AXI4-Lite memory-mapped subsystem** at RTL.
- To demonstrate practical understanding of:
  - AXI4-Lite protocol transactions
  - Read/write channel handshaking
  - Memory-mapped address decoding
  - Peripheral integration
  - RTL verification
  - RTL linting
  - Logic synthesis
  - Timing analysis
  - Power and utilization analysis
  - Synthesized-netlist simulation

## Main Objectives

- Implement a functional **32-bit AXI4-Lite interface**.
- Support independent AXI4-Lite read and write transactions.
- Correctly handle:
  - `AWVALID/AWREADY`
  - `WVALID/WREADY`
  - `BVALID/BREADY`
  - `ARVALID/ARREADY`
  - `RVALID/RREADY`
- Implement address-based peripheral selection.
- Integrate:
  - **1 KB RAM**
  - **GPIO peripheral**
- Support AXI byte write strobes.
- Generate appropriate AXI responses:
  - `OKAY`
  - `DECERR`
- Verify valid and invalid memory accesses.
- Verify the synthesized Yosys netlist using the same top-level testbench.

| Tool | Purpose |
|---|---|
| SystemVerilog | RTL design |
| Vivado 2025.1 | RTL simulation, synthesis, implementation, timing, power |
| XSim | Functional simulation |
| Verilator | RTL lint |
| Yosys 0.62 | ASIC-oriented synthesis |
| LibreLane 3.0.11 | ASIC synthesis environment |
| Docker | Reproducible ASIC tool environment |
| WSL2 / Ubuntu 24.04 | Development environment |
| Git / GitHub | Version control and project hosting |

## Design Specifications

| Parameter | Specification |
|---|---|
| Protocol | AXI4-Lite |
| Address Width | 32-bit |
| Data Width | 32-bit |
| Write Strobes | 4-bit |
| Clock | 100 MHz |
| Clock Period | 10 ns |
| Reset | Active-low synchronous |
| RAM Size | 1 KB |
| RAM Depth | 256 × 32-bit |
| GPIO Data Width | 32-bit |

## Memory Map

| Address Range | Peripheral | Description |
|---|---|---|
| `0x0000_0000 – 0x0000_03FF` | RAM | 1 KB memory |
| `0x0000_1000 – 0x0000_10FF` | GPIO | GPIO register space |
| Other addresses | Unmapped | Returns `DECERR` |

### GPIO Registers

| Address | Register | Access |
|---|---|---|
| `0x0000_1000` | GPIO Output | Read/Write |
| `0x0000_1004` | GPIO Input | Read-only |
| `0x0000_1008` | GPIO Direction | Read/Write |
| `0x0000_100C+` | Invalid | `DECERR` |

## RTL Architecture

<table align="center">
    <td align="center">
      <img width="1692" height="930" alt="AXI4-Lite TOP block diagram" src="https://github.com/user-attachments/assets/af02a6e8-b094-4126-8704-5fb07c28bd1c" /><br/>
      <small>Fig. RTL Architecture</small>
    </td>
</table>

## RTL Modules

| Module | Description | Key Features / Responsibilities |
|---|---|---|
| `axi4_lite_pkg.sv` | Defines common AXI4-Lite parameters and response codes. | - Address width<br>- Data width<br>- Strobe width<br>- AXI response definitions |
| `axi4_lite_if.sv` | Defines the AXI4-Lite SystemVerilog interface. | - Write address channel<br>- Write data channel<br>- Write response channel<br>- Read address channel<br>- Read data channel<br>- Master and slave modports |
| `axi4_lite_master.sv` | Implements AXI4-Lite master transaction control. | - Write transactions<br>- Read transactions<br>- AXI handshakes<br>- Response reception |
| `axi4_lite_slave.sv` | Generic AXI4-Lite slave implementation. | - Independent arrival ordering of write address and write data<br>- AXI response generation |
| `axi4_lite_addr_decoder.sv` | Decodes AXI addresses and generates peripheral selection signals. | Determines whether an address belongs to:<br>- RAM<br>- GPIO<br>- Unmapped region |
| `ram_slave.sv` | Implements a 1 KB RAM peripheral. | **Organization:**<br>- 256 words<br>- 32 bits per word<br><br>**Supports:**<br>- Read operations<br>- Write operations<br>- Byte write strobes<br>- Registered responses |
| `gpio_slave.sv` | Implements memory-mapped GPIO registers. | - Output register<br>- Input register<br>- Direction register<br>- Byte write strobes<br>- Invalid register accesses return `DECERR` |
| `axi4_lite_interconnect.sv` | Provides a separately implemented AXI4-Lite interconnect structure. | - Peripheral selection<br>- Response routing<br>- Independent verification |
| `axi4_lite_top.sv` | Top-level subsystem. | Instantiates:<br>- AXI4-Lite master<br>- Address decoders<br>- RAM<br>- GPIO<br><br>Implements top-level transaction and response handling. |

## Verification Strategy

Verification was performed at multiple levels:

- Individual RTL module verification.
- Top-level subsystem verification.
- AXI protocol transaction verification.
- Invalid-address verification.
- Byte-strobe verification.
- Synthesized-netlist simulation.

### Dedicated Testbenches

- `tb_axi4_lite_master.sv`
- `tb_axi4_lite_slave.sv`
- `tb_axi4_lite_addr_decoder.sv`
- `tb_axi4_lite_interconnect.sv`
- `tb_ram_slave.sv`
- `tb_gpio_slave.sv`
- `tb_axi4_lite_top.sv`
- `tb_axi4_lite_top_netlist.sv`

## Top-Level Verification

The top-level testbench verifies:

- ✅ RAM write
- ✅ RAM read
- ✅ RAM byte strobes
- ✅ GPIO output
- ✅ GPIO direction
- ✅ GPIO input
- ✅ GPIO byte strobes
- ✅ Unmapped write
- ✅ Unmapped read
- ✅ Invalid GPIO register access
- ✅ RAM last-word access

### Result

```text
==============================================
[PASS] AXI4-Lite top-level test completed successfully
==============================================
```
11/11 functional tests passed.

## Important Functional Checks

### RAM

- Normal write/read operation.
- Byte-level write using `WSTRB`.
- First RAM address tested.
- Last RAM word tested.

### GPIO

- Output register write/read.
- Direction register write/read.
- Input register read.
- Byte-strobe writes.
- Invalid register detection.

### Error Handling

- Unmapped write → `DECERR`
- Unmapped read → `DECERR`
- Invalid GPIO register write → `DECERR`
- Invalid GPIO register read → `DECERR`

## RTL Lint

**Tool:** Verilator

```bash
verilator --lint-only --Wall \
  --top-module axi4_lite_top \
  rtl/axi4_lite_pkg.sv \
  rtl/axi4_lite_if.sv \
  rtl/axi4_lite_master.sv \
  rtl/axi4_lite_slave.sv \
  rtl/axi4_lite_addr_decoder.sv \
  rtl/ram_slave.sv \
  rtl/gpio_slave.sv \
  rtl/axi4_lite_interconnect.sv \
  rtl/axi4_lite_top.sv
```

### Result

- **Warnings: 0**
- **Errors: 0**
- RTL lint: **PASS** ✅

## FPGA-Oriented Synthesis and Implementation

**Tool:** Xilinx Vivado 2025.1

**Target:**

- `xc7a200tfbg676-2`

**Clock:**

- 100 MHz
- 10 ns period

### Post-Synthesis Results

| Metric | Result |
|---|---:|
| LUTs | 208 |
| Flip-Flops | 288 |
| BRAM | 0 |
| DSP | 0 |
| WNS | +5.415 ns |
| TNS | 0 ns |
| Failing Endpoints | 0 |

### Post-Implementation Results

| Metric | Result |
|---|---:|
| LUTs | 204 |
| Flip-Flops | 354 |
| BRAM | 0 |
| DSP | 0 |
| WNS | +4.366 ns |
| TNS | 0 ns |
| Failing Endpoints | 0 |

### Timing Summary

- Single clock domain.
- CDC analysis: **All paths are safely timed.**
- Post-synthesis WNS: **+5.415 ns**
- Post-implementation WNS: **+4.366 ns**
- Setup violations: **0**
- Hold violations: **0**

## ASIC-Oriented Synthesis

**Tool:** Yosys

**Environment:**

- LibreLane Docker
- LibreLane `v3.0.11`
- Yosys `0.62`

### Synthesis Flow

```text
SystemVerilog RTL
       │
       ▼
Read RTL
       │
       ▼
Hierarchy
       │
       ▼
Process Conversion
       │
       ▼
Optimization
       │
       ▼
Memory Mapping
       │
       ▼
Technology Mapping
       │
       ▼
Yosys Netlist
```

### Yosys Result

```text
19346 cells
1800 $_AND_
8192 $_DFFE_PP_
8420 $_MUX_
172 $_NOT_
385 $_OR_
319 $_SDFFE_PN0P_
2 $_SDFF_PN0_
56 $_XOR_
```

### Hierarchy

```text
5 submodules
1 ram_slave
1 master
1 gpio_slave
2 decoder
```

> The RAM is synthesized into flip-flop/multiplexer logic because no ASIC memory macro/library is provided. Therefore, the Yosys cell count should not be interpreted as the area of an ASIC implementation with a compiled SRAM macro.

## Synthesized-Netlist Verification

- The Yosys-generated netlist was re-elaborated successfully.
- The top-level testbench was adapted for the synthesized hierarchy.
- Functional simulation was performed on the synthesized netlist.

### Result

**All 11 top-level functional tests passed.**

This confirms that the synthesized RTL netlist preserves the expected functional behavior of the original RTL design.

## Tools Used

## Results at a Glance

| Category | Result |
|---|---|
| Top-Level Functional Tests | **11/11 PASS** |
| RTL Lint | **0 warnings / 0 errors** |
| Yosys Synthesis | **PASS** |
| Netlist Elaboration | **PASS** |
| Synthesized-Netlist Simulation | **11/11 PASS** |
| Clock | **100 MHz** |
| Post-Synthesis WNS | **+5.415 ns** |
| Post-Implementation WNS | **+4.366 ns** |
| Setup Violations | **0** |
| Hold Violations | **0** |
| FPGA LUTs | **204 implemented** |
| FPGA FFs | **354 implemented** |
| On-Chip Power | **0.136 W** |

## Documentation / Results

### Top-Level Block Diagram

<table>
  <tr>
    <td align="center">
      <img width="994" height="1000" alt="1master" src="https://github.com/user-attachments/assets/6a90bdbf-a9eb-4c7a-a742-f0f23c6bf5a3" /><br/>
      <small>AXI-4 lite Master</small>
    </td>
    <td align="center">
      <img width="1029" height="1000" alt="1slave" src="https://github.com/user-attachments/assets/bdc10f60-b8a8-4c04-850c-5ad25684b608" /><br/>
      <small>AXI-4 lite Slave</small>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="2963" height="800" alt="addr decoder" src="https://github.com/user-attachments/assets/956a5cb8-66f5-4c56-82c4-2ecacdedf680" /><br/>
      <small>AXI-4 lite Address decoder</small>
    </td>
    <td align="center">
      <img width="2118" height="800" alt="1ramslave" src="https://github.com/user-attachments/assets/f9534f0a-d6d6-490d-b24a-3b65bea61c29" /><br/>
      <small>AXI-4 lite RAM slave</small>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="1081" height="1000" alt="1gpio" src="https://github.com/user-attachments/assets/5be68104-b962-4d8e-9153-410d67c8e5e3" /><br/>
      <small>AXI-4 lite Address decoder</small>
    </td>
    <td align="center">
      <img width="1396" height="1000" alt="if" src="https://github.com/user-attachments/assets/f12c9522-677e-492b-8a90-475fcc0cd376" /><br/>
      <small>AXI-4 lite Interface</small>
    </td>
  </tr>
</table>

<table align="center">
    <td align="center">
      <img width="679" height="1500" alt="1top" src="https://github.com/user-attachments/assets/674c2bee-b575-47dd-b7ab-03f20254eeaf" /><br/>
      <small>AXI-4 lite Top</small>
    </td>
</table>

### Functional Simulation Waveform

**[Insert AXI4-Lite top-level waveform here]**

`results/simulation/AXI4-Lite TOP waveform.png`

### Synthesis Utilization

**[Insert synthesis utilization report here]**

`results/synthesis/utilization_rpt.png`

### Implementation Utilization

**[Insert implementation utilization report here]**

`results/implementation/utilization_rpt.png`

### Timing Results

**[Insert timing report here]**

`results/implementation/timing_rpt.png`

### Power Results

**[Insert power report here]**

`results/implementation/power_rpt.png`

## Project Workflow

```text
Specification
     ↓
AXI4-Lite Interface Definition
     ↓
RTL Module Development
     ↓
Module-Level Verification
     ↓
Top-Level Integration
     ↓
Top-Level Functional Verification
     ↓
RTL Lint
     ↓
Vivado Synthesis
     ↓
Timing / Power / Utilization Analysis
     ↓
Yosys Synthesis
     ↓
Synthesized-Netlist Simulation
     ↓
Results Documentation
```

## Key Learning Outcomes

- Practical implementation of the **AXI4-Lite protocol**.
- Understanding of independent AXI read/write channels.
- Memory-mapped peripheral architecture.
- Address decoding and peripheral selection.
- Byte-enable / `WSTRB` handling.
- AXI response and error handling.
- RTL module-level and subsystem-level verification.
- SystemVerilog interface and package usage.
- RTL linting with Verilator.
- FPGA-oriented synthesis and timing analysis.
- ASIC-oriented synthesis using Yosys.
- Synthesized-netlist functional verification.
- Hardware design project organization using Git and GitHub.

## Conclusion

- Successfully implemented a compact **AXI4-Lite RTL subsystem with RAM and GPIO peripherals**.
- The design demonstrates the complete path from:
  - RTL architecture
  - Functional verification
  - Linting
  - Synthesis
  - Timing analysis
  - Power analysis
  - Synthesized-netlist verification
- The final top-level design successfully passes **11/11 functional tests**.
- RTL linting completes with **zero warnings and zero errors**.
- Both Vivado and Yosys synthesis flows successfully process the design.
- The project provides a practical demonstration of **digital design, AXI4-Lite protocol implementation, verification, and ASIC-oriented RTL development**.

## Author

**Bibhu Asish Panda**

**Project:** AXI4-Lite ASIC RTL Subsystem with RAM and GPIO Peripherals
