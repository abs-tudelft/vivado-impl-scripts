#incremental optimizations, taken from the Xilinx Design Analysis and Closure Techniques manual (UG906):
if {[get_property SLACK [get_timing_paths ]] <= -0.5} {
  puts "The design has significant negative slack. Meeting timing seems highly unlikely and the script will not attempt incremental P&R optimizations."
  break
}

for {set i 0} {$i < 3} {incr i} {
  if {[get_property SLACK [get_timing_paths ]] >= 0} {break}; #stop if timing is met

  place_design -post_place_opt
  phys_opt_design -directive Explore
  route_design -directive Explore -tns_cleanup
  phys_opt_design -directive AggressiveExplore
}
