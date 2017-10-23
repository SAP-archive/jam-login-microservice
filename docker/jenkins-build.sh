#!/bin/bash

#
# Presets
#

PROXY=http://proxy.wdf.sap.corp:8080
NO_PROXY=github.wdf.sap.corp


WORKDIR=$(dirname $0)/..
DOCKERDIR=$WORKDIR/docker

#
# Params
#
MIX_ENV="$1"
IMAGE="$2"

shift; shift;

if [ -z "$MIX_ENV" ] || [ -z "$IMAGE" ]; then
  echo "Usage: $0 MIX_ENV IMAGE_NAME:TAG [ --disable-proxy ] [ --prompt PS1_PREFIX ] [ --build-info INFO ]"
  echo
  echo "--prompt PS1_PREFIX adds a prefix to the PS1 prompt when shelling into the container\n"
  echo "                    (this is useful for indicating what container you are in)"
  echo
  echo "--build-info INFO   writes INFO content to a build.txt (ie, write version/branch data to container)"
  exit 1;
fi

DISABLE_PROXY=

while [ -n "$1" ]; do
    COMMAND="$1"
    shift
    case "$COMMAND" in
        --disable-proxy)
            DISABLE_PROXY=true
            ;;
        --prompt)
            PROMPT=$1
            shift
            ;;
        --build-info)
            INFO="$1"
            shift
            ;;
    esac
done


PROXY_PARAMS=( HTTPS_PROXY https_proxy HTTP_PROXY http_proxy )
NO_PROXY_PARAMS=( NO_PROXY no_proxy )

PROXY_ARGS=
PROMPT_ARG=
INFO_ARG=

if [ -z $DISABLE_PROXY ]; then
    for param_name in ${PROXY_PARAMS[@]}; do
        PROXY_ARGS="${PROXY_ARGS} --build-arg $param_name=$PROXY"
    done
    for param_name in ${NO_PROXY_PARAMS[@]}; do
        PROXY_ARGS="${PROXY_ARGS} --build-arg $param_name=$NO_PROXY"
    done
fi

if [ -n "$PROMPT" ]; then
  PROMPT_ARG="--build-arg PROMPT=$PROMPT"
fi

if [ -n "$INFO" ]; then
  INFO_ARG="--build-arg INFO=$INFO"
fi

docker build \
  $PROXY_ARGS \
  $PROMPT_ARG \
  $INFO_ARG \
  --build-arg MIX_ENV=$MIX_ENV \
  -t $IMAGE \
  -f $DOCKERDIR/Dockerfile \
  $WORKDIR
