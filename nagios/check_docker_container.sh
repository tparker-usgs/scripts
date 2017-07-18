#!/bin/bash

for name in "$@"
do
    docker ps --format '{{.Names}}' | egrep "^${name}\$" > /dev/null
    if [ $? != 0 ]; then
        DEAD="$DEAD $name"
    fi
done

if [ "X$DEAD" == "X" ]; then
    echo "OK - Found $@"
    exit 0
else
    echo "CRITICAL - missing containers: $DEAD."
    exit 2
fi
