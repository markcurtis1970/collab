#!/usr/bin/env bash
#
# Triggers a JFR on this node

function useage {
    echo
    echo "Usage: $0 <start|dump|stop|check>"
    echo
    echo "Example: $0 start - starts a JFR for the running Cassandra process"
    echo
    exit
}

function check_java {
    JVM=$($JAVA_HOME/bin/java -version 2>&1 | grep -A 1 '[openjdk|java] version' | awk 'NR==2 {print $1}') 
    echo "JVM type: $JVM"
    if [ $JVM == 'Java(TM)' ]; then
        echo "Oracle Java found... proceeding"
    else
        echo "Oracle java is currently the only JDK that supports JFR"
        exit
    fi
}

function check_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.check 
}

function start_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID VM.unlock_commercial_features
    sudo -u $CASSUSER $JCMD $CASSPID JFR.start name=$JFRNAME settings=profile 
}

function stop_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.stop name=$JFRNAME
}

function dump_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.dump name=$JFRNAME filename=$JFRFILE compress=true
}

if [ $# -ne 1 ]; then
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
JFRNAME="$NODE-DSEJFR"
DATE=$(date '+%Y-%m-%d_%H:%M:%S')
MONDIR="/tmp"
CASSPID=$(cat /run/dse/dse.pid)
CASSUSER="cassandra"
JFRFILE="$MONDIR/$NODE-$DATE-$CASSPID.jfr"
ACTION=$1
if [ "$JAVA_HOMEx" != "x" ];then
    JCMD="$JAVA_HOME/bin/jcmd"
else
    JCMD=$(which jcmd)
fi

# Main control
#
# This is where we call functions
# to run commands to get diagnostics

# Check we have Oracle JDK
check_java

# Choose actions
if [ $ACTION == "start" ]; then
    echo ">>> starting JFR..."
    start_jfr
elif [ $ACTION == "stop" ]; then
    echo ">>> stopping JFR..."
    stop_jfr
elif [ $ACTION == "dump" ]; then
    echo ">>> dumping JFR..."
    dump_jfr
    echo ">>> stopping JFR..."
    stop_jfr
else
    echo ">>> checking JFR..."
    check_jfr
fi
exit
