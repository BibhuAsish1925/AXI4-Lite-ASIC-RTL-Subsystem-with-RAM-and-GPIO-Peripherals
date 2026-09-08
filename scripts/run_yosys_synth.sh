#!/usr/bin/env bash

set -euo pipefail


# ==============================================================
# AXI4-Lite ASIC RTL Subsystem
# Yosys Synthesis Runner
# ==============================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RESULTS_DIR="$ROOT/results/yosys"

mkdir -p "$RESULTS_DIR"


# ==============================================================
# Configuration
# ==============================================================

DOCKER_IMAGE="ghcr.io/librelane/librelane:3.0.11"

LOG_FILE="$RESULTS_DIR/yosys_synthesis.log"

NETLIST="$RESULTS_DIR/axi4_lite_top_yosys.v"


# ==============================================================
# Header
# ==============================================================

echo "======================================================================"
echo " AXI4-LITE ASIC RTL SUBSYSTEM"
echo " YOSYS SYNTHESIS"
echo "======================================================================"

echo
echo "Project root:"
echo "  $ROOT"

echo
echo "Docker image:"
echo "  $DOCKER_IMAGE"

echo
echo "Output directory:"
echo "  $RESULTS_DIR"

echo
echo "Netlist:"
echo "  $NETLIST"

echo
echo "Log:"
echo "  $LOG_FILE"


# ==============================================================
# Check Docker
# ==============================================================

if ! command -v docker >/dev/null 2>&1; then

    echo
    echo "[FAIL] Docker is not installed or not available."

    exit 1

fi


# ==============================================================
# Check synthesis script
# ==============================================================

if [[ ! -f "$ROOT/scripts/yosys_synth.ys" ]]; then

    echo
    echo "[FAIL] Missing Yosys synthesis script:"
    echo "  $ROOT/scripts/yosys_synth.ys"

    exit 1

fi


# ==============================================================
# Run Yosys
# ==============================================================

echo
echo "Running Yosys..."

docker run --rm \
    --entrypoint bash \
    -v "$ROOT:/work" \
    "$DOCKER_IMAGE" \
    -lc "yosys -s /work/scripts/yosys_synth.ys" \
    2>&1 | tee "$LOG_FILE"


# ==============================================================
# Verify netlist
# ==============================================================

if [[ ! -f "$NETLIST" ]]; then

    echo
    echo "[FAIL] Expected synthesized netlist was not generated:"
    echo "  $NETLIST"

    exit 1

fi


# ==============================================================
# Summary
# ==============================================================

echo
echo "======================================================================"
echo " YOSYS SYNTHESIS COMPLETE"
echo "======================================================================"

echo
echo "[PASS] Yosys synthesis completed."

echo
echo "Generated netlist:"
echo "  $NETLIST"

echo
echo "Synthesis log:"
echo "  $LOG_FILE"

echo
echo "======================================================================"
