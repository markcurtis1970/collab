#!/usr/bin/env bash
#

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

function run_top_once {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running top for pid $CASSPID" 
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running top for pid $CASSPID"  >> $LOG
    top -b -n 1 >> $LOG
}

function run_iostat_once {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running iostat"
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running iostat" >> $LOG
   iostat -c -x -d 1 1 >> $LOG
}

function run_vmstat_once {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running vmstat"
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running VMstat" >> $LOG
   vmstat -w >> $LOG
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

LOG="$MONDIR/$NODE-$DATE-monitor.out"

# Main control
#
# This is where we call functions
# to run commands to get diagnostics

# Run the ttop commands first in the background
# these will continue running until they are killed
# if you CTRL+C this script you will have to kill
# ttop manually

echo "Running monitor script... "

# Execute loop to run regular commands
# typically nodetool and thread dumps
# in addition to some OS level commands
#
# Note using a negatvie value for the count
# means the script will run indefinitely
if [ $COUNT -lt 0 ]; then
    while true
    do
        echo "Running contonuously"
        run_top_once
        run_iostat_once
        run_vmstat_once
        sleep $DELAY
    done
else
    for loop in $(seq $COUNT)
    do
        echo "Running iteration $loop of $COUNT"
        run_top_once
        run_iostat_once
        run_vmstat_once
        sleep $DELAY
    done
fi

# Clean up ttop processes and exit
echo "Exiting monitor script ... please find outputs in $MONDIR"
exit
