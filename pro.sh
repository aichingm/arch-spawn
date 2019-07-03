#!/bin/bash
VAL=$( awk -F "=" "$(echo '/^'"$2"'/{ print $2}')" $(dirname $0)/profiles/$1.ini)
if [[ "" == $VAL ]]; then
    awk -F "=" "$(echo '/^'"$2"'/{ print $2}')" $(dirname $0)/profiles/default.ini
    echo Falling back to default.ini >&2
else
    echo $VAL
fi
