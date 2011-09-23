#!/bin/bash

set -e

. '../test-common'

PATH="$PATH:`abs_dirname "$0"`"; export PATH # for 'backup'

#
# making backups
#

test_begin 'making full backup'
    first_date
    use_data '0'
    backup
test_end

test_begin 'making incremental backup against a full backup'
    next_date
    use_data '1'
    backup --incremental
test_end

test_begin 'making incremental backup against an incremental backup'
    next_date
    use_data '2'
    backup --incremental
test_end



#
# checking backups
#

check_backup() {
    local title=$1
    local reference=$2
    test_begin "checking $title files"
        restore_files "${DATE[$reference]}"
        check_files "$reference"
    test_end
    test_begin "checking $title db"
        restore_db "${DATE[$reference]}"
        check_db "$reference"
    test_end
    test_begin "checking $title ignore-tables"
        check_ignore_tables
    test_end
}

check_backup 'full backup' '0'
check_backup '1st incremental backup' '1'
check_backup '2nd incremental backup' '2'



cleanup

