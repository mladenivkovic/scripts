#!/bin/bash

# unzip *.zip in this directory to new created dirs.


while [[ $# > 0 ]]; do
    arg="$1"

    case $arg in 

        -n | --nodir )
        nodir=true
        ;;

        -d | --delete )
        delete=true
        ;;

        *)

        echo This script unzips all .zip files in this directory
        echo in a directory with the same name as the zipfile.
        echo -d : delete .zip file after extracting
        echo -n : dont create new directory, just extract here
        exit
        ;;

    esac

    shift

done





for f in *.zip; do
    if [[ $delete == true ]]; then
        if [[ $nodir == true ]]; then
            unzip "$f" -d "${f%.zip}" && rm "$f"
            for file in `ls "${f%.zip}"`; do
                echo $file
                mv "${f%.zip}"/"$file" "${f%.zip}"-"$file";
                rmdir "${f%.zip}";
            done

        else
            unzip "$f" -d "${f%.zip}" && rm "$f";
        fi
    
    else

    echo check

        if [[ $nodir == true ]]; then
            unzip "$f" -d "${f%.zip}";
            for file in `ls "${f%.zip}"`; do
                echo $file
                mv "${f%.zip}"/"$file" "${f%.zip}"-"$file";
                rmdir "${f%.zip}";
            done
        else
            unzip "$f" -d "${f%.zip}";
        fi
    fi 
done
