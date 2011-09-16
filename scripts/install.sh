#!/bin/bash

PREFIX=${PREFIX:-'/usr/local'}

cp -a --no-preserve=ownership src/bin "$PREFIX"
cp -a --no-preserve=ownership src/lib "$PREFIX"

