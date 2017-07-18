#!/bin/bash

for name in "$@"
do
    docker ps --format '{{.Names}}' | egrep "^${name}\$" > /dev/null
    if [ $? != 0 ]; then
        DEAD="$DEAD $name"
    fi
done

if [ "X$DEAD" != "X" ]; then
    echo "CRITICAL - missing containers: $DEAD."
    exit 2
else
    echo "OK - All containers running"
    exit 0
fi
