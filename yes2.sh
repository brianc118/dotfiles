#!/bin/bash

yes2() {
    if [ $# -eq 0 ]; then
        echo "Usage: yes2 word1 [word2 ...]"
        return 1
    fi

    while true; do
        for word in "$@"; do
            echo "$word"
        done
    done
}

yes2 "$@"
