#Script to try combinations of implementation strategies.
#A successful build will have a small negative slack after phys_opt.
#So don't bother trying routing and post-route optimization if that is not the case.
#
#The normal order is
#synth_design
#opt_design
#place_design
#phys_opt_design
#route_design
#phys_opt_design

ROUTE_STRATS="Explore AggressiveExplore HigherDelayCost AlternateCLBRouting"
PHYSOPT_STRATS="Explore AggressiveExplore AlternateReplication AggressiveFanoutOpt AlternateFlowWithRetiming"

if [ "$#" -ne 2 ]; then
    echo "Usage: route_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a placed design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

for rs in $ROUTE_STRATS; do
  for os in $PHYSOPT_STRATS; do
     echo "ROUTE strategy: $rs, PHYSOPT strategy: $os"
      wdir=$wdir_base/strategies/$rs/$os
      mkdir -p $wdir
      script=$wdir/vivado_script.tcl
      
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
      
      #Run Vivado with the created script
      vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
  done
done

