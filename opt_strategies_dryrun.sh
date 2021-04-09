#!/bin/bash

#Test version of script to try combinations of netlist optimization strategies.

# To get a better idea of the influence of this exploration, you can choose to continue all the implementation steps after each opt_design attempt.
fullbuilds=no

OPT_STRATS="Explore ExploreArea ExploreWithRemap ExploreSequentialArea"

if [ "$#" -ne 2 ]; then
    echo "Usage: route_strategies_dryrun.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a synthesized design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

for os in $OPT_STRATS; do
  echo "OPT strategy: $os"
  wdir=$wdir_base/strategies/$os
  mkdir -p $wdir
  
  #Generate random WNS and log to a file
  echo "-0.$(($RANDOM%999))" > $wdir/opt_wns.txt
  if [ $fullbuilds == "yes" ]; then
    echo "-0.$(($RANDOM%999))" > $wdir/place_wns.txt
    echo "-0.$(($RANDOM%999))" > $wdir/route_wns.txt
  fi
done

