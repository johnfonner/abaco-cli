#!/bin/bash

if [[ ! -x $( which jq ) ]]; then
    echo "Error: jq was not found."
    echo "This CLI requires jq. Please install it first."
    echo " - https://stedolan.github.io/jq/download/"
    exit 1
fi

AGAVE_AUTH_CACHE=
if [ ! -z "${AGAVE_CACHE_DIR}" ] && [ -d "${AGAVE_CACHE_DIR}" ]; then
    if [ -f "${AGAVE_CACHE_DIR}/current" ]; then
        AGAVE_AUTH_CACHE="${AGAVE_CACHE_DIR}/current"
    fi
else
    AGAVE_AUTH_CACHE="$HOME/.agave/current"
fi
if [ ! -f "${AGAVE_AUTH_CACHE}" ]; then
    echo "Error: API credentials are not configured."
    exit 1
fi

BASE_URL=$(jq -r .baseurl ${AGAVE_AUTH_CACHE})
CLIENT_SECRET=$(jq -r .apisecret  ${AGAVE_AUTH_CACHE})
CLIENT_KEY=$(jq -r .apikey  ${AGAVE_AUTH_CACHE})
USERNAME=$(jq -r .username  ${AGAVE_AUTH_CACHE})
TOKEN=$(jq -r .access_token  ${AGAVE_AUTH_CACHE})
TENANTID=$(jq -r .tenantid  ${AGAVE_AUTH_CACHE})

function build_json_from_array() {
    local myarray=("$@")
    local var_count=${#myarray[@]}

    if [ $var_count -eq 0 ]; then
        echo "{}"
        exit 0
    fi

    local last_index=$((${#myarray[@]}-1))
    local json="{"
    for i in $(seq 0 $last_index); do
        local key_value=${myarray[$i]}
        local key=${key_value%=*}
        local value=${key_value#*=}

        # add key-value pair
        json="${json}\"$key\":\"$value\""

        # if last pair, close with curly brace
        # otherwise, add comma for next value
        if [ $i -eq $last_index ]; then
            json="${json}}"
        else
            json="${json}, "
        fi
    done

    echo "$json"
}

function is_json() {
    echo "$@" | jq -e . >/dev/null 2>&1
}

function single_quote() {
    local str="$1"
    local first_char="$(echo "$str" | head -c 1)"
    if ! [ "$first_char" == "'" ]; then
        str="'$str'"
    fi
    echo "$str"
}

function die() {

    echo "[CRITICAL] $1"
    exit 1

}

function warn() {

    echo "[WARNING] $1"

}

function info() {

    echo "[INFO] $1"

}
