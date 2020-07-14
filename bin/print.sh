#!/usr/bin/env bash

# Usage : print [spip.json]
# Description : Display last poll summary
# Needs jq

# shellcheck source=bin/tools.sh
source tools

SPIP_JSON=${1:-spip.json}
SPIP_BASE_ARCHIVE=${SPIP_JSON%.*}

# Error if SPIP_JSON does not exist.
[[ ! -f "$SPIP_JSON" ]] && >&2 echo "Bad SPIP JSON file '$SPIP_JSON'." && exit 1

LAST=$(date -r "$SPIP_JSON" '+%Y-%m-%d %H:%M:%S')
SPIP=$(jq '[.[]|.sites] | add' "$SPIP_JSON" | xargs printf "% 6d")
PHP=$(jq '[.[].php[]|.sites] | add' "$SPIP_JSON" | xargs printf "% 6d")
RATIO=$(echo "$PHP" | jq '. / '"$SPIP"' * 100' | xargs printf "% 9.2f")"%"

# Compare and output diffs since before last poll
# On first time run, SPIP_BASE_ARCHIVE does not exists
[[ -d "$SPIP_BASE_ARCHIVE" ]] && BEFORE_LAST_POLL=$(find "$SPIP_BASE_ARCHIVE" -type f -name \*.json | sort | tail -1)
[[ -z "$BEFORE_LAST_POLL" ]] && echo "First run! Nothing to compare."
[[ -n "$BEFORE_LAST_POLL" ]] && if  ! diff -u "$BEFORE_LAST_POLL" "$SPIP_JSON" > diff.patch; then
    LAST="$LAST (compared with $(date -r "$BEFORE_LAST_POLL" '+%Y-%m-%d %H:%M:%S'))"
    BEFORE_SPIP=$(jq '[.[]|.sites] | add' "$BEFORE_LAST_POLL")
    COMPARE=$(printf "%+4d" "$((SPIP-BEFORE_SPIP))")
    SPIP="$SPIP     ($COMPARE)"
    BEFORE_PHP=$(jq '[.[].php[]|.sites] | add' "$BEFORE_LAST_POLL")
    COMPARE=$(printf "%+4d" "$((PHP-BEFORE_PHP))")
    PHP="$PHP     ($COMPARE)"
fi

echo "Last poll was on $LAST"
echo
echo "Verified sites:$SPIP"
echo "PHP exposed   :$PHP"
echo "Ratio         :$RATIO"
echo

exit 0
