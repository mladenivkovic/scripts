#!/bin/bash

#https://wiki.ubuntuusers.de/Paketverwaltung/Tipps/#Paketliste-zur-Wiederherstellung-erzeugen
export DATE=`date +%y%m%d%H%M`
cd /media/mivkov/internal_backup/packagelist

dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > packages.list."$DATE".save
apt-mark showauto > package-states-auto-"$DATE"
apt-mark showmanual > package-states-manual-"$DATE"
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'echo -e "\n## $1 ";grep "^[[:space:]]*[^#[:space:]]" ${1}' _ {} \; > sources.list."$DATE".save
cp /etc/apt/trusted.gpg trusted-keys."$DATE".gpg 
cp -R /etc/apt/trusted.gpg.d trusted.gpg.d."$DATE".save 
cp /etc/apt/auth.conf auth."$DATE".conf 

