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

if [ "$#" -ne 2 ]; then
    echo "Usage: explore_strategies.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    echo "N is the number of designs that are taken into the next round"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"
echo ""

#The first stage, opt_design, is different from the other 2 because:
# 1) it consist of only 1 step (the other have 2; both include a phys_opt step)
# 2) this step does not have to start from potentially multiple checkpoints (when exploring the N best strategies)
stage=opt
echo "Exploring strategies for ${stage}_design"

stage_dir=$wdir_base/${stage}_strategies
mkdir -p $stage_dir
summary=$stage_dir/summary.txt
echo "Starting checkpoint: $starting_checkpoint" > $summary
echo "Workspace directory: $wdir_base" >$summary
timingfile=stage_dir/timing_results.txt
touch $timingfile

#Run the exploration
#bash $scriptdir/${stage}_strategies.sh $starting_checkpoint $stage_dir

echo "Done exploring $stage strategies. Results:"
for strat in $(ls $stage_dir/strategies); do
  wns=$(cat $bestdir/$i/${stage}_wns.txt)
  echo "Strategy $(basename $strat): WNS $wns"
  echo "$wns|$strategy" >> $timingfile
  echo ""
done

bestdir=$stage_dir/bestsorted
mkdir $bestdir
echo "This directory contains softlinks to the result directories for all the ${stage}_design strategies, sorted by timing performance (WNS closest to 0)" > $stage_dir/best/README
sort -t. $timingfile
i=1
cat $timingfile | while read entry; do
  strat=$(echo $entry | cut -d'|' -f2)
  ln -sf $stage_dir/strategies/$strat $bestdir/$i
  i=$((i+1))
done
starting_checkpoint=$bestdir/1/${stage}_design.dcp

exit



stage="place route"

for stage in $stages; do
  echo "Exploring strategies for ${stage}_design"

  stage_dir=$wdir_base/${stage}_strategies
  mkdir -p $stage_dir
  summary=$stage_dir/summary.txt
  echo "Starting checkpoint: $starting_checkpoint" > $summary
  echo "Workspace directory: $wdir_base" >$summary
  
  #Run the exploration
  #bash $scriptdir/${stage}_strategies.sh $starting_checkpoint $stage_dir

  echo "Done exploring $stage strategies. Results:"
  for strat in $(ls $stage_dir/strategies); do
    wns=$(cat $bestdir/$i/${stage}_wns.txt)
    echo "Strategy $(basename $strat): WNS $wns"
    echo "$wns|$strategy" >> $timingfile
    echo ""
  done

  bestdir=$stage_dir/bestsorted
  mkdir $bestdir
  echo "This directory contains softlinks to the result directories for all the ${stage}_design strategies, sorted by timing performance (WNS closest to 0)" > $stage_dir/best/README
  sort -t. $timingfile
  i=1
  cat $timingfile | while read entry; do
    strat=$(echo $entry | cut -d'|' -f2)
    ln -sf $stage_dir/strategies/$strat $bestdir/$i
    i=$((i+1))
  done
  starting_checkpoint=$bestdir/1/${stage}_design.dcp
done

