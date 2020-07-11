#!/usr/bin/env bash

# Usage : print [spip.json]
# Description : Display last poll summary
# Needs jq

# shellcheck source=bin/tools.sh
source tools

SPIP_JSON=${1:-spip.json}

LAST=$(date -r "$SPIP_JSON" '+%Y-%m-%d %H:%M:%S')
SPIP=$(jq '[.[]|.sites] | add' "$SPIP_JSON" | xargs printf "% 6d")
PHP=$(jq '[.[].php[]|.sites] | add' "$SPIP_JSON" | xargs printf "% 6d")
RATIO=$(echo "$PHP" | jq '. / '"$SPIP"' * 100' | xargs printf "% 9.2f")"%"
echo "Last poll was on $LAST"
echo
echo "Verified sites:$SPIP"
echo "PHP exposed   :$PHP"
echo "Ratio         :$RATIO"
echo
