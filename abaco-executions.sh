#!/bin/bash

HELP="
./abaco-executions.sh [OPTION]... [ACTORID]

Returns list of execution IDs for the provided actor or JSON description 
of execution if execution ID provided with -e flag.

Options:
  -h	show help message
  -e	execution ID
  -v	verbose output
"

#function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":hve:" o; do
    case "${o}" in
        e) # execution
            execution=${OPTARG}
            ;;
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
    echo "Please specify actor"
    usage
fi

if [ -z "$execution" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/executions'"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/executions/$execution'"
#    verbose="true"
fi

function filter_list() {
    eval $@ | jq -r '.result | .ids | .[]' | column -t
}

function filter_description() {
    eval $@ | jq -r '.result | [.workerId, .status] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    if [ -z "$execution" ]; then
        filter_list $curlCommand
    else
        filter_description $curlCommand
    fi
fi
