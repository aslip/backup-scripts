#!/bin/bash

PREFIX=${PREFIX:-'/usr/local'}

cp -a --no-preserve=ownership bin "$PREFIX"
cp -a --no-preserve=ownership lib "$PREFIX"

