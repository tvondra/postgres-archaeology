#!/usr/bin/bash -x

set -e

PATH_OLD=$PATH
DATADIR=/mnt/pgdata/data
PSQL=/mnt/data/builds/18/bin/psql

TS=$(date +%Y%m%d-%H%M%S)
LOGDIR=$TS/logs
RESULTS=$TS/results

RUNS=3

mkdir -p $LOGDIR
mkdir -p $RESULTS

for s in 1 10; do

	for w in 0 4; do

		VERSIONS="18 17 16 15 14 13"

		for v in $VERSIONS; do

			killall -9 postgres || true

			PATH=/mnt/data/builds/$v/bin:$PATH_OLD

			rm -Rf $DATADIR
			initdb -D $DATADIR > $LOGDIR/initdb-$v-$s.log 2>&1

			echo "shared_buffers = 262143" >> $DATADIR/postgresql.conf
			echo "checkpoint_timeout = 1800" >> $DATADIR/postgresql.conf
			echo "max_connections = 1000" >> $DATADIR/postgresql.conf
			echo "work_mem = '32768'" >> $DATADIR/postgresql.conf

			echo "random_page_cost = 1.5" >> $DATADIR/postgresql.conf

			echo "effective_io_concurrency = 54" >> $DATADIR/postgresql.conf

			echo "max_wal_size = '128GB'" >> $DATADIR/postgresql.conf
			echo "min_wal_size = '32GB'" >> $DATADIR/postgresql.conf

			echo "cpu_index_tuple_cost = 0.005" >> $DATADIR/postgresql.conf
			echo "default_statistics_target = 100" >> $DATADIR/postgresql.conf
			echo "effective_cache_size = 16384" >> $DATADIR/postgresql.conf
			echo "maintenance_work_mem = 65536" >> $DATADIR/postgresql.conf
			echo "wal_buffers = 512" >> $DATADIR/postgresql.conf
			echo "work_mem = 4096" >> $DATADIR/postgresql.conf

			pg_ctl -D $DATADIR -l $LOGDIR/pg-$v-$s-$w.log -w start

			sleep 1

			createdb test

			a=$(date +%s)

			$PSQL -e test > $LOGDIR/load-$v-$s-$w.log 2>&1 <<EOF
set max_parallel_maintenance_workers = $w;
set max_parallel_workers_per_gather = $w;
\timing on
\i load-$s.sql
EOF

			b=$(date +%s)

			echo $v $s $w $((b-a)) >> load.csv 2>&1

			rm -f explains.log

			./run-queries-tuned.sh $v $s $w $DATADIR results.csv
			mv explains.log $LOGDIR/explains-$v-$s-$w.log

			./run-analyze-tuned.sh $v $s $w $DATADIR results.csv
			mv explains.log $LOGDIR/analyze-$v-$s-$w.log

			pg_ctl -D $DATADIR -w stop

			sleep 1

		done

	done

done
