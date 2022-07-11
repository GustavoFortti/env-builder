#!/bin/sh

REPOSITORY=0
DIR_NAME=0

configure_package() {
    unzip /root/package.zip
    sleep 3

    mv /package/id_rsa /root/.ssh/
    mv /package/entrypoint.config /root/

    DIR_NAME=$(echo `grep -n 'name' /root/entrypoint.config` | cut -d "=" -f 2)
    dir_project="/package/$DIR_NAME"
    if [ -d "$dir_project" ]; then
        mkdir /root/project
        mv $dir_project /root/project
    else
        REPOSITORY=1
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
    file_config=`cat ./root/entrypoint.config`

    for i in $file_config
    do
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

    git clone $repository /root/project
    ls /root/
    # git checkout master
}

start() {

    # prepara o pacote gerado pelo build.sh
    configure_package

    # configura para download do repositorio
    if [ $REPOSITORY = "1" ]; then
        configure_ssh
        configure_repository
    fi

    echo "Start "
    python3 /root/project/$DIR_NAME/main.py
}

start
