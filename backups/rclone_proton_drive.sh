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
if [[ "$PULL" == "false" && "$SYNC" == "false" && "$PULL" == "false" ]]; then
  echo "Error: You must select a direction. Set --push, --pull, or --sync flag."
  exit 1
fi

exit

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


# Select correct base command.
rclone_base_cmd=""
if [[ "$PUSH" == "true" ]]; then
  echo "NOT IMPLEMENTED YET"
  exit 1
  rclone_base_cmd=""
elif [[ "$PULL" == "true"]]; then
  echo "NOT IMPLEMENTED YET"
  exit 1
  rclone_base_cmd=""
elif [[ "$SYNC" == "true" ]]; then
  rclone_base_cmd="rclone bisync"
else
  echo "How did we get here?"
  exit 1
fi



# https://blog.otterlord.dev/posts/proton-drive-rclone/
# https://rclone.org/
# https://rclone.org/bisync/

# To be on the safe side, make directories in proton drive manually first via browser
# You should be able to run `rclone mkdir protondrive_remote:dirname` too.

# If running for the first time, run with --resync:
#   It is your first bisync run (between these two paths)
#   You've just made changes to your bisync settings (such as editing the contents of your --filters-file)
#   There was an error on the prior run, and as a result, bisync now requires --resync to recover


# rclone_cmd="rclone sync -l -v"
# rclone_cmd="rclone bisync -l -v --resync --resync-mode=newer --dry-run"
# rclone_cmd="rclone bisync -l -v --resync --resync-mode=newer"
rclone_cmd="rclone bisync -l -v"
# --protondrive-replace-existing-draft=true

if [[ "$WORK" == "true" || "$ALL" == "true" ]]; then
  $rclone_cmd $HOME/Work protondrive_remote:sync/Work
  $rclone_cmd $HOME/Zotero protondrive_remote:sync/Zotero
  $rclone_cmd $HOME/calibre_library protondrive_remote:sync/calibre_library
else
  # See if we're syncing specific dirs then
  if [[ "$WORKDOCS" == "true" ]]; then
    $rclone_cmd $HOME/Work protondrive_remote:sync/Work
  fi
  if [[ "$ZOTERO" == "true" ]]; then
    $rclone_cmd $HOME/Zotero protondrive_remote:sync/Zotero
  fi
  if [[ "$CALIBRE" == "true" ]]; then
    $rclone_cmd $HOME/calibre_library protondrive_remote:sync/calibre_library
  fi
fi


if [[ "$PERSONAL" == "true" || "$ALL" == "true" ]]; then

  if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
    $rclone_cmd $HOME/Pictures/Memories/videos protondrive_remote:sync/Pictures/Memories/videos
    $rclone_cmd $HOME/Pictures/Memories/childhood protondrive_remote:sync/Pictures/Memories/childhood
    $rclone_cmd $HOME/Pictures/Memories/Pre-2018 protondrive_remote:sync/Pictures/Memories/Pre-2018
    $rclone_cmd $HOME/Pictures/Memories/2018 protondrive_remote:sync/Pictures/Memories/2018
    $rclone_cmd $HOME/Pictures/Memories/2019 protondrive_remote:sync/Pictures/Memories/2019
    $rclone_cmd $HOME/Pictures/Memories/2020 protondrive_remote:sync/Pictures/Memories/2020
    # $rclone_cmd $HOME/Pictures/Memories/2021 protondrive_remote:sync/Pictures/Memories/2021 # does not exist...
    $rclone_cmd $HOME/Pictures/Memories/2022 protondrive_remote:sync/Pictures/Memories/2022
    $rclone_cmd $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
  fi

  $rclone_cmd $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
  $rclone_cmd $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025

  $rclone_cmd $HOME/Documents/important protondrive_remote:sync/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  $rclone_cmd $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
else

  if [[ "$PICTURES" == "true" ]]; then
    if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
      $rclone_cmd $HOME/Pictures/Memories/videos protondrive_remote:sync/Pictures/Memories/videos
      $rclone_cmd $HOME/Pictures/Memories/childhood protondrive_remote:sync/Pictures/Memories/childhood
      $rclone_cmd $HOME/Pictures/Memories/Pre-2018 protondrive_remote:sync/Pictures/Memories/Pre-2018
      $rclone_cmd $HOME/Pictures/Memories/2018 protondrive_remote:sync/Pictures/Memories/2018
      $rclone_cmd $HOME/Pictures/Memories/2019 protondrive_remote:sync/Pictures/Memories/2019
      $rclone_cmd $HOME/Pictures/Memories/2020 protondrive_remote:sync/Pictures/Memories/2020
      # $rclone_cmd $HOME/Pictures/Memories/2021 protondrive_remote:sync/Pictures/Memories/2021 # does not exist...
      $rclone_cmd $HOME/Pictures/Memories/2022 protondrive_remote:sync/Pictures/Memories/2022
      $rclone_cmd $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
    fi

    $rclone_cmd $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
    $rclone_cmd $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025
  fi

  if [[ "$PERSONAL_DOCS" == "true" ]]; then
    $rclone_cmd $HOME/Documents/important protondrive_remote:sync/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  fi

  if [[ "$AO3" == "true" ]]; then
    $rclone_cmd $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
  fi

fi
