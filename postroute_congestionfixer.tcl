# Run me after routing, to combat congestion:
# Unroute all the nets in congested_component, and route the critical nets first
# Usage: postroute.tcl <congested component>

set congested_component [lindex $argv 0]

# Normally, you would run this command -before- routing, because then the congestion is not a factor yet (only the placement and fanout etc.)
# Also, it is possible these nets are not in the congested component (but then the design has other problems that are more severe)
set myCritNets [get_nets -of [get_timing_paths -max_paths 10]]

route_design -unroute [get_nets $congested_component/*]
route_design -delay -nets [get_nets $myCritNets]
route_design -preserve

