#!/bin/bash

helpmsg="
This script updates or creates a copy of specified file in your online backup\n
directory. All the files should be listed in \$linklist file from the\n
scrbackup.sh script.\n

Usage:\n\n

scrbackupupdate.sh [options] [sourcefile]\n\n

[sourcefile]:\t   file to read links from. If none specified, it will use the hardcoded one.\n
[options]:\t    -h    \t  show this message\n
"


#================================================
# Read cmdlineargs, get SRCFILE and DESTFILE
#================================================


if [ $# == 0 ]; then

    echo "USING HARDCODED ORIGINAL LINKS FILE."
    echo "IF YOU WANT TO USE A DIFFERENT FILE, SPECIFY IT AS CMD LINE ARG."
    SRCFILE=$PJ/online-backup/original_links.txt
    
elif [ $# == 1 ]; then

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


    # do rsync in both directions, such that wherever you modified the file,
    # it will be updated.
    # scrbackup --no-log "$src" "$dest"

    # use rsync instead of hard/soft links because git breaks links
    echo "$src" '-->' "$dest"
    rsync -a --update "$src" "$dest"

    echo "$dest" '-->' "$src"
    rsync -a --update "$dest" "$src"

    if [ $? -ne 0 ]; then
        echo 'In case you forgot: I need to have scrbackup in the path so I can run it'
        exit 1
    fi

done < "$SRCFILE"
