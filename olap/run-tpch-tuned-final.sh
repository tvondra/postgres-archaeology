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

	for v in 18 8.0 9.4 12 9.0 15 9.6 9.2 8.3 17 14 11 9.5 9.3 8.4 16 13 10 9.1 8.2; do
	#for v in 18 17 16 15 14 13 12 11 10 9.6 9.5 9.4 9.3 9.2 9.1 9.0 8.4 8.3 8.2 8.0; do

		for w in 0 4; do

			# no parallelism for old releases
			if [ "$w" == "4" ]; then
				if [ "$v" == "9.5" ] || [ "$v" == "9.4" ] || [ "$v" == "9.3" ] || [ "$v" == "9.2" ] || [ "$v" == "9.1" ] || [ "$v" == "9.0" ] || [ "$v" == "8.4" ] || [ "$v" == "8.3" ] || [ "$v" == "8.2" ] || [ "$v" == "8.0" ]; then
					continue
				fi
			fi

			killall -9 postgres || true

			PATH=/mnt/data/builds/$v/bin:$PATH_OLD

			rm -Rf $DATADIR
			initdb -D $DATADIR > $LOGDIR/initdb-$v-$s.log 2>&1

			echo "shared_buffers = 262143" >> $DATADIR/postgresql.conf
			echo "checkpoint_timeout = 1800" >> $DATADIR/postgresql.conf
			echo "max_connections = 1000" >> $DATADIR/postgresql.conf
			echo "work_mem = '32768'" >> $DATADIR/postgresql.conf

			echo "random_page_cost = 2" >> $DATADIR/postgresql.conf

			if [ "$v" == "8.0" ] || [ "$v" == "8.1" ] || [ "$v" == "8.2" ] || [ "$v" == "8.3" ]; then
				echo "# effective_io_concurrency not supported" >> $DATADIR/postgresql.conf
			elif [ "$v" == "13" ] || [ "$v" == "14" ] || [ "$v" == "15" ] || [ "$v" == "16" ] || [ "$v" == "17" ] || [ "$v" == "18" ]; then
				echo "effective_io_concurrency = 54" >> $DATADIR/postgresql.conf
			else
				echo "effective_io_concurrency = 16" >> $DATADIR/postgresql.conf
			fi

			if [ "$v" == "9.4" ] || [ "$v" == "9.3" ] || [ "$v" == "9.2" ] || [ "$v" == "9.1" ] || [ "$v" == "9.0" ] || [ "$v" == "8.4" ] || [ "$v" == "8.3" ] || [ "$v" == "8.2" ] || [ "$v" == "8.1" ] || [ "$v" == "8.0" ] || [ "$v" == "7.4" ]; then
				echo "checkpoint_segments = 8192" >> $DATADIR/postgresql.conf
			else
				echo "max_wal_size = '128GB'" >> $DATADIR/postgresql.conf
				echo "min_wal_size = '32GB'" >> $DATADIR/postgresql.conf
			fi

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

			if [ "$v" == "8.0" ] || [ "$v" == "8.1" ] || [ "$v" == "8.2" ] || [ "$v" == "8.3" ] || [ "$v" == "8.4" ]; then
				$PSQL -e test > $LOGDIR/load-$v-$s-$w.log 2>&1 <<EOF
set max_parallel_maintenance_workers = $w;
set max_parallel_workers_per_gather = $w;
set maintenance_work_mem = 262144;
\timing on
\i load-$s-old.sql
EOF
			else
				$PSQL -e test > $LOGDIR/load-$v-$s-$w.log 2>&1 <<EOF
set max_parallel_maintenance_workers = $w;
set max_parallel_workers_per_gather = $w;
set maintenance_work_mem = 262144;
\timing on
\i load-$s.sql
EOF
			fi

			b=$(date +%s)

			$PSQL -e test >> $LOGDIR/load-$v-$s-$w.log 2>&1 <<EOF
set max_parallel_maintenance_workers = $w;
set max_parallel_workers_per_gather = $w;
set maintenance_work_mem = 262144;
\timing on
\i ios.sql
EOF

			c=$(date +%s)

			$PSQL -e test > $LOGDIR/fkeys-$v-$s-$w.log 2>&1 <<EOF
set max_parallel_maintenance_workers = $w;
set max_parallel_workers_per_gather = $w;
set maintenance_work_mem = 262144;
\timing on
\i foreign-keys.sql
EOF

			d=$(date +%s)

			echo $v $s $w $((b-a)) $((c-b)) $((d-c)) >> load.csv 2>&1

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
