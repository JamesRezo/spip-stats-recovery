#!/usr/bin/env bash

# Usage : bin/compile.sh
# Description : Transform JSON stats files into CSV files, date are stored in GMT Timezone
# Needs jq

echo "date,version,sites" > spip.csv

for poll in $(find spip -type f -name \*.json | sort)
do
    datetime=$(TZ=":GMT" date -r "$poll" '+%Y-%m-%dT%H:%M:%SZ')
    for data in $(jq -r '.[]|["\""+.version+"\"",.sites]|join(",")' "$poll")
    do
        echo "${datetime},${data}" >> spip.csv
    done
done

echo "date,version,sites" > php.csv

for poll in $(find php -type f -name \*.json | sort)
do
    datetime=$(TZ=":GMT" date -r "$poll" '+%Y-%m-%dT%H:%M:%SZ')
    for data in $(jq -r '.[]|["\""+.version+"\"",.sites]|join(",")' "$poll")
    do
        echo "${datetime},${data}" >> php.csv
    done
done

exit 0
