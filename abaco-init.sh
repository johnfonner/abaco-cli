#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [IMAGE]

Initializes a new Abaco actor project.

Options:
  -h    show help message
  -n    project name (e.g. my_new_actor)
  -l    language (default: python2)
"

function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/common.sh"

function slugify {
  echo "${1}" | tr -c -d [A-Za-z\ _-] | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
}

name=
repo=
lang="python2"
tenant="tacc.cloud"

while getopts ":hl:n:i:" o; do
    case "${o}" in
        n) # name
            name=${OPTARG}
            ;;
        l) # language
            lang=${OPTARG}
            ;;
        i) # repo
            repo=${OPTARG}
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${name}" ]
then
  usage
fi

# URL-safen name
safename=`slugify "${name}"`
if [ "$safename" != "$name" ]
then
  info "Making project name URL safe: $safename"
  name="$safename"
fi

# Ensure directory $name is doens't exist yet
if [ ! -d "$name" ]
then
  mkdir -p "$name"
else
  die "Project directory $name exists."
fi

# Template language
if [ -z "${lang}" ]
then
  lang="python2"
  info "Defaulting to Python2"
fi

# TODO: More stringent check on Docker repo name
#       especially if passed by user. 
if [ -z "${repo}" ]
then
  repo=${name}
fi

# Get tenant ID
if [ -f "$HOME/.agave/current" ]
then
  tenant=$(jq -r .tenantid $HOME/.agave/current)
else
  die "Can't determine TACC Cloud tenant"
fi

# Copy in template
echo "$DIR/templates/$tenant/$lang"
if [ -d "$DIR/templates/$tenant/$lang" ]
then
  cp -R ${DIR}/templates/${tenant}/${lang}/ ${name}/
else
  rm -rf ${name}
  die "Error creating project directory $name"
fi

# Template in the reactor.rc file
cat << EOF > "${name}/reactor.rc"
# Reactor mandatory settings
REACTOR_NAME=${name}

# Reactor optional settings
# REACTOR_DESCRIPTION=
# REACTOR_WORKERS=1
# REACTOR_PRIVILEGED=0
# REACTOR_STATELESS=0
# REACTOR_USE_UID=0
# REACTOR_ALIAS=aka_reactor_demo

# Docker settings
DOCKER_HUB_ORG=your_docker_registory_uname
DOCKER_IMAGE_TAG=${name}
DOCKER_IMAGE_VERSION=0.1
EOF
