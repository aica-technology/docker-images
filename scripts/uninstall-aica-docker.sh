#!/bin/bash

function get_shell_rc_path () {
  local user home_dir
  user=$(logname)
  home_dir=$(eval echo "~${user}")
  if [[ "${SHELL##*|}" == *"zsh"* ]]; then
    echo "${home_dir}/.zshrc"
  elif [[ "${SHELL##*|}" == *"bash"* ]]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
      echo "${home_dir}/.bashrc"
    else
      echo "Currently, bash shells on Mac are not supported, please contact the maintainers."
      exit 1
    fi
  else
    echo "Currently, only zsh and bash shells are supported for autocompletion with aica-docker."
    exit 1
  fi
}

SYMLINK=/usr/local/bin/aica-docker
echo "Removing symbolic link ${SYMLINK}"
rm -f "${SYMLINK}"

SHELL_RC_PATH=$(get_shell_rc_path)
if grep -Rq "/src/aica-docker-completion.sh" "${SHELL_RC_PATH}"; then
  echo "Removing auto completion from ${SHELL_RC_PATH}"
  grep -v /src/aica-docker-completion.sh "${SHELL_RC_PATH}" > tmpfile && mv tmpfile "${SHELL_RC_PATH}"
fi

