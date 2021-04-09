#!/bin/bash

#Script to try combinations of route strategies.
#A successful build will have a small negative slack after phys_opt.
#So don't bother trying routing and post-route optimization if that is not the case.

ROUTE_STRATS="Explore AggressiveExplore HigherDelayCost AlternateCLBRouting"
PHYSOPT_STRATS="Explore AggressiveExplore AlternateReplication AggressiveFanoutOpt AlternateFlowWithRetiming"

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    echo "Usage: route_strategies.sh <Starting Checkpoint> <Workspace directory> [dry]"
    echo "Starting checkpoint must be a placed design"
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

for rs in $ROUTE_STRATS; do
  for os in $PHYSOPT_STRATS; do
    echo "ROUTE strategy: $rs, PHYSOPT strategy: $os"
    wdir=$wdir_base/strategies/$rs/$os
    mkdir -p $wdir
    script=$wdir/vivado_script.tcl
    
    if [ -f $wdir/route_wns.txt ] && [ $(cat $wdir/route_wns.txt) != "" ]; then
      echo "Pre-existing results found, skipping..."
    else
      
      if [ $dryrun == "yes" ]; then
        #Generate random WNS and log to a file
        echo "-0.$(($RANDOM%999))" > $wdir/route_wns.txt
      else
        #Open the starting checkpoint
        echo "open_checkpoint $starting_checkpoint" > $script
        
        #Get a function for making nice short timing summaries for in the logs:
        echo "source $scriptdir/timing_summary_parser.tcl" >> $script
        
        #Route the design
        echo "route_design -directive $rs" >> $script
        echo "write_checkpoint $wdir/route_design.dcp -force" >> $script
        echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_route.rpt" >> $script
        echo "getTimingInfo" >> $script
        
        #Perform physical optimization
        echo "phys_opt_design -directive $os" >> $script
        echo "write_checkpoint $wdir/opt_routed_design.dcp -force" >> $script
        echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_routed.rpt" >> $script
        echo "getTimingInfo" >> $script
        echo "set myWns [get_property SLACK [get_timing_paths ]]" >> $script
        echo "puts \"post-optrouted WNS: |\$myWns|\"" >> $script
        
        #Run Vivado with the created script
        vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
        
        #Find WNS and log to a file
        grep "post-optrouted WNS" $wdir/vivado_build.log | cut -d '|' -f 2 > $wdir/route_wns.txt
      fi
    fi
  done
done

