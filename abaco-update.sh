#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID]

Updates an actor. Default environment variables, state 
status, uid use, and actor name cannot be changed.

Options:
  -h	show help message
  -i    change Docker image
  -p    remove privileged status
  -P    add privileged status
  -f    force update
  -z    api access token
  -v    verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/abaco-common.sh"

tok=
image=
force=false
unpriv_flag=false
priv_flag=false
while getopts ":hi:pPfvz:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
            ;;
        i) # change Docker image
            image=${OPTARG}
            ;;
        p) # remove privileged status
            unpriv_flag=true
            ;;
        P) # add privileged status
            priv_flag=true
            ;;
        f) # force
            force=true
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

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]]
then
    verbose="true"
fi

# fail if no actorid
if [ -z "$actorid" ] 
then
    echo "Please specify an actor ID"
    usage
fi

# set up privileged status
# fail if conflicting flags
privileged=
if $priv_flag && $unpriv_flag
then
    echo "Conflicting info about $actorid privileged status"
    usage
elif $priv_flag
then
    privileged=true
elif $unpriv_flag
then
    privileged=false
fi

# building data (image, privileged, force)
# only include image, privileged if specified
function add_json () {
    echo "$@" | jq -s add
}
data="{\"force\":${force}}"
if ! [ -z "$image" ]
then
    data=$(add_json "${data} {\"image\":\"${image}\"}")
fi
if ! [ -z "$privileged" ]
then
    data=$(add_json "${data} {\"privileged\":${privileged}}")
fi

# curl command
curlCommand="curl -X PUT -sk -H \"Authorization: Bearer $TOKEN\"  -H \"Content-Type: application/json\" --data '$data' '$BASE_URL/actors/v2/${actorid}'"

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
