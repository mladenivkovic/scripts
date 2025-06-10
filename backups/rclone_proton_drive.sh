#!/bin/bash

ERRMSG='
rclone_proton_drive.sh -  sync local dirs with Proton Drive.

Usage:

 rclone_proton_drive.sh direction [options]

 direction:

  -u, --up --push     Push local changes to drive
  -d, --down, --pull  Pull changes from drive to local machine
  -b, --sync          Sync bi-directionally

 options:

  -a, --all           Sync all (hardcoded) dirs
  -w, --work          Sync (all) work dirs
  -p, --personal      Sync (all) private dirs
  --docs              Sync private documents
  --pics, --pictures  Sync pictures
  --ao3               Sync ao3 stuff
  --workdocs          Sync work documents
  --zotero            Sync zotero dir
  --calibre           Sync calibre dir

  --work-archive      Sync work archive dirs (not included in -w, -a, -p flags)
  --mail-archive      Sync mail archive dirs (not included in -w, -a, -p flags)

  -h, --help          Print help and exit.
'


PUSH="false"
PULL="false"
SYNC="false"

ALL="false"
WORK="false"
PERSONAL="false"
PERSONAL_DOCS="false"
PICTURES="false"
AO3="false"
WORKDOCS="false"
ZOTERO="false"
CALIBRE="false"
WORK_ARCHIVE="false"
MAIL_ARCHIVE="false"



# Handle cmdline args.
# --------------------

if [[ $# == 0 ]]; then
  echo "Error: No direction provided. Don't know what you want."
  printf "$ERRMSG"
  exit
else

  while [[ $# > 0 ]]; do
  ARG="$1"

  case $ARG in
    -u | --up | --push)
      PUSH="true"
    ;;

    -d | --down | --pull)
      PULL="true"
    ;;

    -b | --sync)
      SYNC="true"
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

    --calibre)
      CALIBRE="true"
    ;;

    --work-archive)
      WORK_ARCHIVE="true"
    ;;

    --mail-archive)
      MAIL_ARCHIVE="true"
    ;;

    -h | --help)
      echo "$ERRMSG"
      exit
    ;;

    *)
      echo "Error: Unknown argument:" $ARG
      echo "use -h or --help for help."
      echo ""
      exit 1
    ;;
  esac

  shift
  done
fi


# No mixed signals.
if [[ "$PUSH" == "true" && "$PULL" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --push or --pull."
  exit 1
fi
if [[ "$PUSH" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --push or --sync."
  exit 1
fi
if [[ "$PULL" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pull or --sync."
  exit 1
fi
if [[ "$PUSH" == "false" && "$PULL" == "false" && "$SYNC" == "false" ]]; then
  echo "Error: You must select a direction. Set --push, --pull, or --sync flag."
  exit 1
fi


# Check for hostname.
# --------------------
HOST=`hostname`
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"
HOSTNAME_HP_PROBOOK="mivkov-hpprobook"

DO_LENOVO_THINKPAD="false"
DO_HP_PROBOOK="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD )
    DO_LENOVO_THINKPAD="true"
  ;;
  $HOSTNAME_HP_PROBOOK )
    DO_HP_PROBOOK="true"
  ;;
  *)
    echo "Unrecognized hostname. Adapt script before you break things."
    echo "hostname=$HOST"
    exit 1
  ;;
esac




function rclone_cmd() {
  # -----------------------------------------
  # Use the correct rclone command.
  # Usage:
  #   rclone_cmd <src> <dest> [extra flags]
  # -----------------------------------------


  if [[ $# < 2 ]]; then
    echo "Wrong usage: You need to provide source and destination paths."
    exit
  fi

  SRC="$1"
  DEST="$2"
  shift
  shift
  EXTRA_PASSED_FLAGS=""

  while [[ $# > 0 ]]; do
    EXTRA_PASSED_FLAGS="$EXTRA_PASSED_FLAGS"" $1"
    shift
  done


  # Select correct base command.
  rclone_base_cmd=""
  if [[ "$PUSH" == "true" ]]; then
    rclone_base_cmd="rclone copy"' '"$SRC"' '"$DEST"
  elif [[ "$PULL" == "true" ]]; then
    # SRC and DEST are switched on purpose here.
    rclone_base_cmd="rclone sync"' '"$DEST"' '"$SRC"
  elif [[ "$SYNC" == "true" ]]; then

    # https://blog.otterlord.dev/posts/proton-drive-rclone/
    # https://rclone.org/
    # https://rclone.org/bisync/

    # To be on the safe side, make directories in proton drive manually first
    # via browser You should be able to run `rclone mkdir protondrive_remote:dirname`
    # too.

    # If running for the first time, run with --resync:
    #   It is your first bisync run (between these two paths)
    #   You've just made changes to your bisync settings (such as editing the
    #   contents of your --filters-file) There was an error on the prior run,
    #   and as a result, bisync now requires --resync to recover

    rclone_base_cmd="rclone bisync"' '"$SRC"' '"$DEST"
  else
    echo "How did we get here?"
    exit 1
  fi

  EXTRA_FLAGS=""
  EXTRA_FLAGS="$EXTRA_FLAGS"" -l -v"
  # EXTRA_FLAGS="$EXTRA_FLAGS"" --force"
  # EXTRA_FLAGS="$EXTRA_FLAGS"" --resync --resync-mode=newer"
  # EXTRA_FLAGS="$EXTRA_FLAGS"" --dry-run"
  # EXTRA_FLAGS="$EXTRA_FLAGS"" --protondrive-replace-existing-draft=true"

  rclone_full_cmd="$rclone_base_cmd"' '"$EXTRA_FLAGS"' '"$EXTRA_PASSED_FLAGS"

  $rclone_full_cmd
}



# --------------------------
# Do the actual work
# --------------------------

if [[ "$WORK" == "true" || "$ALL" == "true" ]]; then
  rclone_cmd $HOME/Work protondrive_remote:sync/Work
  rclone_cmd $HOME/Zotero protondrive_remote:sync/Zotero
  rclone_cmd $HOME/calibre_library protondrive_remote:sync/calibre_library
else

  # See if we're syncing specific dirs then

  if [[ "$WORKDOCS" == "true" ]]; then
    rclone_cmd $HOME/Work protondrive_remote:sync/Work
  fi
  if [[ "$ZOTERO" == "true" ]]; then
    rclone_cmd $HOME/Zotero protondrive_remote:sync/Zotero
  fi
  if [[ "$CALIBRE" == "true" ]]; then
    rclone_cmd $HOME/calibre_library protondrive_remote:sync/calibre_library
  fi
fi


if [[ "$PERSONAL" == "true" || "$ALL" == "true" ]]; then

  if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
    rclone_cmd $HOME/Pictures/Memories/videos protondrive_remote:sync/Pictures/Memories/videos
    rclone_cmd $HOME/Pictures/Memories/childhood protondrive_remote:sync/Pictures/Memories/childhood
    rclone_cmd $HOME/Pictures/Memories/Pre-2018 protondrive_remote:sync/Pictures/Memories/Pre-2018
    rclone_cmd $HOME/Pictures/Memories/2018 protondrive_remote:sync/Pictures/Memories/2018
    rclone_cmd $HOME/Pictures/Memories/2019 protondrive_remote:sync/Pictures/Memories/2019
    rclone_cmd $HOME/Pictures/Memories/2020 protondrive_remote:sync/Pictures/Memories/2020
    # rclone_cmd $HOME/Pictures/Memories/2021 protondrive_remote:sync/Pictures/Memories/2021 # does not exist...
    rclone_cmd $HOME/Pictures/Memories/2022 protondrive_remote:sync/Pictures/Memories/2022
    rclone_cmd $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
  fi

  rclone_cmd $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
  rclone_cmd $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025

  rclone_cmd $HOME/Documents/important protondrive_remote:sync/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
    rclone_cmd $HOME/Documents/creative protondrive_remote:sync/Documents/creative
  fi

  rclone_cmd $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml

else

  # See if we're syncing specific dirs then

  if [[ "$PICTURES" == "true" ]]; then
    if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
      rclone_cmd $HOME/Pictures/Memories/videos protondrive_remote:sync/Pictures/Memories/videos
      rclone_cmd $HOME/Pictures/Memories/childhood protondrive_remote:sync/Pictures/Memories/childhood
      rclone_cmd $HOME/Pictures/Memories/Pre-2018 protondrive_remote:sync/Pictures/Memories/Pre-2018
      rclone_cmd $HOME/Pictures/Memories/2018 protondrive_remote:sync/Pictures/Memories/2018
      rclone_cmd $HOME/Pictures/Memories/2019 protondrive_remote:sync/Pictures/Memories/2019
      rclone_cmd $HOME/Pictures/Memories/2020 protondrive_remote:sync/Pictures/Memories/2020
      # rclone_cmd $HOME/Pictures/Memories/2021 protondrive_remote:sync/Pictures/Memories/2021 # does not exist...
      rclone_cmd $HOME/Pictures/Memories/2022 protondrive_remote:sync/Pictures/Memories/2022
      rclone_cmd $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
    fi

    rclone_cmd $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
    rclone_cmd $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025
  fi

  if [[ "$PERSONAL_DOCS" == "true" ]]; then
    rclone_cmd $HOME/Documents/important protondrive_remote:sync/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  fi

  if [[ "$AO3" == "true" ]]; then
    rclone_cmd $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
  fi

fi



if [[ "$WORK_ARCHIVE" == "true" ]]; then

  if [[ "$DO_HP_PROBOOK" == "true" ]]; then
    echo "Are you sure you're on the right machine???"
    exit
  fi

  if [[ "$SYNC" == "true" ]]; then
    echo "Are you sure you want to bi-sync?"
    exit
  fi

  rclone_cmd $HOME/Documents/archive_docs protondrive_remote:archive_docs

fi


if [[ "$MAIL_ARCHIVE" == "true" ]]; then

  if [[ "$DO_HP_PROBOOK" == "true" ]]; then
    echo "Are you sure you're on the right machine???"
    exit
  fi

  if [[ "$SYNC" == "true" ]]; then
    echo "Are you sure you want to bi-sync?"
    exit
  fi

  rclone_cmd $HOME/Documents/archive_mail protondrive_remote:archive_mail

fi



