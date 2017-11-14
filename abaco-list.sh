#!/bin/bash

HELP="
./abaco-list.sh [OPTION]...
./abaco-list.sh [OPTION]... [ACTORID]

Returns list of actor names, IDs, and statuses or JSON description of 
actor if ID provided

Options:
  -h	show help message
  -v	verbose output
"

#function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":hv" o; do
    case "${o}" in
        v) # verbose
            verbose="true"
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))

actor="$1"
if [ -z "$actor" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2'"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor'"
    verbose="true"
fi

function filter() {
    eval $@ | jq -r '.result | .[] | [.name, .id, .status] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
