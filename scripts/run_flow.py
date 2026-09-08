#!/usr/bin/env python3

"""
AXI4-Lite ASIC RTL automated verification/synthesis flow.

Runs:
    1. Project structure checks
    2. Verilator RTL lint
    3. Yosys synthesis
    4. Synthesized-netlist simulation
    5. Optional Vivado Tcl flow

Usage:
    python automation/run_flow.py
    python automation/run_flow.py --vivado
"""

from pathlib import Path
import argparse
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent


def run_command(command, name):
    print()
    print("=" * 60)
    print(name)
    print("=" * 60)
    print("Command:", " ".join(command))
    print()

    result = subprocess.run(command, cwd=ROOT)

    if result.returncode != 0:
        print()
        print(f"[FAIL] {name}")
        sys.exit(result.returncode)

    print()
    print(f"[PASS] {name}")


def check_files():
    required = [
        "rtl/axi4_lite_pkg.sv",
        "rtl/axi4_lite_if.sv",
        "rtl/axi4_lite_master.sv",
        "rtl/axi4_lite_slave.sv",
        "rtl/axi4_lite_addr_decoder.sv",
        "rtl/ram_slave.sv",
        "rtl/gpio_slave.sv",
        "rtl/axi4_lite_interconnect.sv",
        "rtl/axi4_lite_top.sv",

        "tb/tb_axi4_lite_top.sv",

        "constraints/axi4_lite_top.xdc",

        "scripts/yosys_synth.ys",
        "scripts/run_verilator_lint.sh",
        "scripts/run_yosys_netlist_sim.sh",
    ]

    missing = []

    for item in required:
        path = ROOT / item

        if path.exists():
            print(f"[PASS] {item}")
        else:
            print(f"[FAIL] {item}")
            missing.append(item)

    if missing:
        print()
        print("Missing required project files:")
        for item in missing:
            print(f"  - {item}")

        sys.exit(1)


def run_verilator():
    files = [
        "rtl/axi4_lite_pkg.sv",
        "rtl/axi4_lite_if.sv",
        "rtl/axi4_lite_master.sv",
        "rtl/axi4_lite_slave.sv",
        "rtl/axi4_lite_addr_decoder.sv",
        "rtl/ram_slave.sv",
        "rtl/gpio_slave.sv",
        "rtl/axi4_lite_interconnect.sv",
        "rtl/axi4_lite_top.sv",
    ]

    command = [
        "verilator",
        "--lint-only",
        "--Wall",
        "--top-module",
        "axi4_lite_top",
    ]

    command.extend(files)

    run_command(command, "Verilator RTL Lint")


def run_yosys():
    command = [
        "yosys",
        "-s",
        "scripts/yosys_synth.ys",
    ]

    run_command(command, "Yosys Synthesis")


def run_netlist_sim():
    command = [
        "bash",
        "scripts/run_yosys_netlist_sim.sh",
    ]

    run_command(command, "Synthesized Netlist Simulation")


def run_vivado():
    command = [
        "vivado",
        "-mode",
        "batch",
        "-source",
        "automation/vivado_flow.tcl",
    ]

    run_command(command, "Vivado Tcl Flow")


def main():
    parser = argparse.ArgumentParser(
        description="AXI4-Lite ASIC RTL automated design flow"
    )

    parser.add_argument(
        "--vivado",
        action="store_true",
        help="Run Vivado synthesis/implementation Tcl flow",
    )

    args = parser.parse_args()

    print()
    print("=" * 60)
    print(" AXI4-Lite ASIC RTL AUTOMATION FLOW")
    print("=" * 60)

    print()
    print("[1/5] Checking project structure...")
    check_files()

    run_verilator()
    run_yosys()
    run_netlist_sim()

    if args.vivado:
        run_vivado()

    print()
    print("=" * 60)
    print(" AUTOMATION FLOW COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print()

    print("RTL lint              : PASS")
    print("Yosys synthesis       : PASS")
    print("Netlist simulation    : PASS")

    if args.vivado:
        print("Vivado Tcl flow       : PASS")
    else:
        print("Vivado Tcl flow       : NOT RUN")

    print()


if __name__ == "__main__":
    main()