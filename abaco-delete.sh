#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "image=jturcino/abaco-d2s:0.0.17&name=jturcino-d2s-trial17&privileged=true" https://api.sd2e.org/actors/v2

function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }

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
    echo "Please specify actor ID at end of command"
    usage
fi

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" -X DELETE $BASE_URL/actors/v2/${actor}"

function filter() {
    eval $@ | jq -r '.message'
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
