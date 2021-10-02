#!/bin/bash

function remove_source_completion_script () {
  ACTUAL_USER=$(logname)
  HOME_DIR=$(eval echo "~${ACTUAL_USER}")
  if [[ "${SHELL##*|}" == *"zsh"* ]]; then
    su - "${ACTUAL_USER}" -c "grep -v /src/aica-docker-completion.sh ${HOME_DIR}/.zshrc > tmpfile && mv tmpfile ${HOME_DIR}/.zshrc"
  elif [[ "${SHELL##*|}" == *"bash"* ]]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
      su - "${ACTUAL_USER}" -c "grep -v /src/aica-docker-completion.sh ${HOME_DIR}/.bashrc > tmpfile && mv tmpfile ${HOME_DIR}/.bashrc"
    else
      su - "${ACTUAL_USER}" -c "grep -v /src/aica-docker-completion.sh ${HOME_DIR}/.bashrc > tmpfile && mv tmpfile ${HOME_DIR}/.bashrc"
    fi
  fi
}

SYMLINK=/usr/local/bin/aica-docker
echo "Removing symbolic link ${SYMLINK}"
rm -f "${SYMLINK}"

remove_source_completion_script