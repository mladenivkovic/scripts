#!/bin/bash
# Script to back up files to external HD.
# EMERGENCY: meant for small backup at home.


export DATE=`date +%F_%Hh%M`
export BACKUP_MEDIA=/media/mivkov/BACKUP_LENOVO
export BACKUP_DIR=$BACKUP_MEDIA/mivkov #Directory where the backup shall be saved
export DIR_TO_BACKUP=/home/mivkov #Parent directory to be backed up

dirs_to_backup="$HOME/local $HOME/coding $HOME/Documents $HOME/Desktop $HOME/EPFL $HOME/Pictures/Memories $HOME/scripts $HOME/Encfs/.Private-backup $HOME/'Calibre Library' $HOME/UZH $HOME/Zotero"

echo "---Backup started---"

#Private files

for dir in $dirs_to_backup; do
    echo "====================================="
    echo working for $dir
    echo "====================================="
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


echo "====================================="
echo "--- Backing up repos and software ---"
echo "====================================="
sudo aptik --scripted \
    --backup-all \
    --skip-users --skip-groups --skip-mounts --skip-home \
    --basepath $BACKUP_MEDIA/aptik-backup




echo "---Backup ended---"
exit
