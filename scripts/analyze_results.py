#!/usr/bin/env python3

from pathlib import Path
import re
import sys


# ==============================================================
# AXI4-Lite ASIC RTL Subsystem
# Results Analyzer
# ==============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

RESULTS_DIR = PROJECT_ROOT / "results"


# ==============================================================
# Utility functions
# ==============================================================

def read_text_file(path: Path) -> str:
    """Read a text file safely."""

    if not path.is_file():
        return ""

    return path.read_text(
        encoding="utf-8",
        errors="replace",
    )


def find_number(pattern: str, text: str):
    """Return the first regex capture group as an integer."""

    match = re.search(pattern, text)

    if match:
        return int(match.group(1))

    return None


# ==============================================================
# RTL regression analysis
# ==============================================================

def analyze_rtl_regression():

    regression_dir = RESULTS_DIR / "rtl_regression"

    print()
    print("RTL REGRESSION")
    print("-" * 70)

    if not regression_dir.is_dir():

        print("  Status : NOT RUN")
        return

    test_dirs = sorted(
        path
        for path in regression_dir.iterdir()
        if path.is_dir()
    )

    if not test_dirs:

        print("  Status : NOT RUN")
        return

    passed = 0
    failed = 0
    incomplete = 0

    for test_dir in test_dirs:

        simulation_log = test_dir / "simulation.log"
        compile_log = test_dir / "compile.log"

        name = test_dir.name

        if not compile_log.is_file():

            print(f"  {name:<35} NOT RUN")
            incomplete += 1
            continue

        if not simulation_log.is_file():

            compile_output = read_text_file(compile_log)

            if "error" in compile_output.lower():

                print(f"  {name:<35} COMPILE FAIL")
                failed += 1

            else:

                print(f"  {name:<35} INCOMPLETE")
                incomplete += 1

            continue

        output = read_text_file(simulation_log)

        if "[FAIL]" in output or "%Error" in output:

            print(f"  {name:<35} FAIL")
            failed += 1

        else:

            print(f"  {name:<35} PASS")
            passed += 1

    total = passed + failed + incomplete

    print()
    print(f"  Tests discovered : {total}")
    print(f"  Passed           : {passed}")
    print(f"  Failed           : {failed}")
    print(f"  Incomplete       : {incomplete}")

    if failed == 0 and incomplete == 0:

        print("  Overall status   : PASS")

    elif failed > 0:

        print("  Overall status   : FAIL")

    else:

        print("  Overall status   : INCOMPLETE")


# ==============================================================
# Yosys synthesis analysis
# ==============================================================

def analyze_yosys():

    print()
    print("YOSYS SYNTHESIS")
    print("-" * 70)

    possible_logs = [
        RESULTS_DIR / "yosys_synthesis.log",
        RESULTS_DIR / "yosys_synth.log",
        RESULTS_DIR / "yosys.log",
    ]

    log_path = None

    for candidate in possible_logs:

        if candidate.is_file():

            log_path = candidate
            break

    if log_path is None:

        # The current project may have the synthesis log outside
        # the repository results directory.
        print("  Status : LOG NOT FOUND")
        return

    text = read_text_file(log_path)

    if "ERROR" in text or "Error:" in text:

        print("  Status : FAIL")

    else:

        print("  Status : PASS")

    print(f"  Log    : {log_path}")

    # ----------------------------------------------------------
    # Extract final cell count if available
    # ----------------------------------------------------------

    cell_count = find_number(
        r"Number of cells:\s+([0-9]+)",
        text,
    )

    if cell_count is not None:

        print(f"  Cells  : {cell_count}")

    # ----------------------------------------------------------
    # Extract submodule count if available
    # ----------------------------------------------------------

    submodule_count = find_number(
        r"Number of cells:\s+[0-9]+\s+\((?:.*)\)",
        text,
    )

    # ----------------------------------------------------------
    # Extract common cell types
    # ----------------------------------------------------------

    patterns = {
        "$_AND_": r"\$_AND_\s+([0-9]+)",
        "$_DFFE_PP_": r"\$_DFFE_PP_\s+([0-9]+)",
        "$_MUX_": r"\$_MUX_\s+([0-9]+)",
        "$_NOT_": r"\$_NOT_\s+([0-9]+)",
        "$_OR_": r"\$_OR_\s+([0-9]+)",
        "$_XOR_": r"\$_XOR_\s+([0-9]+)",
    }

    for cell_name, pattern in patterns.items():

        count = find_number(pattern, text)

        if count is not None:

            print(f"  {cell_name:<12} : {count}")


# ==============================================================
# Netlist simulation analysis
# ==============================================================

def analyze_netlist_simulation():

    print()
    print("SYNTHESIZED-NETLIST SIMULATION")
    print("-" * 70)

    possible_logs = [
        RESULTS_DIR / "netlist_sim" / "yosys_netlist_sim.log",
        RESULTS_DIR / "yosys_netlist_sim.log",
    ]

    log_path = None

    for candidate in possible_logs:

        if candidate.is_file():

            log_path = candidate
            break

    if log_path is None:

        print("  Status : LOG NOT FOUND")
        return

    text = read_text_file(log_path)

    if (
        "[PASS] AXI4-Lite top-level test completed successfully"
        in text
    ):

        print("  Status : PASS")

    elif "[PASS]" in text and "$finish called" in text:

        print("  Status : PASS")

    elif "[FAIL]" in text or "%Error" in text:

        print("  Status : FAIL")

    else:

        print("  Status : INCOMPLETE")

    print(f"  Log    : {log_path}")


# ==============================================================
# Vivado timing analysis
# ==============================================================

def analyze_vivado_timing():

    print()
    print("VIVADO TIMING")
    print("-" * 70)

    timing_log = (
        PROJECT_ROOT
        / "vivado"
        / "timing"
        / "vivado_timing_summary.txt"
    )

    if not timing_log.is_file():

        print("  Status : REPORT NOT FOUND")
        return

    text = read_text_file(timing_log)

    # ----------------------------------------------------------
    # WNS
    # ----------------------------------------------------------

    wns_match = re.search(
        r"WNS(?:\s*\(ns\))?.*?([+-]?[0-9]+\.[0-9]+)",
        text,
        re.IGNORECASE,
    )

    # ----------------------------------------------------------
    # TNS
    # ----------------------------------------------------------

    tns_match = re.search(
        r"TNS(?:\s*\(ns\))?.*?([+-]?[0-9]+\.[0-9]+)",
        text,
        re.IGNORECASE,
    )

    if wns_match:

        print(f"  WNS : {wns_match.group(1)} ns")

    else:

        print("  WNS : not parsed")

    if tns_match:

        print(f"  TNS : {tns_match.group(1)} ns")

    else:

        print("  TNS : not parsed")

    if "0 failing" in text.lower():

        print("  Status : PASS")

    else:

        print("  Status : SEE REPORT")


# ==============================================================
# Main analysis
# ==============================================================

def main():

    print("=" * 70)
    print(" AXI4-LITE ASIC RTL SUBSYSTEM")
    print(" RESULTS ANALYZER")
    print("=" * 70)

    print()
    print("Project root:")
    print(f"  {PROJECT_ROOT}")

    print()
    print("Results directory:")
    print(f"  {RESULTS_DIR}")

    analyze_rtl_regression()
    analyze_yosys()
    analyze_netlist_simulation()
    analyze_vivado_timing()

    print()
    print("=" * 70)
    print(" ANALYSIS COMPLETE")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    sys.exit(main())
