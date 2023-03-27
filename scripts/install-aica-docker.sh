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
  echo "Writing the auto completion option to $1."
  grep -v /src/aica-docker-completion.sh "$1" > tmpfile && mv tmpfile "$1"
  echo "source ${SCRIPT_DIR}/src/aica-docker-completion.sh" >> "$1"
}

if [[ "$OSTYPE" != "darwin"* ]]; then
  mkdir -p /usr/local/bin
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
echo "#!/bin/bash
function connect () {" > "${SCRIPT_DIR}/tmpfile"
echo "$(cat ${SCRIPT_DIR}/src/connect.sh)" >> "${SCRIPT_DIR}/tmpfile"
echo "}
function interactive () {" >> "${SCRIPT_DIR}/tmpfile"
echo "$(cat ${SCRIPT_DIR}/src/interactive.sh)" >> "${SCRIPT_DIR}/tmpfile"
echo "}
function server () {" >> "${SCRIPT_DIR}/tmpfile"
echo "$(cat ${SCRIPT_DIR}/src/server.sh)" >> "${SCRIPT_DIR}/tmpfile"
echo "}" >> "${SCRIPT_DIR}/tmpfile"
echo "$(cat ${SCRIPT_DIR}/aica-docker.sh)" >> "${SCRIPT_DIR}/tmpfile"
BIN_PATH="/usr/local/bin/aica-docker"

if test -f "$BIN_PATH"; then
  echo "Updating script at ${BIN_PATH};"
  sudo rm "${BIN_PATH}" || exit 1
else
  echo "Copying script to ${BIN_PATH};"
fi
sudo mv "${SCRIPT_DIR}/tmpfile" ${BIN_PATH} && sudo chmod +x ${BIN_PATH} || exit 1

SHELL_RC_PATH=$(get_shell_rc_path)
while true; do
  read -r -p "Do you with to install auto completion for aica-docker to '${SHELL_RC_PATH}'? [YES|no]
>>>" yn
  case $yn in
    "" | yes | YES | y) source_completion_script "${SHELL_RC_PATH}"; break;;
    no | n) exit;;
    *) echo "Please answer 'yes/y' or 'no/n'.";;
  esac
done
