#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID]

Prints logs for actor and exection IDs provided, respectively. Both 
inputs are required.

Options:
  -h 	show help message
  -z    api access token
  -e	execution ID
  -v	verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"
tok=

while getopts ":hve:z:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
            ;;             
        e) # execution
            execution=${OPTARG}
            ;;
        v) # verbose
            verbose="true"
            ;;
        V) # verbose
            very_verbose="true"
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]];
then
    verbose="true"
fi

actor="$1"
if [ -z "$actor" ]; then
    echo "Please specify actor"
    usage
fi

if [ -z "$execution" ]; then
    echo "Please specify execution"
    usage
fi

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/executions/$execution/logs'"

function filter() {
    # eval $@ | jq -r '.result | ["logs:\n",.logs] | @tsv' 
    echo -e "\033[92mLogs for execution $execution:\033[0m" && eval $@ | jq -r '.result | .logs ' | sed 's/\\n/\n/g'
}

if [[ "$very_verbose" == "true" ]];
then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
