#!/usr/bin/env bash

set -euo pipefail

# ==============================================================
# AXI4-Lite ASIC RTL Subsystem
# Yosys Synthesized-Netlist Simulation Runner
# ==============================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NETLIST="$ROOT/results/yosys/axi4_lite_top_yosys.v"
TB="$ROOT/tb/tb_axi4_lite_top_netlist.sv"

RESULTS_DIR="$ROOT/results/netlist_sim"
LOG_FILE="$RESULTS_DIR/yosys_netlist_sim.log"

BUILD_DIR="/tmp/axi4_lite_yosys_netlist_sim"

# ==============================================================
# Header
# ==============================================================

echo "======================================================================"
echo " AXI4-LITE ASIC RTL SUBSYSTEM"
echo " YOSYS NETLIST SIMULATION"
echo "======================================================================"

echo
echo "Project root:"
echo "  $ROOT"

echo
echo "Synthesized netlist:"
echo "  $NETLIST"

echo
echo "Testbench:"
echo "  $TB"

echo
echo "Results directory:"
echo "  $RESULTS_DIR"

echo
echo "Simulation log:"
echo "  $LOG_FILE"

# ==============================================================
# Prepare directories
# ==============================================================

mkdir -p "$RESULTS_DIR"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ==============================================================
# Check required files
# ==============================================================

if [[ ! -f "$NETLIST" ]]; then
    echo
    echo "[FAIL] Synthesized netlist not found:"
    echo "  $NETLIST"
    echo
    echo "Run first:"
    echo "  ./scripts/run_yosys_synth.sh"
    exit 1
fi

if [[ ! -f "$TB" ]]; then
    echo
    echo "[FAIL] Netlist testbench not found:"
    echo "  $TB"
    exit 1
fi

# ==============================================================
# Check native WSL tools
# ==============================================================

if ! command -v verilator >/dev/null 2>&1; then
    echo
    echo "[FAIL] Native WSL Verilator is not available."
    exit 1
fi

if ! command -v make >/dev/null 2>&1; then
    echo
    echo "[FAIL] Native WSL make is not available."
    echo
    echo "Install it with:"
    echo "  sudo apt update"
    echo "  sudo apt install make"
    exit 1
fi

echo
echo "Native WSL build tools:"
echo "  $(verilator --version)"
echo "  $(make --version | head -n 1)"

# ==============================================================
# Compile synthesized netlist
# ==============================================================

echo
echo "Compiling synthesized netlist with native WSL Verilator..."

verilator \
    --binary \
    --timing \
    --top-module tb_axi4_lite_top \
    -Wno-TIMESCALEMOD \
    -Wno-INITIALDLY \
    -Wno-UNOPTFLAT \
    --Mdir "$BUILD_DIR/obj_dir" \
    -o "$BUILD_DIR/axi4_yosys_sim" \
    "$NETLIST" \
    "$TB"

echo
echo "[PASS] Netlist compilation successful."

# ==============================================================
# Run simulation
# ==============================================================

echo
echo "Running synthesized-netlist simulation..."

"$BUILD_DIR/axi4_yosys_sim" \
    2>&1 | tee "$LOG_FILE"

# ==============================================================
# Check simulation result
# ==============================================================

if grep -q "\[PASS\] AXI4-Lite top-level test completed successfully" \
    "$LOG_FILE"; then

    echo
    echo "======================================================================"
    echo " NETLIST SIMULATION COMPLETE"
    echo "======================================================================"

    echo
    echo "[PASS] Synthesized-netlist simulation completed successfully."

    echo
    echo "Simulation log:"
    echo "  $LOG_FILE"

    exit 0
fi

# ==============================================================
# Failure
# ==============================================================

echo
echo "======================================================================"
echo " NETLIST SIMULATION FAILED"
echo "======================================================================"

echo
echo "[FAIL] Synthesized-netlist test did not report PASS."

echo
echo "Simulation log:"
echo "  $LOG_FILE"

exit 1
