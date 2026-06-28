#!/bin/bash

###############################################################
#
# Script to sync up files to external HD.
# Syncs up back-and-forth between stuff on the HD,
# and stuff on the local machine.
#
###############################################################


errmsg="
Sync up all directories hardcoded in this script onto hard drives,
whose paths are also hardcoded in this script.

usage:
  $ syncHD.sh direction dirflags

  $ syncHD.sh  -h, --help          show this message and quit


  direction: specifies direction of sync. Possible values:

  -s, --sync                       Bi-directional sync
  -owl, --overwrite-local          forcibly overwrite LOCAL STATE with what's on the HD
  -owh, --overwrite-hd             forcibly overwrite HD STATE with what's on the local machine

  dirflags: make (selection of) directories to sync:

  -a, --all                        Sync all (hardcoded) dirs. Equivalent to --work --personal --storage
  -w, --work                       Sync (all) work dirs. Equivalent to --workdocs --zotero
  -p, --personal                   Sync (all) private dirs. Equivalent to --docs --pics --ao3

  --docs                           Sync private documents
  --pics, --pictures               Sync pictures
  --ao3                            Sync ao3 stuff
  --workdocs                       Sync work documents
  --zotero                         Sync zotero dir
  --storage                        Sync 'storage' dirs
"




#---------------------------------------------------------------------------------------
# Top level call to synchronize a single directory (recursively) back and forth between
# the HD and local machine.
# Calls `sync_dir_unison` if we're using unison (bi-directional sync) or `sync_dir_rsync`
# if we're using directional sync.
#
# Usage:
#   sync_dir LOCALDIR HDDIR UNISON_PROFILE [--exclude=dir1, --exclude=dir2, ...]
#
# LOCALDIR :       directory on your local machine
# HDDIR :          directory on your HD
# UNISON_PROFILE:  which `unison` profile to use.
# --exclude=dir :  optional strings to add to the rsync call to exclude
#                  whatever you want excluded. The paths may be relative
#                  to LOCALDIR and HDDIR. Only passed to rsync, i.e. for
#                  directional sync.
#---------------------------------------------------------------------------------------
sync_dir() {

  if [ -z ${HDPATH+x} ]; then
    echo "Didn't find HDPATH variable."
    echo 'Needs to be set before this command is called.'
    exit 1
  fi

  # better safe than sorry.
  if [ ! -d "$HDPATH" ]; then
    echo "HDPATH '"$HDPATH"' isn't a directory. Quitting."
  fi

  # check passed arguments.
  if [[ "$#" -lt 3 ]]; then
    echo "sync_dir(): not enough arguments given. Can't handle that."
    echo $0 $1 $2 $3 $4
    exit 1
  fi

  LOCALDIR=$1
  HDDIR=$2
  UNISON_PROFILE=$3
  shift
  shift
  shift

  # make full proper paths
  if [[ "$LOCALDIR" = /* ]]; then
    : # this should be a full path. `:` means do nothing.
  else
      LOCALDIR="$PWD"/"$LOCALDIR"
  fi
  if [[ "$HDDIR" = /* ]]; then
    : # this should be a full path. `:` means do nothing.
  else
    HDDIR="$HDPATH"/"$HDDIR"
  fi

  # make sure the dirs don't have trailing slashes. This modifies
  # rsync behaviour.
  # Run it twice in case someone has stupid ideas.

  HDDIR=${HDDIR%/}
  HDDIR=${HDDIR%/}
  LOCALDIR=${LOCALDIR%/}
  LOCALDIR=${LOCALDIR%/}

  # someplace to store the logs
  mkdir -p $PWD/logs

  # Check that directories in fact exist.
  if [ ! -d "$HDDIR" ]; then
    echo "WARNING: Target directory on HD not found. Target is '"$HDDIR"', HDPATH is '"$HDPATH"'"
    while true; do
      read -p "Create it? (y/n) " yn
      case $yn in
        [Yy]* ) mkdir -p "$HDDIR"; break;;
        [Nn]* ) echo "exiting."; exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi

  if [ ! -d "$LOCALDIR" ]; then
    echo "Target directory on LOCAL not found. Target is '"$LOCALDIR"'"
    while true; do
      read -p "Create it? (y/n) " yn
      case $yn in
        [Yy]* ) mkdir -p "$LOCALDIR"; break;;
        [Nn]* ) echo "exiting."; exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi


  # select appropriate sync tool.
  if [[ "$BISYNC" == "yes" ]]; then
    sync_dir_unison "$LOCALDIR" "$HDDIR" "$UNISON_PROFILE"
  else
    # Grab additional arguments
    additional_args=""
    while [[ $# > 0 ]]; do
      additional_args="$additional_args"" $1"
      shift
    done
    sync_dir_rsync "$LOCALDIR" "$HDDIR" $additional_args
  fi
}

#---------------------------------------------------------------------------------------
# Same as `sync_dir`, but provide a special target dir to sync to/from.
#
# Usage:
#   sync_dir_full_path_target LOCALDIR FULL_PATH_TO_HDDIR UNISON_PROFILE [--exclude=dir1, --exclude=dir2, ...]
#
# LOCALDIR :       directory on your local machine
# FULL_PATH_TO_HDDIR :  full path to directory (on your HD)
# UNISON_PROFILE:  which `unison` profile to use.
# --exclude=dir :  optional strings to add to the rsync call to exclude
#                  whatever you want excluded. The paths may be relative
#                  to LOCALDIR and HDDIR. Only passed to rsync, i.e. for
#                  directional sync.
#---------------------------------------------------------------------------------------
sync_dir_full_path_target() {

  # check passed arguments.
  if [[ "$#" -lt 3 ]]; then
    echo "sync_dir(): not enough arguments given. Can't handle that."
    echo $0 $1 $2 $3 $4
    exit 1
  fi

  LOCALDIR=$1
  HDDIR=$2
  UNISON_PROFILE=$3
  shift
  shift
  shift

  # make full proper paths
  if [[ "$LOCALDIR" = /* ]]; then
    : # this should be a full path. `:` means do nothing.
  else
      LOCALDIR="$PWD"/"$LOCALDIR"
  fi
  if [[ "$HDDIR" = /* ]]; then
    : # this should be a full path. `:` means do nothing.
  else
    echo "'\$HDDIR' should be a full path, you provided '$HDDIR'"
    exit 1
  fi

  # make sure the dirs don't have trailing slashes. This modifies
  # rsync behaviour.
  # Run it twice in case someone has stupid ideas.

  HDDIR=${HDDIR%/}
  HDDIR=${HDDIR%/}
  LOCALDIR=${LOCALDIR%/}
  LOCALDIR=${LOCALDIR%/}

  # someplace to store the logs
  mkdir -p $PWD/logs

  # Check that directories in fact exist.
  if [ ! -d "$HDDIR" ]; then
    echo "Error: target HDDIR doesn't exist: '"$HDDIR"'"
    exit 1
  fi

  if [ ! -d "$LOCALDIR" ]; then
    echo "Target directory on LOCAL not found. Target is '"$LOCALDIR"'"
    while true; do
      read -p "Create it? (y/n) " yn
      case $yn in
        [Yy]* ) mkdir -p "$LOCALDIR"; break;;
        [Nn]* ) echo "exiting."; exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi


  # select appropriate sync tool.
  if [[ "$BISYNC" == "yes" ]]; then
    sync_dir_unison "$LOCALDIR" "$HDDIR" "$UNISON_PROFILE" $additional_args
  else
    # Grab additional args
    additional_args=""
    while [[ $# > 0 ]]; do
      additional_args="$additional_args"" $1"
      shift
    done
    sync_dir_rsync "$LOCALDIR" "$HDDIR" $additional_args
  fi
}




sync_dir_unison(){

  if [[ "$BISYNC" != "yes" ]]; then
      echo Wrong branch in sync_dir_unison
      exit 1
  fi

  # read in passed arguments.
  # reminder: $0 is script's own name, not function name.
  LOCALDIR=$1
  HDDIR=$2
  UNISON_PROFILE=$3

  DATE=`date +%F_%Hh%M` # current time
  bname=`basename $LOCALDIR`

  echo unison "$UNISON_PROFILE" "$LOCALDIR" "$HDDIR" -logfile=$PWD/logs/unison-"$DATE"-"$bname".log -auto
  unison "$UNISON_PROFILE" "$LOCALDIR" "$HDDIR" -logfile=$PWD/logs/unison-"$DATE"-"$bname".log -auto

}



sync_dir_rsync() {
  # read in passed arguments.
  # reminder: $0 is script's own name, not function name.
  LOCALDIR=$1
  HDDIR=$2

  # shift parameter counter to after HDDIR
  shift
  shift

  excludestr_rsync_local=""
  excludestr_rsync_HD=""

  while [[ $# > 0 ]]; do

    ARG="$1"

    case "$ARG" in

      "--exclude="* )
        : # ':' means do nothing
      ;;

      *)
        "sync_dir(): Unrecognized argument '""$ARG""'"
      exit 1

    esac


    # check full proper paths
    # WARNING: Don't actually use full paths.
    newarg_local="${ARG#--exclude=}"
    newarg_local_full="$newarg_local"
    if [[ "$newarg_local_full" = /* ]]; then
      : # this should be a full path. `:` means do nothing.
    else
      # Assume excludes may be relative to source dir
      newarg_local_full="$LOCALDIR"/"$newarg_local_full"
    fi
    if [[ ! -d "$newarg_local_full" && ! -f "$newarg_local_full" ]]; then
      echo "WARNING: Directory or file to exclude doesn't exist on LOCAL. Passed argument was '"$1"', full path is '"$newarg_local_full"'"
    fi

    newarg_HD="${ARG#--exclude=}"
    newarg_HD_full="$newarg_local"
    if [[ "$newarg_HD_full" = /* ]]; then
      : # this should be a full path. `:` means do nothing.
    else
      newarg_HD_full="$HDDIR"/"$newarg_HD_full"
    fi
    if [[ ! -d "$newarg_HD_full" && ! -f "$newarg_HD_full" ]]; then
      echo "WARNING: Directory or file to exclude doesn't exist on HD. Passed argument was '"$1"', full path is '"$newarg_HD_full"'"
    fi

    excludestr_rsync_local="$excludestr_rsync_local ""--exclude=$newarg_local/**"" --exclude=$newarg_local "
    excludestr_rsync_HD="$excludestr_rsync_HD ""--exclude=$newarg_HD/**"" --exclude=$newarg_HD "
    shift
  done

  DATE=`date +%F_%Hh%M` # current time

  RSYNC_CMD="rsync    --archive \
                      --verbose \
                      --human-readable \
                      --progress \
                      --stats \
                      --update \
                      --recursive \
                      "

  RSYNC_CMD_DELETE_FIRST="rsync   --archive \
                                  --verbose \
                                  --human-readable \
                                  --progress \
                                  --stats \
                                  --update \
                                  --recursive \
                                  --delete \
                                  "

  RSYNC_CMD_DELETE_FIRST_DRY_RUN="rsync   --archive \
                                          --human-readable \
                                          --recursive \
                                          --verbose \
                                          --stats \
                                          --update \
                                          --delete \
                                          --dry-run \
                                          "


  RSYNC_CMD_DEFAULT_EXCLUDES="
                      --exclude=**/*tmp*/ \
                      --exclude=**/*cache*/ \
                      --exclude=**/*Cache*/ \
                      --exclude=**~ \
                      --exclude=**/lost+found*/ \
                      --exclude=**/*Trash*/ \
                      --exclude=**/*trash*/ \
                      --exclude=**/.gvfs/ \
                      --exclude=**/__pycache__ \
                      --exclude=*.pyc "

  RSYNC_CMD=${RSYNC_CMD}${RSYNC_CMD_DEFAULT_EXCLUDES}
  RSYNC_CMD_DELETE_FIRST=${RSYNC_CMD_DELETE_FIRST}${RSYNC_CMD_DEFAULT_EXCLUDES}


  if [ "$OVERWRITE_LOCAL" == "yes" ]; then
    echo "==================================================================================="
    echo "OVERWRITING" $LOCALDIR " with "  $HDDIR
    echo "==================================================================================="
    $RSYNC_CMD_DELETE_FIRST_DRY_RUN $excludestr_rsync_local "$HDDIR"/ "$LOCALDIR"
    while true; do
      read -p "That was a dry run. This will overwrite your LOCAL MACHINE STATE. Do you wish to continue? (y/n) " yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "exiting."; return;;
        * ) echo "Please answer yes or no.";;
      esac
    done
    $RSYNC_CMD_DELETE_FIRST $excludestr_rsync_local --log-file=logs/rsync-HD2L-overwrite-"$DATE"".log" "$HDDIR"/ "$LOCALDIR"


  elif [ "$OVERWRITE_HD" == "yes" ]; then

    echo "==================================================================================="
    echo "OVERWRITING" $HDDIR " with "  $LOCALDIR
    echo "==================================================================================="
    $RSYNC_CMD_DELETE_FIRST_DRY_RUN $excludestr_rsync_local "$LOCALDIR"/ "$HDDIR"
    while true; do
      read -p "That was a dry run. This will overwrite your HD STATE. Do you wish to continue? (y/n) " yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "exiting."; return;;
        * ) echo "Please answer yes or no.";;
      esac
    done
    $RSYNC_CMD_DELETE_FIRST $excludestr_rsync_local --log-file=logs/rsync-L2HD-overwrite-"$DATE"".log" "$LOCALDIR"/ "$HDDIR"

  else
    # BISYNC is done with unison.
    echo "Invalid branch in sync_dir_rsync - we shouldn't be here."
  fi
}










#-----------------------------------------------------------------------
# First, let's read the cmdline args.
#-----------------------------------------------------------------------

OVERWRITE_LOCAL="no"
OVERWRITE_HD="no"
BISYNC="no"

ALL="false"
WORK="false"
PERSONAL="false"
PERSONAL_DOCS="false"
PICTURES="false"
AO3="false"
WORKDOCS="false"
ZOTERO="false"
STORAGE="false"



while [[ $# > 0 ]]; do
  ARG="$1"

  case "$ARG" in

    -h | --help)
      echo -e "$errmsg"
      exit 0
    ;;

    -owl | --overwrite-local)
      OVERWRITE_LOCAL="yes"
      echo "Will overwrite LOCAL MACHINE STATE instead of syncing"
    ;;

    -owh | --overwrite-hd)
      OVERWRITE_HD="yes"
      echo "Will overwrite HD STATE instead of syncing"
    ;;

    -s | --sync)
      BISYNC="yes"
      echo "Will do bi-directional sync."
    ;;

    -a | --all)
      ALL="true"
    ;;

    -w | --work)
      WORK="true"
    ;;

    -p | --personal)
      PERSONAL="true"
    ;;

    --docs)
      PERSONAL_DOCS="true"
    ;;

    --pics | --pictures)
      PICTURES="true"
    ;;

    --ao3)
      AO3="true"
    ;;

    --workdocs)
      WORKDOCS="true"
    ;;

    --zotero)
      ZOTERO="true"
    ;;

    --storage)
      STORAGE="true"
    ;;


    * )
      echo "Unknown cmdline arg '"$ARG"'"
      echo
      echo -e $errmsg
      exit
    ;;

  esac

  shift
done


# --------------------
# Check for hostname.
# --------------------
HOST=`hostname`
HOSTNAME_ASUS_ZENBOOK="mivkov-asuszenbook14"
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"
HOSTNAME_LENOVO_LEGION="mivkov-lenovo-legion"
HOSTNAME_HP_PROBOOK="mivkov-hpprobook"

DO_LENOVO_THINKPAD="false"
DO_HP_PROBOOK="false"
DO_LENOVO_LEGION="false"
DO_ASUS_ZENBOOK="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD )
    DO_LENOVO_THINKPAD="true"
  ;;
  $HOSTNAME_HP_PROBOOK )
    DO_HP_PROBOOK="true"
  ;;
  $HOSTNAME_LENOVO_LEGION )
    DO_LENOVO_LEGION="true"
  ;;
  $HOSTNAME_ASUS_ZENBOOK )
    DO_ASUS_ZENBOOK="true"
  ;;
  *)
    echo "Unrecognized hostname. Adapt script before you break things."
    echo "hostname=$HOST"
    exit 1
  ;;
esac




#------------------------------------------------------------------------
# Determine which hard drive to sync with.
# Choices are hardcoded in here.
#
# @MLADEN: NOTE: Make sure this fails and exits if no HDPATH is found.
# Otherwise, the subsequent rsync calls are going to do stupid things.
#
# @MLADEN: NOTE that this sync doesn't require encrypted drives EXCEPT
# for documents.
#------------------------------------------------------------------------
HOMEDIR_BASENAME=`basename $HOME`
HDPATH="/run/media/$HOMEDIR_BASENAME/WD_free"

if [ ! -d "$HDPATH" ]; then
  # echo "Din't find target dir '"$HDPATH"', trying second option"
  # HDPATH="/media/$HOMEDIR_BASENAME/archive/"
  # if [ ! -d "$HDPATH" ]; then
  #     echo "Din't find target dir" $HDPATH
  #     exit 1
  # fi
  echo "Din't find target dir" $HDPATH
  exit 1
fi



# Set appropriate variables from shortcuts/collective flags

if [[ "$ALL" == "true" ]]; then
  WORKDOCS="true"
  ZOTERO="true"
  PICTURES="true"
  PERSONAL_DOCS="true"
  AO3="true"
  STORAGE="true"
fi

if [[ "$WORK" == "true" ]]; then
  WORKDOCS="true"
  ZOTERO="true"
fi

if [[ "$PERSONAL" == "true" ]]; then
  PICTURES="true"
  PERSONAL_DOCS="true"
  AO3="true"
fi


# are we including personal files?
INCLUDE_PERSONAL="false"
if [[ "$DO_LENOVO_THINKPAD" == "true" || "$DO_LENOVO_LEGION" == "true" || "$DO_ASUS_ZENBOOK" == "true" ]]; then
  INCLUDE_PERSONAL="true"
fi





# --------------------------
# Do the actual work
# --------------------------


if [[ "$WORKDOCS" == "true" ]]; then
  sync_dir $HOME/Work sync/Work sync_HD_default.prf
fi
if [[ "$ZOTERO" == "true" ]]; then
  sync_dir $HOME/Zotero sync/Zotero sync_HD_default.prf
fi

if [[ "$PICTURES" == "true" ]]; then
  if [[ "$INCLUDE_PERSONAL" == "true" ]]; then
    sync_dir $HOME/Pictures/Memories/videos sync/Pictures/Memories/videos sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/childhood sync/Pictures/Memories/childhood sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/Pre-2018 sync/Pictures/Memories/Pre-2018 sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/2018 sync/Pictures/Memories/2018 sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/2019 sync/Pictures/Memories/2019 sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/2020 sync/Pictures/Memories/2020 sync_HD_default.prf
    # sync_dir $HOME/Pictures/Memories/2021 sync/Pictures/Memories/2021 # does not exist...
    sync_dir $HOME/Pictures/Memories/2022 sync/Pictures/Memories/2022 sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/2023 sync/Pictures/Memories/2023 sync_HD_default.prf
    sync_dir $HOME/Pictures/Memories/2024 Pictures/Memories/2024 sync_HD_default.prf

    sync_dir $HOME/Pictures/Wallpaper sync/Pictures/Wallpaper sync_HD_default.prf
    sync_dir $HOME/Pictures/screenshots_keep sync/Pictures/screenshots_keep sync_HD_default.prf
  fi

  sync_dir $HOME/Pictures/Memories/2025 Pictures/Memories/2025 sync_HD_default.prf
  sync_dir $HOME/Pictures/Memories/2026 Pictures/Memories/2026 sync_HD_default.prf

  sync_dir $HOME/Pictures/profile_pics sync/Pictures/profile_pics sync_HD_default.prf
fi

if [[ "$PERSONAL_DOCS" == "true" ]]; then
  if [[ "$INCLUDE_PERSONAL" == "true" ]]; then
    # Just sync the entire directory. But exclude "important" dir; that's handled later
    sync_dir $HOME/Documents sync/Documents sync_HD_documents.prf --exclude=important
  else
    # only sync 'swift_stuff' and 'notion_icons' dirs from /Documents
    sync_dir $HOME/Documents/swift_stuff sync/Documents/swift_stuff sync_HD_default.prf
    sync_dir $HOME/Documents/notion_icons sync/Documents/notion_icons sync_HD_default.prf
  fi

  if [ ! -d $HOME/Encfs/docs/Documents ]; then
    echo "Didn't find dir $HOME/Encfs/docs/Documents, did you forget to mount it?"
    exit 1
  fi
  sync_dir_full_path_target $HOME/Documents/important $HOME/Encfs/docs/Documents/important sync_HD_default.prf

  sync_dir $HOME/coding/documents sync/coding/documents sync_HD_default.prf
  sync_dir $HOME/Templates sync/Templates sync_HD_default.prf
fi

if [[ "$AO3" == "true" ]]; then
  sync_dir $HOME/.ao3statscraper sync/.ao3statscraper sync_HD_ao3.prf --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml --exclude=ao3statscraper.session.pkl
fi



if [[ "$STORAGE" == "true" ]]; then

  if [[ "$DO_HP_PROBOOK" == "true" ]]; then
    if [[ "$ALL" == "true" ]]; then
      echo "Trying to backup storage dirs."
      echo "Are you sure you're on the right machine???"
    else
      echo "Trying to backup storage dirs."
      echo "Are you sure you're on the right machine???"
      exit 1
    fi

  else

    LOCALDIR=$HOME/storage
    if [[ "$DO_LENOVO_LEGION" == "true" ]]; then
        LOCALDIR=/run/media/InternalHD/storage
    fi

    sync_dir "$LOCALDIR" sync/storage sync_HD_default.prf

  fi
fi


echo DONE.


exit 0
