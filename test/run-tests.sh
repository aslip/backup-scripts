#!/bin/bash

MY_PATH=`readlink -f "$0"`
TEST_DIR=`dirname "$MY_PATH"`

for TEST in "$TEST_DIR"/*.sh; do
    if [[ `readlink -f "$TEST"` != $MY_PATH ]]; then
        TEST_NAME=`basename "$TEST"`
        echo =============== Running $TEST_NAME ===============
        if ! $TEST; then
            echo -e "\n$TEST_NAME: TEST FAILED\n"
            exit 1
        fi
    fi
done

