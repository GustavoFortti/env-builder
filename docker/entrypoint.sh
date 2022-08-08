#!/bin/bash

PROJECT_NAME=""
PROJECT_PATH=$1
DOWNLOAD_REPOSITORY=0
DIR_PROJECT=""

source $PROJECT_PATH/setup-env.sh

configure_package() {
    unzip $PROJECT_PATH/package.zip -d $PROJECT_PATH
    ls $PROJECT_PATH

    mv $PROJECT_PATH/package/id_rsa /root/.ssh/
    mv $PROJECT_PATH/package/entrypoint.cfg $PROJECT_PATH/

    PROJECT_NAME=$(echo `grep -n 'project-name=' $PROJECT_PATH/entrypoint.cfg` | cut -d "=" -f 2)
    DIR_PROJECT="$PROJECT_PATH/package/$PROJECT_NAME"
    if [ ! -d "$DIR_PROJECT" ]; then
        DOWNLOAD_REPOSITORY=1
    fi

    rm $PROJECT_PATH/package.zip
}

configure_ssh() {
    chmod 600 /root/.ssh/id_rsa
    chmod 777 $PROJECT_PATH/entrypoint.sh

    eval $(ssh-agent -s)
    ssh-add /root/.ssh/id_rsa
    ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts 
}

configure_repository() {
    file_config=`cat $PROJECT_PATH/entrypoint.cfg`

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
    
    echo "git -C $DIR_PROJECT clone $repository"
    git -C $DIR_PROJECT clone $repository
    if [ $branch != "master" ]; then
        git -C $DIR_PROJECT checkout $branch
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

    keep_running_container=$(echo `grep -n 'container-running=' $PROJECT_PATH/entrypoint.cfg` | cut -d "=" -f 2)
    echo $keep_running_container
    exit 0
    if [ $keep_running_container = true ]; then
        tail -f /dev/null
    fi
}

start