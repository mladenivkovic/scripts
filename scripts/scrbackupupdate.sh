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
    echo
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






#============================================================
# Read in files line by line, and update the scripts
#============================================================


while read line; do
    src=`echo $line | sed 's/:/ /g' | awk '{print $1}'`
    dest=`echo $line | sed 's/:/ /g' | awk '{print $2}'`

    do_check=true
    # set them to 'false' here because they will be used as a check
    src_rsync=
    dest_rsync=

    if [ ! -f "$src" ]; then
        # 'src' file doesn't exist
        src_rsync="$dest"
        dest_rsync="$src"
        do_check=
    fi


    [ "$do_check" ] && \
    if [ ! -f "$dest" ]; then
        src_rsync="$src"
        dest_rsync="$dest"
        do_check=
    fi

    [ "$do_check" ] && \
    if [ "$src" -nt "$dest" ]; then
        src_rsync="$src"
        dest_rsync="$dest"
    elif [ "$dest" -nt "$src" ]; then
        src_rsync="$dest"
        dest_rsync="$src"
    fi;


    # if there is work to do, $src_rsync will be defined
    if [ "$src_rsync" ]; then

        # use rsync instead of hard/soft links because git breaks links
        # echo "$src_rsync" '-->' "$dest_rsync"
        echo "SOURCE:     " "$src_rsync"
        echo "DESTINATION:" "$dest_rsync"
        echo

        rsync -a --update "$src_rsync" "$dest_rsync"
        # update time
        touch -m -c  "$dest_rsync" "$src_rsync"

        # old version
        # scrbackup --no-log "$src_rsync" "$dest_rsync"
        # if [ $? -ne 0 ]; then
        #     echo 'In case you forgot: I need to have scrbackup in the path so I can run it'
        #     exit 1
        # fi
    fi

done < "$SRCFILE"



echo "Finished updating backed up scripts."
