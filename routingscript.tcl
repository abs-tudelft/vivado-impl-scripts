# Get the nets in the top 10 critical paths, assign to $preRoutes
set preRoutes [get_nets -of [get_timing_paths -max_paths 10]]
# route $preRoutes first with the smallest possible delay
route_design -nets [get_nets $preRoutes] -delay
# preserve the routing for $preRoutes and continue with the rest of the design
route_design -preserve 



#to combat congestion:
# Unroute all the nets in u0/u1, and route the critical nets first
route_design -unroute [get_nets congested_component/*]
route_design -delay -nets [get_nets $myCritNets]
route_design -preserve

