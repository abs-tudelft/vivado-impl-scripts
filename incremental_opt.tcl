
#Get a function for making nice short timing summaries for in the logs:
set script_path [ file dirname [ file normalize [ info script ] ] ]
source $script_path/timing_summary_parser.tcl

puts "Timing info:"
getTimingInfo

#incremental optimizations, taken from the Xilinx Design Analysis and Closure Techniques manual (UG906):
if {[get_property SLACK [get_timing_paths ]] <= -0.5} {
  puts "The design has significant negative slack. Meeting timing seems highly unlikely and the script will not attempt incremental P&R optimizations."
  break
}

set basename incremental_opt_

puts "Attempting incremental P&R optimizations."
for {set i 0} {$i < 3} {incr i} {
  if {[get_property SLACK [get_timing_paths ]] >= 0} {break}; #stop if timing is met
  place_design -post_place_opt
  phys_opt_design -directive Explore
  append checkpointname $basename iteration $i _opt1
  write_checkpoint $checkpointname.dcp -force
  report_timing_summary -quiet -max_paths 10 -file $checkpointname.rpt
  getTimingInfo
  route_design -directive Explore -tns_cleanup
  phys_opt_design -directive AggressiveExplore
  append checkpointname2 $basename iteration $i _opt2
  write_checkpoint $checkpointname2.dcp -force
  report_timing_summary -quiet -max_paths 10 -file $checkpointname2.rpt
  getTimingInfo
}
