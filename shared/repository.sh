#!/bin/bash

save_env_files() {
    cp ./docker/Dockerfile ./project/.env/docker
    cp ./docker/conf/entrypoint.cfg ./project/.env/docker/conf
}

first_commit() {
    if [ ! -d "./project/.git" ]; then
        git -C ./project init
        git -C ./project add .
        git -C ./project commit -m "create project structure"
        git -C ./project remote add origin $repository_address
        git -C ./project push -u origin master
    fi
}

commit() {
    first_commit

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