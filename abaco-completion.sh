#!/usr/bin/env bash

_abaco () {
    COMPREPLY=()
    local prev cur
    cur=${COMP_WORDS[COMP_CWORD]}

    local commands="list create delete workers submit executions logs"

    COMPREPLY=( $(compgen -W "$commands" -- $cur) )

    return 0
}

complete  -F _abaco abaco
