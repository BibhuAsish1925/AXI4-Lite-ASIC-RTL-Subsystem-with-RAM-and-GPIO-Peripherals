#!/usr/bin/env bash
set -e

verilator \
  --binary \
  --timing \
  --top-module tb_axi4_lite_top \
  -Wno-TIMESCALEMOD \
  netlist/axi4_lite_top_yosys.v \
  tb/tb_axi4_lite_top_netlist.sv \
  -o axi4_yosys_sim

./obj_dir/axi4_yosys_sim
