#!/usr/bin/env bash

# Usage : bin/get.sh
# Description : Get JSON files from https://stats.spip.net
# Needs curl, jq

STATS_SPIP_NET="https://stats.spip.net/spip.php?page=stats.json"

# Get Raw datas
curl -s "${STATS_SPIP_NET}" | \
    # Transform to have useful datas in correct type
    jq '{
        total_sites: .total_sites|tonumber,
        spip: [.versions[]|{version, sites: .sites|tonumber}],
        php: [.php[]|{version, sites: .sites|tonumber}]
    }' > stats.json

for v in $(jq -r '.spip[]|.version' stats.json);
do
    curl -s "${STATS_SPIP_NET}&v=${v}" | \
    jq '{
        total_sites: .total_sites|tonumber,
        php: [.php[]|{version, sites: .sites|tonumber}]
    }' > "stats.${v}.json"
done

exit 0
