#!/bin/sh

usage() {
    log info "USEGE"
}

log() {
    message=$1
    if [ "$message" = "info" ]; then
        echo "[INFO]" $(date) " - " $2 >> ./logs/build.log
        echo "[INFO]" $(date) " - " $2
    elif [ "$message" = "error" ]; then
        echo "[ERROR]" $(date) " - " $2 >> ./logs/build.log
        echo "[ERROR]" $(date) " - " $2
    else
        echo "no log"
    fi
}

parse_arguments() {
    log info "PARSE ARGUMENTS"
}

configure_entrypoint() {
    set=$1
    log info "build with $set"

    entrypoint_path="./docker/config/entrypoint.config"

    start_line_index=$(expr $(echo `grep -n $set $entrypoint_path` | cut -d ":" -f 1) + 1)
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
    set=$1

    log info "START BUILD"

    mkdir -p ./package/
    # cria uma copia da chave ssh do repositorio
    cp /home/$(whoami)/.ssh/id_rsa ./package/

    # defini a configuracao inicias para executar o projeto
    configure_entrypoint $set
    zip -r ./docker/package.zip ./package/*

    # build container
    log info "LOAD CONTAINER"
    docker build ./docker/ -t python-machine
    log info "BUILD COMPLETE"

    rm -r ./package/
    rm ./docker/package.zip
    
    log info "SUCCESS"
}

start() {
    run=true
    if [ "$run" = "true" ]; then
        docker run -it --name test --rm -p 8088:8088 python-machine
    fi
}

usage
parse_arguments
build $@
start