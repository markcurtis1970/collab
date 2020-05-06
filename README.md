# collab
Collab stuff - a few scripts and things to assist in the spirit of collabration

`monitor.sh` - A simple monitoring script to gather a few simple OS level metrics, also Cassandra nodetool commands
ttop output and JVM thread dumps

`jfr.sh` - runs a JFR for the Cassandra JVM, makes it (hopefully) a little easier than doing it by hand. Also invokes
it on the fly so no need to bounce the JVM to get those addititonal parameters in there.  Note: this only works with a Oracle JVM
at present.

