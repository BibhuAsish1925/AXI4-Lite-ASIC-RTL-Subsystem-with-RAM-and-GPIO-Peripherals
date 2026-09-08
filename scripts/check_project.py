#!/usr/bin/env python3

from pathlib import Path
import sys


# ==============================================================
# AXI4-Lite ASIC RTL Subsystem
# Project Health Checker
# ==============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent


# ==============================================================
# Required repository files
# ==============================================================

REQUIRED_FILES = {
    "RTL sources": [
        "rtl/axi4_lite_pkg.sv",
        "rtl/axi4_lite_if.sv",
        "rtl/axi4_lite_master.sv",
        "rtl/axi4_lite_slave.sv",
        "rtl/axi4_lite_addr_decoder.sv",
        "rtl/ram_slave.sv",
        "rtl/gpio_slave.sv",
        "rtl/axi4_lite_interconnect.sv",
        "rtl/axi4_lite_top.sv",
    ],

    "Testbenches": [
        "tb/tb_axi4_lite_master.sv",
        "tb/tb_axi4_lite_slave.sv",
        "tb/tb_axi4_lite_addr_decoder.sv",
        "tb/tb_ram_slave.sv",
        "tb/tb_gpio_slave.sv",
        "tb/tb_axi4_lite_interconnect.sv",
        "tb/tb_axi4_lite_top.sv",
        "tb/tb_axi4_lite_top_netlist.sv",
    ],

    "Constraints": [
        "constraints/axi4_lite_top.xdc",
    ],

    "Existing scripts": [
        "scripts/run_verilator_lint.sh",
        "scripts/run_yosys_netlist_sim.sh",
        "scripts/yosys_synth.ys",
    ],

    "Vivado project": [
        "vivado/axi4.xpr",
    ],

    "Documentation / repository files": [
        "README.md",
        "LICENSE",
        ".gitignore",
        ".gitattributes",
    ],
}


# ==============================================================
# File check
# ==============================================================

def check_file(relative_path: str) -> bool:
    """Return True if the required file exists."""

    return (PROJECT_ROOT / relative_path).is_file()


# ==============================================================
# Section checker
# ==============================================================

def check_section(title: str, files: list[str]) -> tuple[int, int]:

    print(f"\n{title}")
    print("-" * len(title))

    passed = 0

    for relative_path in files:

        if check_file(relative_path):
            print(f"  [PASS] {relative_path}")
            passed += 1
        else:
            print(f"  [FAIL] {relative_path}")

    return passed, len(files)


# ==============================================================
# Main
# ==============================================================

def main() -> int:

    print("=" * 70)
    print(" AXI4-LITE ASIC RTL SUBSYSTEM")
    print(" PROJECT HEALTH CHECK")
    print("=" * 70)

    print("\nProject root:")
    print(f"  {PROJECT_ROOT}")

    total_passed = 0
    total_files = 0
    failed_sections = 0

    for title, files in REQUIRED_FILES.items():

        passed, total = check_section(title, files)

        total_passed += passed
        total_files += total

        if passed != total:
            failed_sections += 1

    print("\n" + "=" * 70)
    print(" SUMMARY")
    print("=" * 70)

    print(f"\nFiles checked : {total_files}")
    print(f"Files present : {total_passed}")
    print(f"Files missing : {total_files - total_passed}")

    if failed_sections == 0:

        print("\nPROJECT STATUS: PASS")
        print("All required project files are present.")

        return 0

    print("\nPROJECT STATUS: FAIL")
    print("One or more required project files are missing.")

    return 1


if __name__ == "__main__":
    sys.exit(main())
