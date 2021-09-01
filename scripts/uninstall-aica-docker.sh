#!/bin/bash

SYMLINK=/usr/local/bin/aica-docker
if test -f "$SYMLINK"; then
  echo "Removing symbolic link ${SYMLINK}"
  rm "${SYMLINK}"
fi
