#!/bin/bash

function fn_exists () {
  declare -f "$1" > /dev/null
  echo $?
}

HELP_MESSAGE="Usage: aica-docker [server | interactive | connect]"

if [ -z "$1" ]; then
  echo "${HELP_MESSAGE}"
  exit 1
fi

# get the full path of the scripts, following the symlink if necessary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SYMLINK="${SCRIPT_DIR}"/aica-docker
if [[ -L "$SYMLINK" ]]; then
  SCRIPT_DIR="$(readlink "$SYMLINK")"
  SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
fi

case "$1" in
connect)
  shift 1
  if [ $(fn_exists "connect") == 0 ]; then
    connect "$@"
  else
    source "${SCRIPT_DIR}"/src/connect.sh "$@"
  fi
  exit $?
  ;;
interactive)
  shift 1
  if [ $(fn_exists "interactive") == 0 ]; then
    interactive "$@"
  else
    source "${SCRIPT_DIR}"/src/interactive.sh "$@"
  fi
  exit $?
  ;;
server)
  shift 1
  if [ $(fn_exists "server") == 0 ]; then
    server "$@"
  else
    source "${SCRIPT_DIR}"/src/server.sh "$@"
  fi
  exit $?
  ;;
*)
  echo "Unknown option: $1"
  echo "${HELP_MESSAGE}"
  exit 1
  ;;
esac
