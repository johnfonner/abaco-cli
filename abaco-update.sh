#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTOR ID] [IMAGE]

Updates an actor to a different Docker image. Default 
environment variables, privileged status, state status, 
uid use, and actor name cannot be changed.

Options:
  -h	show help message
  -z    api access token
  -v    verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

container=
tok=
while getopts ":hn:e:E:pfsuvz:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
            ;;
        v) # verbose
            verbose="true"
            ;;
        V) # verbose
            very_verbose="true"
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))
actorid="$1"
repo="$2"

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]];
then
    verbose="true"
fi

# check actor id and container
if [ -z "$actorid" ]; then
    echo "Please specify an actor ID"
    usage
fi
if [ -z "$repo" ]; then
    echo "Please specify a Docker image"
    usage
fi

# curl command
curlCommand="curl -X PUT -sk -H \"Authorization: Bearer $TOKEN\" -d image='${repo}' '$BASE_URL/actors/v2/${actorid}'"

function filter() {
#    eval $@ | jq -r '.result | [.name, .id, .image] | @tsv' | column -t
    eval $@ | jq -r '.result | [.name, .id, .image] |  "\(.[0]) \(.[1]) \(.[2])"' | column -t
}

if [[ "$very_verbose" == "true" ]];
then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi