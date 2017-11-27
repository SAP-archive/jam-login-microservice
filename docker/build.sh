#!/bin/bash

WORKDIR=$(dirname $0)
BASE_IMAGE=kora/login-proxy

REGISTRY=clm-registry.mo.sap.corp:5000

BUILD_ENVS=()
PROXY_ARG=

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
        --disable-proxy)
            PROXY_ARG=" --disable-proxy "
            ;;
    esac
done

# build a runnable image by default if no other args passed
if [ -z "${BUILD_ENVS[*]}" ]; then
    BUILD_ENVS=( prod )
fi

#
# for each env we want to build, build it with a custom name
# and whichever proxy parameterization we've chosen
#
REGISTRY_IMAGE=${REGISTRY}/${BASE_IMAGE}
GIT_REF=$( git rev-parse --short --verify HEAD )
TAG=$( whoami )-${GIT_REF}

for BUILD_ENV in ${BUILD_ENVS[@]}; do

    case $BUILD_ENV in
      dev)
        ${WORKDIR}/jenkins-build.sh dev \
          ${REGISTRY_IMAGE}-dev:$TAG \
          $PROXY_ARG \
          --prompt ${BASE_IMAGE}-dev \
          --build-info "local-dev-build-${TAG}-$( date '+%Y-%m-%d@%H.%M.%S' )"

        [ "$?" == "0" ] || { echo "Dev build failed"; exit 1; }
        ;;
      prod)
        ${WORKDIR}/jenkins-build.sh prod \
          ${REGISTRY_IMAGE}:$TAG \
          --build ${REGISTRY_IMAGE}-build:$TAG \
          $PROXY_ARG \
          --prompt ${BASE_IMAGE}-prod \
          --build-info "local-prod-build-${TAG}-$( date '+%Y-%m-%d@%H.%M.%S' )"
        [ "$?" == "0" ] || { echo "Prod build failed"; exit 1; }
        ;;
    esac
done
