# Vivado implementation scripts

This repository contains a number of scripts that aid in meeting timing constraints in Vivado.

## Exploring different vivado implementation strategies
Note: in a normal situation, it does not make sense to try all kinds of different optimization strategies. 
The _Explore_ directive usually achieves _very_ good results and can easily be one of the best performing ones even after trying out many strategies with this script.
So if your design does not meet timing, go back to your source and improve the critical parts of your design there.
However, if you have a finalized design, or have components that you cannot change, and are very close to meeting timing, you can give these scripts a try instead of manually starting all kinds of runs.

The Vivado build process consists of the following steps:
```
synth_design
opt_design
place_design
phys_opt_design
route_design
phys_opt_design
```
Each of these steps has a number of different _directives_ (or strategies), leading to a very large search space (6 steps, ~5 strategies each => 15625 combinations).
Combined with the very long runtimes (even small builds easily take 1 hour), trying out all combinations is not feasible. 
It is also not very useful.
After each step, Vivado can report the timing status. This way, we can select one of a few of the best performing strategies and continue with these.
In this repo, the scripts assume you're starting from a synthesized design and then break up the rest of the implementation process into 3 parts; optimization, placement, and routing
after placement and routing, a physical optimization step is performed.

## Scripted incremental optimizations
The Vivado build process allows for incremental improvements to a placed and routed design.
Note that in my experience, often these incremental runs actually degrade timing, and the best results are achieved when going through the build process as listed above sequentially.
However, for some designs it might help.

The script tries to iterate optimizing placement (after routing, timing driven), then performs new routing and optimization passes.
It comes from the Xilinx Design Analysis and Closure Techniques manual (UG906).
Source the script from vivado after opening your design checkpoint.
You can modify the script for the number of iterations.
Using the script only makes sense if the negative slack is very small (less than 200 ps, according to Xilinx).


## Trying out different pblocks
TODO: create a script that takes a list of pblocks and tries them


## Routing critical nets first
The preroute_criticalnets.tcl file contains commands (also from the Xilinx Design Analysis and Closure Techniques manual (UG906)) that can help routing critical nets first.
After using this script, the user can run post-route optimization manually or run the incremental optimization script.

## Fix congestion after routing
The postroute_congestionfixer.tcl file contains commands (also from the Xilinx Design Analysis and Closure Techniques manual (UG906)) that can help dealing with routing congestion.
It finds the critical nets in the design, unroutes the nets in the (user specified!) congested component, then routes the critical nets first (only in the specified components, because the rest of the design is already routed).
The script currently gets the critical nets -after- routing. In this situation, the congestion already plays an important role.
It would be better to get the most critical nets before routing.
After using this script, the user can run post-route optimization manually or run the incremental optimization script.
