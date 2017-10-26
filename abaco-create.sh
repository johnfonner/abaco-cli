#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "image=jturcino/abaco-d2s:0.0.17&name=jturcino-d2s-trial17&privileged=true" https://api.sd2e.org/actors/v2

function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

privileged="false"
stateless="false"
force="false"

while getopts ":hi:n:psfv" o; do
    case "${o}" in
        i) # image repository, name, and tag
            image=${OPTARG}
            ;;
        n) # name
            name=${OPTARG}
            ;;
        p) # privileged
            privileged="true"
            ;;
        f) # force image update
            force="true"
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

if [ -z "$image" ]; then
    if [ "x$1" == "x" ]; then
        echo "Please specify a Docker image to use for the actor"
        usage
    else
        image=$1
    fi
fi

if [ -z "$name" ]; then
    echo "Please specify a name to give your actor"
    usage
fi
curlCommand="curl -X POST -sk -H \"Authorization: Bearer $TOKEN\" --data 'image=${image}&name=${name}&privileged=${privileged}&stateless=${stateless}&force=${force}' '$BASE_URL/actors/v2'"

function filter() {
    eval $@ | jq -r '.result' # | [.name, .id] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

