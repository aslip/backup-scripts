#!/bin/bash -x

# clean
rm -rf ./test
# ...
cp -a ./test.1 ./test
# ...
backup-files ./test test 2011-09-01


