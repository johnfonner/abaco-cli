#!/bin/bash

#curl -sk -H "Authorization: Bearer $tok" 'https://api.sd2e.org/actors/v2/lJbR84DxY5OmR/executions

function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":ha:ve:" o; do
    case "${o}" in
        a) # actor
            actor=${OPTARG}
            ;;
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

if [ -z "$actor" ]; then
    if [ "x$1" == "x" ]; then
        echo "Please specify actor"
        usage
    else
        actor=$1
    fi
fi

if [ -z "$execution" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" $BASE_URL/actors/v2/$actor/executions"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" $BASE_URL/actors/v2/$actor/executions/$execution"
fi

function filter() {
    eval $@ | jq -r '.result' # | .[] | [.name, .id] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

