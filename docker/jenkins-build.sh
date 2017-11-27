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
BUILD_TYPE="$1"
IMAGE="$2"

shift; shift;

if [ -z "$BUILD_TYPE" ] || [ -z "$IMAGE" ]; then
  echo "Usage: $0 BUILD_TYPE IMAGE_NAME:TAG [ --build BUILD-IMG:TAG ] [ --disable-proxy ] [ --prompt PS1_PREFIX ] [ --build-info INFO ]"
  echo
  echo "BUILD_TYPE can be one of:"
  echo "   dev"
  echo "   prod"
  echo "and will build Dockerfile.dev and Dockerfile.prod, respectively."
  echo " (if the dockerfile does not exist, it will fallback to Dockerfile (no extension)"
  echo
  echo "Resulting image will be taged to IMAGE_NAME:TAG"
  echo
  echo "If --build BUILD-IMG:TAG is provided, the build image will be built referencing Dockerfile.build"
  echo " before either prod or dev"
  echo
  echo "--prompt PS1_PREFIX adds a prefix to the PS1 prompt when shelling into the container\n"
  echo "                    (this is useful for indicating what container you are in)"
  echo
  echo "--build-info INFO   writes INFO content to a build.txt (ie, write version/branch data to container)"
  exit 1;
fi

DISABLE_PROXY=
BUILD=

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
        --build)
            BUILD="$1"
            shift
            ;;
    esac
done

#
# All of the complex stuffs needed to make this work behind (or not) the proxy
#

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

#
# Let our shell be excellent when we exec a container
#

if [ -n "$PROMPT" ]; then
  PROMPT_ARG="--build-arg PROMPT=$PROMPT"
fi

#
# Bake build information right into the container
#

if [ -n "$INFO" ]; then
  INFO_ARG="--build-arg INFO=$INFO"
fi

#
# Generate build image if specified
#

PREBUILD_ARG=

if [ -n "$BUILD" ]; then
  BUILDFILE="$DOCKERDIR/Dockerfile.build"
  [ -f "$BUILDFILE" ] || { echo "No $BUILDFILE, bailing"; exit 1; }
  docker build \
    $PROXY_ARGS \
    $PROMPT_ARG \
    $INFO_ARG \
    -t $BUILD \
    -f "$BUILDFILE" \
    $WORKDIR
  [ "$?" == 0 ] || { echo "Build container failed"; exit 1; }
  PREBUILD_ARG="--build-arg BUILD_IMAGE=$BUILD"
fi

DOCKERFILE=$DOCKERDIR/Dockerfile.$BUILD_TYPE

if [ ! -f "$DOCKERFILE" ]; then
  echo -n "$DOCKERFILE not found, fallling back to "
  DOCKERFILE=$DOCKERDIR/Dockerfile
  echo "$DOCKERFILE"
fi
[ -f "$DOCKERFILE" ] || { echo "Fallback $DOCKERFILE not found, exiting"; exit 1; }

docker build \
  $PROXY_ARGS \
  $PROMPT_ARG \
  $INFO_ARG \
  $PREBUILD_ARG \
  -t $IMAGE \
  -f "$DOCKERFILE" \
  $WORKDIR
