#!/bin/bash

##############################################
#
# Script to back up files to external HD.
#
##############################################


#---------------------------------------------------------------------------------
#
# usage:
#   $backup_extHD.sh          backs up all directories hardcoded in this script
#   $backup_extHD.sh <dir>    backs up only given directory, if it is part of
#                             hardcoded directories
#
#---------------------------------------------------------------------------------



ROOT_BACKUP_DIR=$HOME                        # Root dir to backup
DATE=`date +%F_%Hh%M`                        # current time
BACKUP_DIR=/run/media/mivkov/BACKUP_LENOVO/  # where to store the backup

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Din't find target dir" $BACKUP_DIR
    exit 1
fi


EXCLUDES="" # Define parent directories that are to be excluded here
EXCLUDES="$EXCLUDES Audiobooks"
EXCLUDES="$EXCLUDES Dropbox"
EXCLUDES="$EXCLUDES Podcasts"
EXCLUDES="$EXCLUDES Downloads"
EXCLUDES="$EXCLUDES Encfs"
EXCLUDES="$EXCLUDES texmf"
EXCLUDES="$EXCLUDES .dbus"

# generate exclusion string for rsync
excludestr_rsync=""
for EX in $EXCLUDES; do
    excludestr_rsync="$excludestr_rsync ""--exclude=$EX/**"" --exclude=$EX "
done

# echo "|"$EXCLUDES"|"
# echo
# echo $excludestr_rsync
# exit



# get and prepare cmdline args
if [ $# = 0 ]; then
    echo "Doing full backup."
    do_full=true
    DIR_TO_BACKUP="$ROOT_BACKUP_DIR"
elif [ $# == 1 ]; then
    do_full=false
    dir_given=$1
    DIR_TO_BACKUP=`realpath $dir_given`
    if [ ! -d $DIR_TO_BACKUP ]; then
        echo "Didn't find directory you've provided: '"$dir_given"'"
        exit 1
    else
        echo "Doing partial backup of" "$dir_given"
    fi
else
    echo "Too many cmdline args. I only accept 1 (specific dir to backup) or none (do full backup)"
    exit 1
fi


# if partial backup:
if [[ "$do_full" = false ]]; then

    # first check that it's within ROOT_BACKUP_DIR
    if [[ ! "$DIR_TO_BACKUP" = "$ROOT_BACKUP_DIR"* ]]; then
        echo "$dir_given" is not in the root backup directory $ROOT_BACKUP_DIR
        exit 1
    else
        echo "Continuing partial backup, is in root dir"
    fi

    # then check that it's not in an excluded dir
    for EX in $EXCLUDES; do
        if [[ "$DIR_TO_BACKUP" = "$EX"* ]]; then
            echo "$dir_given" is in an excluded backup directory: $EX
            exit 1
        fi
    done
    echo "Continuing partial backup, not in excludes"


    # now add the additional path of the directory to BACKUP_DIR
    parent_root_dir="$(dirname $ROOT_BACKUP_DIR)"
    parent_dir_to_backup="$(dirname $DIR_TO_BACKUP)"
    BACKUP_DIR="$BACKUP_DIR"/"${parent_dir_to_backup#$parent_root_dir}"
    mkdir -p "$BACKUP_DIR"
    # example:
    #   initially:
    #   BACKUP_DIR = /media/mivkov/backup
    #   DIR_TO_BACKUP = /home/mivkov/xkcd/oglaf/ToG
    #
    #   change into:
    #   parent_root_dir = /home
    #   parent_dir_to_backup = /home/mivkov/xkcd/oglaf
    #   BACKUP_DIR += /mivkov/xkcd

fi



echo "---Backup started---"


# =====================================
# Private files
# =====================================

echo "$DIR_TO_BACKUP"

rsync   --archive \
        --verbose \
        --human-readable \
        --progress \
        --stats \
        --update \
        --recursive \
        --delete \
        --exclude=/mnt/*/** \
        --exclude=/media/*/** \
        --exclude=**/lost+found*/ \
        --exclude=**/.gvfs/ \
        $excludestr_rsync \
        --log-file=rsync-backup-LENOVO-FULL-"$DATE"".log" \
        "$DIR_TO_BACKUP" "$BACKUP_DIR"
        # covered by --archive
        #   --recursive \
        #   --times \
        #   --devices \
        #   --specials \
        #   --links \
        #   --perms \

        # --delete-excluded \

echo "---Backup ended---"
exit 0
