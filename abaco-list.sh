#!/bin/bash

#curl -sk -H "Authorization: Bearer $tok" 'https://api.sd2e.org/actors/v2


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" $BASE_URL/actors/v2"

function filter() {
    eval $@ | jq -r '.result | .[] | [.name, .id] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

