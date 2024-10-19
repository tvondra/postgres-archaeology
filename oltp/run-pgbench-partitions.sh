#!/usr/bin/bash -x

set -e

PATH_OLD=$PATH
DATADIR=/mnt/pgdata/data
DURATION=60
PGBENCH=/mnt/data/builds/18/bin/pgbench

TS=$(date +%Y%m%d-%H%M%S)
LOGDIR=$TS/logs
RESULTS=$TS/results

RUNS=3
CLIENTS="1 16 32 64 128 256"
PARTITIONS="10 100"

mkdir -p $LOGDIR
mkdir -p $RESULTS

rm -f clients.list
for c in $CLIENTS; do
	echo $c >> clients.list
done


for s in 100 1000 10000; do

	for p in $PARTITIONS; do

		for v in 18 17 16 15 14 13 12 11; do

			killall -9 postgres || true

			PATH=/mnt/data/builds/$v/bin:$PATH_OLD

			rm -Rf $DATADIR
			initdb -D $DATADIR > $LOGDIR/initdb-$v-$s-$p.log 2>&1

			echo "shared_buffers = '4GB'" >> $DATADIR/postgresql.conf
			echo "checkpoint_timeout = '30min'" >> $DATADIR/postgresql.conf
			echo "max_connections = 1000" >> $DATADIR/postgresql.conf
			echo "max_locks_per_transaction = 1024" >> $DATADIR/postgresql.conf

			echo "autovacuum_vacuum_scale_factor = 0.01" >> $DATADIR/postgresql.conf
			echo "autovacuum_analyze_scale_factor = 0.05" >> $DATADIR/postgresql.conf
			echo "autovacuum_vacuum_cost_limit = 1000" >> $DATADIR/postgresql.conf
			echo "autovacuum_vacuum_cost_delay = 2ms" >> $DATADIR/postgresql.conf
			echo "vacuum_cost_page_hit = 1" >> $DATADIR/postgresql.conf
			echo "vacuum_cost_page_miss = 2" >> $DATADIR/postgresql.conf
			echo "vacuum_cost_page_dirty = 20" >> $DATADIR/postgresql.conf

			if [ "$v" == "9.4" ] || [ "$v" == "9.3" ] || [ "$v" == "9.2" ]; then
		                echo "checkpoint_segments = 8192" >> $DATADIR/postgresql.conf
			else
		                echo "max_wal_size = '128GB'" >> $DATADIR/postgresql.conf
		                echo "min_wal_size = '32GB'" >> $DATADIR/postgresql.conf
			fi

			pg_ctl -D $DATADIR -l $LOGDIR/pg-$v-$s-$p.log -w start

			sleep 1

			createdb test

			$PGBENCH -i -s $s --partitions=$p test > $LOGDIR/pgbench-init-$v-$s-$p.log 2>&1

			for t in ro rw rw-full; do

				for r in $(seq 1 $RUNS); do

					for m in simple prepared; do

						mkdir -p $RESULTS/$s/$v/$t/$r/$m/$p/

						for c in $(shuf clients.list); do

							psql test -c "checkpoint"

							if [ "$t" == "ro" ]; then
								$PGBENCH -S -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$p/$c.log 2>&1
							elif [ "$t" == "rw" ]; then
								$PGBENCH -N -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$p/$c.log 2>&1
							else
								$PGBENCH -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$p/$c.log 2>&1
							fi

						done

					done

				done

			done

			pg_ctl -D $DATADIR -w -t 3600 stop

			sleep 1

		done

	done

done
