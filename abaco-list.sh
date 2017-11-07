#!/bin/bash

#curl -sk -H "Authorization: Bearer $tok" 'https://api.sd2e.org/actors/v2

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

if [ -z $1 ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" $BASE_URL/actors/v2"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" $BASE_URL/actors/v2/$1"
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

