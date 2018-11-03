#!/bin/bash

REPOSITORY="oydeu"
CONTAINER="oyd-pia2"

# read commandline options
BUILD_CLEAN=false
DOCKER_UPDATE=false


while [ $# -gt 0 ]; do
    case "$1" in
        --clean*)
            BUILD_CLEAN=true
            ;;
        --dockerhub*)
            DOCKER_UPDATE=true
            ;;
        *)
            printf "unknown option(s)\n"
            if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
                return 1
            else
                exit 1
            fi
    esac
    shift
done

if $BUILD_CLEAN; then
    docker build --no-cache -t $REPOSITORY/$CONTAINER .
else
    docker build -t $REPOSITORY/$CONTAINER .
fi

if $DOCKER_UPDATE; then
    docker push $REPOSITORY/$CONTAINER
fi
