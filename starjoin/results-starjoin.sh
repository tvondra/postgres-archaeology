#!/usr/bin/bash

DIR=$1

for s in $(ls $DIR/results); do

	for v in $(ls $DIR/results/$s); do

		for r in $(ls $DIR/results/$s/$v); do

			for m in $(ls $DIR/results/$s/$v/$r); do

				for c in $(ls $DIR/results/$s/$v/$r/$m); do

					tps=$(grep 'tps = ' $DIR/results/$s/$v/$r/$m/$c | awk '{print $3}')

					echo $s $v $r $m ${c/.log/} $tps

				done

			done

		done

	done

done
