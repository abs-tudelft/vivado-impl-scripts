#!/bin/bash

#Test version of script to try combinations of placement strategies.

# To get a better idea of the influence of this exploration, you can choose to continue all the implementation steps after each opt_design attempt.
fullbuilds=no

PLACE_STRATS="Explore ExtraNetDelay_high ExtraNetDelay_low ExtraPostPlacementOpt ExtraTimingOpt"
PHYSOPT_STRATS="Explore AggressiveExplore AlternateReplication AggressiveFanoutOpt AlternateFlowWithRetiming"
ROUTE_STRATS="Explore AggressiveExplore HigherDelayCost AlternateCLBRouting"

if [ "$#" -ne 2 ]; then
    echo "Usage: place_strategies_dryrun.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized (and optimized) design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

for ps in $PLACE_STRATS; do
  for os in $PHYSOPT_STRATS; do
    echo "PLACE strategy: $ps, PHYSOPT strategy: $os"
    wdir=$wdir_base/strategies/$ps/$os
    mkdir -p $wdir

    #Generate random WNS and log to a file
    echo "-0.$(($RANDOM%999))" > $wdir/opt_wns.txt > $wdir/place_wns.txt
    if [ $fullbuilds == "yes" ]; then
      echo "-0.$(($RANDOM%999))" > $wdir/opt_wns.txt > $wdir/route_wns.txt
    fi
  done
done

