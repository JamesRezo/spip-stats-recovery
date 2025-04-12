#!/usr/bin/env bash

# Usage : bin/compile.sh
# Description : Transform JSON stats files into CSV files, date are stored in GMT Timezone
# Needs jq

SINCE=${1:-2022-02-23}

# Lat commit formatted date
LAST_COMMIT="$(git log -1 --format="%at" | xargs -I{} date -d @{} +%Y%m%d%H%M.%S)"

[ -f spip.csv ] && {
    touch -m -t "${LAST_COMMIT}" spip.csv
    SPIP_POLL="$(find spip -type f -name \*.json -newer spip.csv | sort)"
}
[ -f php.csv ] && {
    touch -m -t "${LAST_COMMIT}" php.csv
    PHP_POLL="$(find php -type f -name \*.json -newer php.csv | sort)"
}

[ ! -f spip.csv ] && {
    echo "date,version,sites" > spip.csv
    SPIP_POLL="$(find spip -type f -name \*.json | sort)"
}
[ ! -f php.csv ] && {
    echo "date,version,sites" > php.csv
    PHP_POLL="$(find php -type f -name \*.json | sort)"
}

for poll in $SPIP_POLL
do
    datetime="$(sed -e 's#^\w\+/##' -e 's#\.json$##' -e 's#/#-#g' -e 's#-\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)$#T\1:\2:\3Z#' <<< "${poll}")"
    jq --arg datetime "${datetime}" -r '.[]|[$datetime,"\""+.version+"\"",.sites]|join(",")' "$poll"
done >> spip.csv

for poll in $PHP_POLL
do
    datetime="$(sed -e 's#^\w\+/##' -e 's#\.json$##' -e 's#/#-#g' -e 's#-\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)$#T\1:\2:\3Z#' <<< "${poll}")"
    jq --arg datetime "${datetime}" -r '.[]|[$datetime,"\""+.version+"\"",.sites]|join(",")' "$poll"
done >> php.csv

FIRST="$(grep -n "${SINCE}" spip.csv | head -1 | cut -d: -f1)"
[ "${FIRST}" != "" ] && {
    LINES="$(wc -l spip.csv | cut -d' ' -f1)"
    LAST="$(("${LINES}"-"${FIRST}"+1))"
    echo "date,version,sites"
    tail -n "${LAST}" spip.csv
} > "spip.since-${SINCE}.csv"

FIRST="$(grep -n "${SINCE}" php.csv | head -1 | cut -d: -f1)"
[ "${FIRST}" != "" ] && {
    LINES="$(wc -l php.csv | cut -d' ' -f1)"
    LAST="$(("${LINES}"-"${FIRST}"+1))"
    echo "date,version,sites"
    tail -n "${LAST}" php.csv
} > "php.since-${SINCE}.csv"

exit 0
