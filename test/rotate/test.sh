#!/bin/bash

set -e

. '../test-common'

PATH="$PATH:`abs_dirname "$0"`"; export PATH # for 'backup'

DATA=0

rotate_use_data() {
    use_data $DATA

    DATA=$(($DATA + 1))
    if (($DATA > 2)); then
        DATA=0
    fi
}

first_date
for week in `seq 1 3`; do
    test_begin "week $week, day 1: full backup"
        next_date
        rotate_use_data
        backup > /dev/null; read
    test_end

    for day in `seq 2 7`; do
        test_begin "week $week, day $day: incremental backup"
            next_date
            rotate_use_data
            backup --incremental > /dev/null; read
        test_end
    done
done

