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
    sleep $DELAY
}

function run_cpu_ttop {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running ttop"
   nodetool sjk ttop -o CPU -n 50 >> $TTOP_CPU_LOG &
}

function run_alloc_ttop {
   echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... running ttop"
   nodetool sjk ttop -o ALLOC -n 50 >> $TTOP_ALLOC_LOG &
}

function kill_ttop {
    for PID in $(ps -ef | grep ttop | grep -v grep | awk '{print $2}')
    do
        echo ">>> $(date '+%Y-%m-%d_%H:%M:%S') ... Killing ttop process $PID"
        kill $PID
    done
}


if [ $# -ne 2 ]; then
    useage
    exit
fi


NODE=$(hostname -i)
DATE=$(date '+%Y-%m-%d_%H:%M:%S')
LOG="/tmp/$NODE-$DATE-monitor.out"
TTOP_CPU_LOG="/tmp/$NODE-$DATE-monitor-ttop-cpu.out"
TTOP_ALLOC_LOG="/tmp/$NODE-$DATE-monitor-ttop-alloc.out"
DELAY=$1
COUNT=$2

echo "Running monitor script... please check nodetool sjk is not still running after with \"ps -ef | grep ttop\""

run_cpu_ttop
run_alloc_ttop
for loop in $(seq $COUNT)
do
   run_nodetool
   sleep $DELAY
done
kill_ttop

echo "Exiting monitor script ... please find outputs in /tmp"
