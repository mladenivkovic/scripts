#!/bin/bash

##############################################
#
# Script to back up files to external HD.
#
##############################################


ERRMSG='
backup_extHD-HP.sh - back up your data to external HD.
                     Backs up all directories hardcoded in this script.

usage:
  backup_extHD-HP.sh [dir] [-h] [-m]

  [dir]         if provided, backs up only given directory, if it is part of
                hardcoded directories
  -h, --help    show this message and exit.
  -m, --minimal only do minimal backup (only very selected, hardcoded dirs)
'



ROOT_BACKUP_FROM_DIR=$HOME               # Root dir to backup
DATE=`date +%F_%Hh%M`                    # current time
BACKUP_TO_DIR=/home/mivkov/Encfs/BACKUP_HP/  # where to store the backup
HOMEDIR_BASENAME=`basename $HOME`


# Handle cmdline args.
# --------------------

MINIMAL="false"
BACKUP_FROM_DIR="#none"

while [[ $# > 0 ]]; do
  ARG="$1"

  case $ARG in
    -h | --help)
      echo "$ERRMSG"
      exit
    ;;

    -m | --minimal)
      MINIMAL="true"
    ;;

    *)
      BACKUP_FROM_DIR=`realpath $ARG`
      if [ ! -d "$BACKUP_FROM_DIR" ]; then
        echo "Error: Didn't find directory " $BACKUP_FROM_DIR
      fi
    ;;

  esac

  shift
done



if [ ! -d "$BACKUP_TO_DIR"/$HOMEDIR_BASENAME ]; then
  echo "Din't find target dir '"$BACKUP_TO_DIR/$HOMEDIR_BASENAME"', trying second option"

  # try the second HDD
  found_dir="false"
  BACKUP_TO_DIR=/home/mivkov/Encfs/BACKUP_HP_HOME/  # where to store the backup
  if [ ! -d "$BACKUP_TO_DIR/$HOMEDIR_BASENAME" ]; then
    echo "Din't find target dir '"$BACKUP_TO_DIR/$HOMEDIR_BASENAME"', trying third option"
  else
    found_dir="true"
  fi

  if [[ "$found_dir" == "false" ]]; then
    # try the third HDD
    BACKUP_TO_DIR=/home/mivkov/Encfs/BACKUP_HP_WORK/  # where to store the backup
    if [ ! -d "$BACKUP_TO_DIR/$HOMEDIR_BASENAME" ]; then
      echo "Din't find target dir '"$BACKUP_TO_DIR/$HOMEDIR_BASENAME"', trying fourth option"
    else
      found_dir="true"
    fi
  fi

  if [[ "$found_dir" == "false" ]]; then
    # try the fourth HDD
    BACKUP_TO_DIR=/home/mivkov/Encfs/BACKUP_HP_DAVOS/  # where to store the backup
    if [ ! -d "$BACKUP_TO_DIR/$HOMEDIR_BASENAME" ]; then
      echo "Din't find target dir '"$BACKUP_TO_DIR/$HOMEDIR_BASENAME"', exiting"
      echo "Did you remember to mount the encrypted drives?"
      exit 1
    fi
  fi

fi

echo Writing backup to $BACKUP_TO_DIR


EXCLUDEDIRS="" # Define parent directories that are to be excluded here
EXCLUDEDIRS="$EXCLUDEDIRS Audiobooks"
EXCLUDEDIRS="$EXCLUDEDIRS Downloads"
EXCLUDEDIRS="$EXCLUDEDIRS Dropbox"
EXCLUDEDIRS="$EXCLUDEDIRS dwhelper"
EXCLUDEDIRS="$EXCLUDEDIRS Encfs"
EXCLUDEDIRS="$EXCLUDEDIRS google-drive"
EXCLUDEDIRS="$EXCLUDEDIRS Music"
EXCLUDEDIRS="$EXCLUDEDIRS Podcasts"
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


# indended usage: $rsync_cmd "$BACKUP_FROM_DIR" "$BACKUP_TO_DIR"
rsync_cmd=rsync
rsync_cmd+=" --archive --verbose --human-readable --progress --stats"
rsync_cmd+=" --update --recursive --delete --exclude=**/*tmp*/ --exclude=**/*cache*/"
rsync_cmd+=" --exclude=**/*Cache*/ --exclude=**~ --exclude=/mnt/*/** --exclude=/media/*/**"
rsync_cmd+=" --exclude=**/lost+found*/ --exclude=**/*Trash*/ --exclude=**/*trash*/"
rsync_cmd+=" --exclude=**/.gvfs/ --log-file=rsync-backup-HP-""$DATE"".log"
rsync_cmd+=" ""$excludestr_rsync"
  # covered by --archive
  #   --recursive \
  #   --times \
  #   --devices \
  #   --specials \
  #   --links \
  #   --perms \

  # --delete-excluded \


# if we're doing only a single dir backup:
if [[ "$BACKUP_FROM_DIR" != "#none" ]]; then

  # first check that it's within ROOT_BACKUP_FROM_DIR
  if [[ ! "$BACKUP_FROM_DIR" = "$ROOT_BACKUP_FROM_DIR"* ]]; then
    echo "$BACKUP_FROM_DIR" is not in the root backup directory $ROOT_BACKUP_FROM_DIR
    exit 1
  fi

  # then check that it's not in an excluded dir
  for EX in $EXCLUDES; do
    if [[ "$BACKUP_FROM_DIR" = "$EX"* ]]; then
      echo "$BACKUP_FROM_DIR" is in an excluded backup directory: $EX
      exit 1
    fi
  done

  # now add the additional path of the directory to BACKUP_TO_DIR
  parent_root_dir="$(dirname $ROOT_BACKUP_FROM_DIR)"
  parent_dir_to_backup="$(dirname $BACKUP_FROM_DIR)"
  BACKUP_TO_DIR="$BACKUP_TO_DIR"/"${parent_dir_to_backup#$parent_root_dir}"
  mkdir -p "$BACKUP_TO_DIR"
  # example:
  #   initially:
  #   BACKUP_TO_DIR = /media/mivkov/backup
  #   BACKUP_FROM_DIR = /home/mivkov/xkcd/ksbd/ToG
  #
  #   change into:
  #   parent_root_dir = /home
  #   parent_dir_to_backup = /home/mivkov/xkcd/ksbd
  #   BACKUP_TO_DIR += /mivkov/xkcd

  echo "---Backing up single dir '$BACKUP_FROM_DIR'---"
  $rsync_cmd "$BACKUP_FROM_DIR" "$BACKUP_TO_DIR"
  echo "---Single dir backup ended---"

  exit
fi


MINIMAL_ROOT_DIRS=" $HOME/Documents "
MINIMAL_ROOT_DIRS+=" $HOME/Durham "
MINIMAL_ROOT_DIRS+=" $HOME/EPFL "
MINIMAL_ROOT_DIRS+=" $HOME/Pictures "
# MINIMAL_ROOT_DIRS+=" $HOME/Work "


# if we're doing a "minimal" backup:
if [[ "$MINIMAL" = "true" ]]; then

  echo "---Starting minimal backup---"

  for DIR in $MINIMAL_ROOT_DIRS; do

    BACKUP_FROM_DIR=`realpath $DIR`

    # first check that it's within ROOT_BACKUP_FROM_DIR
    if [[ ! "$DIR" = "$ROOT_BACKUP_FROM_DIR"* ]]; then
      echo "$BACKUP_FROM_DIR" is not in the root backup directory $ROOT_BACKUP_FROM_DIR
      exit 1
    fi

    # then check that it's not in an excluded dir
    for EX in $EXCLUDES; do
      if [[ "$BACKUP_FROM_DIR" = "$EX"* ]]; then
        echo "$BACKUP_FROM_DIR" is in an excluded backup directory: $EX
        exit 1
      fi
    done

    # now add the additional path of the directory to BACKUP_TO_DIR
    parent_root_dir="$(dirname $ROOT_BACKUP_FROM_DIR)"
    parent_dir_to_backup="$(dirname $BACKUP_FROM_DIR)"
    BACKUP_TO_DIR="$BACKUP_TO_DIR"/"${parent_dir_to_backup#$parent_root_dir}"
    mkdir -p "$BACKUP_TO_DIR"
    # example:
    #   initially:
    #   BACKUP_TO_DIR = /media/mivkov/backup
    #   BACKUP_FROM_DIR = /home/mivkov/xkcd/ksbd/ToG
    #
    #   change into:
    #   parent_root_dir = /home
    #   parent_dir_to_backup = /home/mivkov/xkcd/ksbd
    #   BACKUP_TO_DIR += /mivkov/xkcd

    echo "---Minimal backup: backing '$BACKUP_FROM_DIR'---"
    $rsync_cmd "$BACKUP_FROM_DIR" "$BACKUP_TO_DIR" --log-file=rsync-backup-HP-"$DATE"-"$DIR".log

  done
  echo "---Minimal backup ended---"
  exit 0

fi


# get and prepare cmdline args
# if [ $# = 0 ]; then
#   echo "Doing full backup."
#   do_full=true
#   BACKUP_FROM_DIR="$ROOT_BACKUP_FROM_DIR"
# elif [ $# == 1 ]; then
#   do_full=false
#   dir_given=$1
#   BACKUP_FROM_DIR=`realpath $dir_given`
#   if [ ! -d $DIR_TO_BACKUP ]; then
#       echo "Didn't find directory you've provided: '"$dir_given"'"
#       exit 1
#   else
#       echo "Doing partial backup of" "$dir_given"
#     fi
# else
#     echo "Too many cmdline args. I only accept 1 (specific dir to backup) or none (do full backup)"
#     exit 1
# fi


# Doing full backup, then
BACKUP_FROM_DIR="$ROOT_BACKUP_FROM_DIR"

echo "---Starting full backup---"
$rsync_cmd "$BACKUP_FROM_DIR" "$BACKUP_TO_DIR"
echo "---Full backup ended---"
exit 0
