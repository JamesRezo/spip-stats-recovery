#!/usr/bin/env bash

# Usage : save
# Description : Save the backup repository
# Needs : git

# shellcheck source=bin/tools.sh
source tools

[[ $DEBUG ]] && echo "save:$0"

SPIP_JSON=${1:-spip.json}
DATE=$(date -r "$SPIP_JSON" '+%Y/%m/%d/%H%M%S')

[[ $DEBUG ]] && git status
[[ $DEBUG ]] && echo "Committting with message \"poll ${DATE}\""
git add .
git commit -m "poll ${DATE}"

exit 0
