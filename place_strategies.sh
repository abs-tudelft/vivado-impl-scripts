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

# To get a better idea of the influence of this exploration, you can choose to continue all the implementation steps after each opt_design attempt.
fullbuilds=yes

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

#default strategies for downstream implementation steps (to get a better idea of the influence of our exploration)
pos="Explore"
rs="Explore"

for ps in $PLACE_STRATS; do
  for os in $PHYSOPT_STRATS; do
     echo "PLACE strategy: $ps, PHYSOPT strategy: $os"
      wdir=$wdir_base/strategies/$ps/$os
      mkdir -p $wdir
      script=$wdir/vivado_script.tcl
      
      #Open the starting checkpoint
      echo "open_checkpoint $starting_checkpoint" > $script
      
      #Get a function for making nice short timing summaries for in the logs:
      echo "source $scriptdir/timing_summary_parser.tcl" >> $script
      
      #Place the design
      echo "place_design -directive $ps" >> $script
      echo "write_checkpoint $wdir/place_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_place.rpt" >> $script
      echo "getTimingInfo" >> $script
      
      #Perform physical optimization
      echo "phys_opt_design -directive $os" >> $script
      echo "write_checkpoint $wdir/phys_opt_design.dcp -force" >> $script
      echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_phys_opt.rpt" >> $script
      echo "getTimingInfo" >> $script
      
      if [ $fullbuilds == "yes" ]; then
        echo "Performing a full build"
      
        #Routing & physical optimization (with default directives)
        echo "route_design -directive $rs" >> $script
        echo "write_checkpoint $wdir/route_design.dcp -force" >> $script
        echo "phys_opt_design -directive $pos" >> $script
        echo "write_checkpoint $wdir/opt_routed_design.dcp -force" >> $script
        echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_routed_design.rpt" >> $script
        echo "getTimingInfo" >> $script
      fi
      
      #Run Vivado with the created script
      vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
  done
done

