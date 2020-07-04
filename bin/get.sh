#!/usr/bin/env bash

# Usage : bin/get.sh
# Description : Get JSON files from https://stats.spip.net
# Needs curl, jq

STATS_SPIP_NET="https://stats.spip.net/spip.php?page=stats.json"

# Get SPIP Versions exposed
curl -s "${STATS_SPIP_NET}" | jq '[.versions[]|.version]' > stats.json

# For each version, get number of verified sites and number of PHP versions exposed
TMP_FILES=
for v in $(jq '.[]' stats.json);
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
echo "$TMP_FILES" | xargs jq -s '.' > stats.json
echo "$TMP_FILES" | xargs rm

echo -n "Verified sites:"
jq '[.[]|.sites] | add' stats.json | xargs printf "% 6d\n"
echo -n "PHP exposed   :"
jq '[.[].php[]|.sites] | add' stats.json | xargs printf "% 6d\n"

exit 0
