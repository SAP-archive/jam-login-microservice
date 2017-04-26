#!/bin/bash

WORKDIR=$(dirname $0)/..
DOCKERDIR=$WORKDIR/docker
REGISTRY=clm-registry.mo.sap.corp:5000
PROXY=http://proxy.wdf.sap.corp:8080
NO_PROXY=github.wdf.sap.corp

IS_PROD=
MIX_ENV=test

while [ -n "$1" ]; do
    COMMAND="$1"
    shift
    case "$COMMAND" in
        --prod)
            MIX_ENV=prod
            ;;
    esac
done

IMAGE_NAME=clm-loginproxy-$MIX_ENV

docker build --build-arg HTTPS_PROXY=$PROXY \
             --build-arg HTTP_PROXY=$PROXY \
             --build-arg http_proxy=$PROXY \
             --build-arg https_proxy=$PROXY \
             --build-arg NO_PROXY=$NO_PROXY \
             --build-arg no_proxy=$NO_PROXY \
             --build-arg TEST_REPORT=1 \
             --build-arg MIX_ENV=$MIX_ENV \
             -t $REGISTRY/$IMAGE_NAME -f $DOCKERDIR/Dockerfile $WORKDIR