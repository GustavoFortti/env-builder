#!/bin/bash

source ./utils/logs.sh
source ./utils/build.sh
source ./utils/env.sh
source ./utils/repository.sh

usage() {
    echo ""
    echo "NAME"
    echo "    build - prepares to build an execution environment"
    echo ""
    echo "SYNOPSIS"
    echo "    build [OPTION]..."
    echo ""
    echo "DESCRIPTION"
    echo ""
    echo "    --set-entrypoint, -S"
    echo "        Defines the initial settings for running the project from the entrypoint.conf file."
    echo ""
    echo "    --run-container, -R"
    echo "        Just control the image or run the contatainer"
    echo "        run container = 1"
    echo ""
    echo "    --del"
    echo "        delete docker images that REPOSITORY is <none>"
    echo ""
    echo "    --init"
    echo "        creates folder and file structure at project start"
    echo ""
    exit 0
}

parse_arguments() {
    log info "PARSE ARGUMENTS"
    log info "$@"

    while  [ $# -gt 0 ]; do
        option="$1"
        shift
        case $option in
            "--" ) break 2;;
            "--set-entrypoint"|"-S")
                    SET_ENTRYPOINT="$1"
                    shift;;
            "--run-container"|"-R")
                    RUN_CONTAINER="$1"
                    shift;;
        esac
    done
}


if [ "$1" = "--help" ]; then
    usage
elif [ "$1" = "--init" ]; then
    init
elif [ "$1" = "--del" ]; then
    delete_docker_images
elif [ "$1" = "--commit" ]; then
    commit
fi

parse_arguments "$@"
build $1
run $1