#!/usr/bin/bash

set -e

VERSION=$1
SCALE=$2
WORKERS=$3
DATADIR=$4
RESULTS=$5

for q in $(seq 1 22); do

	for r in 1; do

			pg_ctl -D $DATADIR -l pg.log -w restart
			sudo ./drop-caches.sh

			echo "query $q run $r" >> explains.log

			cat explain/$q.sql | sed 's/explain/explain analyze/' > explain.sql

			psql test >> explains.log <<EOF
set work_mem = '32MB';
set max_parallel_workers_per_gather = $WORKERS;
set statement_timeout = 3600000;
\i explain.sql
EOF

			psql test >> explains.log <<EOF
set work_mem = '32MB';
set max_parallel_workers_per_gather = $WORKERS;
set statement_timeout = 3600000;
\i explain.sql
EOF

	done

done
