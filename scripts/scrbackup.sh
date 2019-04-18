#!/bin/bash


DESTDIR=/home/mivkov/coding/projekte/online-backup
linklist='original_links.txt'

nolog=false

helpmsg="
This script creates a copy with rsync of specified file in your online backup\n
directory, which currently is:\n
\t    $DESTDIR \n\n
Furthermore, it keeps track of where the source is by appending it to a list in\n
the backup directory, so that the links can be restored quickly using the\n
scrbackuprestore.sh script in case you need to restore the links in of the\n
backed up files when migrating your system.\n\n\n

Usage:\n\n

scrbackup.sh [options] sourcefile [destfile]\n\n

sourcefile:\t   file to be backed up\n
[options]:\t    -h    \t   show this message\n
\t\t            --no-log\t don't write down what link you made.\n
[destfile]:\t   how to call the file in the backup directory. If not specified,\n
\t\t it will just take the same name.

"



# "Rules" for variables:
# SRCFILE: can be full or relative path
# DESTFILE: can be full or relative path
# DESTDIR: needs to be full path



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
            if [ -d "$SRCFILE" ]; then
                echo "I'm creating hard links. Can't do that with directories."
            fi
            echo "Run scrbackup.sh -h for help"
            exit 1 
        fi
        DESTFILE=${SRCFILE#"$PWD"}
        ;;
    esac

else     

    isfirst=true
    gotbothfiles=false

    while [[ $# > 0 ]]; do


        case "$1" in

        -h | --help)
            echo -e $helpmsg
            exit
            ;;

        --no-log)
            nolog=true
            ;;

        *)
            if [ $gotbothfiles = true ]; then
                
                echo "ERROR: Too many arguments given."
                echo "Run scrbackup.sh -h for help"
                exit 1 
            fi

            FILE="$1"
            if [ $isfirst = true ]; then
                SRCFILE=${FILE#"$PWD"}
                isfirst=false
                if [ ! -f "$FILE" ]; then
                    echo "ERROR: DIDN'T FIND FILE" "$FILE"
                    if [ -d "$FILE" ]; then
                        echo "I'm creating hard links. Can't do that with directories."
                    fi
                    echo "Run scrbackup.sh -h for help"
                    exit 1 
                fi

            else
                DESTFILE=${FILE#"$PWD"}
                DESTFILE=${FILE#"$DESTDIR"}
                gotbothfiles=true
            fi

            ;;
        esac
        shift

    done

fi


# "Rules" for variables at this point:
# SRCFILE:  relative path
# DESTFILE: relative path
# DESTDIR:  needs to be full path
# fpath:    full path


#================================================
# Get correct names, create dirs in backup folder
#================================================

bn=`basename "$DESTFILE"` # get basename
newdirs=${DESTFILE%"$bn"} # figure out what new directories you need to create: for starters, take everything before basename
newdirs=${newdirs#"$PWD"} # subtract PWD
newdirs=${newdirs#"$DESTDIR"} # subtract DESTDIR


mkdir -p "$DESTDIR"/"$newdirs" # create new dirs if necessary
fpath="$DESTDIR"/"$DESTFILE" # define full path
if [ -d "$fpath" ]; then
    # if $DESTFILE was only a directory name, add the same filename as file currently has
    # this is needed to write down things properly for eventual updates; otherwise only
    # the directory will be stored
    fpath="$fpath"/`basename $SRCFILE`
fi


#===========================
# Try to create link
#===========================

echo "$SRCFILE" '-->' "$DESTFILE"


# use rsync instead of hard/soft links because git breaks links
rsync -a --update "$SRCFILE" "$fpath"



#===========================================
# Log what you are doing in linklist log
#===========================================

if [ $? = 0 ]; then
    if [ $nolog = false ]; then
        echo "$PWD"/"$SRCFILE":"$fpath" >> "$DESTDIR"/"$linklist"
        echo "written down what I did."
    fi
fi
