#!/bin/bash

log() {
    message=$1
    shift
    if [ "$message" = "info" ]; then
        echo "[INFO]" $(date) " - " $@ >> ./logs/build.log
        echo "[INFO]" $(date) " - " $@
    elif [ "$message" = "error" ]; then
        echo "[ERROR]" $(date) " - " $@ >> ./logs/build.log
        echo "[ERROR]" $(date) " - " $@
    else
        echo "no log"
    fi
}