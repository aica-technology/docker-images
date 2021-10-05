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

function source_completion_script () {
  grep -v /src/aica-docker-completion.sh "$1" > tmpfile && mv tmpfile "$1"
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "autoload bashcompinit; bashcompinit; source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "$1"
  else
    echo "source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "$1"
  fi
}

if [[ "$OSTYPE" != "darwin"* ]]; then
  mkdir -p /usr/local/bin
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SYMLINK="/usr/local/bin/aica-docker"

if test -f "$SYMLINK"; then
  echo "Updating symbolic link from ${SYMLINK} to ${SCRIPT_DIR}/aica-docker.sh;"
  sudo rm "${SYMLINK}" || exit 1
else
  echo "Creating a symbolic link from ${SYMLINK} to ${SCRIPT_DIR}/aica-docker.sh;"
fi
sudo ln -s "${SCRIPT_DIR}/aica-docker.sh" ${SYMLINK}

SHELL_RC_PATH=$(get_shell_rc_path)
while true; do
  read -r -p "Do you with to install auto completion for aica-docker to '${SHELL_RC_PATH}'? [yes|no]
[yes] >>>" yn
  case $yn in
    yes) source_completion_script "${SHELL_RC_PATH}"; break;;
    no) exit;;
    *) echo "Please answer 'yes' or 'no'.";;
  esac
done
