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

			psql test >> explains.log <<EOF
set work_mem = '32MB';
set max_parallel_workers_per_gather = $WORKERS;
set statement_timeout = 3600000;
\i explain/$q.sql
EOF

			s=$(psql -t -A test -c "SELECT extract(epoch from now())")

			psql test > /dev/null <<EOF
set work_mem = '32MB';
set max_parallel_workers_per_gather = $WORKERS;
set statement_timeout = 3600000;
\i queries/$q.sql
EOF

			t=$(psql -t -A test -c "SELECT (extract(epoch from now()) - $s) * 1000")

			echo "tpch" $VERSION $SCALE $WORKERS $q $r uncached $t >> $RESULTS

                        s=$(psql -t -A test -c "SELECT extract(epoch from now())")

                        psql test > /dev/null <<EOF
set work_mem = '32MB';
set max_parallel_workers_per_gather = $WORKERS;
set statement_timeout = 1800000;
\i queries/$q.sql
EOF

                        t=$(psql -t -A test -c "SELECT (extract(epoch from now()) - $s) * 1000")

                        echo "tpch" $VERSION $SCALE $WORKERS $q $r cached $t >> $RESULTS

	done

done
