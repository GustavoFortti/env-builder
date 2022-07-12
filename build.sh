#!/bin/sh

SET_ENTRYPOINT=0
RUN_CONTAINER=0

usage() {
    echo ""
    echo "NAME"
    echo "    build - prepares to build an execution environment"
    echo ""
    echo "SYNOPSIS"
    echo "    build --set-entrypoint [ARG] [OPTION]..."
    echo ""
    echo "DESCRIPTION"
    echo ""
    echo "    --set-entrypoint, -S"
    echo "        Defines the initial settings for running the project from the entrypoint.conf file."
    echo ""
    echo "    --run-container, -R"
    echo "        Just control the image or run the contatainer"
    echo "        build image = 0"
    echo "        build image and run container = 1"
    echo ""
    exit 0
}

log() {
    message=$1
    shift
    if [ "$message" = "info" ]; then
        echo "[INFO]" $(date) " - " $@ >> ./logs/build.log
        echo "[INFO]" $(date) " - " $@
    elif [ "$message" = "error" ]; then
        echo "[ERROR]" $(date) " - " $@ >> ./logs/build.log
        echo "[ERROR]" $(date) " - " $@
    else
        echo "no log"
    fi
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

configure_entrypoint() {
    log info "build with $SET_ENTRYPOINT"

    entrypoint_path="./docker/config/entrypoint.config"

    start_line_index=$(expr $(echo `grep -n $SET_ENTRYPOINT $entrypoint_path` | cut -d ":" -f 1) + 1)
    file_size=$(stat -c%s "$entrypoint_path")
    file_config=$(echo $(echo `cat $entrypoint_path | sed -n "$start_line_index,$file_size p"`) | cut -d "[" -f 1)

    log info "$file_config"
    # salva as configuracoes escolhidas para ser executadas pelo entrypoint.sh
    dir_name=$(echo `grep -n 'name' $entrypoint_path` | cut -d "=" -f 2)
    echo "name=$dir_name" > ./package/entrypoint.config
    echo $file_config >> ./package/entrypoint.config

    # caso local=true o projeto executado sera o local e nao do repositorio
    if [ -n "$( echo "$file_config" | sed -n '/local=true/p')" ]; then
        mkdir ./package/$dir_name
        cp -r ./project/* ./package/$dir_name
    fi
}

build() {
    log info "START BUILD"

    mkdir -p ./package/
    # cria uma copia da chave ssh do repositorio
    cp /home/$(whoami)/.ssh/id_rsa ./package/
    # defini a configuracao inicias para executar o projeto
    configure_entrypoint $SET_ENTRYPOINT
    zip -r ./docker/package.zip ./package/*

    # build IMAGE
    log info "LOAD IMAGE"
    docker build ./docker/ -t python-machine
    log info "BUILD IMAGE"

    log info "remove packages"
    rm -r ./package/
    rm ./docker/package.zip
    
    log info "SUCCESS"
}

start() {
    if [ "$RUN_CONTAINER" = "1" ]; then
        log info "RUN CONTAINER"
        docker run -it --name test --rm -p 8088:8088 python-machine
    fi
}

if [ "$1" = "man" ]; then
    usage
fi
parse_arguments "$@"
build $1
start $1