#!/bin/bash

SCRIPTS=("connect" "interactive" "server")
CONTAINERS=$(docker ps --format "{{ .Names }}" 2> /dev/null)
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" 2> /dev/null)
IMAGES=${IMAGES//"<none>:<none>"/}

_aica_docker () {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ ${COMP_CWORD} -eq 2 ]]; then
    CONTAINERS=$(docker ps --format "{{ .Names }}" 2> /dev/null)
    IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" 2> /dev/null)
    IMAGES=${IMAGES//"<none>:<none>"/}
  fi

  case "${prev}" in
      aica-docker)
        COMPREPLY=($(compgen -W "${SCRIPTS[*]}" "${cur}"))
      ;;
      connect)
        COMPREPLY=($(compgen -W "${CONTAINERS}" "${cur}"))
      ;;
      interactive|server)
        COMPREPLY=($(compgen -W "${IMAGES}" "${cur}"))
      ;;
  esac
}

complete -F _aica_docker aica-docker
