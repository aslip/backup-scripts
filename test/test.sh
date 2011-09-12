#!/bin/bash


# exit on any error
set -e

echo -n "initializing... "

# all backups will be copied here
TEST_DIR=`readlink -f "$0"`
TEST_DIR=`dirname "$TEST_DIR"`
export TEST_DIR # for config/*

FILES_DIR="www"
export FILES_DIR # for config/*

BACKUP_TMP_DIR="$TEST_DIR/tmp_dir" # this is what backup scripts know as TMP_DIR
export BACKUP_TMP_DIR

BACKUP_EXCLUDE_TABLES="table2 table3"
export BACKUP_EXCLUDE_TABLES

BACKUP_FILES_ID=test
export BACKUP_FILES_ID

SRV_ID=$TEST_DIR/srv

TEST_DB=backup_test
MYSQL='mysql -uroot'
USER=root
PASS=-

cleanup() {
    if [[ -e $TEST_DIR/tmp ]]; then
        rm -r "$TEST_DIR/tmp"
    fi
    if [[ -e $TEST_DIR/$FILES_DIR ]]; then
        rm -r "$TEST_DIR/$FILES_DIR"
    fi
    if [[ -e $SRV_ID ]]; then
        rm -r "$SRV_ID"
    fi
    if [[ -e $BACKUP_TMP_DIR ]]; then
        rm -r "$BACKUP_TMP_DIR"
    fi
    $MYSQL -e "DROP DATABASE IF EXISTS $TEST_DB"
    $MYSQL -e "CREATE DATABASE $TEST_DB DEFAULT CHARSET utf8"
}

cleanup

. "$TEST_DIR/../src/functions"

use_files() {
    local FILES_TO_USE=$1
    rm -rf "$TEST_DIR/$FILES_DIR"
    cp -a "$TEST_DIR/data/$FILES_TO_USE" "$TEST_DIR/$FILES_DIR"
}

use_db() {
    local SQL_TO_USE=$1
    cat "$TEST_DIR/data/$SQL_TO_USE" | $MYSQL "$TEST_DB"
}

restore_files() {
    local DATE=$1
    local ARCHIVE=$2 # e.g. "test" or "test.inc"
    # don't produce error only when there is already a "restored-files" dir
    # i.e. this is different from "mkdir -p", because it will fail if e.g. "tmp" will not exist
    if [[ ! -e $TEST_DIR/tmp/restored-files ]]; then
        mkdir "$TEST_DIR/tmp/restored-files"
    fi
    if [[ $UID != 0 ]]; then
        DAR_OPT=-O # ignore owner (owner can be restored only under root)
    fi
    # -w means "don't warn when overwriting files" and it must be there 
    # if we are simply restoring an archive
    dar $DAR_OPT -w -x "$SRV_ID/$DATE/files/$ARCHIVE" -R "$TEST_DIR/tmp/restored-files" > /dev/null
}

check_files() {
    local REFERENCE_FILES=$1
    diff -r "$TEST_DIR/tmp/restored-files" "$TEST_DIR/data/$REFERENCE_FILES" > /dev/null
    # keep the restored-files dir for incremental restores
}

restore_db() {
    local DATE=$1
    bunzip2 -kc "$SRV_ID/$DATE/db/$TEST_DB.sql.bz2" > "$TEST_DIR/tmp/restored-db.sql"
    cat "$TEST_DIR/tmp/restored-db.sql" | $MYSQL "$TEST_DB"
    # keep the restored-db.sql for incremental restores
}

restore_db_incr() {
    local DATE=$1
    bunzip2 -kc "$SRV_ID/$DATE/db/$TEST_DB.sql.inc.bz2" > "$TEST_DIR/tmp/sql.inc"
    ed "$TEST_DIR/tmp/restored-db.sql" < "$TEST_DIR/tmp/sql.inc" 2> /dev/null
    rm "$TEST_DIR/tmp/sql.inc"
    cat "$TEST_DIR/tmp/restored-db.sql" | $MYSQL "$TEST_DB"
}

check_db() {
    local REFERENCE_SQL=$1
    local OPT=`make_ignore_table_option "$BACKUP_EXCLUDE_TABLES" "$TEST_DB"`
    DB="$TEST_DB" XTRA_OPT="$OPT" dump_to "$TEST_DIR/restored.sql"
    diff "$TEST_DIR/restored.sql" "$TEST_DIR/data/$REFERENCE_SQL"
    rm "$TEST_DIR/restored.sql"
}

check_ignore_tables() {
    grep -vi table1 "$TEST_DIR/tmp/restored-db.sql" > /dev/null
    grep -vi table2 "$TEST_DIR/tmp/restored-db.sql" > /dev/null
}

DATE0=`date -d '+0 days' -I`
DATE1=`date -d '+1 days' -I`
DATE2=`date -d '+2 days' -I`

PATH="$PATH:$TEST_DIR/../src"

mkdir "$SRV_ID"
mkdir "$TEST_DIR/tmp"

echo OK # initializing



echo -n 'making full backup... '
use_files test.0
use_db backup_test.0.sql
DATE="$DATE0" BACKUP_OPTIONS="$TEST_DIR/config" backup "$SRV_ID" > /dev/null
echo OK

echo -n 'making incremental backup against a full backup... '
use_files test.1
use_db backup_test.1.sql
DATE="$DATE1" BACKUP_OPTIONS="$TEST_DIR/config" backup-incr "$SRV_ID" > /dev/null
echo OK

echo -n 'making incremental backup against an incremental backup... '
use_files test.2
use_db backup_test.2.sql
DATE="$DATE2" BACKUP_OPTIONS="$TEST_DIR/config" backup-incr "$SRV_ID" > /dev/null
echo OK




echo checking full backup...
echo -n '   files... '
restore_files "$DATE0" "$BACKUP_FILES_ID"
check_files test.0
echo OK
echo -n '   db... '
restore_db "$DATE0"
check_db reference.0.sql
echo OK
echo -n '   ignore-tables...'
check_ignore_tables
echo OK



echo checking 1st incremental backup...
echo -n '   files... '
restore_files "$DATE1" "$BACKUP_FILES_ID.inc"
check_files test.1
echo OK
echo -n '   db... '
restore_db_incr "$DATE1"
check_db reference.1.sql
echo OK
echo -n '   ignore-tables...' 
check_ignore_tables
echo OK


echo checking 2nd incremental backup...
echo -n '   files... '
restore_files "$DATE2" "$BACKUP_FILES_ID.inc"
check_files test.2
echo OK
echo -n '   db... '
restore_db_incr "$DATE2"
check_db reference.2.sql
echo OK
echo -n '  ignore-tables...' 
check_ignore_tables
echo OK

echo cleanup...

cleanup

echo
echo TEST PASSED
echo

