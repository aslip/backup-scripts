#!/bin/bash

usage() {
    cat << EOF
Enables/disables debug mode for all scripts in specified dir
by replacing the first line with #!/bin/bash -x

Examples

enable debug for all scripts in ./src:
    ${0##*/} on ./src

disable debug for all scripts in ./src:
    ${0##*/} off ./src
EOF
    exit 1
}

ON=$1
DIR=$2

if [[ -z $ON || -z $DIR ]]; then
    usage
fi

if [[ $ON == "on" ]]; then
    perl -pi -e 's|^#!/bin/((ba)?sh)[\s]*$|#!/bin/$1 -x\n|' $DIR/*
elif [[ $ON == "off" ]]; then
    perl -pi -e 's|^#!/bin/((ba)?sh)[\s]*-x[\s]*$|#!/bin/$1\n|' $DIR/*
else
    echo 'first parameter should be either "on" or "off"!'
    usage
fi

