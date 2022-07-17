#!/bin/bash

save_env_files() {
    cp ./docker/Dockerfile ./project/.env/docker
    cp ./docker/conf/entrypoint.cfg ./project/.env/docker/conf
}

commit() {

    # copia os arquivos de ambinte para quee seja salvo no repositorio
    save_env_files

    git -C ./project status
    read -p "ok? (y/n): " alter
    if [ $alter = "n" ]; then
        exit 0
    fi

    git -C ./project add .

    read -p "write message to commit: " message
    git -C ./project commit -m "$message"

    read -p "push? (y): " push
    if [ $push = "y" ]; then
        read -p "branch to commit: " branch_commit
        git -C ./project push origin $branch_commit
    fi
    

    exit 0
}