#!/bin/bash

. colors

get_test_current() {
    if [[ -e '/tmp/backup-scripts/test-current' ]]; then
        cat '/tmp/backup-scripts/test-current'
        rm '/tmp/backup-scripts/test-current'
    fi
}

restore_date() {
    if [[ -e './days' ]]; then
        local days=`cat './days'`
        sudo date -s "-$days days"
        rm './days'
    fi
}

find '.' -mindepth 1 -maxdepth 1 -type d | while read test; do
    if [[ -e "$test/test.sh" ]]; then
        test_name=`basename "$test"`
        echo -e "${C_BYELLOW}Running test: $test_name"
        echo -e "===================================================================${C_RESET}"
        pushd "$CWD" > /dev/null; cd "$test"
        ./test.sh; result=$?
        restore_date
        popd > /dev/null
        if (( $result != 0 )); then
            echo -e "${C_BRED}`get_test_current` - FAILED${C_RESET}"
            echo -e "\n${C_BWHITE}$test_name: ${C_BRED}TEST FAILED${C_RESET}\n"
            exit 1
        else
            echo -e "\n${C_BWHITE}$test_name: ${C_BGREEN}TEST PASSED${C_RESET}\n"
        fi
    fi
done

