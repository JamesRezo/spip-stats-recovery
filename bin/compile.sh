#!/usr/bin/env bash

# Usage : bin/compile.sh
# Description : Transform JSON stats files into CSV files, date are stored in GMT Timezone
# Needs jq

# TODO do not regenerate csv if exist and add what is missing ...
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

echo "date,version,sites" > spip.since-2022-02-23.csv && \
tail -$(expr $(
    expr $(wc -l spip.csv | tr "s" "," | cut -d, -f1 | tr -d "[:space:]") - $(grep -n 2022-02-23 spip.csv | head -1 | cut -d: -f1)
) + 1) spip.csv >> spip.since-2022-02-23.csv

echo "date,version,sites" > php.since-2022-02-23.csv && \
tail -$(expr $(
    expr $(wc -l php.csv | tr "p" "," | cut -d, -f1 | tr -d "[:space:]") - $(grep -n 2022-02-23 php.csv | head -1 | cut -d: -f1)
) + 1) php.csv >> php.since-2022-02-23.csv

exit 0
