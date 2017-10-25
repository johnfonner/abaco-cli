#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "image=jturcino/abaco-d2s:0.0.17&name=jturcino-d2s-trial17&privileged=true" https://api.sd2e.org/actors/v2

function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

while getopts ":hc:n:psv" o; do
    case "${o}" in
        c) # container
            container=${OPTARG}
            ;;
        n) # name
            name=${OPTARG}
            ;;
        p) # privileged
            privileged="true"
            ;;
        s) # stateless
            stateless="true"
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

if [ -z "$container" ]; then
    if [ "x$1" == "x" ]; then
        echo "Please specify container"
        usage
    else
        container=$1
    fi
fi

curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" -X POST --data \"image=${container}&name=${name}&privileged=${privileged}&stateless=${stateless}\" $BASE_URL/actors/v2"

function filter() {
    eval $@ | jq -r '.result | [.name, .id] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
