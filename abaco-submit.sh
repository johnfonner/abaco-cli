#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "message=" "https://api.sd2e.org/actors/v2/${actorid}/messages?outdir=${outdir}&system=${system}"

function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":hm:q:v" o; do
    case "${o}" in
        m) # msg to pass to actor environment as $MSG
            msg=${OPTARG}
            ;;
        q) # query string to pass to actor environment
            query=${OPTARG}
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

# last arg at end should be actor id
actorid="$1"
if [ -z "$actorid" ]; then
    echo "Please give an actor ID at the end of the command"
    usage
fi

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" -X POST --data \"message='${msg}'\" \"$BASE_URL/actors/v2/${actorid}/messages?${query}\""

function filter() {
    eval $@ | jq -r '.result | [.executionId, .msg] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
