# ==============================================================
# AXI4-Lite ASIC RTL Subsystem
# Vivado automated synthesis / implementation flow
# ==============================================================

set project_dir [file normalize "./vivado"]
set project_file [file normalize "./vivado/axi4.xpr"]

puts ""
puts "=============================================================="
puts " AXI4-Lite Vivado Automated Flow"
puts "=============================================================="
puts ""

if {![file exists $project_file]} {
    puts "ERROR: Vivado project not found:"
    puts "  $project_file"
    exit 1
}

puts "Opening Vivado project..."
open_project $project_file

puts ""
puts "Project: [current_project]"
puts "Top module: [get_property top [get_filesets sources_1]]"

# --------------------------------------------------------------
# Synthesis
# --------------------------------------------------------------

puts ""
puts "--------------------------------------------------------------"
puts " Running synthesis"
puts "--------------------------------------------------------------"

launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]

puts ""
puts "Synthesis status: $synth_status"

if {$synth_status ne "synth_design Complete!"} {
    puts "ERROR: Synthesis failed."
    exit 1
}

open_run synth_1

file mkdir "./vivado/reports"

puts ""
puts "Generating post-synthesis reports..."

report_utilization \
    -file "./vivado/reports/post_synth_utilization.txt"

report_timing_summary \
    -file "./vivado/reports/post_synth_timing.txt"

check_timing \
    -file "./vivado/reports/post_synth_check_timing.txt"

# --------------------------------------------------------------
# Implementation
# --------------------------------------------------------------

puts ""
puts "--------------------------------------------------------------"
puts " Running implementation"
puts "--------------------------------------------------------------"

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]

puts ""
puts "Implementation status: $impl_status"

if {$impl_status ne "write_bitstream Complete!"} {
    puts "ERROR: Implementation did not complete successfully."
    exit 1
}

open_run impl_1

puts ""
puts "Generating post-implementation reports..."

report_utilization \
    -file "./vivado/reports/post_impl_utilization.txt"

report_timing_summary \
    -file "./vivado/reports/post_impl_timing.txt"

check_timing \
    -file "./vivado/reports/post_impl_check_timing.txt"

report_drc \
    -file "./vivado/reports/post_impl_drc.txt"

puts ""
puts "=============================================================="
puts " Vivado automated flow completed"
puts "=============================================================="
puts ""

close_project