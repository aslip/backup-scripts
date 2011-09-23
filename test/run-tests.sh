#!/bin/bash

. colors

MY_PATH=`readlink -f "$0"`
TEST_DIR=`dirname "$MY_PATH"`

get_test_current() {
    if [[ -e '/tmp/backup-scripts/test-current' ]]; then
        cat '/tmp/backup-scripts/test-current'
        rm '/tmp/backup-scripts/test-current'
    fi
}

for TEST in "$TEST_DIR"/*.sh; do
    if [[ `readlink -f "$TEST"` != $MY_PATH ]]; then
        TEST_NAME=`basename "$TEST"`
        echo -e "${C_BYELLOW}Running $TEST_NAME"
        echo -e "===================================================================${C_RESET}"
        if ! $TEST; then
            echo -e "${C_BRED}`get_test_current` - FAILED${C_RESET}"
            echo -e "\n${C_BWHITE}$TEST_NAME: ${C_BRED}TEST FAILED${C_RESET}\n"
            exit 1
        else
            echo -e "\n${C_BWHITE}$TEST_NAME: ${C_BGREEN}TEST PASSED${C_RESET}\n"
        fi
    fi
done

