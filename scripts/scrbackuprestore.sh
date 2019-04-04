#!/bin/bash

helpmsg="
This script creates a hard link of specified file in your online backup\n
directory. All the files should be listed in \$linklist file from the\n
scrbackup.sh script.\n
If you moved the files in the meantime, I guess you're fucked... But at\n
least you had a backup I guess. :)

Usage:\n\n

scrbackuprestore.sh [options] sourcefile\n\n

sourcefile:\t   file to read links from\n
[options]:\t    -h    \t  show this message\n
"


#================================================
# Read cmdlineargs, get SRCFILE and DESTFILE
#================================================

if [ $# == 0 ]; then
    echo "ERROR: need file"
    echo -e $helpmsg
    exit 1
fi



if [ $# == 1 ]; then

    case $1 in

    -h | --help)
        echo -e $helpmsg
        exit
        ;;

    *)
        SRCFILE="$1"
        if [ ! -f "$SRCFILE" ]; then
            echo "ERROR: DIDN'T FIND FILE" "$SRCFILE"
            echo "Run scrbackuprestore.sh -h for help"
            exit 1 
        fi
        ;;
    esac


else

    echo "ERROR: Too many arguments given."
    echo "Run scrbackuprestore.sh -h for help"
    exit 1 

fi


while read line; do
    src=`echo $line | sed 's/:/ /g' | awk '{print $1}'`
    dest=`echo $line | sed 's/:/ /g' | awk '{print $2}'`

    scrbackup --no-log "$src" "$dest"

    if [ $? -ne 0 ]; then
        echo 'In case you forgot: I need to have scrbackup in the path so I can run it'
        exit 1
    fi

done < "$SRCFILE"
