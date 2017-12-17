#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [IMAGE]

Creates an abaco actor from the provided image and returns the name and ID
of the actor.

Options:
  -h	show help message
  -z    api access token
  -n    name of actor
  -e    default environment variables (JSON)
  -p    make privileged actor
  -f    force actor update
  -s    make stateless actor
  -u    use actor uid
  -v    verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

privileged="false"
stateless="false"
force="false"
use_uid="false"
default_env={}
tok=

while getopts ":hn:e:pfsuvz:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
            ;;
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
        u) # use uid
            use_uid="true"
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

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]];
then
    verbose="true"
fi
    
image="$1"
if [ -z "$image" ]; then
    echo "Please specify a Docker image to use for the actor"
    usage
fi

if [ -z "$name" ]; then
    echo "Please specify a name to give your actor"
    usage
fi

# check default env
if ! [ -z "$default_env" ]; then
    if ! $(is_json "$default_env"); then
        echo "Default environment variables not formatted as JSON"
        exit 0
    fi
fi

curlCommand="curl -X POST -sk -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" --data '{\"image\":\"${image}\", \"name\":\"${name}\", \"privileged\":${privileged}, \"stateless\":${stateless}, \"force\":${force}, \"useContainerUid\":${use_uid}, \"defaultEnvironment\":${default_env} }' '$BASE_URL/actors/v2'"

function filter() {
#    eval $@ | jq -r '.result | [.name, .id] | @tsv' | column -t
    eval $@ | jq -r '.result | [.name, .id] |  "\(.[0]) \(.[1])"' | column -t
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
