#!/usr/bin/bash -x

set -e

LABEL=$1
PATH_OLD=$PATH
DATADIR=/mnt/pgdata/data
DURATION=60
PGBENCH=/mnt/data/builds/18/bin/pgbench

TS=$(date +%Y%m%d-%H%M%S)
LOGDIR=$TS-$LABEL/logs
RESULTS=$TS-$LABEL/results

RUNS=1
CLIENTS="1 16 32 64 128 256"

mkdir -p $LOGDIR
mkdir -p $RESULTS

rm -f clients.list
for c in $CLIENTS; do
	echo $c >> clients.list
done


for s in 100 1000 10000; do
#for s in 10000; do

	#for t in ro rw rw-full; do
	for t in ro rw; do

		for v in 8.0 18 9.4 12 9.0 15 9.6 9.2 8.3 17 14 11 9.5 9.3 8.4 16 13 10 9.1 8.2; do
		#for v in 18 17 16 15 14 13 12 11 10 9.6 9.5 9.4 9.3 9.2 9.1 9.0 8.4 8.3 8.2 8.0; do

			killall -9 postgres || true
			killall -9 postmaster || true

			PATH=/mnt/data/builds/$v/bin:$PATH_OLD

			rm -Rf $DATADIR
			initdb -D $DATADIR > $LOGDIR/initdb-$v-$s-$t.log 2>&1

			#echo "shared_buffers = '8GB'" >> $DATADIR/postgresql.conf
			echo "shared_buffers = 262143" >> $DATADIR/postgresql.conf
			echo "checkpoint_timeout = 1800" >> $DATADIR/postgresql.conf
			echo "max_connections = 1000" >> $DATADIR/postgresql.conf
			echo "work_mem = '32768'" >> $DATADIR/postgresql.conf
			echo "log_error_verbosity = 'verbose'" >> $DATADIR/postgresql.conf
			echo "log_min_error_statement = 'error'" >> $DATADIR/postgresql.conf

			if [ "$v" == "8.0" ]; then
				echo "skip autovacuum"
			else
				echo "autovacuum_vacuum_scale_factor = 0.01" >> $DATADIR/postgresql.conf
				echo "autovacuum_analyze_scale_factor = 0.05" >> $DATADIR/postgresql.conf
				echo "autovacuum_vacuum_cost_limit = 1000" >> $DATADIR/postgresql.conf
				echo "autovacuum_vacuum_cost_delay = 2ms" >> $DATADIR/postgresql.conf
			fi

			echo "vacuum_cost_page_hit = 1" >> $DATADIR/postgresql.conf
			echo "vacuum_cost_page_miss = 2" >> $DATADIR/postgresql.conf
			echo "vacuum_cost_page_dirty = 20" >> $DATADIR/postgresql.conf

			if [ "$v" == "9.4" ] || [ "$v" == "9.3" ] || [ "$v" == "9.2" ] || [ "$v" == "9.1" ] || [ "$v" == "9.0" ] || [ "$v" == "8.4" ] || [ "$v" == "8.3" ] || [ "$v" == "8.2" ] || [ "$v" == "8.1" ] || [ "$v" == "8.0" ] || [ "$v" == "7.4" ]; then
		                echo "checkpoint_segments = 8192" >> $DATADIR/postgresql.conf
			else
	                	echo "max_wal_size = '128GB'" >> $DATADIR/postgresql.conf
		                echo "min_wal_size = '32GB'" >> $DATADIR/postgresql.conf
			fi

			pg_ctl -D $DATADIR -l $LOGDIR/pg-$v-$s-$t.log -w start

			sleep 1

			createdb test

			psql test -c "select * from pg_settings" > $LOGDIR/pg-settings-$v-$s-$t.log 2>&1

			# init using the same version
			pgbench -i -s $s test > $LOGDIR/pgbench-init-$v-$s-$t.log 2>&1

			if [ "$v" == "8.0" ] || [ "$v" == "8.2" ] || [ "$v" == "8.3" ]; then
				psql test <<EOF
alter table accounts rename to pgbench_accounts;
alter table branches rename to pgbench_branches;
alter table tellers rename to pgbench_tellers;
alter table history rename to pgbench_history;
EOF
			fi

			for r in $(seq 1 $RUNS); do

				for m in simple prepared; do

					mkdir -p $RESULTS/$s/$v/$t/$r/$m/

					for c in $(shuf clients.list); do

						psql test -c "checkpoint"

						if [ "$t" == "ro" ]; then
							$PGBENCH -S -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$c.log 2>&1
						elif [ "$t" == "rw" ]; then
							$PGBENCH -N -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$c.log 2>&1
						else
							$PGBENCH -M $m -j $c -c $c -T $DURATION -P 1 test > $RESULTS/$s/$v/$t/$r/$m/$c.log 2>&1
						fi

					done

				done

			done

			pg_ctl -D $DATADIR -w stop

			sleep 1

		done

	done

done
