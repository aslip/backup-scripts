#!/bin/bash

PREFIX=${PREFIX:-'/usr/local'}

rm "$PREFIX/bin/backup-init"
rm "$PREFIX/bin/backup-include"
rm "$PREFIX/bin/backup-mysql"
rm "$PREFIX/bin/backup-dar"
rm "$PREFIX/bin/backup-scp"
rm -r "$PREFIX/lib/backup-scripts"

