#!/usr/bin/env bash

# Usage : bin/poll.sh
# Description : Get JSON files from https://stats.spip.net
# Needs curl, jq

# shellcheck source=bin/tools.sh
source tools

[[ $DEBUG ]] && echo "poll:$0"

STATS_SPIP_NET="https://stats.spip.net/spip.php?page=stats.json"

# Get SPIP Minor Versions exposed (x.y)
# Stored as strings to avoid float to integer conversion: x.0 -> x
getFileFromRemote "$STATS_SPIP_NET" versions.json "[.versions[]|.version]"

# For each minor version
# Keep only php versions with sites > 0
# TODO Track each patch (x.y.z*) version
for v in $(jq -r '.[]' versions.json);
do
    getFileFromRemote "$STATS_SPIP_NET&v=$v" "stats.$v.json" '{
        version: "'"${v}"'",
        sites: .total_sites|tonumber,
        php: [.php[]|{version, sites: .sites|tonumber}|select(.sites>0)]
    }'
    TMP_FILES="$TMP_FILES stats.$v.json"
done
slurpTmpFilesTo spip.json

rm -f versions.json

exit 0
