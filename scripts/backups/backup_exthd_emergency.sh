#!/bin/bash
#Script to back up files to external HD.


export DATE=`date +%F_%Hh%M`
export BACKUP_DIR=/media/mivkov/Mladen/emergency_backup #Directory where the backup shall be saved
export DIR_TO_BACKUP=/home/mivkov #Parent directory to be backed up

dirs_to_backup="$HOME/local $HOME/coding $HOME/Documents $HOME/Desktop $HOME/EPFL $HOME/Pictures/Memories $HOME/scripts $HOME/Encfs/.Private-backup"

echo "---Backup started---"

echo "====================================="
echo "Started backup private files"
echo "====================================="
#Private files

for dir in $dirs_to_backup; do
    echo working for $dir
    rsync -a -h --progress --stats  -r -t -D -l \
        --update --delete-before --delete-excluded \
        --exclude=**/*tmp*/ \
        --exclude=**/*cache*/ \
        --exclude=**/*Cache*/ \
        --exclude=**~ \
        --exclude=**/*Trash*/ \
        --exclude=**/*trash*/ \
        --log-file=logs/rsync-backup-private-"$DATE"".log" \
        $dir $BACKUP_DIR 
done


echo "---Backup ended---"
exit 0
