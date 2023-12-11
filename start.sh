#! /bin/bash

if [ -z $1 ]; then
    echo "You should provide a file name"
    exit 1
fi

docker run --rm -it -p 8080:8080 \
 -e STRUCTURIZR_WORKSPACE_FILENAME=$1 \
 -v ~/Personal/notifications/design:/usr/local/structurizr structurizr/lite