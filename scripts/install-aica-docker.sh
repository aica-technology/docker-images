#!/bin/bash

if [[ "$OSTYPE" != "darwin"* ]]; then
  mkdir -p /usr/local/bin
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/aica-docker.sh

echo "Creating a symbolic link from /usr/local/bin/aica-docker to ${SCRIPT_DIR}"
ln -s "${SCRIPT_DIR}" /usr/local/bin/aica-docker
