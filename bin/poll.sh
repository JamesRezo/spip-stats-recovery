#!/usr/bin/env bash

# Usage : poll [file]
# Description : Get JSON files from https://contrib.spip.net
# Needs curl, jq

# shellcheck source=bin/tools.sh
source tools

[[ $DEBUG ]] && echo "poll:$0"

[[ -f .polling ]] && echo "Polling ... Try again in a few seconds." && exit 0
touch .polling
echo "Doing one poll..."

POLL_FILE=${1:-spip.json}

STATS_SPIP_NET="https://contrib.spip.net/spip.php?page=stats.json"

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
makeDirForFile "$POLL_FILE"
slurpTmpFilesTo "$POLL_FILE"

rm -f versions.json
echo "Done."
rm -f .polling
touch .polled

exit 0
