#!/bin/bash

#Script to try combinations of implementation strategies.
#
#The normal order is
#synth_design
#opt_design
#place_design
#phys_opt_design
#route_design
#phys_opt_design

# To get a better idea of the influence of this exploration, you can choose to continue all the implementation steps after each opt_design attempt.
fullbuilds=yes

OPT_STRATS="Explore ExploreArea ExploreWithRemap ExploreSequentialArea"

if [ "$#" -ne 2 ]; then
    echo "Usage: route_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

#default strategies for downstream implementation steps
ps="Explore"
pos="Explore"
rs="Explore"

for os in $OPT_STRATS; do
   echo "OPT strategy: $os"
    wdir=$wdir_base/strategies/$os
    mkdir -p $wdir
    script=$wdir/vivado_script.tcl
    
    #Open the starting checkpoint
    echo "open_checkpoint $starting_checkpoint" > $script

    #Get a function for making nice short timing summaries for in the logs:
    echo "source $scriptdir/timing_summary_parser.tcl" >> $script
    
    #Optimize the design
    echo "opt_design -directive $os" >> $script
    echo "write_checkpoint $wdir/opt_design.dcp -force" >> $script
    echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_design.rpt" >> $script
    echo "getTimingInfo" >> $script
    echo "set myTns [get_property SLACK [get_timing_paths ]]" >> $script
    echo "puts post-netlist-optimization TNS: |\$myTns|" >> $script
    
    if [ $fullbuilds == "yes" ]; then
      echo "Performing a full build"
    
      #Placement & physical optimization (with default directives)
      echo "place_design -directive $ps" >> $script
      echo "write_checkpoint $wdir/placed_design.dcp -force" >> $script
      echo "phys_opt_design -directive $pos" >> $script
      echo "write_checkpoint $wdir/phys_opt_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_phys_opt_design.rpt" >> $script
      echo "getTimingInfo" >> $script
      echo "set myTns [get_property SLACK [get_timing_paths ]]" >> $script
      echo "puts post-fullbuild-physopt TNS: |\$myTns|" >> $script
      
      #Routing & physical optimization (with default directives)
      echo "route_design -directive $rs" >> $script
      echo "write_checkpoint $wdir/route_design.dcp -force" >> $script
      echo "phys_opt_design -directive $pos" >> $script
      echo "write_checkpoint $wdir/opt_routed_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_routed_design.rpt" >> $script
      echo "getTimingInfo" >> $script
      echo "set myTns [get_property SLACK [get_timing_paths ]]" >> $script
      echo "puts post-fullbuild-optrouted TNS: |\$myTns|" >> $script
    fi
    
    #Run Vivado with the created script
    vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
done

