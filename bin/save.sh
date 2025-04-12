#!/usr/bin/env bash

# Usage : save
# Description : Save the backup repository
# Needs : git

# shellcheck source=bin/tools.sh
source tools

[[ $DEBUG ]] && echo "save:$0"

SPIP_JSON=${1:-spip.json}
DATE=$(date -r "$SPIP_JSON" '+%Y/%m/%d/%H%M%S')

[[ $DEBUG ]] && {
    git status
    echo "Committting with message \"poll ${DATE}\""
    echo "user.email=${GIT_AUTHOR_EMAIL}"
    echo "user.name=${GIT_AUTHOR_NAME}"
}

test -n "${GIT_AUTHOR_EMAIL}" && git config user.email "${GIT_AUTHOR_EMAIL}"
test -n "${GIT_AUTHOR_NAME}" && git config user.name "${GIT_AUTHOR_NAME}"

git add .
git commit -m "poll ${DATE}"

exit 0
