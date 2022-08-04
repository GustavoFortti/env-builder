#!/bin/bash

source /root/setup-env.sh

DOWNLOAD_REPOSITORY=0
DIR_NAME=""

configure_package() {
    unzip /root/package.zip
    sleep 3

    mv /package/id_rsa /root/.ssh/
    mv /package/entrypoint.cfg /root/

    DIR_NAME=$(echo `grep -n 'project-name=' /root/entrypoint.cfg` | cut -d "=" -f 2)
    dir_project="/package/$DIR_NAME"
    mkdir -p /root/project/$DIR_NAME
    if [ -d "$dir_project" ]; then
        mv $dir_project /root/project
    else
        DOWNLOAD_REPOSITORY=1
    fi

    rm -r /root/package.zip
}

configure_ssh() {
    chmod 600 /root/.ssh/id_rsa
    chmod 777 /root/entrypoint.sh

    eval $(ssh-agent -s)
    ssh-add /root/.ssh/id_rsa
    ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts 
}

configure_repository() {
    file_config=`cat ./root/entrypoint.cfg`

    for i in $file_config; do
        option=`echo $i | cut -f 1 -d "="`
        choice=`echo $i | cut -f 2 -d "="`
        case $option in
            "branch")
                branch=$choice
                ;;
            "repository")
                repository=$choice
                ;;
        esac
    done
    
    echo "git -C /root/project/$DIR_NAME clone $repository"
    git -C /root/project/$DIR_NAME clone $repository
    if [ $branch != "master" ]; then
        git -C /root/project/$DIR_NAME checkout $branch
    fi
}

start() {
    # prepara o pacote gerado pelo build.sh
    configure_package

    # configura para download do repositorio
    if [ $DOWNLOAD_REPOSITORY = "1" ]; then
        configure_ssh
        configure_repository
    fi

    # Executes environment-specific functionality
    setup_env

    CONTAINER_RUNNING=$(echo `grep -n 'container-running=' /root/entrypoint.cfg` | cut -d "=" -f 2)
    if [ $CONTAINER_RUNNING = true ]; then
        tail -f /dev/null
    fi
}

start