#!/bin/bash

save_env_files() {
    cp ./docker/Dockerfile ./project/.env/docker
    cp ./docker/conf/entrypoint.cfg ./project/.env/docker/conf
}

commit() {

    # copia os arquivos de ambinte para quee seja salvo no repositorio
    save_env_files

    git status ./project
    read -p "ok? (y/n): " alter
    if [ $alter = "n" ]; then
        exit 0
    fi

    git add .

    read -p "write message to commit: " message
    git commit -m "$message" ./project

    read -p "push? (y): " push
    if [ $push = "y" ]; then
        read -p "branch to commit: " branch_commit
        git push origin $branch_commit ./project
    fi
    

    exit 0
}