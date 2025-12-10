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



ROOT_BACKUP_SRC_DIR=$HOME                      # Root dir to backup
DATE=`date +%F_%Hh%M`                          # current time
BACKUP_DEST_DIR=/home/mivkov/Encfs/BACKUP_HP/  # where to store the backup
HOMEDIR_BASENAME=`basename $HOME`


# Handle cmdline args.
# --------------------

MINIMAL="false"
BACKUP_SRC_DIR="#none"

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
      BACKUP_SRC_DIR=`realpath $ARG`
      if [ ! -d "$BACKUP_SRC_DIR" ]; then
        echo "Error: Didn't find directory " $BACKUP_SRC_DIR
      fi
    ;;

  esac

  shift
done


if [ ! -d "$BACKUP_DEST_DIR"/$HOMEDIR_BASENAME ]; then
  echo "Din't find target dir '"$BACKUP_DEST_DIR/$HOMEDIR_BASENAME"', trying second option"
  # echo "Did you remember to mount the encrypted drives?"
  exit 1
fi

echo Writing backup to "$BACKUP_DEST_DIR"


EXCLUDEDIRS="" # Define parent directories that are to be excluded here
# EXCLUDEDIRS="$EXCLUDEDIRS Audiobooks"
# EXCLUDEDIRS="$EXCLUDEDIRS Downloads"
# EXCLUDEDIRS="$EXCLUDEDIRS Dropbox"
# EXCLUDEDIRS="$EXCLUDEDIRS dwhelper"
EXCLUDEDIRS="$EXCLUDEDIRS Encfs"
EXCLUDEDIRS="$EXCLUDEDIRS google-drive"
# EXCLUDEDIRS="$EXCLUDEDIRS Music"
# EXCLUDEDIRS="$EXCLUDEDIRS Podcasts"
# EXCLUDEDIRS="$EXCLUDEDIRS Steam"
# EXCLUDEDIRS="$EXCLUDEDIRS Templates"
# EXCLUDEDIRS="$EXCLUDEDIRS texmf"
# EXCLUDEDIRS="$EXCLUDEDIRS Videos"
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
EXCLUDEFILES="$EXCLUDEFILES **/swiftsim/**/*.lo"
EXCLUDEFILES="$EXCLUDEFILES **/swiftsim/**/*.Plo"

# generate exclusion string for rsync
excludestr_rsync=""
for EX in $EXCLUDEDIRS; do
  excludestr_rsync="$excludestr_rsync ""--exclude=$EX/**"" --exclude=$EX "
done
for EX in $EXCLUDEFILES; do
  excludestr_rsync="$excludestr_rsync --exclude=$EX "
done


# indended usage: $rsync_cmd "$BACKUP_SRC_DIR" "$BACKUP_DEST_DIR"
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
if [[ "$BACKUP_SRC_DIR" != "#none" ]]; then

  # first check that it's within ROOT_BACKUP_SRC_DIR
  if [[ ! "$BACKUP_SRC_DIR" = "$ROOT_BACKUP_SRC_DIR"* ]]; then
    echo "$BACKUP_SRC_DIR" is not in the root backup directory $ROOT_BACKUP_SRC_DIR
    exit 1
  fi

  # then check that it's not in an excluded dir
  for EX in $EXCLUDES; do
    if [[ "$BACKUP_SRC_DIR" = "$EX"* ]]; then
      echo "$BACKUP_SRC_DIR" is in an excluded backup directory: $EX
      exit 1
    fi
  done

  # now add the additional path of the directory to BACKUP_DEST_DIR
  parent_root_dir="$(dirname $ROOT_BACKUP_SRC_DIR)"
  parent_backup_src_dir="$(dirname $BACKUP_SRC_DIR)"
  BACKUP_DEST_DIR="$BACKUP_DEST_DIR"/"${parent_backup_src_dir#$parent_root_dir}"
  mkdir -p "$BACKUP_DEST_DIR"
  # example:
  #   initially:
  #   BACKUP_DEST_DIR = /media/mivkov/backup
  #   BACKUP_SRC_DIR = /home/mivkov/xkcd/ksbd/ToG
  #
  #   change into:
  #   parent_root_dir = /home
  #   parent_dir_to_backup = /home/mivkov/xkcd/ksbd
  #   BACKUP_DEST_DIR += /mivkov/xkcd

  echo "---Backing up single dir '$BACKUP_SRC_DIR'---"
  $rsync_cmd "$BACKUP_SRC_DIR" "$BACKUP_DEST_DIR"
  echo "---Single dir backup ended---"

  exit
fi


MINIMAL_ROOT_SOURCES=" $HOME/Documents "
MINIMAL_ROOT_SOURCES+=" $HOME/Durham "
MINIMAL_ROOT_SOURCES+=" $HOME/EPFL "
MINIMAL_ROOT_SOURCES+=" $HOME/Pictures "
# MINIMAL_ROOT_SOURCES+=" $HOME/Work "


# if we're doing a "minimal" backup:
if [[ "$MINIMAL" = "true" ]]; then

  echo "---Starting minimal backup---"

  for DIR in $MINIMAL_SOURCES; do

    BACKUP_SRC_DIR=`realpath $DIR`

    # first check that it's within ROOT_BACKUP_SRC_DIR
    if [[ ! "$DIR" = "$ROOT_BACKUP_SRC_DIR"* ]]; then
      echo "$BACKUP_SRC_DIR" is not in the root backup directory $ROOT_BACKUP_SRC_DIR
      exit 1
    fi

    # then check that it's not in an excluded dir
    for EX in $EXCLUDES; do
      if [[ "$BACKUP_SRC_DIR" = "$EX"* ]]; then
        echo "$BACKUP_SRC_DIR" is in an excluded backup directory: $EX
        exit 1
      fi
    done

    # now add the additional path of the directory to BACKUP_DEST_DIR
    parent_root_dir="$(dirname $ROOT_BACKUP_SRC_DIR)"
    parent_backup_src_dir="$(dirname $BACKUP_SRC_DIR)"
    BACKUP_DEST_DIR="$BACKUP_DEST_DIR"/"${parent_backup_src_dir#$parent_root_dir}"
    mkdir -p "$BACKUP_DEST_DIR"
    # example:
    #   initially:
    #   BACKUP_DEST_DIR = /media/mivkov/backup
    #   BACKUP_SRC_DIR = /home/mivkov/xkcd/ksbd/ToG
    #
    #   change into:
    #   parent_root_dir = /home
    #   parent_dir_to_backup = /home/mivkov/xkcd/ksbd
    #   BACKUP_DEST_DIR += /mivkov/xkcd

    echo "---Minimal backup: backing '$BACKUP_SRC_DIR'---"
    $rsync_cmd "$BACKUP_SRC_DIR" "$BACKUP_DEST_DIR" --log-file=rsync-backup-HP-"$DATE"-"$DIR".log

  done
  echo "---Minimal backup ended---"
  exit 0

fi


# Doing full backup, then
BACKUP_SRC_DIR="$ROOT_BACKUP_SRC_DIR"

echo "---Starting full backup---"
$rsync_cmd "$BACKUP_SRC_DIR" "$BACKUP_DEST_DIR"
echo "---Full backup ended---"
exit 0
