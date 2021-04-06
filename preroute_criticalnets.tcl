# Run me before routing, to pre-route and fixate the more difficult nets first

# Get the nets in the top 10 critical paths, assign to $preRoutes
set preRoutes [get_nets -of [get_timing_paths -max_paths 10]]
# route $preRoutes first with the smallest possible delay
route_design -nets [get_nets $preRoutes] -delay
# preserve the routing for $preRoutes and continue with the rest of the design
route_design -preserve 



