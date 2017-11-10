#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "message=" "https://api.sd2e.org/actors/v2/${actor}/messages?outdir=${outdir}&system=${system}"

HELP="
./abaco-submit.sh [OPTION]... [ACTORID]

Executes the actor with provided ID and returns execution ID

Options:
  -h	show help message
  -m	value of actor env variable $MSG
  -q	query string to pass to actor env
  -v	verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

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

actor="$1"
if [ -z "$actor" ]; then
    echo "Please give an actor ID at the end of the command"
    usage
fi

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" -X POST --data \"message='${msg}'\" \"$BASE_URL/actors/v2/${actor}/messages?${query}\""

function filter() {
    eval $@ | jq -r '.result | [.executionId, .msg] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
