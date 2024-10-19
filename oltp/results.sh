#!/usr/bin/bash

RESULTS=$1

for s in 100 1000 10000; do

        for v in 18 17 16 15 14 13 12 11 10 9.6 9.5 9.4 9.3 9.2 9.1 9.0 8.4 8.3 8.2 8.0; do

                for t in ro rw rw-full; do

			if [ ! -d "$RESULTS/$s/$v/$t" ]; then
				continue
			fi

			for r in $(ls $RESULTS/$s/$v/$t); do

	                        for m in simple prepared; do

        	                        for c in 1 16 32 64 128 256; do

						if [ ! -f "$RESULTS/$s/$v/$t/$r/$m/$c.log" ]; then
							continue
						fi

						tps=$(grep 'tps = ' $RESULTS/$s/$v/$t/$r/$m/$c.log | awk '{print $3}')
						med=$(grep 'progress' $RESULTS/$s/$v/$t/$r/$m/$c.log | awk '{print $4}' | sort -n | head -n 30 | tail -n 1)

						echo $s $v $t $r $m $c $tps $med

					done

				done

			done

		done

	done

done

