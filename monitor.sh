#!/usr/bin/env bash
#

# nodetool commands used
#    compactionstats              Print statistics on compactions
#    describecluster              Print the name, snitch, partitioner and schema version of a cluster
#    failuredetector              Shows the failure detector information for the cluster
#    gcstats                      Print GC Statistics
#    gossipinfo                   Shows the gossip information for the cluster
#    info                         Print node information (uptime, load, ...)
#    netstats                     Print network information on provided host (connecting node by default)
#    proxyhistograms              Print statistic histograms for network operations
#    status                       Print cluster information (state, load, IDs, ...)
#    statusbinary                 Status of native transport (binary protocol)
#    statusgossip                 Status of gossip
#    statushandoff                Status of storing future hints on the current node
#    tpstats                      Print usage statistics of thread pools

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

function run_nodetool {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool commands"
    for COMMAND in compactionstats describecluster failuredetector gcstats gossipinfo info netstats proxyhistograms status statusbinary statusgossip statushandoff 'tpstats --cores'
    do
        echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running nodetool $COMMAND" >> $LOG
        nodetool $COMMAND >> $LOG
    done
}

function run_threaddump {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running thread dump"
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running thread dump" >> $TD_LOG
    sudo -u $CASSUSER $JSTACK -l $CASSPID >> $TD_LOG
}

function run_cpu_ttop {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running ttop (CPU)"
   nodetool sjk ttop -o CPU -n 50 >> $TTOP_CPU_LOG &
}

function run_alloc_ttop {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running ttop (ALLOC)"
   nodetool sjk ttop -o ALLOC -n 50 >> $TTOP_ALLOC_LOG &
}

function kill_ttop {
    for PID in $(ps -ef | grep ttop | grep -v grep | awk '{print $2}')
    do
        echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... Killing ttop process $PID"
        kill $PID
    done
}

function run_top_once {
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running top for pid $CASSPID" 
    echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running top for pid $CASSPID"  >> $LOG
    top -b -n 1 -p $CASSPID >> $LOG
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
CASSPID=$(cat /run/dse/dse.pid)
CASSUSER="cassandra"
LOG="$MONDIR/$NODE-$DATE-monitor-$CASSPID.out"
TD_LOG="$MONDIR/$NODE-$DATE-thread-dump-$CASSPID.out"
TTOP_CPU_LOG="$MONDIR/$NODE-$DATE-monitor-ttop-cpu-$CASSPID.out"
TTOP_ALLOC_LOG="$MONDIR/$NODE-$DATE-monitor-ttop-alloc-$CASSPID.out"
export export PATH=$PATH:$JAVA_HOME/bin
JSTACK=$(which jstack)

# Main control
#
# This is where we call functions
# to run commands to get diagnostics

# Run the ttop commands first in the background
# these will continue running until they are killed
# if you CTRL+C this script you will have to kill
# ttop manually

echo "Running monitor script... please check nodetool sjk is not still running after with \"ps -ef | grep ttop\""
run_cpu_ttop
run_alloc_ttop

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
        run_nodetool
        run_threaddump
        sleep $DELAY
    done
else
    for loop in $(seq $COUNT)
    do
        echo "Running iteration $loop of $COUNT"
        run_top_once
        run_iostat_once
        run_vmstat_once
        run_nodetool
        run_threaddump
        sleep $DELAY
    done
fi

# Clean up ttop processes and exit
kill_ttop
echo "Exiting monitor script ... please find outputs in $MONDIR"
exit
