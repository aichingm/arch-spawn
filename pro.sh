#!/bin/bash
VAL=$( awk -F "=" "$(echo '/'"$2"'/{ print $2}')" $(dirname $0)/profiles/$1.ini)
if [[ "" == $VAL ]]; then 
    awk -F "=" "$(echo '/'"${2}"'/{ print $2}')" $(dirname $0)/profiles/default.ini
    >&2 echo Falling back to default.ini
else
    echo $VAL
fi
