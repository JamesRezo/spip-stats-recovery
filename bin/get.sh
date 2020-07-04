#!/usr/bin/env bash

# Usage : bin/get.sh
# Description : Get JSON files from https://stats.spip.net
# Needs curl, jq

STATS_SPIP_NET="https://stats.spip.net/spip.php?page=stats.json"

# Archive stats.json file if exists.
[[ -f stats.json ]] && LAST_POLL=$(date -r stats.json '+%Y/%m/%d/%H%M%S').json
[[ -f stats.json ]] && mkdir -p "$(dirname "$LAST_POLL")" && cp -p stats.json "$LAST_POLL"

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

SPIP=$(jq '[.[]|.sites] | add' stats.json | xargs printf "% 6d")
PHP=$(jq '[.[].php[]|.sites] | add' stats.json | xargs printf "% 6d")
RATIO=$(echo "$PHP" | jq '. / '"$SPIP"' * 100' | xargs printf "% 9.2f")"%"
echo "Verified sites:$SPIP"
echo "PHP exposed   :$PHP"
echo "Ratio         :$RATIO"

# Check diff with last poll
[[ -f "$LAST_POLL" ]] && if diff -u "$LAST_POLL" stats.json > diff.patch; then
    echo "No change since last poll."
    rm "$LAST_POLL"
else
    echo "Changes to store! See diff.patch"
    cat diff.patch
    # TODO rm diff.patch
fi

exit 0
