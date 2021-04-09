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

#For testing. Just generate some random results.
dryrun=true

if [ "$#" -ne 3 ]; then
    echo "Usage: explore_strategies.sh <Starting Checkpoint> <Workspace directory> <N best designs>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    echo "N best designs is the number of designs that are taken into the next round"
    exit -1
fi

starting_checkpoint=$1
nbest=$3
wdir_base=$(cd $2; pwd)
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ $nbest -gt 4 ]; then
  echo "Cannot explore more than 4 best strategies because 1 of the steps only has 4 in total."
  exit -1
fi

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
echo "Workspace directory: $wdir_base" >> $summary
timingfile=$stage_dir/timing_results.txt
echo -n "" > $timingfile
bestdir=$stage_dir/bestsorted
mkdir -p $bestdir

#Run the exploration
if [ $dryrun -eq true ]; then
  bash $scriptdir/${stage}_strategies_dryrun.sh $starting_checkpoint $stage_dir
else
  bash $scriptdir/${stage}_strategies.sh $starting_checkpoint $stage_dir
fi

echo "Done exploring $stage strategies. Results:"
for strat in $(ls $stage_dir/strategies); do
  wns=$(cat $stage_dir/strategies/$strat/${stage}_wns.txt)
  if [[ $wns == "" ]]; then
    echo "Error, WNS not found for one of the runs, exiting"
    exit -1
  fi
  echo "Strategy $(basename $strat): WNS $wns"
  echo "$wns|$strat" >> $timingfile
done

echo "This directory contains softlinks to the result directories for all the ${stage}_design strategies, sorted by timing performance (WNS closest to 0)" > $bestdir/README
sort -t. $timingfile > ${timingfile}.tmp
rm $timingfile
mv ${timingfile}.tmp $timingfile
echo "" >> $summary
cat $timingfile >> $summary

#Make softlinks to the strategy output directories in sorted order
i=1
cat $timingfile | while read entry; do
  strat=$(echo $entry | cut -d'|' -f2)
  #echo "Linking result dir: ln -sf $stage_dir/strategies/$strat $bestdir/$i"
  ln -sf $stage_dir/strategies/$strat $bestdir/$i
  i=$((i+1))
done
starting_checkpoints=""
for i in $(seq $nbest); do
  starting_checkpoints="$starting_checkpoints $bestdir/$i/${stage}_design.dcp"
done
echo "Best $nbest checkpoints: $starting_checkpoints"

# Continue with the later stages
stages="place route"

for stage in $stages; do
  echo "Exploring the best $nbest strategies from the previous stage for ${stage}_design"
  for starting_checkpoint in $starting_checkpoints; do
    echo "Exploring checkpoint $starting_checkpoint"

    #instead of creating a new parallel directory, create a tree-like structure continuing from the previous results directories
    #stage_dir=$wdir_base/${stage}_strategies
    stage_dir=$(dirname $starting_checkpoint)/${stage}_strategies
    mkdir -p $stage_dir
    summary=$stage_dir/summary.txt
    echo "Starting checkpoint: $starting_checkpoint" > $summary
    echo "Workspace directory: $wdir_base" >> $summary
    timingfile=$stage_dir/timing_results.txt
    echo -n "" > $timingfile
    bestdir=$stage_dir/bestsorted
    mkdir -p $bestdir

    #Run the exploration
    bash $scriptdir/${stage}_strategies.sh $starting_checkpoint $stage_dir
  done

  echo "Done exploring $stage strategies for $nbest best starting checkpoints. Results:"
  for strat1 in $(ls $stage_dir/strategies); do
    for strat2 in $(ls $stage_dir/strategies/$strat1); do
      wns=$(cat $stage_dir/strategies/$strat1/$strat2/${stage}_wns.txt)
      if [[ $wns == "" ]]; then
        echo "Error, WNS not found for one of the runs, exiting"
        exit -1
      fi
      echo "Strategy $strat1/$strat2: WNS $wns"
      echo "$wns|$strat1/$strat2" >> $timingfile
    done
  done
  echo "" >> $summary
  cat $timingfile >> $summary

  echo "This directory contains softlinks to the result directories for all the ${stage}_design strategies, sorted by timing performance (WNS closest to 0)" > $bestdir/README
  sort -t. $timingfile > ${timingfile}.tmp
  rm $timingfile
  mv ${timingfile}.tmp $timingfile
  i=1
  cat $timingfile | while read entry; do
    strat=$(echo $entry | cut -d'|' -f2)
    ln -sf $stage_dir/strategies/$strat $bestdir/$i
    i=$((i+1))
  done
  starting_checkpoints=""
  for i in $(seq $nbest); do
    starting_checkpoints="$starting_checkpoints $bestdir/$i/${stage}_design.dcp"
  done
  echo "Best $nbest checkpoints after $stage_design stage: $starting_checkpoints"
done


