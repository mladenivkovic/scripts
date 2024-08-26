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



ROOT_BACKUP_DIR=$HOME                    # Root dir to backup
DATE=`date +%F_%Hh%M`                    # current time
BACKUP_DIR=/home/mivkov/Encfs/BACKUP_HP/  # where to store the backup
HOMEDIR_BASENAME=`basename $HOME`

if [ ! -d "$BACKUP_DIR"/$HOMEDIR_BASENAME ]; then
    echo "Din't find target dir '"$BACKUP_DIR/$HOMEDIR_BASENAME"', trying second option"
    # try the second HDD
    BACKUP_DIR=/home/mivkov/Encfs/BACKUP_HP_HOME/  # where to store the backup
    if [ ! -d "$BACKUP_DIR/$HOMEDIR_BASENAME" ]; then
        echo "Din't find target dir '"$BACKUP_DIR/$HOMEDIR_BASENAME"', exiting"
        echo "Did you remember to mount the encrypted drives?"
        exit 1
    fi
fi


EXCLUDEDIRS="" # Define parent directories that are to be excluded here
EXCLUDEDIRS="$EXCLUDEDIRS Audiobooks"
EXCLUDEDIRS="$EXCLUDEDIRS Downloads"
EXCLUDEDIRS="$EXCLUDEDIRS Dropbox"
EXCLUDEDIRS="$EXCLUDEDIRS dwhelper"
EXCLUDEDIRS="$EXCLUDEDIRS Encfs"
EXCLUDEDIRS="$EXCLUDEDIRS google-drive"
EXCLUDEDIRS="$EXCLUDEDIRS Music"
EXCLUDEDIRS="$EXCLUDEDIRS Podcasts"
# EXCLUDEDIRS="$EXCLUDEDIRS "'Soulseek Chat Logs'
EXCLUDEDIRS="$EXCLUDEDIRS Steam"
EXCLUDEDIRS="$EXCLUDEDIRS Templates"
EXCLUDEDIRS="$EXCLUDEDIRS texmf"
EXCLUDEDIRS="$EXCLUDEDIRS Videos"
EXCLUDEDIRS="$EXCLUDEDIRS .dbus"

EXCLUDEFILES="" # Define file patterns that are to be excluded here
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/celldata/**"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/globaldata/**"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/observers/**"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/repositories/**"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/vertexdata/**"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/*.o"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/*.a"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/**/*.Po"
EXCLUDEFILES="$EXCLUDEFILES **/Peano/doxygen-html/**"
EXCLUDEFILES="$EXCLUDEFILES **/swiftsim/**/*.o"

# generate exclusion string for rsync
excludestr_rsync=""
for EX in $EXCLUDEDIRS; do
    excludestr_rsync="$excludestr_rsync ""--exclude=$EX/**"" --exclude=$EX "
done
for EX in $EXCLUDEFILES; do
    excludestr_rsync="$excludestr_rsync --exclude=$EX "
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
        --exclude=**/*tmp*/ \
        --exclude=**/*cache*/ \
        --exclude=**/*Cache*/ \
        --exclude=**~ \
        --exclude=/mnt/*/** \
        --exclude=/media/*/** \
        --exclude=**/lost+found*/ \
        --exclude=**/*Trash*/ \
        --exclude=**/*trash*/ \
        --exclude=**/.gvfs/ \
        $excludestr_rsync \
        --log-file=rsync-backup-HP-"$DATE"".log" \
        "$DIR_TO_BACKUP" "$BACKUP_DIR"
        # covered by --archive
        #   --recursive \
        #   --times \
        #   --devices \
        #   --specials \
        #   --links \
        #   --perms \

        # --delete-excluded \

# echo "====================================="
# echo "Started backup root files"
# echo "====================================="
# # backup /etc
# rsync -h --progress --stats -r -t -l -D \
#     --super --update --delete-before --delete-excluded \
#     --exclude=**/*tmp*/ \
#     --exclude=**/*cache*/ \
#     --exclude=**/*Cache*/ \
#     --exclude=**~ \
#     --exclude=**/*Trash*/ \
#     --exclude=**/*trash*/ \
#     --log-file=logs/rsync-backup-etc-"$DATE".log \
#     /etc $BACKUP_DIR_ROOT

echo "---Backup ended---"
exit 0
