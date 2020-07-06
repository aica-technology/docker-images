#!/bin/bash
BASE_IMAGE=ros
BASE_TAG=foxy

docker pull "${BASE_IMAGE}:${BASE_TAG}"

REBUILD=0

while getopts 'r' opt; do
    case $opt in
        r) REBUILD=1 ;;
        *) echo 'Error in command line parsing' >&2
           exit 1
    esac
done
shift "$(( OPTIND - 1 ))"

NAME="${PWD##*/}"

UID="$(id -u "${USER}")"
GID="$(id -g "${USER}")"

if [ "$REBUILD" -eq 1 ]; then
	docker build \
    	--no-cache \
    	--build-arg BASE_IMAGE="${BASE_IMAGE}" \
    	--build-arg BASE_TAG="${BASE_TAG}" \
 		--build-arg UID="${UID}" \
 		--build-arg GID="${GID}" \
 		-t "${NAME}:${BASE_TAG}" .
else
	docker build \
	    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
	    --build-arg BASE_TAG="${BASE_TAG}" \
 		--build-arg UID="${UID}" \
 		--build-arg GID="${GID}" \
 		-t "${NAME}:${BASE_TAG}" .
fi