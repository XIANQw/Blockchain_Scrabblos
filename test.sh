#!/bin/bash

rm -Rf _build
rm -Rf tmp

TEMPDIR=$(pwd)/tmp
mkdir $TEMPDIR
N_AUTHORS=1
N_POL=1
dune build

(
    sleep 3
    for i in `seq 1 $N_AUTHORS`; do
        dune exec ./src/author.exe >$TEMPDIR/author$i.LOG 2>$TEMPDIR/author$i.err &
    done

    sleep 10



    for i in `seq 1 $N_POL`; do
        dune exec ./src/politicien.exe >$TEMPDIR/politicien$i.LOG  2>$TEMPDIR/politicien$i.err &
    done
) &

echo "LOG FILES in $TEMPDIR"
dune exec ./src/main_server.exe | tee $TEMPDIR/main_server.LOG
