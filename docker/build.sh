#!/bin/bash

WORKDIR=$(dirname $0)/..
DOCKERDIR=$WORKDIR/docker


REGISTRY=clm-registry.mo.sap.corp:5000

PROXY=http://proxy.wdf.sap.corp:8080
NO_PROXY=github.wdf.sap.corp

BUILD_ENVS=()
DISABLE_PROXY=

while [ -n "$1" ]; do
    COMMAND="$1"
    shift
    case "$COMMAND" in
        --prod)
            BUILD_ENVS=( ${BUILD_ENVS[@]} prod )
            ;;
        --dev)
            BUILD_ENVS=( ${BUILD_ENVS[@]} dev )
            ;;
        --test)
            BUILD_ENVS=( ${BUILD_ENVS[@]} test )
            ;;
        --disable-proxy)
            DISABLE_PROXY=true
            ;;
    esac
done

# build a runnable image by default if no other args passed
if [ -z "${BUILD_ENVS[*]}" ]; then
    BUILD_ENVS=( prod )
fi

#
# construct (or not) proxy configuration to pass into build
#

PROXY_PARAMS=( HTTPS_PROXY https_proxy HTTP_PROXY http_proxy )
NO_PROXY_PARAMS=( NO_PROXY no_proxy )

PROXY_ARGS=

if [ -z $DISABLE_PROXY ]; then
    for param_name in ${PROXY_PARAMS[@]}; do
        PROXY_ARGS="${PROXY_ARGS} --build-arg $param_name=$PROXY"
    done
    for param_name in ${NO_PROXY_PARAMS[@]}; do
        PROXY_ARGS="${PROXY_ARGS} --build-arg $param_name=$NO_PROXY"
    done
fi

#
# for each env we want to build, build it with a custom name
# and whichever proxy parameterization we've chosen
#

for BUILD_ENV in ${BUILD_ENVS[@]}; do

    IMAGE_NAME=clm-loginproxy-${BUILD_ENV}

    docker build $PROXY_ARGS \
        --build-arg MIX_ENV=$BUILD_ENV \
        -t $REGISTRY/$IMAGE_NAME -f $DOCKERDIR/Dockerfile $WORKDIR
done
