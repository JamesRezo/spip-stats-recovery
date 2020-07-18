#!/usr/bin/env bash

# Usage : include "source tools" in a bash script
# Description : Helpers
# Needs curl, jq

# Usage : slugify [string]
# Description : https://example.org/path/script?V=1.0 -> https-example-org-path-script-v-1-0
# Note : Saddly, slugify does not transliterate non ascii letters
function slugify
{
    echo "$1" | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+|-+$//g' | tr '[:upper:]' '[:lower:]'
}

# Usage : makeDirForFile path/to/file
# Description : create path/to directory if not exists
function makeDirForFile
{
    local FILE=$1
    local DIR

    DIR=$(dirname "${FILE}")
    test -d "$DIR" || mkdir -p "$DIR"
}

# Slurp temporary files into one json array
# Usage : slurpTmpFilesTo path/to/file
# Description : TMP_FILES as a string of existing valid JSON files separated by space
#               Sorted alphabetically by filename
#               Put JSON content of each file like
#               [content1,content2,...,contentn] in path/to/file
#               Delete each existing valid JSON files and reset TMP_FILES
function slurpTmpFilesTo
{
    TMP_FILES=$(echo "$TMP_FILES" | tr " " "\n" | sort | uniq)

    makeDirForFile "$1"
    echo "$TMP_FILES" | xargs jq -s '.' > "$1"
    echo "$TMP_FILES" | xargs rm

    TMP_FILES=
}

# Guess a filename from an url
# Usage : getDefaultFilename url
# Descripton : use a slugified basename of url with magick deletion of "spip.php?page="
#              use hostname if no basename (i.e. https://example.org -> example-org.json)
function getDefaultFilename
{
    local URL=$1

    # Error if URL not provided
    [[ -z "$URL" ]] && >&2 echo "URL not provided." && exit 1

    echo "$(slugify "$(basename "${URL/.json/}" | sed "s/spip\.php\?page=//")").json"
}

# Usage : getFileFromRemote url
#         getFileFromRemote url path/to/file
#         getFileFromRemote url path/to/file "jq filter"
# Description : test, retrieve, check and compress a remote json file to local filesystem
#               files are cached in .cache directory by default (see CACHE_PATH env variable)
#               Errors output on STDERR may be :
#                   "URL not provided." if called without any parameters
#                   "Bad remote file." if HTTP status is not 200
#                   "Bad format." if jq transformation produces some errors
#               DEBUG=1 getFileFromRemote url will print stages on STDOUT
function getFileFromRemote
{
    local URL=$1
    local DEST=$2
    local FILTER=${3:-.}
    local HTTP_STATUS
    local RAW
    local VALID

    makeDirForFile "$CACHE_RAW_FILE"
    makeDirForFile "$CACHE_VALID_FILE"

    # Error if URL not provided
    [[ -z "$URL" ]] && >&2 echo "URL not provided." && exit 1

    # Guess DEST parameter, if not provided
    [[ -z "$DEST" ]] && DEST=$(getDefaultFilename "$URL")

    # Get HTTP Status. 200/304 expected
    [[ $DEBUG ]] && echo "Testing ${URL}"

    _slug="$(slugify "$URL")"
    RAW=${CACHE_RAW_FILE/_url_/$_slug}
    if [ -f "$RAW" ]; then
        # HTTP 304 management date as RFC7232 format
        DATE_FORMAT=$(TZ=":GMT" date -r "${RAW}" '+%a, %d %b %Y %H:%M:%S %Z')
        [[ $DEBUG ]] && echo "Comparing with ${RAW} at ${DATE_FORMAT}"
        HTTP_STATUS=$(curl --head --header "If-Modified-Since: ${DATE_FORMAT}" --write-out '%{http_code}' --connect-timeout 1 --output /dev/null --silent "${URL}")
    else
        HTTP_STATUS=$(curl --head --write-out '%{http_code}' --connect-timeout 1 --output /dev/null --silent "${URL}")
    fi
    [[ $DEBUG ]] && echo "HTTP_STATUS ${HTTP_STATUS}"
    [[ $HTTP_STATUS -eq 304 ]] && exit 0
    [[ $HTTP_STATUS -ne 200 ]] && >&2 echo "Bad remote file." && exit 1

    # Get Json main file to extract actual exposed versions
    [[ $DEBUG  ]] && echo "Downloading into ${RAW}"
    curl --request GET --connect-timeout 1 --output "${RAW}" --silent "${URL}"

    # Validate format
    VALID=${CACHE_VALID_FILE/_url_/$_slug}
    [[ $DEBUG  ]] && echo "Validating into ${VALID}"
    ! jq "${FILTER}" "${RAW}" > "${VALID}" && >&2 echo "Bad format." && exit 1

    # Compress to destination
    makeDirForFile "${DEST}"
    [[ $DEBUG  ]] && echo "Copying into ${DEST}"
    tr -d '[:space:]' < "${VALID}" > "${DEST}"
}

# Inverse matrix spip/php in php/spip sites number
# Usage : spip2php
#         spip2php path/to/spipfile
#         spip2php path/to/spipfile path/to/phpfile
# Description : turn a .spip.php into a .php.spip Json schema aggregated by PHP versions
function spip2php
{
    local SPIP_JSON=${1:-spip.json}
    local PHP_JSON=${2:-php.json}

    # Error if SPIP_JSON does not exist.
    [[ -z "$SPIP_JSON" ]] && >&2 echo "Bad SPIP JSON file '$SPIP_JSON'." && exit 1

    # Step 1 : Inversion .spip.php -> .php.spip
    for v in $(jq -r '.[]|.version' "$SPIP_JSON");
    do
        jq '.[]|select(.version=="'"$v"'")|.php[]|{version, spip: [{version: "'"$v"'", sites}]}' "$SPIP_JSON" > "spip.$v.json"
        TMP_FILES="$TMP_FILES spip.$v.json"
    done
    slurpTmpFilesTo "$PHP_JSON"

    # Step 2 : Aggregation by PHP versions
    for v in $(jq -r '.[]|.version' "$PHP_JSON");
    do
        jq '[.[]|select(.version=="'"$v"'")|.spip[]]|{version: "'"$v"'", sites: [.[]|.sites]|add, spip: .}' "$PHP_JSON" > "php.$v.json"
        TMP_FILES="${TMP_FILES} php.$v.json"
    done
    slurpTmpFilesTo "$PHP_JSON"
}

TMP_FILES=
CACHE_PATH=${CACHE_PATH:-.cache/_file_}
CACHE_RAW_FILE=${CACHE_PATH/_file_/raw._url_.json}
CACHE_VALID_FILE=${CACHE_PATH/_file_/valid._url_.json}
[[ $DEBUG ]] && echo "tools:$0"
