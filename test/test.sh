#!/bin/bash

set -e

echo -n 'initializing... '

PATH=$PATH:../src/bin

. "`backup-include util`"

TEST_BACKUP_DIR='local_dir'; export TEST_BACKUP_DIR
TEST_FILES_DIR='www'; export TEST_FILES_DIR # files to backup
TEST_FILES_ALIAS='test'; export TEST_FILES_ALIAS
TEST_IGNORE_TABLES='table2 table3'; export TEST_IGNORE_TABLES
TEST_SERVER="`whoami`@localhost"; export TEST_SERVER
TEST_SERVER_PATH="`abs_dirname "$0"`/srv"; export TEST_SERVER_PATH # server path should be absolute

LOG_FILE="`abs_basename "$0"`.log"

TEST_DB='backup_test'; export TEST_DB
TEST_USER='root'; export TEST_USER
TEST_PASS=''; export TEST_PASS

MYSQL='mysql -uroot'

cleanup() {
    if [[ -e './tmp' ]]; then
        rm -r './tmp'
    fi
    if [[ -e "./$TEST_FILES_DIR" ]]; then
        rm -r "./$TEST_FILES_DIR"
    fi
    if [[ -e $TEST_SERVER_PATH ]]; then
        rm -r "$TEST_SERVER_PATH"
    fi
    if [[ -e "./$TEST_BACKUP_DIR" ]]; then
        rm -r "./$TEST_BACKUP_DIR"
    fi
    $MYSQL -e "DROP DATABASE IF EXISTS $TEST_DB"
    $MYSQL -e "CREATE DATABASE $TEST_DB DEFAULT CHARSET utf8"
}

cleanup

echo '' > $LOG_FILE

use_files() {
    local files_to_use=$1
    rm -rf "./$TEST_FILES_DIR"
    cp -a "./data/$files_to_use" "./$TEST_FILES_DIR"
}

use_db() {
    local sql_to_use=$1
    cat "./data/$sql_to_use" | $MYSQL "$TEST_DB"
}

restore_files() {
    local date=$1
    local archive=$2 # e.g. "test" or "test.inc"
    # don't produce error only when there is already a "restored-files" dir
    # this is different from "mkdir -p", because it will fail when e.g. "tmp" does not exist
    if [[ ! -e './tmp/restored-files' ]]; then
        mkdir './tmp/restored-files'
    fi
    if [[ $UID != 0 ]]; then
        local dar_opt=-O # ignore owner (owner can be restored only under root)
    fi
    # -w means "don't warn when overwriting files" and it must be there 
    # if we are simply restoring an archive
    dar $dar_opt -w -x "$TEST_SERVER_PATH/$date/files/$archive" -R './tmp/restored-files' >> $LOG_FILE
}

check_files() {
    local reference_files=$1
    diff -r './tmp/restored-files' "./data/$reference_files" >> $LOG_FILE
    # keep the restored-files dir for incremental restores
}

restore_db() {
    local date=$1
    bunzip2 -kc "$TEST_SERVER_PATH/$date/db/$TEST_DB.sql.bz2" > './tmp/restored-db.sql'
    cat './tmp/restored-db.sql' | $MYSQL "$TEST_DB"
    # keep the restored-db.sql for incremental restores
}

restore_db_incr() {
    local date=$1
    bunzip2 -kc "$TEST_SERVER_PATH/$date/db/$TEST_DB.sql.inc.bz2" > './tmp/sql.inc'
    # suppress diagnostics (ed's man requires this when ed's stdin is from script)
    ed -s './tmp/restored-db.sql' < './tmp/sql.inc'
    rm './tmp/sql.inc'
    cat './tmp/restored-db.sql' | $MYSQL "$TEST_DB"
}

. "`backup-include mysql`" # for backup_mysql_dump

check_db() {
    local reference_sql=$1
    local opt=`ignore_table_opt "$TEST_DB" "$TEST_IGNORE_TABLES"`
    backup_mysql_dump "$TEST_DB" "$TEST_USER" "$TEST_PASS" "$opt" './restored.sql'
    diff './restored.sql' "./data/$reference_sql"
    rm './restored.sql'
}

check_ignore_tables() {
    grep -vi 'table1' './tmp/restored-db.sql' > /dev/null
    grep -vi 'table2' './tmp/restored-db.sql' > /dev/null
}

DATE0=`date -d '+0 days' -I`
DATE1=`date -d '+1 days' -I`
DATE2=`date -d '+2 days' -I`

PATH="$PATH:../src/bin"

mkdir "$TEST_SERVER_PATH"
mkdir './tmp'

echo OK # initializing



echo -n 'making full backup... '
use_files 'test.0'
use_db 'backup_test.0.sql'
BACKUP_DATE="$DATE0" test-backup >> $LOG_FILE
echo OK

echo -n 'making incremental backup against a full backup... '
use_files 'test.1'
use_db 'backup_test.1.sql'
BACKUP_DATE="$DATE1" test-backup --incremental >> $LOG_FILE
echo OK

echo -n 'making incremental backup against an incremental backup... '
use_files 'test.2'
use_db 'backup_test.2.sql'
BACKUP_DATE="$DATE2" test-backup --incremental >> $LOG_FILE
echo OK




echo 'checking full backup...'
echo -n '   files... '
restore_files "$DATE0" "$TEST_FILES_ALIAS"
check_files 'test.0'
echo 'OK'
echo -n '   db... '
restore_db "$DATE0"
check_db 'reference.0.sql'
echo 'OK'
echo -n '   ignore-tables...'
check_ignore_tables
echo 'OK'



echo 'checking 1st incremental backup...'
echo -n '   files... '
restore_files "$DATE1" "$TEST_FILES_ALIAS.inc"
check_files 'test.1'
echo 'OK'
echo -n '   db... '
restore_db_incr "$DATE1"
check_db 'reference.1.sql'
echo 'OK'
echo -n '   ignore-tables...' 
check_ignore_tables
echo 'OK'


echo 'checking 2nd incremental backup...'
echo -n '   files... '
restore_files "$DATE2" "$TEST_FILES_ALIAS.inc"
check_files 'test.2'
echo 'OK'
echo -n '   db... '
restore_db_incr "$DATE2"
check_db 'reference.2.sql'
echo 'OK'
echo -n '  ignore-tables...' 
check_ignore_tables
echo 'OK'

echo 'cleanup...'

cleanup

echo
echo 'TEST PASSED'
echo

