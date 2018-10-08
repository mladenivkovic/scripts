#!/bin/bash

#========================================
# Script to back up files to internal HD.
#========================================





#--------------------
# mount internal HDD. 
#--------------------

# First make it mountable by user in /etc/fstab.
mount /dev/sda4 >> /dev/null 2>&1
dest='/media/mivkov/internal_backup/'


export DATE=`date +%F_%Hh%M`




echo "---Backup started---"

#--------------------------
# backup personal files
#--------------------------

echo "====================================="
echo "Started backup private files"
echo "====================================="
rsync -h --progress --stats -r -t --modify-window=1 -l -D --super --update \
    --delete-after --delete-excluded --ignore-errors \
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
    --exclude=/home/mivkov/Downloads \
    --exclude=/mivkov/Downloads/** \
    --log-file=/home/mivkov/Skripte/Backup_IntHD/Logs/rsync-backup-"$DATE"-private.log \
    /home/mivkov "$dest"/home





#-------------------
# backup /etc
#-------------------
echo ""
echo "====================================="
echo "Started backup root files"
echo "====================================="
rsync -h --progress --stats -r -t --modify-window=1 -l -D --super --update \
    --delete-before --delete-excluded --ignore-errors \
    --exclude=**/*tmp*/ \
    --exclude=**/*cache*/ \
    --exclude=**/*Cache*/ \
    --exclude=**~ \
    --exclude=**/*Trash*/ \
    --exclude=**/*trash*/ \
    --log-file=/home/mivkov/Skripte/Backup_IntHD/Logs/rsync-backup-"$DATE"-etc.log \
    /etc "$dest"/root





#---------------------------
# backing up package lists
#---------------------------

#https://wiki.ubuntuusers.de/Paketverwaltung/Tipps/#Paketliste-zur-Wiederherstellung-erzeugen
if [[ -d "$dest"/packagelist ]];
    then cd "$dest"/packagelist;
    else mkdir "$dest"/packagelist;
    cd "$dest"/packagelist;
fi

dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > packages.list.save
apt-mark showauto > package-states-auto
apt-mark showmanual > package-states-manual
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'echo -e "\n## $1 ";grep "^[[:space:]]*[^#[:space:]]" ${1}' _ {} \; > sources.list.save
cp /etc/apt/trusted.gpg trusted-keys.gpg 
cp -R /etc/apt/trusted.gpg.d trusted.gpg.d.save 
cp /etc/apt/auth.conf auth.conf 





#----------------
# Finish
#----------------


umount -l /media/mivkov/internal_backup >> /dev/null 2>&1

echo "---Backup ended---"
exit 0
