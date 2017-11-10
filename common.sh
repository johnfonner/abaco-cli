#!/bin/bash

BASE_URL=$(awk -F, '{print $2}' ~/.agave/current | cut -d '"' -f 4)
CLIENT_SECRET=$(awk -F, '{print $4}' ~/.agave/current | cut -d '"' -f 4)
CLIENT_KEY=$(awk -F, '{print $5}' ~/.agave/current | cut -d '"' -f 4)

USERNAME=$(awk -F, '{print $6}' ~/.agave/current | cut -d '"' -f 4)
TOKEN=$(awk -F, '{print $7}' ~/.agave/current | cut -d '"' -f 4)

if [[ ! -x $( which jq ) ]]; then
    echo "Error: jq was not found."
    echo "This CLI requires jq.  Please install it first"
    exit 1
fi

function is_json() {
    echo "$@" | jq -e . >/dev/null 2>&1
}

function format_json(){
    echo ${@//\"/\\\"}
}

