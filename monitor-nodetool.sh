#!/usr/bin/env bash
#
# Add your keyspace.table names into
# the TABLES=".." line below

function useage {
    echo
    echo "Usage: $0 <interval> <count>" 
    echo
    echo "Example: $0 10 30 - (runs 30 times, every 10 seconds)" 
    echo "Example: $0 10 -1 - (runs continuously, every 10 seconds)" 
    echo "Example: $0 <no args> - (runs just once)" 
    echo
    exit
}

function run_histos {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool proxyhistograms" >> $LOG
    nodetool proxyhistograms >> $LOG
    for TABLE in $TABLES
    do
        echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool tablestats $TABLE" >> $LOG
        nodetool tablehistograms $TABLE >> $LOG
    done
}

function run_nodetool {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool commands"
    for COMMAND in compactionstats describecluster failuredetector gcstats gossipinfo info netstats proxyhistograms status statusbinary statusgossip statushandoff tpstats 'tpstats --cores'
    do
        echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool $COMMAND" >> $LOG
        nodetool $COMMAND >> $LOG
    done
}

if [ $# -ne 0 ] && [ $# -ne 2 ]; then
    useage
    exit
fi

# Configuration 
#
# Set things like Cassandra PID here
# for example you might use:
#
# $(cat /var/run/cassandra.pid)
#
# Also other things like file location,
# date format, file names and such

NODE=$(hostname -i)
DATE=$(date '+%Y-%m-%d_%H:%M:%S')
MONDIR="/tmp"
if [ $# -ne 0 ]; then
    DELAY=$1
    COUNT=$2
else
    DELAY=1
    COUNT=1
fi

CASSPID=$(cat /run/dse/dse.pid)
CASSUSER="cassandra"
LOG="$MONDIR/$NODE-$DATE-monitor-$CASSPID.out"
export PATH=$PATH:$JAVA_HOME/bin
TABLES="system.peers system.paxos"

# Main control
#
# This is where we call functions
# to run commands to get diagnostics

# Execute loop to run regular commands
# typically nodetool and thread dumps
# in addition to some OS level commands
#
# Note using a negatvie value for the count
# means the script will run indefinitely
if [ $COUNT -lt 0 ]; then
    while true
    do
        echo "Running continuously"
        run_histos
        sleep $DELAY
    done
else
    for loop in $(seq $COUNT)
    do
        echo "Running iteration $loop of $COUNT"
        run_histos
        sleep $DELAY
    done
fi

echo "Exiting monitor script ... please find outputs in $MONDIR"
exit
