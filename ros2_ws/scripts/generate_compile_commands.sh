#!/bin/sh

PACKAGES=""
CMAKE_ARGS="-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
TIMEOUT=30

HELP_MESSAGE="
Usage: ./generate_compile_commands [OPTIONS]

Generate compile commands for clangd. The following options are supported:

  -p|--packages <packages>  The ROS packages to build (space-separated).
  --cmake-args <args>       Additional CMake arguments (space-separated).
  -t|--timeout <seconds>    Timeout in seconds (default: 30).
  -h|--help                 Show this help message.
"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p|--packages)
      shift
      while [ "$#" -gt 0 ] && [ "${1#-}" = "$1" ]; do
        PACKAGES="$PACKAGES $1"
        shift
      done
      ;;
    --cmake-args)
      shift
      while [ "$#" -gt 0 ] && [ "${1#-}" = "$1" ]; do
        CMAKE_ARGS="$CMAKE_ARGS -D$1"
        shift
      done
      ;;
    -t|--timeout) TIMEOUT=$2; shift 2;;
    -h|--help) echo "$HELP_MESSAGE"; exit 0;;
    *)
      echo "Unknown option: $1"
      echo "$HELP_MESSAGE"
      exit 1
      ;;
  esac
done

cd ~/ws
colcon build \
    --event-handlers console_direct+ --cmake-force-configure --cmake-args $CMAKE_ARGS \
    --packages-select $PACKAGES > /dev/null 2>&1 &
COLCON_PID=$!
TIMER=0
touch compile_commands.json
for PACKAGE in $PACKAGES; do
  while ! [ -s build/$PACKAGE/compile_commands.json ] && [ $TIMER -lt $TIMEOUT ] ; do
    echo "waiting for package $PACKAGE ($TIMER)"
    sleep 1
    TIMER=$((TIMER + 1))
  done
  jq -s 'add' compile_commands.json build/$PACKAGE/compile_commands.json > tmp && mv tmp compile_commands.json
done
kill -INT $COLCON_PID
cp compile_commands.json ~/.devcontainer