#!/bin/bash

#Test version of script to try combinations of route strategies.

ROUTE_STRATS="Explore AggressiveExplore HigherDelayCost AlternateCLBRouting"
PHYSOPT_STRATS="Explore AggressiveExplore AlternateReplication AggressiveFanoutOpt AlternateFlowWithRetiming"

if [ "$#" -ne 2 ]; then
    echo "Usage: route_strategies_dryrun.sh <Starting Checkpoint> <Workspace directory>"
    echo "Starting checkpoint must be a placed design"
    echo "The workspace directory is where all the output will be created"
    exit -1
fi

starting_checkpoint=$1
wdir_base=$2
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting checkpoint: $starting_checkpoint"
echo "Workspace directory: $wdir_base"

for rs in $ROUTE_STRATS; do
  for os in $PHYSOPT_STRATS; do
    echo "ROUTE strategy: $rs, PHYSOPT strategy: $os"
    wdir=$wdir_base/strategies/$rs/$os
    mkdir -p $wdir
    
    #Generate random WNS and log to a file
    echo "-0.$(($RANDOM%999))" > $wdir/opt_wns.txt > $wdir/route_wns.txt
  done
done

