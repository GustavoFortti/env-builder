#!/bin/bash

source ./shared/logs.sh
source ./shared/environment.sh
source ./shared/repository.sh

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
    echo "  EXCUTION FUNCTIONS"
    echo ""
    echo "    --set-entrypoint, -S"
    echo "        Defines the initial settings for running the project from the entrypoint.conf file."
    echo ""
    echo "    --run-container, -R"
    echo "        Just control the image or run the contatainer"
    echo "        run container = 1"
    echo ""
    echo "  SUPORT FUNCTIONS"
    echo ""
    echo "    --delete-images"
    echo "        delete docker images that REPOSITORY is <none>"
    echo ""
    echo "    --init"
    echo "        creates folder and file structure at project start"
    echo ""
    echo "    --commit"
    echo "       copy the environment files to the project and send the code to the repository"
    echo ""
    echo "    --delete-project"
    echo "       delete ./project ./docker/Dockerfile ./docker/conf/entrypoint.cfg"
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


arg=$1
case $arg in
    "--help")
            usage
            shift;;
    "--init")
            init
            shift;;
    "--delete-images"| "-D")
            delete_env_images
            shift;;
    "--delete-project")
            delete_project
            shift;;
    "--commit")
            commit
            shift;;
esac

parse_arguments "$@"
build $1
run $1