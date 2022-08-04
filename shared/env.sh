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
    touch ./docker/setup-env.sh
    echo "#!/bin/bash" >> setup-env.sh
    echo "# specific command for building the environment" >> setup-env.sh

    touch ./docker/conf/entrypoint.cfg

    create_entrypoint

    touch ./project/main.py
    touch ./project/.gitignore

    cp ./docker/Dockerfile ./project/.env/docker
    cp ./docker/conf/entrypoint.cfg ./project/.env/docker/conf

    first_commit
    exit 0
}

create_entrypoint() {
    read -p "project name: " project_name
    read -p "repository: " repository_address

    echo "# environment build settings" >> ./docker/conf/entrypoint.cfg
    echo "# these settings are changed by parameters in build.sh" >> ./docker/conf/entrypoint.cfg
    echo "" >> ./docker/conf/entrypoint.cfg
    echo "# standard project information" >> ./docker/conf/entrypoint.cfg
    echo "name=$project_name" >> ./docker/conf/entrypoint.cfg
    echo "repository=$repository_address" >> ./docker/conf/entrypoint.cfg

}

setup_entrypoint() {
    log info "build with $SET_ENTRYPOINT"

    entrypoint_path="./docker/conf/entrypoint.cfg"
    package_entrypoint_path="./package/entrypoint.cfg"

    # salva as configuracoes escolhidas para ser executadas pelo entrypoint.sh
    DIR_NAME=$(echo `grep -n 'project-name=' $entrypoint_path` | cut -d "=" -f 2)
    REPOSITORY=$(echo `grep 'repository=' $entrypoint_path`)
    echo "project-name=$DIR_NAME" > $package_entrypoint_path
    echo $REPOSITORY >> $package_entrypoint_path

    # busca pela primeira e ultima linha que contem a definição da configuração
    count=0
    set_index=(`grep -n "\[" $entrypoint_path`)
    for i in ${set_index[@]}; do
        IFS=: read -r index value <<< $i
        if [ "$value" = "[$SET_ENTRYPOINT]" ]; then
            start_line_config=$index
            end_index=$(expr $count + 1)
            aux_end_line_config=`echo ${set_index[end_index]} | cut -d ":" -f 1`
            if [ "$aux_end_line_config" = "" ]; then
                end_line_config=$(expr `cat $entrypoint_path | wc -l` + 1)
            else
                end_line_config=$(expr $aux_end_line_config - 1)
            fi

            break
        fi
        count=$(expr $count + 1)
    done
    cat $entrypoint_path | sed -n "${start_line_config},${end_line_config}p" >> $package_entrypoint_path
    
    CONTAINER_PARMS=$(echo `grep -n 'container-run=' $package_entrypoint_path` | cut -d "=" -f 2)

    log info $(cat $package_entrypoint_path)
    # caso local=true o projeto executado sera o local e nao do repositorio
    if [ -n "$( cat "$package_entrypoint_path" | sed -n '/local=true/p')" ]; then
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
    setup_entrypoint $SET_ENTRYPOINT
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

run() {
    if [ "$RUN_CONTAINER" = "1" ]; then
        log info "RUN CONTAINER"
        log info "docker run $CONTAINER_PARMS $DIR_NAME"
        docker run $CONTAINER_PARMS $DIR_NAME
    fi
}

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

delete_project() {
    rm -r -f ./project
    rm -r -f ./logs
    rm ./docker/Dockerfile
    rm ./docker/conf/entrypoint.cfg

    exit 0
}