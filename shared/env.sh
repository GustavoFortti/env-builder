#!/bin/bash

delete_env_images() {
    log info "DELETE DOCKER IMAGE"

    image_name=`docker images | awk '{print $1}'`
    aux=`docker images | awk '{print $3}'`
    image_id=( $aux )

    index=0
    images_delete=""
    for i in $image_name; do
        if [ "$i" = "<none>" ]; then
            images_delete="${image_id[$index]} $images_delete"
        fi
        index=$(($index + 1))
    done

    log info "$images_delete"
    if [ "$images_delete" != "" ]; then
        docker rmi -f $images_delete
    else
        echo "no image was found"
    fi

    exit 0
}

run() {
    if [ "$RUN_CONTAINER" = "1" ]; then
        log info "RUN CONTAINER"
        docker run $CONTAINER_PARMS $DIR_NAME
    fi
}