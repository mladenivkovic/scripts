#!/bin/bash

##############################################
#
# Script to sync up files to external HD.
# Syncs up back-and-forth between stuff on the HD,
# and stuff on the local machine.
#
##############################################


errmsg="
Sync up all directories hardcoded in this script onto hard drives,
whose paths are also hardcoded in this script.

usage:
    $ syncHD.sh                      backs up all directories hardcoded in this script

    $ syncHD.sh  -h                  show this message and quit
                 --help

    $ syncHD.sh  -owl                Don't syncronize to and from the HD backups, but
                 --overwrite-local   forcibly overwrite LOCAL STATE with what's on the HD

    $ syncHD.sh  -owh                Don't syncronize to and from the HD backups, but
                 --overwrite-hd      forcibly overwrite HD STATE with what's on the local
                                     machine
"
#-----------------------------------------------------------------------
# First, let's read the cmdline args.
#-----------------------------------------------------------------------

OVERWRITE_LOCAL="no"
OVERWRITE_HD="no"
while [[ $# > 0 ]]; do
    arg="$1"

    case $arg in
        -h | --help)
            echo "$errmsg"
            exit 0
        ;;

        -owl | --overwrite-local)
            OVERWRITE_LOCAL="yes"
            echo "Will overwrite LOCAL MACHINE STATE instead of syncing"
        ;;

        -owh | --overwrite-hd)
            OVERWRITE_HD="yes"
            echo "Will overwrite HD STATE instead of syncing"
        ;;

        * )
        echo "Unknown cmdline arg '"$arg"'"
        echo
        echo $errmsg
        exit
        ;;

    esac

    shift
done




#------------------------------------------------------------------------
# Determine which hard drive to sync with.
# Choices are hardcoded in here.
# TODO: Make sure this fails and exits if no HDPATH is found.
# Otherwise, the subsequent rsync calls are going to do stupid things.
#
# @Mladen: Note that this sync doesn't require encrypted drives.
#------------------------------------------------------------------------
find_HD_path(){

    HOMEDIR_BASENAME=`basename $HOME`
    HDPATH="/media/$HOMEDIR_BASENAME/WD free/"
    # This is the "home" HD. Include private/personal documents in the sync.
    INCLUDE_PRIVATE="yes"

    if [ ! -d "$HDPATH" ]; then
        echo "Din't find target dir '"$HDPATH"', trying second option"
        HDPATH="/media/$HOMEDIR_BASENAME/archive/"
        if [ ! -d "$HDPATH" ]; then
            echo "Din't find target dir" $HDPATH
            exit 1
        fi
        # This is the "work" HD. Don't include private/personal documents in the sync.
        INCLUDE_PRIVATE="no"
    fi
}



#------------------------------------------------------------------------
# Synchronize a single directory (recursively) back and forth between
# the HD and local machine.
#
# Usage:
#   sync_dir LOCALDIR HDDIR [exclude1, exclude2, ...]
#
# LOCALDIR :    directory on your local machine
# HDDIR :       directory on your HD
# `exclude#` :  optional strings to add to the rsync call to exclude
#               whatever you want excluded. The paths may be relative
#               to LOCALDIR and HDDIR.
#------------------------------------------------------------------------
sync_dir() {


    if [ -z ${HDPATH+x} ]; then
        echo "Didn't find HDPATH variable."
        echo 'Call `find_HD_path` function before calling this one.'
        exit 1
    fi

    # better safe than sorry.
    if [ ! -d "$HDPATH" ]; then
        echo "HDPATH '"$HDPATH"' isn't a directory. Quitting."
    fi

    # check passed arguments.
    if [[ "$#" -lt 2 ]]; then
        echo "sync_dir(): no arguments given. Can't handle that."
        exit
    fi

    # read in passed arguments.
    # reminder: $0 is script's own name, not function name.
    LOCALDIR=$1
    HDDIR=$2


    # make full proper paths
    if [[ "$LOCALDIR" = /* ]]; then
        : # this should be a full path. `:` means do nothing.
    else
        LOCALDIR="$PWD"/"$LOCALDIR"
    fi
    if [[ "$HDDIR" = /* ]]; then
        : # this should be a full path. `:` means do nothing.
    else
        HDDIR="$HDPATH"/"$HDDIR"
    fi

    # make sure the dirs don't have trailing slashes. This modifies
    # rsync behaviour.
    # Run it twice in case someone has stupid ideas.

    HDDIR=${HDDIR%/}
    HDDIR=${HDDIR%/}
    LOCALDIR=${LOCALDIR%/}
    LOCALDIR=${LOCALDIR%/}

    # Check that directories in fact exist.
    if [ ! -d "$HDDIR" ]; then
        echo "Target directory on HD not found. Target is '"$HDDIR"', HDPATH is '"$HDPATH"'"
        exit 1
    fi
    if [ ! -d "$LOCALDIR" ]; then
        echo "Target directory on LOCAL not found. Target is '"$LOCALDIR"'"
        exit 1
    fi


    # shift parameter counter to after HDDIR
    shift
    shift

    excludestr_rsync_local=""
    excludestr_rsync_HD=""
    while [[ $# > 0 ]]; do
        newarg_local=$1
        newarg_local_full=$1

        # check full proper paths
        # WARNING: Don't actually use full paths.
        if [[ "$newarg_local_full" = /* ]]; then
            : # this should be a full path. `:` means do nothing.
        else
            # Assume excludes may be relative to source dir
            newarg_local_full="$LOCALDIR"/"$newarg_local_full"
        fi
        if [ ! -d "$newarg_local_full" ]; then
            echo "WARNING: Directory to exclude doesn't exist on LOCAL. Passed argument was '"$1"', full path is '"$newarg_local_full"'"
        fi

        newarg_HD=$1
        newarg_HD_full=$1
        if [[ "$newarg_HD_full" = /* ]]; then
            : # this should be a full path. `:` means do nothing.
        else
            newarg_HD_full="$HDDIR"/"$newarg_HD_full"
        fi
        if [ ! -d "$newarg_HD_full" ]; then
            echo "WARNING: Directory to exclude doesn't exist on HD. Passed argument was '"$1"', full path is '"$newarg_HD_full"'"
        fi


        excludestr_rsync_local="$excludestr_rsync_local ""--exclude=$newarg_local/**"" --exclude=$newarg_local "
        excludestr_rsync_HD="$excludestr_rsync_HD ""--exclude=$newarg_HD/**"" --exclude=$newarg_HD "
        shift
    done

    DATE=`date +%F_%Hh%M` # current time
    mkdir -p logs

    RSYNC_CMD="rsync    --archive \
                        --verbose \
                        --human-readable \
                        --progress \
                        --stats \
                        --update \
                        --recursive \
                        "

    RSYNC_CMD_DELETE_FIRST="rsync   --archive \
                                    --verbose \
                                    --human-readable \
                                    --progress \
                                    --stats \
                                    --update \
                                    --recursive \
                                    --delete \
                                    "

    RSYNC_CMD_DELETE_FIRST_DRY_RUN="rsync   --archive \
                                            --human-readable \
                                            --recursive \
                                            --verbose \
                                            --stats \
                                            --update \
                                            --delete \
                                            --dry-run \
                                            "


    RSYNC_CMD_DEFAULT_EXCLUDES="
                        --exclude=**/*tmp*/ \
                        --exclude=**/*cache*/ \
                        --exclude=**/*Cache*/ \
                        --exclude=**~ \
                        --exclude=**/lost+found*/ \
                        --exclude=**/*Trash*/ \
                        --exclude=**/*trash*/ \
                        --exclude=**/.gvfs/ "

    RSYNC_CMD=${RSYNC_CMD}${RSYNC_CMD_DEFAULT_EXCLUDES}
    RSYNC_CMD_DELETE_FIRST=${RSYNC_CMD_DELETE_FIRST}${RSYNC_CMD_DEFAULT_EXCLUDES}


    if [ "$OVERWRITE_LOCAL" == "yes" ]; then
        echo "==================================================================================="
        echo "OVERWRITING" $LOCALDIR " with "  $HDDIR
        echo "==================================================================================="
        $RSYNC_CMD_DELETE_FIRST_DRY_RUN $excludestr_rsync_local "$HDDIR"/ "$LOCALDIR"
        while true; do
            read -p "That was a dry run. This will overwrite your LOCAL MACHINE STATE. Do you wish to continue? (y/n) " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) echo "exiting."; return;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        $RSYNC_CMD_DELETE_FIRST $excludestr_rsync_local --log-file=logs/rsync-HD2L-overwrite-"$DATE"".log" "$HDDIR"/ "$LOCALDIR"


    elif [ "$OVERWRITE_HD" == "yes" ]; then

        echo "==================================================================================="
        echo "OVERWRITING" $HDDIR " with "  $LOCALDIR
        echo "==================================================================================="
        $RSYNC_CMD_DELETE_FIRST_DRY_RUN $excludestr_rsync_local "$LOCALDIR"/ "$HDDIR"
        while true; do
            read -p "That was a dry run. This will overwrite your HD STATE. Do you wish to continue? (y/n) " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) echo "exiting."; return;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        $RSYNC_CMD_DELETE_FIRST $excludestr_rsync_local --log-file=logs/rsync-L2HD-overwrite-"$DATE"".log" "$LOCALDIR"/ "$HDDIR"

    else
        echo "SYNCING"
        echo $OVERWRITE_HD
        echo $OVERWRITE_LOCAL

        # Sync LOCAL to HD
        echo "==================================================================================="
        echo "TRANSFERING" $LOCALDIR " --> "  $HDDIR
        echo "==================================================================================="
        # $RSYNC_CMD $excludestr_rsync_local --log-file=logs/rsync-L2HD-"$DATE"".log" "$LOCALDIR"/ "$HDDIR"
        # Sync HD to LOCAL
        echo "==================================================================================="
        echo "TRANSFERING" $HDDIR " --> "  $LOCALDIR
        echo "==================================================================================="
        # $RSYNC_CMD $excludestr_rsync_HD --log-file=logs/rsync-HD2L-"$DATE"".log" "$HDDIR"/ "$LOCALDIR"
    fi


}



find_HD_path
# note: everything past the 2nd arg is to be excluded
sync_dir $HOME/Work Work
# sync_dir $HOME/Documents/Bewerbungen Documents/Bewerbungen
sync_dir $HOME/Zotero Zotero

if [ ${INCLUDE_PRIVATE} = "yes" ]; then
    sync_dir $HOME/Pictures/Memories Pictures/Memories videos childhood Pre-2018 2018 2019 2020 2021 2022
    sync_dir $HOME/Documents/Wichtige_Dokumente Documents/Wichtige_Dokumente
fi


echo DONE.


exit 0
