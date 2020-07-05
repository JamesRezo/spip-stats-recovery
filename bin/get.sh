#!/usr/bin/env bash

# Usage : bin/get.sh
# Description : Get JSON files from https://stats.spip.net
# Needs curl, jq

STATS_SPIP_NET="https://stats.spip.net/spip.php?page=stats.json"

# Archive spip.json file if exists.
[[ -f spip.json ]] && LAST_POLL=spip/$(date -r spip.json '+%Y/%m/%d/%H%M%S').json
[[ -f spip.json ]] && mkdir -p "$(dirname "$LAST_POLL")" && cp -p spip.json "$LAST_POLL"

# Get SPIP Versions exposed
curl -s "${STATS_SPIP_NET}" | jq '[.versions[]|.version]' > spip.json

# For each version, get number of verified sites and number of PHP versions exposed
# TODO process and insert last patch version
# jq '.versions[].version' stats.${v//\"/}.json | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -n | tail -1
TMP_FILES=
for v in $(jq '.[]' spip.json);
do
    curl -s "${STATS_SPIP_NET}&v=${v//\"/}" | \
    jq '{
        version: '"${v}"',
        sites: .total_sites|tonumber,
        php: [.php[]|{version, sites: .sites|tonumber}]
    }' > "stats.${v//\"/}.json"
    TMP_FILES="$TMP_FILES stats.${v//\"/}.json"
done

# Slurp temporary files into one json array
echo "$TMP_FILES" | xargs jq -s '.' > spip.json
echo "$TMP_FILES" | xargs rm

SPIP=$(jq '[.[]|.sites] | add' spip.json | xargs printf "% 6d")
PHP=$(jq '[.[].php[]|.sites] | add' spip.json | xargs printf "% 6d")
RATIO=$(echo "$PHP" | jq '. / '"$SPIP"' * 100' | xargs printf "% 9.2f")"%"
echo "Verified sites:$SPIP"
echo "PHP exposed   :$PHP"
echo "Ratio         :$RATIO"

# Check diff with last poll
[[ -f "$LAST_POLL" ]] && if diff -u "$LAST_POLL" spip.json > diff.patch; then
    echo "No change since last poll."
    rm "$LAST_POLL"
else
    echo "Changes to store! See diff.patch"
    #TODO Friendly output changes
    cat diff.patch

    # Archive stats in php directory
    mkdir -p "$(dirname "${LAST_POLL/#spip/php}")"
    #Inverse matrix spip/php in php/spip sites number
    TMP_FILES=
    for v in $(jq '.[]|.version' spip.json);
    do
        jq '.[]|select(.version=='"$v"')|.php[]|{version, spip: [{version: '"$v"', sites}]}' spip.json > "spip.${v//\"/}.json"
        TMP_FILES="$TMP_FILES spip.${v//\"/}.json"
    done
    # Slurp temporary files into one json array
    echo "$TMP_FILES" | xargs jq -s '.' > php.json
    echo "$TMP_FILES" | xargs rm

    TMP_FILES=
    for v in $(jq '.[]|.version' php.json);
    do
        jq '[.[]|select(.version=='"$v"')|.spip[]]|{version: '"$v"', sites: [.[]|.sites]|add, spip: .}' php.json > "php.${v//\"/}.json"
        TMP_FILES="${TMP_FILES} php.${v//\"/}.json"
    done
    # Slurp temporary files into one json array
    TMP_FILES=$(echo "$TMP_FILES" | tr " " "\n" | sort | uniq)
    echo "$TMP_FILES" | xargs jq -s '.' > php.json
    echo "$TMP_FILES" | xargs rm
    cp php.json "${LAST_POLL/#spip/php}"
    touch -m -r "$LAST_POLL" "${LAST_POLL/#spip/php}"
fi

exit 0
