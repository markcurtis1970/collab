#!/usr/bin/env bash

# Setup vars
COUNTRY=$1
F_RESULTS="covid19_fatality_results"
C_RESULTS="covid19_confirmed_results"
DAYS=14

cat ./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv | \
awk -F "," '{
    for (i=5; i<=NF; i++) { 
        if (NR==1) {
            header[i]=$i
            } else { 
            date[$1" "$2","header[i]]=$i
        }
    }
} END {
    for (idx in date) print idx","date[idx]
}' > $F_RESULTS

cat ./COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv | \
awk -F "," '{
    for (i=5; i<=NF; i++) { 
        if (NR==1) {
            header[i]=$i
            } else { 
            date[$1" "$2","header[i]]=$i
        }
    }
} END {
    for (idx in date) print idx","date[idx]
}' > $C_RESULTS

# Count results length - days
# To only show <n> days results
F_LEN=$(( $(grep -E "^\  *$COUNTRY" $F_RESULTS | wc -l | awk '{print $1}') - $DAYS))
C_LEN=$(( $(grep -E "^\  *$COUNTRY" $C_RESULTS | wc -l | awk '{print $1}') - $DAYS))


grep -E "^\  *$COUNTRY" $F_RESULTS | \
sort -t, -k3 -n | \
awk -v days=$F_LEN -F "," 'BEGIN {
    printf "%15s %15s %10s %10s %10s\n","Country","Date","Fatalities" ,"Inc","% Inc"
    } {
    num=$3; 
    inc=num-last; 
    if (last > 0) {
        pct=((inc/last)*100)
    }; 
    last=num;
    printf "%15s %15s %10i %10i %10i%%\n",$1,$2,$3,inc,pct
    }' | \
awk 'NR==1;NR>=days'

grep -E "^\  *$COUNTRY" $C_RESULTS | \
sort -t, -k3 -n | \
awk -v days=$C_LEN -F "," 'BEGIN {
    printf "%15s %15s %10s %10s %10s\n","Country","Date","Confirmed" ,"Inc","% Inc"
    } {
    num=$3; 
    inc=num-last; 
    if (last > 0) {
        pct=((inc/last)*100)
    }; 
    last=num;
    printf "%15s %15s %10i %10i %10i%%\n",$1,$2,$3,inc,pct
    }' | \
awk 'NR==1;NR>=days'

