#!/usr/bin/env bash
#
# Script to consolidate commands
# for tracing keys in sstables
# for a given node

function useage {
    echo
    echo "Usage: $0 <keyspace> <table> <key>"
    echo
    echo "Example: $0 keyspace1 standard1 100"
    echo
    exit
}

function run_getendpoints {
    echo -e ">>> Finding endpoints for key: $KEY"
    NODES=$(nodetool getendpoints $KEYSPACE $TABLE "$KEY")
    match=0
    for NODE in $NODES
    do
        if [ $NODE = $THIS_NODE ]; then
            match=1
        fi
    done
    if [ $match = 1 ]; then
        run_getsstables
        exit
    else
        echo "$THIS_NODE not found in endpoints for key: $KEY"
        echo ""
        echo "Endpoints are: $NODES"
        exit
    fi
}

function run_getsstables {
     echo -e ">>> Finding sstables for key: $KEY"
     SSTABLES=$(nodetool getsstables $KEYSPACE $TABLE "$KEY")
     ONESSTABLE=$(echo $SSTABLES | awk '{print $1}')
     if [ $ONESSTABLE"x" != "x" ]; then
         run_sstablecmds
     else
         echo "Key: $KEY not found in any sstable"
         echo ""
         echo "SSTables are: $SSTABLES"
         exit
     fi
}

function run_sstablecmds {
     echo -e "\n>>> Inspecting sstables for key: $KEY"
     for SSTABLE in $SSTABLES
     do
         echo -e "\n>>> SSTable: $SSTABLE\n"
         sstablemetadata $SSTABLE
         sudo -u $CASSUSER sstabledump $SSTABLE -k "$KEY" |  sed -e 's/"value" :.*/"value" : <truncated> /g'
     done
}

if [ $# -ne 3 ]; then
    useage
    exit
fi

# Configuration
#
# Set things like Cassandra user here
# for example you might use:
#
# Also other things like file location,
# date format, file names and such

THIS_NODE=$(hostname -i)
NODES=""
SSTABLES=""
KEY=$3
KEYSPACE=$1
TABLE=$2
DATE=$(date '+%Y-%m-%d_%H:%M:%S')
CASSUSER="cassandra"

# Main control
#
# This is where we call functions
# to run commands to get sstable info
run_getendpoints
exit
