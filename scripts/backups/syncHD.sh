#!/bin/bash

##############################################
#
# Script to sync up files to external HD.
# Syncs up back-and-forth between stuff on the HD,
# and stuff on the local machine.
#
##############################################


#---------------------------------------------------------------------------------
#
# usage:
#   $syncHD.sh          backs up all directories hardcoded in this script
#
#---------------------------------------------------------------------------------




#------------------------------------------------------------------------
# Determine which hard drive to sync with.
# Choices are hardcoded in here.
# TODO: Make sure this fails and exits if no HDPATH is found.
# Otherwise, the subsequent rsync calls are going to do stupid things.
#------------------------------------------------------------------------
find_HD_path(){
    HDPATH='/media/mivkov/WD free/'

    if [ ! -d "$HDPATH" ]; then
        echo "Din't find target dir" $DESTDIR "trying second option"
        HDPATH='/media/mivkov/archive/'
        if [ ! -d "$HDPATH" ]; then
            echo "Din't find target dir" $DESTDIR 
            exit 1
        fi
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
    # RUn it twice in case someone has stupid ideas.
    
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
                        --exclude=**/*tmp*/ \
                        --exclude=**/*cache*/ \
                        --exclude=**/*Cache*/ \
                        --exclude=**~ \
                        --exclude=**/lost+found*/ \
                        --exclude=**/*Trash*/ \
                        --exclude=**/*trash*/ \
                        --exclude=**/.gvfs/ "


    # Sync LOCAL to HD
    echo "==================================================================================="
    echo "TRANSFERING" $LOCALDIR " --> "  $HDDIR
    echo "==================================================================================="
    $RSYNC_CMD $excludestr_rsync_local --log-file=logs/rsync-L2HD-"$DATE"".log" "$LOCALDIR"/ "$HDDIR"
    # Sync HD to LOCAL
    echo "==================================================================================="
    echo "TRANSFERING" $HDDIR " --> "  $LOCALDIR
    echo "==================================================================================="
    $RSYNC_CMD $excludestr_rsync_HD --log-file=logs/rsync-HD2L-"$DATE"".log" "$HDDIR"/ "$LOCALDIR"


}







find_HD_path
sync_dir $HOME/Work Work
sync_dir $HOME/Pictures/Memories Pictures/Memories videos childhood Pre-2018 2018 2019 2020 2021 2022
sync_dir $HOME/Documents/Bewerbungen Documents/Bewerbungen
sync_dir $HOME/Documents/Wichtige_Dokumente Documents/Wichtige_Dokumente


echo DONE.


exit 0
