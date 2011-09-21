#!/bin/bash

set -e

echo -n 'initializing... '

PATH="$PATH:`readlink -f .`:`readlink -f ../src/bin`"; export PATH 

. "`backup-include util`"

TEST_BACKUP_DIR='local_dir'; export TEST_BACKUP_DIR
TEST_FILES_DIR='www'; export TEST_FILES_DIR # files to backup
TEST_FILES_ALIAS='test'; export TEST_FILES_ALIAS
TEST_EXCLUDE_TABLES='table2
    table3' # newline intended
TEST_SERVER="`whoami`@localhost"; export TEST_SERVER
TEST_SERVER_PATH="`abs_dirname "$0"`/srv"; export TEST_SERVER_PATH # server path should be absolute

LOG_FILE="`abs_basename "$0"`.log"

TEST_DB='backup_test'; export TEST_DB
TEST_USER='root'; export TEST_USER
TEST_PASS=''; export TEST_PASS

MYSQL='mysql -uroot'

. test-body

