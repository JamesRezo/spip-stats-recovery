#!/usr/bin/env bash

# Usage : include "source tools" in a bash script
# Description : Helpers
# Needs curl, jq

# Usage : slugify string
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

# Usage : getFileFromRemote url
#         getFileFromRemote url path/to/file
#         getFileFromRemote url path/to/file "jq filter"
# Description : test, retrieve, check and compress a remote json file to local filesystem
#               files are cached in .cache directory by default (see CACHE_PATH env variable)
#               Errors output on STDERR may be :
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

    #TODO errors if url not provided

    #TODO check DEST parameter. If not provided, use basename of url with magick deletion of "spip.php?page="
    #     if no basename (i.e. url like https://example.org) use default file name (suglified %{http_host}.json)

    # Get HTTP Status. 200 expected
    [[ $DEBUG ]] && echo "Testing ${URL}"
    HTTP_STATUS=$(curl --head --write-out '%{http_code}' --connect-timeout 1 --output /dev/null --silent "${URL}")
    [[ $HTTP_STATUS -ne 200 ]] && >&2 echo "Bad remote file." && exit 1
    _slug="$(slugify "$URL")"

    makeDirForFile "$CACHE_PATH"

    # Get Json main file to extract actual exposed versions
    RAW=${CACHE_RAW_FILE/_url_/$_slug}
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

TMP_FILES=
CACHE_PATH=${CACHE_PATH:-.cache/_file_}
CACHE_RAW_FILE=${CACHE_PATH/_file_/raw._url_.json}
CACHE_VALID_FILE=${CACHE_PATH/_file_/valid._url_.json}
[[ $DEBUG ]] && echo "tools:$0"
