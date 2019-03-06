#!/bin/bash
#Script to back up files to external HD.


export DATE=`date +%F_%Hh%M`
export BACKUP_DIR=/media/mivkov/BACKUP_LENOVO/ #Directory where the backup shall be saved
export BACKUP_DIR_ROOT=/media/mivkov/BACKUP_LENOVO/root_backup #directory where root files shall be saved
export DIR_TO_BACKUP=/home/mivkov #Parent directory to be backed up

echo "---Backup started---"

echo "====================================="
echo "Started backup private files"
echo "====================================="
#Private files

rsync -a -h --progress --stats  -r -t -D -l \
    --update --delete-before --delete-excluded \
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
    --exclude=/mivkov/Downloads/**  \
    --exclude=/mivkov/Dropbox/**  \
    --exclude=/mivkov/google-drive/**  \
    --log-file=logs/rsync-backup-private-"$DATE"".log" \
    $DIR_TO_BACKUP $BACKUP_DIR 


echo "====================================="
echo "Started backup root files"
echo "====================================="
# backup /etc
rsync -h --progress --stats -r -t -l -D \
    --super --update --delete-before --delete-excluded \
    --exclude=**/*tmp*/ \
    --exclude=**/*cache*/ \
    --exclude=**/*Cache*/ \
    --exclude=**~ \
    --exclude=**/*Trash*/ \
    --exclude=**/*trash*/ \
    --log-file=logs/rsync-backup-etc-"$DATE".log \
    /etc $BACKUP_DIR_ROOT


echo "---Backup ended---"
exit 0
