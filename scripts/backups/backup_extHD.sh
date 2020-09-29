#!/bin/bash

####################################
#
# Backup to ext HD script.
#
####################################

# tee all output to log file
set -o errexit
day=$(date +%Y-%m-%d-%H-%M)
readonly LOG_FILE=./$day.log
touch $LOG_FILE
exec &> >( tee $LOG_FILE )
exec 2>&1

# What to backup. 
backup_files="$HOME/.*"\ 
backup_files="$backup_files ""$HOME/'Calibre Library'"
backup_files="$backup_files ""$HOME/coding"
backup_files="$backup_files ""$HOME/Desktop"
backup_files="$backup_files ""$HOME/Documents"
backup_files="$backup_files ""$HOME/EPFL"
backup_files="$backup_files ""$HOME/local"
backup_files="$backup_files ""$HOME/Music"
backup_files="$backup_files ""$HOME/Pictures"
backup_files="$backup_files ""$HOME/scripts"
backup_files="$backup_files ""$HOME/simulation_archive"
backup_files="$backup_files ""$HOME/UZH"
backup_files="$backup_files ""$HOME/virtualenv"
backup_files="$backup_files ""$HOME/Zotero"


# Where to backup to.
dest="/media/mivkov/BACKUP_LENOVO/tar-archives"

# Create archive filename.
day=$(date +%Y-%m-%d-%H-%M)
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Print start status message.
echo "Backing up $backup_files to $dest/$archive_file"
date
echo

# Backup the files using tar.
tar czf $dest/$archive_file $backup_files

# Print end status message.
echo
echo "Backup finished"
date
