#!/bin/bash

set -e
set -o pipefail
cd "$(dirname $0)"
set -x

env | grep '^PG' || true

psql -c 'create database sample_gtfs_feed'
export PGDATABASE='sample_gtfs_feed'

../cli.js -d --trips-without-shape-id -- \
	../node_modules/sample-gtfs-feed/gtfs/agency.txt \
	../node_modules/sample-gtfs-feed/gtfs/calendar.txt \
	../node_modules/sample-gtfs-feed/gtfs/calendar_dates.txt \
	../node_modules/sample-gtfs-feed/gtfs/frequencies.txt \
	../node_modules/sample-gtfs-feed/gtfs/stops.txt \
	../node_modules/sample-gtfs-feed/gtfs/routes.txt \
	../node_modules/sample-gtfs-feed/gtfs/trips.txt \
	../node_modules/sample-gtfs-feed/gtfs/stop_times.txt \
	../node_modules/sample-gtfs-feed/gtfs/levels.txt \
	../node_modules/sample-gtfs-feed/gtfs/pathways.txt \
	| psql -b

query=$(cat << EOF
select extract(epoch from t_arrival)::integer as t_arrival
from arrivals_departures
where route_id = 'D'
order by t_arrival
EOF)

arr1=$(psql --csv -t -c "$query" | head -n 1)
if [[ "$arr1" != "1553993700" ]]; then
	echo "invalid 1st t_arrival: $arr1" 1>&2
	exit 1
fi

arr2=$(psql --csv -t -c "$query" | head -n 2 | tail -n 1)
if [[ "$arr2" != "1553994180" ]]; then
	echo "invalid 2nd t_arrival: $arr2" 1>&2
	exit 1
fi

arrs_deps_b_downtown_on_working_days=$(cat << EOF
	SELECT
		stop_sequence,
		extract(epoch from t_arrival)::integer as arr,
		extract(epoch from t_departure)::integer as dep
	FROM arrivals_departures
	WHERE trip_id = 'b-downtown-on-working-days'
	ORDER BY t_departure
	LIMIT 1
EOF)
freq_arr_dep1=$(psql --csv -t -c "$arrs_deps_b_downtown_on_working_days")
if [[ "$freq_arr_dep1" != "1,1552028340,1552028400" ]]; then
	echo "invalid/missing frequencies-based arrival/departure: $freq_arr_dep1" 1>&2
	exit 1
fi

cons_b_downtown_on_working_days=$(cat << EOF
	SELECT
		from_stop_sequence,
		extract(epoch from t_departure)::integer as dep,
		to_stop_sequence,
		extract(epoch from t_arrival)::integer as arr
	FROM connections
	WHERE trip_id = 'b-downtown-on-working-days'
	ORDER BY t_departure
	LIMIT 1
EOF)
freq_con1=$(psql --csv -t -c "$cons_b_downtown_on_working_days")
if [[ "$freq_con1" != "1,1552028400,3,1552028760" ]]; then
	echo "invalid/missing frequencies-based connection: $freq_con1" 1>&2
	exit 1
fi

connection_during_dst=$(cat << EOF
	SELECT
		from_stop_sequence,
		extract(epoch from t_departure)::integer as dep
	FROM connections
	WHERE trip_id = 'during-dst-1'
	AND t_departure = '2019-03-31T01:58+01'
EOF)
dst1=$(psql --csv -t -c "$connection_during_dst" | head -n 1)
if [[ "$dst1" != "0,1553993880" ]]; then
	echo "invalid/missing DST t_departure: $dst1" 1>&2
	exit 1
fi

airport_levels=$(cat << EOF
	SELECT
		level_id,
		level_index,
		level_name
	FROM levels
	WHERE level_id LIKE 'airport-%'
	ORDER BY level_index
	LIMIT 1
EOF)
lvl1=$(psql --csv -t -c "$airport_levels" | head -n 1)
if [[ "$lvl1" != "airport-level-0,0,ground level" ]]; then
	echo "invalid/missing lowest airport-% level: $lvl1" 1>&2
	exit 1
fi

airportPathway=$(cat << EOF
	SELECT
		pathway_mode,
		is_bidirectional
	FROM pathways
	WHERE from_stop_id = 'airport-entrance'
	AND to_stop_id = 'airport-1-access'
	LIMIT 1
EOF)
pw1=$(psql --csv -t -c "$airportPathway" | head -n 1)
if [[ "$pw1" != "escalator,f" ]]; then
	echo "invalid/missing DST t_departure: $pw1" 1>&2
	exit 1
fi

timepoint_exact=$(cat << EOF
	SELECT timepoint
	FROM stop_times
	WHERE timepoint = 'exact'
	AND stop_sequence_consec = 0
	LIMIT 1
EOF)
exact1=$(psql --csv -t -c "$timepoint_exact" | head -n 1)
if [[ "$exact1" != "exact" ]]; then
	echo "invalid/missing DST t_departure: $exact1" 1>&2
	exit 1
fi

echo 'works ✔'
