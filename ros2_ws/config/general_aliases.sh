# encoded topic alias and completion

echo "alias print_encoded_topic='export ROS2_WORKSPACE; ros2 run aica_core_components print_encoded_topic'" >> "${HOME}"/.bash_aliases

cat << 'EOF' >> "${HOME}/.bash_aliases"
_print_encoded_topic_completion() {
  local cur_word
  cur_word="${COMP_WORDS[COMP_CWORD]}"
  local topics
  topics=$(ros2 topic list 2>/dev/null)
  COMPREPLY=( $(compgen -W "$topics" -- "$cur_word") )
}
complete -F _print_encoded_topic_completion print_encoded_topic
EOF