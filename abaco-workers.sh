#!/bin/bash

HELP="
./abaco-workers.sh [OPTION]... [ACTORID]

Returns list of worker IDs and statuses or JSON description of worker 
if worker ID provided with -w flag. Use -n flag to change worker count.

Options:
  -h	show help message
  -n    change worker number
  -w	worker ID
  -v	verbose output
"

#function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":hvw:n:" o; do
    case "${o}" in
        w) # worker
            worker=${OPTARG}
            ;;
        n) # worker number
            num=${OPTARG}
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

if ! [ -z "$num" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" -X POST -d 'num=$num' '$BASE_URL/actors/v2/$actor/workers'"
elif [ -z "$worker" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/workers'"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/workers/$worker'"
    verbose="true"
fi

function filter() {
    if ! [ -z "$num" ]; then
        eval $@ | jq -r '.message'
    else
        eval $@ | jq -r '.result | .[] | [.id, .status] | @tsv' | column -t
    fi
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
