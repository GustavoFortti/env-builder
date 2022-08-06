#!/bin/bash

SET_ENTRYPOINT=""
RUN_CONTAINER=0
PROJECT_NAME=""
PROJECT_PATH="/home/"
CONTAINER_NAME=""
CONTAINER_PARMS=""
ENTRYPOINT_PATH="./docker/conf/entrypoint.cfg"

init() {
    mkdir ./logs
    mkdir -p ./project/src/utils
    mkdir ./project/conf/
    mkdir -p ./project/.env/docker/conf

    touch ./docker/Dockerfile
    setup_env_path="./docker/setup-env.sh"

    touch $setup_env_path
    echo "#!/bin/bash" >> $setup_env_path
    echo "# specific command for building the environment" >> $setup_env_path
    echo "# setup_env() {}" >> $setup_env_path

    touch $ENTRYPOINT_PATH

    create_entrypoint

    touch ./project/main.py
    touch ./project/.gitignore

    cp ./docker/Dockerfile ./project/.env/docker
    cp $ENTRYPOINT_PATH ./project/.env/docker/conf$ENTRYPOINT_PATH

    first_commit
    exit 0
}

create_entrypoint() {
    read -p "project name: " project_name
    read -p "repository: " repository_address

    echo "# environment build settings" >> $ENTRYPOINT_PATH
    echo "# these settings are changed by parameters in build.sh" >> $ENTRYPOINT_PATH
    echo "" >> $ENTRYPOINT_PATH
    echo "# standard project information" >> $ENTRYPOINT_PATH
    echo "name=$project_name" >> $ENTRYPOINT_PATH
    echo "repository=$repository_address" >> $ENTRYPOINT_PATH

}

setup_entrypoint() {
    log info "build with $SET_ENTRYPOINT"

    package_entrypoint_path="./package/entrypoint.cfg"

    # salva as configuracoes escolhidas para ser executadas pelo entrypoint.sh
    PROJECT_NAME=$(echo `grep -n 'project-name=' $ENTRYPOINT_PATH` | cut -d "=" -f 2)
    REPOSITORY=$(echo `grep 'repository=' $ENTRYPOINT_PATH`)
    CONTAINER_NAME=$(echo `grep 'container-name=' $ENTRYPOINT_PATH` | cut -d "=" -f 2)
    echo "project-name=$PROJECT_NAME" > $package_entrypoint_path
    echo $REPOSITORY >> $package_entrypoint_path

    # busca pela primeira e ultima linha da configuração escolhida
    count=0
    set_index=(`grep -n "\[" $ENTRYPOINT_PATH`)
    for i in ${set_index[@]}; do
        IFS=: read -r index value <<< $i
        if [ "$value" = "[$SET_ENTRYPOINT]" ]; then
            start_line_config=$(expr $index + 1)
            end_index=$(expr $count + 1)
            aux_end_line_config=`echo ${set_index[end_index]} | cut -d ":" -f 1`
            if [ "$aux_end_line_config" = "" ]; then
                end_line_config=$(expr `cat $ENTRYPOINT_PATH | wc -l` + 1)
            else
                end_line_config=$(expr $aux_end_line_config - 1)
            fi

            break
        fi
        count=$(expr $count + 1)
    done
    cat $ENTRYPOINT_PATH | sed -n "${start_line_config},${end_line_config}p" >> $package_entrypoint_path

    CONTAINER_PARMS=$(echo `grep -n 'container-run=' $package_entrypoint_path` | cut -d "=" -f 2)
    
    log info $(cat $package_entrypoint_path)
    # caso local=true o projeto executado sera o local e nao do repositorio
    if [ -n "$( cat "$package_entrypoint_path" | sed -n '/local=true/p')" ]; then
        mkdir ./package/$PROJECT_NAME
        cp -r ./project/* ./package/$PROJECT_NAME
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

    build_image=$(echo `grep -n 'build=' $package_entrypoint_path` | cut -d "=" -f 2)
    flag=false
    container_running=$(echo ` docker container inspect -f '{{.State.Running}}' $CONTAINER_NAME `)
    if [[ $build_image = "false" && $container_running = "true" ]]; then
        # send code to server
        log info "SENDING..."
        CONTAINER_DEST_PATH="$PROJECT_PATH$PROJECT_NAME"
        docker exec -it airflow-server mkdir -p $CONTAINER_DEST_PATH
        docker cp ./docker/package.zip $CONTAINER_NAME:$CONTAINER_DEST_PATH
        docker cp ./docker/entrypoint.sh $CONTAINER_NAME:$CONTAINER_DEST_PATH
        docker cp ./docker/setup-env.sh $CONTAINER_NAME:$CONTAINER_DEST_PATH
        flag=true
    else
        # build IMAGE
        log info "LOAD IMAGE"
        docker build ./docker/ -t $PROJECT_NAME
        log info "BUILD IMAGE"
    fi

    log info "remove packages"
    rm -r ./package/
    rm ./docker/package.zip
    
    log info "SUCCESS"
    if [ $flag = true ]; then
        exit 0
    fi
}

run() {
    if [ "$RUN_CONTAINER" = "1" ]; then
        log info "RUN CONTAINER"
        log info "docker run $CONTAINER_PARMS $PROJECT_NAME"
        docker run $CONTAINER_PARMS $PROJECT_NAME 
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
    rm $ENTRYPOINT_PATH

    exit 0
}

start() {
    build
    run
}