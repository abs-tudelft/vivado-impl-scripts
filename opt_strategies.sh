#!/bin/bash

#Script to try combinations of netlist optimization strategies.

# To get a better idea of the influence of this exploration, you can choose to continue all the implementation steps after each opt_design attempt.
fullbuilds=no

OPT_STRATS="Explore ExploreArea ExploreWithRemap ExploreSequentialArea"

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    echo "Usage: route_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    echo "add \"dry\" to perform a dry-run (randomly generate results)"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ $3 == "dry" ]; then
  echo "performing dry run"
  dryrun=yes
else
  dryrun=no
fi

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
  
  if [ -f $wdir/route_wns.txt ] && [ $(cat $wdir/route_wns.txt) != "" ]; then
      echo "Pre-existing results found, skipping..."
    else
      
      if [ $dryrun == "yes" ]; then
        #Generate random WNS and log to a file
        echo "-0.$(($RANDOM%999))" > $wdir/opt_wns.txt
      else
  
      #Open the starting checkpoint
      echo "open_checkpoint $starting_checkpoint" > $script

      #Get a function for making nice short timing summaries for in the logs:
      echo "source $scriptdir/timing_summary_parser.tcl" >> $script
      
      #Optimize the design
      echo "opt_design -directive $os" >> $script
      echo "write_checkpoint $wdir/opt_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_design.rpt" >> $script
      echo "getTimingInfo" >> $script
      echo "set myWns [get_property SLACK [get_timing_paths ]]" >> $script
      echo "puts \"post-netlist-optimization WNS: |\$myWns|\"" >> $script
      
      if [ $fullbuilds == "yes" ]; then
        echo "Performing a full build"
      
        #Placement & physical optimization (with default directives)
        echo "place_design -directive $ps" >> $script
        echo "write_checkpoint $wdir/placed_design.dcp -force" >> $script
        echo "phys_opt_design -directive $pos" >> $script
        echo "write_checkpoint $wdir/phys_opt_design.dcp -force" >> $script
        echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_phys_opt_design.rpt" >> $script
        echo "getTimingInfo" >> $script
        echo "set myWns [get_property SLACK [get_timing_paths ]]" >> $script
        echo "puts \"post-fullbuild-physopt WNS: |\$myWns|\"" >> $script
        
        #Routing & physical optimization (with default directives)
        echo "route_design -directive $rs" >> $script
        echo "write_checkpoint $wdir/route_design.dcp -force" >> $script
        echo "phys_opt_design -directive $pos" >> $script
        echo "write_checkpoint $wdir/opt_routed_design.dcp -force" >> $script
        echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_routed_design.rpt" >> $script
        echo "getTimingInfo" >> $script
        echo "set myWns [get_property SLACK [get_timing_paths ]]" >> $script
        echo "puts \"post-fullbuild-optrouted WNS: |\$myWns|\"" >> $script
      fi
      
      #Run Vivado with the created script
      vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
      
      #Find WNS and log to a file
      grep "post-netlist-optimization WNS" $wdir/vivado_build.log | cut -d '|' -f 2 > $wdir/opt_wns.txt
      if [ $fullbuilds == "yes" ]; then
        grep "post-fullbuild-physopt WNS" $wdir/vivado_build.log | cut -d '|' -f 2 > $wdir/place_wns.txt
        grep "post-fullbuild-optrouted WNS" $wdir/vivado_build.log | cut -d '|' -f 2 > $wdir/route_wns.txt
      fi
    fi
  fi
done

