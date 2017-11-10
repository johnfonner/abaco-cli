#!/bin/bash

# curl -sk -H "Authorization: Bearer $tok" -X POST --data "image=jturcino/abaco-d2s:0.0.17&name=jturcino-d2s-trial17&privileged=true" https://api.sd2e.org/actors/v2

HELP="
./abaco-create.sh [OPTION]... [IMAGE]

Creates an abaco actor from the provided image and returns the name and ID
of the actor.

Options:
  -h	show help message
  -n    name of actor
  -e    default environment variables (JSON)
  -p    make privileged actor
  -f    force actor update
  -s    make stateless actor
  -v    verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

privileged="false"
stateless="false"
force="false"

while getopts ":hn:e:psfv" o; do
    case "${o}" in
        n) # name
            name=${OPTARG}
            ;;
        e) # default environment (JSON)
            default_env=${OPTARG}
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

image="$1"
if [ -z "$image" ]; then
    echo "Please specify a Docker image to use for the actor"
    usage
fi

if [ -z "$name" ]; then
    echo "Please specify a name to give your actor"
    usage
fi

curlCommand="curl -X POST -sk -H \"Authorization: Bearer $TOKEN\" --data 'image=${image}&name=${name}&privileged=${privileged}&stateless=${stateless}&force=${force}&default_environment=${default_env}' '$BASE_URL/actors/v2'"

function filter() {
    eval $@ | jq -r '.result | [.name, .id] | @tsv' | column -t
}

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi
