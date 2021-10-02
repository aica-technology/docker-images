#!/bin/bash

function source_completion_script () {
  ACTUAL_USER=$(logname)
  HOME_DIR=$(eval echo "~${ACTUAL_USER}")
  if [[ "${SHELL##*|}" == *"zsh"* ]]; then
    echo "source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "${HOME_DIR}/.zshrc"
  elif [[ "${SHELL##*|}" == *"bash"* ]]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
      echo "source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "${HOME_DIR}/.bashrc"
    else
      echo "source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "${HOME_DIR}/.bashrc"
    fi
  else
    echo "Currently, only zsh and bash shells are supported for autocompletion with aica-docker."
  fi
}

if [[ "$OSTYPE" != "darwin"* ]]; then
  mkdir -p /usr/local/bin
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "Creating a symbolic link from /usr/local/bin/aica-docker to ${SCRIPT_DIR}/aica-docker.sh"
ln -s "${SCRIPT_DIR}/aica-docker.sh" /usr/local/bin/aica-docker

source_completion_script
