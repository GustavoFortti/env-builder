#!/bin/bash

SET_ENTRYPOINT=""
RUN_CONTAINER=0
DIR_NAME=""
CONTAINER_PARMS=""

init() {
    mkdir ./logs
    mkdir -p ./project/src/utils
    mkdir ./project/conf/
    mkdir -p ./project/.env/docker/conf

    touch ./docker/Dockerfile
    touch ./docker/conf/entrypoint.cfg
    touch ./project/main.py
    touch ./project/.gitignore

    cp ./docker/Dockerfile ./project/.env/docker
    cp ./docker/conf/entrypoint.cfg ./project/.env/docker/conf

    exit 0
}

configure_environment() {
    log info "build with $SET_ENTRYPOINT"

    entrypoint_path="./docker/conf/entrypoint.cfg"

    start_line_index=$(expr $(echo `grep -n $SET_ENTRYPOINT $entrypoint_path` | cut -d ":" -f 1) + 1)
    file_size=$(stat -c%s "$entrypoint_path")
    file_config=$(echo $(echo `cat $entrypoint_path | sed -n "$start_line_index,$file_size p"`) | cut -d "[" -f 1)

    # salva as configuracoes escolhidas para ser executadas pelo entrypoint.sh
    DIR_NAME=$(echo `grep -n 'name=' $entrypoint_path` | cut -d "=" -f 2)
    CONTAINER_PARMS=$(echo `grep -n 'container-run=' $entrypoint_path` | cut -d "=" -f 2)
    echo "name=$DIR_NAME" > ./package/entrypoint.cfg
    echo $file_config >> ./package/entrypoint.cfg

    log info $(cat ./package/entrypoint.cfg)
    # caso local=true o projeto executado sera o local e nao do repositorio
    if [ -n "$( echo "$file_config" | sed -n '/local=true/p')" ]; then
        mkdir ./package/$DIR_NAME
        cp -r ./project/* ./package/$DIR_NAME
    fi
}

build() {
    log info "START BUILD"

    mkdir -p ./package/
    # cria uma copia da chave ssh do repositorio
    cp /home/$(whoami)/.ssh/id_rsa ./package/
    # defini a configuracao inicias para executar o projeto
    configure_environment $SET_ENTRYPOINT
    zip -r ./docker/package.zip ./package/*

    # build IMAGE
    log info "LOAD IMAGE"
    docker build ./docker/ -t $DIR_NAME
    log info "BUILD IMAGE"

    log info "remove packages"
    rm -r ./package/
    rm ./docker/package.zip
    
    log info "SUCCESS"
}

