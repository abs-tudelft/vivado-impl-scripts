#Script to try combinations of implementation strategies.
#
#The normal order is
#synth_design
#opt_design
#place_design
#phys_opt_design
#route_design
#phys_opt_design

OPT_STRATS="Explore ExploreArea ExploreWithRemap ExploreSequentialArea"

if [ "$#" -ne 2 ]; then
    echo "Usage: route_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

ps="Explore"
pos="Explore"
rs="Explore"
runs=0
for os in $OPT_STRATS; do
   echo "OPT strategy: $os"
    runs=$((runs+1))
    wdir=$wdir_base/strategies/$os
    mkdir -p $wdir
    script=$wdir/vivado_script.tcl
    echo "open_checkpoint $starting_checkpoint" > $script
    echo "opt_design -directive $os" >> $script
    echo "write_checkpoint $wdir/opt_design.dcp -force" >> $script
    echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_design.rpt" >> $script
    echo "place_design -directive $ps" >> $script
    echo "write_checkpoint $wdir/placed_design.dcp -force" >> $script
    echo "phys_opt_design -directive $pos" >> $script
    echo "write_checkpoint $wdir/phys_opt_design.dcp -force" >> $script
    echo "route_design -directive $rs" >> $script
    echo "write_checkpoint $wdir/route_design.dcp -force" >> $script
    echo "phys_opt_design -directive $pos" >> $script
    echo "write_checkpoint $wdir/opt_routed_design.dcp -force" >> $script
    echo "report_timing_summary -quiet -max_paths 100 -file $wdir/timing_summary_opt_routed_design.rpt" >> $script
    
    #Run Vivado with the created script
    vivado -quiet -mode batch -source $script -notrace -log $wdir/vivado_build.log -journal $wdir/vivado_build.jou
done
#echo "Total number of runs: $runs"
