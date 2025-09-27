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
    $ syncHD.sh [dirflags]           backs up all directories hardcoded in this script,
                                     unless [dirflags] specifies which directires to sync.
                                     See documentation of [dirflags] below

    $ syncHD.sh  -h                  show this message and quit
                 --help

    $ syncHD.sh  -owl [dirflags]     Don't syncronize to and from the HD backups, but
                 --overwrite-local   forcibly overwrite LOCAL STATE with what's on the HD

    $ syncHD.sh  -owh [dirflags]     Don't syncronize to and from the HD backups, but
                 --overwrite-hd      forcibly overwrite HD STATE with what's on the local
                                     machine

    dirflags: make (selection of) directories to sync:

    -a, --all                        Sync all (hardcoded) dirs
    -w, --work                       Sync (all) work dirs
    -p, --personal                   Sync (all) private dirs
    --docs                           Sync private documents
    --pics, --pictures               Sync pictures
    --ao3                            Sync ao3 stuff
    --workdocs                       Sync work documents
    --zotero                         Sync zotero dir
    --calibre                        Sync calibre dir

    --docs-archive      Sync archive document dirs (not included in -w, -a, -p flags)
    --work-archive      Sync work archive dirs (not included in -w, -a, -p flags)
    --mail-archive      Sync mail archive dirs (not included in -w, -a, -p flags)
"




#------------------------------------------------------------------------
# Synchronize a single directory (recursively) back and forth between
# the HD and local machine.
#
# Usage:
#   sync_dir LOCALDIR HDDIR [--exclude=dir1, --exclude=dir2, ...]
#
# LOCALDIR :       directory on your local machine
# HDDIR :          directory on your HD
# --exclude=dir :  optional strings to add to the rsync call to exclude
#                  whatever you want excluded. The paths may be relative
#                  to LOCALDIR and HDDIR.
#------------------------------------------------------------------------
sync_dir() {


    if [ -z ${HDPATH+x} ]; then
        echo "Didn't find HDPATH variable."
        echo 'Needs to be set before this command is called.'
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

        ARG="$1"

        case "$ARG" in

            "--exclude="* )
                : # ':' means do nothing
            ;;

            *)
                "sync_dir(): Unrecognized argument '""$ARG""'"
            exit 1

        esac


        # check full proper paths
        # WARNING: Don't actually use full paths.
        newarg_local="${ARG#--exclude=}"
        newarg_local_full="$newarg_local"
        if [[ "$newarg_local_full" = /* ]]; then
            : # this should be a full path. `:` means do nothing.
        else
            # Assume excludes may be relative to source dir
            newarg_local_full="$LOCALDIR"/"$newarg_local_full"
        fi
        if [ ! -d "$newarg_local_full" ]; then
            echo "WARNING: Directory to exclude doesn't exist on LOCAL. Passed argument was '"$1"', full path is '"$newarg_local_full"'"
        fi

        newarg_HD="${ARG#--exclude=}"
        newarg_HD_full="$newarg_local"
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
    fi


}










#-----------------------------------------------------------------------
# First, let's read the cmdline args.
#-----------------------------------------------------------------------

OVERWRITE_LOCAL="no"
OVERWRITE_HD="no"

ALL="true"
WORK="false"
PERSONAL="false"
PERSONAL_DOCS="false"
PICTURES="false"
AO3="false"
WORKDOCS="false"
ZOTERO="false"
CALIBRE="false"
WORK_ARCHIVE="false"
MAIL_ARCHIVE="false"
DOCS_ARCHIVE="false"



while [[ $# > 0 ]]; do
    ARG="$1"

    case "$ARG" in

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

        -a | --all)
            ALL="true"
        ;;

        -w | --work)
            WORK="true"
            ALL="false"
        ;;

        -p | --personal)
            PERSONAL="true"
            ALL="false"
        ;;

        --docs)
            PERSONAL_DOCS="true"
            ALL="false"
        ;;

        --pics | --pictures)
            PICTURES="true"
            ALL="false"
        ;;

        --ao3)
            AO3="true"
            ALL="false"
        ;;

        --workdocs)
            WORKDOCS="true"
            ALL="false"
        ;;

        --zotero)
            ZOTERO="true"
            ALL="false"
        ;;

        --calibre)
            CALIBRE="true"
            ALL="false"
        ;;

        --work-archive)
            WORK_ARCHIVE="true"
            ALL="false"
        ;;

        --mail-archive)
            MAIL_ARCHIVE="true"
            ALL="false"
        ;;

        --docs-archive)
            DOCS_ARCHIVE="true"
            ALL="false"
        ;;


        * )
        echo "Unknown cmdline arg '"$ARG"'"
        echo
        echo $errmsg
        exit
        ;;

    esac

    shift
done


# --------------------
# Check for hostname.
# --------------------
HOST=`hostname`
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"
HOSTNAME_HP_PROBOOK="mivkov-hpprobook"

DO_LENOVO_THINKPAD="false"
DO_HP_PROBOOK="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD )
    DO_LENOVO_THINKPAD="true"
  ;;
  $HOSTNAME_HP_PROBOOK )
    DO_HP_PROBOOK="true"
  ;;
  *)
    echo "Unrecognized hostname. Adapt script before you break things."
    echo "hostname=$HOST"
    exit 1
  ;;
esac




#------------------------------------------------------------------------
# Determine which hard drive to sync with.
# Choices are hardcoded in here.
# TODO: Make sure this fails and exits if no HDPATH is found.
# Otherwise, the subsequent rsync calls are going to do stupid things.
#
# @Mladen: Note that this sync doesn't require encrypted drives.
#------------------------------------------------------------------------
HOMEDIR_BASENAME=`basename $HOME`
HDPATH="/run/media/$HOMEDIR_BASENAME/WD free/"
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








# --------------------------
# Do the actual work
# --------------------------


# note: everything past the 2nd arg is to be excluded
if [[ "$WORK" == "true" || "$ALL" == "true" ]]; then
    sync_dir $HOME/Work sync/Work
    sync_dir $HOME/Zotero sync/Zotero
    sync_dir $HOME/calibre_library sync/calibre_library
else
    if [[ "$WORKDOCS" == "true" ]]; then
        sync_dir $HOME/Work sync/Work
    fi
    if [[ "$ZOTERO" == "true" ]]; then
        sync_dir $HOME/Zotero sync/Zotero
    fi
    if [[ "$CALIBRE" == "true" ]]; then
        sync_dir $HOME/calibre_library sync/calibre_library
    fi
fi


# $INCLUDE_PRIVATE is determined by whether we're syncing to "home" HD or "work" HD
if [[ "$INCLUDE_PRIVATE" = "yes" ]]; then

    # $PERSONAL determines whether we're syncing personal files.
    if [[ "$PERSONAL" == "true" || "$ALL" == "true" ]]; then

        if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then

            sync_dir $HOME/Pictures/profile_pics sync/Pictures/profile_pics
            sync_dir $HOME/Pictures/Memories/videos sync/Pictures/Memories/videos
            sync_dir $HOME/Pictures/Memories/childhood sync/Pictures/Memories/childhood
            sync_dir $HOME/Pictures/Memories/Pre-2018 sync/Pictures/Memories/Pre-2018
            sync_dir $HOME/Pictures/Memories/2018 sync/Pictures/Memories/2018
            sync_dir $HOME/Pictures/Memories/2019 sync/Pictures/Memories/2019
            sync_dir $HOME/Pictures/Memories/2020 sync/Pictures/Memories/2020
            # sync_dir $HOME/Pictures/Memories/2021 sync/Pictures/Memories/2021 # does not exist...
            sync_dir $HOME/Pictures/Memories/2022 sync/Pictures/Memories/2022
            sync_dir $HOME/Pictures/Memories/2023 sync/Pictures/Memories/2023

        fi

        sync_dir $HOME/Pictures/Memories/2024 sync/Pictures/Memories/2024
        sync_dir $HOME/Pictures/Memories/2025 sync/Pictures/Memories/2025

        sync_dir $HOME/Documents/important sync/Documents/important
        sync_dir $HOME/.ao3statscraper sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml

    else
        # see if we're syncing spcific dirs then


        if [[ "$PICTURES" == "true" ]]; then
            if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
                sync_dir $HOME/Pictures/profile_pics sync/Pictures/profile_pics
                sync_dir $HOME/Pictures/Memories/videos sync/Pictures/Memories/videos
                sync_dir $HOME/Pictures/Memories/childhood sync/Pictures/Memories/childhood
                sync_dir $HOME/Pictures/Memories/Pre-2018 sync/Pictures/Memories/Pre-2018
                sync_dir $HOME/Pictures/Memories/2018 sync/Pictures/Memories/2018
                sync_dir $HOME/Pictures/Memories/2019 sync/Pictures/Memories/2019
                sync_dir $HOME/Pictures/Memories/2020 sync/Pictures/Memories/2020
                # sync_dir $HOME/Pictures/Memories/2021 sync/Pictures/Memories/2021 # does not exist...
                sync_dir $HOME/Pictures/Memories/2022 sync/Pictures/Memories/2022
                sync_dir $HOME/Pictures/Memories/2023 sync/Pictures/Memories/2023
            fi

            sync_dir $HOME/Pictures/Memories/2024 Pictures/Memories/2024
            sync_dir $HOME/Pictures/Memories/2025 Pictures/Memories/2025

        fi


        if [[ "$PERSONAL_DOCS" == "true" ]]; then
            sync_dir $HOME/Documents/important sync/Documents/important
        fi

        if [[ "$AO3" == "true" ]]; then
            sync_dir $HOME/.ao3statscraper sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
        fi

    fi # syncing personal documents

fi # syncinc to home HD



if [[ "$WORK_ARCHIVE" == "true" ]]; then

    if [[ "$DO_HP_PROBOOK" == "true" ]]; then
        echo "Are you sure you're on the right machine???"
        exit
    fi

    sync_dir $HOME/Documents/archive_work sync/archives/archive_work
fi


if [[ "$DOCS_ARCHIVE" == "true" ]]; then

    if [[ "$DO_HP_PROBOOK" == "true" ]]; then
        echo "Are you sure you're on the right machine???"
        exit
    fi

    sync_dir $HOME/Documents/archive_docs sync/archives/archive_docs

fi


if [[ "$MAIL_ARCHIVE" == "true" ]]; then

    if [[ "$DO_HP_PROBOOK" == "true" ]]; then
        echo "Are you sure you're on the right machine???"
        exit
    fi

    sync_dir $HOME/Documents/archive_mail sync/archives/archive_mail

fi




echo DONE.


exit 0
