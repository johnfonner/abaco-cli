#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]...

Build and deploy an Abaco actor from a local project directory.
Requires Docker version 17.03.0-ce or higher, push access to a
Docker registry, and a properly-configired source directory.

Options:
  -h    show help message
  -z    api access token
  -F    Docker file (Dockerfile)
  -B    build config file (reactor.rc)
  -R    dry run - only build image
  -U    update preexisting actor (provided or from .ACTOR_ID)
"

function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/abaco-common.sh"

function get_actorid() { 
  local actorid="$1"
  # If not a valid actor ID, try to get from .ACTOR_ID
  if [[ $actorid == -* ]] || [ -z "$actorid" ]
  then
    if [ -s ".ACTOR_ID" ]
    then
      actorid=$(cat .ACTOR_ID)
    else
      actorid=
    fi
  fi
  echo "$actorid"
}

dockerfile="Dockerfile"
config_rc="reactor.rc"
entrypoint="reactor.py"
default_env="secrets.json"
tok=
dry_run=
current_actor=
while getopts ":hz:F:B:RU" o; do
    case "${o}" in
        z) # API token
            tok=${OPTARG}
            ;;
        F) # Dockerfile
            dockerfile=${OPTARG}
            ;;
        B) # reactor build config
            config_rc=${OPTARG}
            ;;          
        R) # dry run
            dry_run=1
            ;;
        U) # update
            current_actor=$(get_actorid "${@:$OPTIND:1}")
            if [ -z "$current_actor" ]
            then
              warn "Actor ID not found. Creating new actor."
            else
              info "Updating actor $current_actor"
            fi
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]]
then
    verbose="true"
fi

# Check for mandatory files
for mandfile in $dockerfile $config_rc $entrypoint
do
  if [ ! -f "$mandfile" ]
  then
    die "Cannot proceed without file $mandfile"
  fi
done

# Look for config.yml and regenerate if not there
if [ ! -f "config.yml" ]
then
info "File config.yml was not found. Creating an empty one."
# Template out the reactor.rc file
cat << EOF > config.yml
# Reactors config file
---
EOF
fi

# Look for optional files
for optfile in message.json secrets.json
do
  if [ ! -f "$optfile" ]
  then
    info "Optional file $optfile not present"
  fi
done

# Check existence and min version of Docker
command -v docker >/dev/null 2>&1 || { die "Docker is not installed or accessible"; }
DOCKER_VERSION="$(docker --version)"
if [[ ! "$DOCKER_VERSION" =~ "Docker version 17" ]] && [[ ! "$DOCKER_VERSION" =~ "Docker version 18" ]]
then
  die "${DOCKER_VERSION} is not recent enough."
fi
# Verify the user is logged into a Registry
# This isn't formal validation that they can
# push to one, but is a decent sanity check for
# users who don't yet know about docker login
DOCKER_AUTHS="$(jq -r .auths $HOME/.docker/config.json)"
if [[ "${DOCKER_AUTHS}" == "{}" ]]
then
  die "You don't appear to be logged into a Docker Registry. Please run docker login to fix this."
fi

# Allow default set in ENV
ENV_DOCKER_HUB_ORG="${DOCKER_HUB_ORG}"

# Read in config variables
REACTOR_NAME=
REACTOR_DESCRIPTION=
REACTOR_STATELESS=
REACTOR_PRIVILEGED=
REACTOR_USE_UID=

# Docker image
DOCKER_HUB_ORG=
DOCKER_IMAGE_TAG=
DOCKER_IMAGE_VERSION=

set -a
source "${config_rc}"
set +a

# Validate that the ones that are not supposed to be empty... aren't empty
# Automatically assign values where we can
if [ -z "${DOCKER_HUB_ORG}" ] || [ "${DOCKER_HUB_ORG}" == "your_docker_registory_uname" ]
then
  if [ ! -z "${ENV_DOCKER_HUB_ORG}" ]
  then
    DOCKER_HUB_ORG="${ENV_DOCKER_HUB_ORG}"
    export DOCKER_HUB_ORG
  else
    die "DOCKER_HUB_ORG must be your DockerHub username or organization. Set in ENV or in $config_rc"
  fi
fi

if [ -z "${DOCKER_IMAGE_TAG}" ]
then
  die "DOCKER_IMAGE_TAG cannot be empty in $config_rc"
fi

# Reactor values
if [ -z "${REACTOR_NAME}" ]
then
  warn "REACTOR_NAME is empty so we're naming it for you. Don't you love your Reactor?"
  source "$DIR/libs/petname.sh"
  export REACTOR_NAME=$(petname 3)
  echo "${REACTOR_NAME}"
fi

# if [ -z "${REACTOR_DESCRIPTION}" ]
# then
#   warn "REACTOR_DESCRIPTION is empty, so we're cooking up a tasty description for you."
#   REACTOR_DESCRIPTION=$(curl -skL 'https://baconipsum.com/api/?type=all-meat&sentences=1' | jq -r .[0])
#   echo "${REACTOR_DESCRIPTION}"
#   export REACTOR_DESCRIPTION
# fi

# Docker stuff
DOCKER_BUILD_TARGET="${DOCKER_HUB_ORG}/${DOCKER_IMAGE_TAG}"
if [ ! -z "${DOCKER_IMAGE_VERSION}" ]
then
  DOCKER_BUILD_TARGET="${DOCKER_BUILD_TARGET}:${DOCKER_IMAGE_VERSION}"
else
  warn "It is considered a best practice to specify a version for a Docker image"
  warn "Do this by setting DOCKER_IMAGE_VERSION in $config_rc"
fi
export DOCKER_BUILD_TARGET

# Try Docker build
docker -l warn build -f "${dockerfile}" -t "${DOCKER_BUILD_TARGET}" . || { die "Error building ${DOCKER_BUILD_TARGET}"; }

if [ "$dry_run" == 1 ]
then
  info "Stopping deployment as this was only a dry run!"
  exit 0
fi

# Try Docker push
docker push "${DOCKER_BUILD_TARGET}" || { die "Error pushing ${DOCKER_BUILD_TARGET} image to Docker registry"; }

info "Pausing to let Docker Hub register that the repo has been pushed"
sleep 5

# Now, build abaco create/update CLI and call it
# Don't reinvent the wheel by re-writing 'abaco create'
ABACO_CREATE_OPTS="-f"
if [ "${REACTOR_PRIVILEGED}" == 1 ]
then
  ABACO_CREATE_OPTS="$ABACO_CREATE_OPTS -p"
fi
if [ "${REACTOR_USE_UID}" == 1 ]
then
  ABACO_CREATE_OPTS="$ABACO_CREATE_OPTS -u"
fi

# If updating, do not include name or stateless 
if [ -z "$current_actor" ]
then
  ABACO_CREATE_OPTS="$ABACO_CREATE_OPTS -n ${REACTOR_NAME}"
  if [ "${REACTOR_STATELESS}" == 1 ]
  then
    ABACO_CREATE_OPTS="$ABACO_CREATE_OPTS -s"
  fi
fi

# Read default environment variables from secrets.json
# This file never committed to Git or Docker image
if [ -f "${default_env}" ]
then
  info "Reading environment variables from ${default_env}"
  ABACO_CREATE_OPTS="$ABACO_CREATE_OPTS -E ${default_env}"
fi

if [ -f .ACTOR_ID ]
then
  mv .ACTOR_ID .ACTOR_ID.bak
fi

if [ -z "$current_actor" ]
then
  cmd="abaco create -v ${ABACO_CREATE_OPTS} ${DOCKER_BUILD_TARGET}"
else
  cmd="abaco update -v ${ABACO_CREATE_OPTS} ${current_actor} ${DOCKER_BUILD_TARGET}"
fi
eval $cmd | jq -r .result.id > .ACTOR_ID

ACTOR_ID=$(cat .ACTOR_ID)

if [ ! -z "$ACTOR_ID" ]
then
  echo "Successfully deployed actor with ID: $ACTOR_ID"
else
  die "There was an error deploying $REACTOR_NAME"
fi

# TODO: Add/update the alias registry if provided
# This uses REACTOR_ALIAS and the optional message.jsonschema