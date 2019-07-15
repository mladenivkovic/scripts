#!/bin/bash

#------------------------------------------------
# rsync my homepage to/from given destination
# using ssh.
#------------------------------------------------




function errormsg(){
    echo "I need you to tell me in which direction to sync."
    echo "Usage: "
    echo "   sync_homepage.sh local"
    echo "        to sync TO local machine (e.g. FROM unige machine)"
    echo "   sync_homepage.sh unige"
    echo "        to sync TO unige machine"
    exit
}


if [[ "$#" < 1 ]]; then
    errormsg;
else
    case $1 in

        unige)
            echo "Sending to UNIGE"
            UNAME=ivkovic
            HOST=login01.astro.unige.ch
            SRC=~/Documents/homepage/
            DESTDIR=/home/epfl/ivkovic/website/homepage/
            DEST="$UNAME"@"$HOST":"$DESTDIR"
        ;;

        local)
            echo "syncing to local machine"
            UNAME=ivkovic
            HOST=login01.astro.unige.ch
            SRCDIR=/home/epfl/ivkovic/website/homepage/
            SRC="$UNAME"@"$HOST":"$SRCDIR"
            DEST=~/Documents/homepage/
        ;;

        *)
            errormsg;
        ;;

    esac

fi



rsync                   \
    --verbose           \
    --recursive         \
    --update            \
    --links             \
    --hard-links        \
    --executability     \
    --perms             \
    --times             \
    --human-readable    \
    -e ssh              \
    --exclude .git      \
    "$SRC"              \
    "$DEST"
