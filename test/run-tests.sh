#!/bin/bash

. colors

MY_PATH=`readlink -f "$0"`
TEST_DIR=`dirname "$MY_PATH"`

for TEST in "$TEST_DIR"/*.sh; do
    if [[ `readlink -f "$TEST"` != $MY_PATH ]]; then
        TEST_NAME=`basename "$TEST"`
        echo -e "${C_BYELLOW}Running $TEST_NAME"
        echo -e "===================================================================${C_RESET}"
        if ! $TEST; then
            echo -e "\n${C_BWHITE}$TEST_NAME: ${C_BRED}TEST FAILED${C_RESET}\n"
            exit 1
        else
            echo -e "\n${C_BWHITE}$TEST_NAME: ${C_BGREEN}TEST PASSED${C_RESET}\n"
        fi
    fi
done

