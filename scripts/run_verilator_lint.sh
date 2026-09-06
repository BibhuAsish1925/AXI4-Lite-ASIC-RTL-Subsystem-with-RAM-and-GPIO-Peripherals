#!/usr/bin/env bash
set -e

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
