#!/usr/bin/env bash

# Usage : archive [spip.json] [php.json]
# Description : Store changes if any is detected
# Needs jq

# shellcheck source=bin/tools.sh
source tools

SPIP_JSON=${1:-spip.json}
PHP_JSON=${2:-php.json}

# Error if SPIP_JSON does not exist.
[[ ! -f "$SPIP_JSON" ]] && >&2 echo "Bad SPIP JSON file '$SPIP_JSON'." && exit 1

SPIP_BASE_ARCHIVE=${SPIP_JSON%.*}

# On first time run, SPIP_BASE_ARCHIVE does not exists
[[ -d "$SPIP_BASE_ARCHIVE" ]] && LAST_POLL=$(find "$SPIP_BASE_ARCHIVE" -type f -name \*.json | sort | tail -1)
[[ -z "$LAST_POLL" ]] && LAST_POLL=/dev/null

if diff -u "$LAST_POLL" "$SPIP_JSON" > diff.patch; then
    echo "No change since last poll."
else
    echo "Changes to store! See diff.patch"
    LAST_POLL=$SPIP_BASE_ARCHIVE/$(date -r "$SPIP_JSON" '+%Y/%m/%d/%H%M%S').json
    makeDirForFile "$LAST_POLL"
    cp -p "$SPIP_JSON" "$LAST_POLL"

    spip2php "$@"

    # Archive stats in php directory
    if [ -f "$PHP_JSON" ]; then
        PHP_BASE_ARCHIVE=${PHP_JSON%.*}
        makeDirForFile "${LAST_POLL/#$SPIP_BASE_ARCHIVE/$PHP_BASE_ARCHIVE}"
        cp "$PHP_JSON" "${LAST_POLL/#$SPIP_BASE_ARCHIVE/$PHP_BASE_ARCHIVE}"
        touch -m -r "$LAST_POLL" "${LAST_POLL/#$SPIP_BASE_ARCHIVE/$PHP_BASE_ARCHIVE}"
    fi
fi

exit 0
