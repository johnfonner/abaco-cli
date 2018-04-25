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
  -e    set environment variables (key=value)
  -E    read environment variables from json file 
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

source "$DIR/abaco-common.sh"

privileged="false"
stateless="false"
force="false"
use_uid="false"
tok=
env_json=
declare -a env_args

while getopts ":hn:e:E:pfsuvz:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
            ;;
        n) # name
            name=${OPTARG}
            ;;
        e) # default environment (command line key=value)
            env_args[${#env_args[@]}]=${OPTARG}
            ;;
        E) # default environment (json file)
            env_json=${OPTARG}
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

# default env
# check env vars json file (exists, have contents, be json)
file_default_env=
if [ ! -z "$env_json" ]
    then
    if [ ! -f "$env_json" ] || [ ! -s "$env_json" ] || ! $(is_json $(cat $env_json)); then
        die "$env_json is not valid. Please ensure it exists and contains valid JSON."
    fi
    file_default_env=$(cat $env_json)
fi
# build command line env vars into json
args_default_env=$(build_json_from_array "${env_args[@]}")
#combine both 
default_env=$(echo "$file_default_env $args_default_env" | jq -s add)

# curl command
data="{\"image\":\"${image}\", \"name\":\"${name}\", \"privileged\":${privileged}, \"stateless\":${stateless}, \"force\":${force}, \"useContainerUid\":${use_uid}, \"defaultEnvironment\":${default_env}}"
curlCommand="curl -X POST -sk -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" --data '$data' '$BASE_URL/actors/v2'"

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
