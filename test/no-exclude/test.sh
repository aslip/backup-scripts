#!/bin/bash

set -e

TEST_EXCLUDE_TABLES=''; export TEST_EXCLUDE_TABLES # empty

../default/test.sh

