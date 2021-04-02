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

PLACE_STRATS="Explore ExtraNetDelay_high ExtraNetDelay_low ExtraPostPlacementOpt ExtraTimingOpt"
PHYSOPT_STRATS="Explore AggressiveExplore AlternateReplication AggressiveFanoutOpt AlternateFlowWithRetiming"
ROUTE_STRATS="Explore AggressiveExplore HigherDelayCost AlternateCLBRouting"

if [ "$#" -ne 2 ]; then
    echo "Usage: place_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized (and optimized) design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

runs=0
for ps in $PLACE_STRATS; do
  for os in $PHYSOPT_STRATS; do
    #for rs in $ROUTE_STRATS; do
    #  echo "PLACE strategy: $ps, PHYSOPT strategy: $os, ROUTE strategy: $rs"
     echo "PLACE strategy: $ps, PHYSOPT strategy: $os"
      runs=$((runs+1))
      wdir=$wdir_base/strategies/$ps/$os
      mkdir -p $wdir
      script=$wdir/vivado_script.tcl
      echo "open_checkpoint $starting_checkpoint" > $script
      echo "place_design -directive $ps" >> $script
      echo "write_checkpoint $wdir/place_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_place.rpt" >> $script
      
      echo "phys_opt_design -directive $os" >> $script
      echo "write_checkpoint $wdir/phys_opt_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_phys_opt.rpt" >> $script
      
      #Run Vivado with the created script
      vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
    #done
  done
done
#echo "Total number of runs: $runs"
