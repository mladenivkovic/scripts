#!/bin/bash

# removes trailing whitespace on every line in provided file(s).

if [[ $# == 0 ]]; then
    echo "no arguments given. Can't handle that. Give me a file to work on."
    exit
else

    while [[ $# > 0 ]]; do
    arg="$1"

    case "$arg" in 

        -h | --help)
        echo "removes trailing whitespaces on every line in provided file(s)." 
        echo "Usage: remove-whitespace file1 file2 ..."
        exit
        ;;

        *)
        if [ -f "$arg" ]; then
            sed -i 's/\s*$//g' "$arg"
        else
            echo "'""$arg""' is not a file. Skipping."
        fi
        ;;
    esac

    shift
    done
fi


