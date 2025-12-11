#!/bin/bash

# First setup: https://rclone.org/drive/

# as set up with `rclone config`
GOOGLE_DRIVE_REMOTE_NAME=google_drive
# root dir on google remote where to place syncs
REMOTE_SYNC_ROOT_DIR=sync
# root dir on google remote where to place archives
REMOTE_ARCHIVE_ROOT_DIR=archive
# backup directory on remote for syncing process
REMOTE_SYNC_BACKUP_DIR=sync_backup
# backup directory on remote for syncing process
REMOTE_ARCHIVE_BACKUP_DIR=archive_backup



ERRMSG='
rclone_google_drive.sh - sync local dirs with Google Drive.

Usage:

 rclone_google_drive.sh direction [options]

 direction:

  -u, --up --push       Push local changes to drive (copy, not sync)
  -d, --down, --pull    Pull changes from drive to local machine (copy, not sync)
  --pushsync            Push local changes to drive via sync (overwrite drive state with local state)
  --pullsync            Pull changes from drive via sync (overwrite local state with drive)
  -b, --sync, --bisync  Sync bi-directionally

 options:

  (selection of) directories to sync:

    -a, --all           Sync all (hardcoded) dirs. Equivalent to --work --personal                    [ NOTE: CURRENTLY DISABLED ]
    -w, --work          Sync (all) work dirs. Equivalent to --workdocs --zotero --calibre --teaching  [ NOTE: CURRENTLY DISABLED ]
    -p, --personal      Sync (all) private dirs. Equivalent to --docs --pics --ao3                    [ NOTE: CURRENTLY DISABLED ]
    -t, --testing       Directory to test sync: ~/tmp/testing_sync
    --docs              Sync private documents      [ NOTE: CURRENTLY DISABLED ]
    --pics, --pictures  Sync pictures               [ NOTE: CURRENTLY DISABLED ]
    --ao3               Sync ao3 stuff
    --workdocs          Sync work documents
    --teaching          Sync Durham/teaching documents
    --zotero            Sync zotero dir             [ NOTE: CURRENTLY DISABLED ]
    --calibre           Sync calibre dir            [ NOTE: CURRENTLY DISABLED ]

    --docs-archive      Sync archive document dirs (not included in -w, -a, -p flags) [ NOTE: CURRENTLY DISABLED]
    --work-archive      Sync work archive dirs (not included in -w, -a, -p flags)     [ NOTE: CURRENTLY DISABLED]
    --mail-archive      Sync mail archive dirs (not included in -w, -a, -p flags)     [ NOTE: CURRENTLY DISABLED]

  rclone flags:

    --resync            Pass the --resync flag to rclone. Only works for --sync direction
    --force             Pass the --force flag to rclone. Only for bisync direction
    --dry-run           Pass the --force flag to rclone. Only for bisync direction

  Additional flags:

    -h, --help          Print help and exit.
'


PUSH="false"
PUSHSYNC="false"
PULL="false"
PULLSYNC="false"
SYNC="false"

ALL="false"
WORK="false"
PERSONAL="false"
TESTING="false"
PERSONAL_DOCS="false"
PICTURES="false"
AO3="false"
WORKDOCS="false"
TEACHING="false"
ZOTERO="false"
CALIBRE="false"
WORK_ARCHIVE="false"
MAIL_ARCHIVE="false"
DOCS_ARCHIVE="false"
RESYNC="false"
FORCE="false"
DRYRUN="false"



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

      --pullsync)
        PULLSYNC="true"
      ;;

      --pushsync)
        PUSHSYNC="true"
      ;;

      -b | --sync | --bisync )
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

      -t | --testing)
        TESTING="true"
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

      --teaching)
        TEACHING="true"
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

      --docs-archive)
        DOCS_ARCHIVE="true"
      ;;

      --resync)
        RESYNC="true"
      ;;

      --force)
        FORCE="true"
      ;;

      --dry-run)
        DRYRUN="true"
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
if [[ "$PUSH" == "true" && "$PUSHSYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --push or --pushsync."
  exit 1
fi
if [[ "$PUSH" == "true" && "$PULLSYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --push or --pullsync."
  exit 1
fi
if [[ "$PUSH" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --push or --sync."
  exit 1
fi

if [[ "$PULL" == "true" && "$PUSHSYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pull or --pushsync."
  exit 1
fi
if [[ "$PULL" == "true" && "$PULLSYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pull or --pullsync."
  exit 1
fi
if [[ "$PULL" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pull or --sync."
  exit 1
fi

if [[ "$PULLSYNC" == "true" && "$PUSHSYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pullsync or --pushsync."
  exit 1
fi

if [[ "$PULLSYNC" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pullsync or --sync."
  exit 1
fi

if [[ "$PUSHSYNC" == "true" && "$SYNC" == "true" ]]; then
  echo "Error: Can't select several directions. Pick either --pushsync or --sync."
  exit 1
fi



if [[ "$PUSH" == "false" && "$PULL" == "false" && "$SYNC" == "false" && "$PUSHSYNC" == "false" && "$PULLSYNC" == "false" ]]; then
  echo "Error: You must select a direction. Set --push, --pull, --pushsync, --pullsync, or --sync flag."
  exit 1
fi


if [[ "$SYNC" != "true" && "$RESYNC" == "true" ]]; then
  echo "--resync flag is only valid for bisync mode (-b/--sync direction), ignoring it."
  RESYNC="false"
fi

if [[ "$SYNC" != "true" && "$FORCE" == "true" ]]; then
  echo "--force flag is only valid for bisync mode (-b/--sync direction), ignoring it."
  FORCE="false"
fi


if [[ "$TESTING" == "true" ]]; then
  REMOTE_SYNC_ROOT_DIR=test_sync
  REMOTE_SYNC_BACKUP_DIR=test_sync_backup
fi


# Temporarily disable certain directories
if [[ "$DOCS" == "true" ]]; then
  echo "--docs is currently disabled"
  exit
fi
if [[ "$PICTURES" == "true" ]]; then
  echo "--pics, --pictures is currently disabled"
  exit
fi
if [[ "$ZOTERO" == "true" ]]; then
  echo "--zotero is currently disabled"
  exit
fi
if [[ "$CALIBRE" == "true" ]]; then
  echo "--calibre is currently disabled"
  exit
fi
if [[ "$DOCS_ARCHIVE" == "true" ]]; then
  echo "--docs-archive is currently disabled"
  exit
fi
if [[ "$WORK_ARCHIVE" == "true" ]]; then
  echo "--work-archive is currently disabled"
  exit
fi
if [[ "$MAIL_ARCHIVE" == "true" ]]; then
  echo "--mail-archive is currently disabled"
  exit
fi
if [[ "$ALL" == "true" ]]; then
  echo "-a, --all is currently disabled"
  exit
fi
if [[ "$WORK" == "true" ]]; then
  echo "-w, --work is currently disabled"
  exit
fi
if [[ "$PERSONAL" == "true" ]]; then
  echo "-p, --personal is currently disabled"
  exit
fi




# Check for hostname.
# --------------------
HOST=`hostname`
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"
HOSTNAME_LENOVO_LEGION="mivkov-lenovo-legion"
HOSTNAME_HP_PROBOOK="mivkov-hpprobook"

DO_PRIVATE_MACHINE="false"
DO_WORK_MACHINE="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD | $HOSTNAME_LENOVO_LEGION)
    DO_PRIVATE_MACHINE="true"
  ;;
  $HOSTNAME_HP_PROBOOK )
    DO_WORK_MACHINE="true"
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

  # Grab additional flags passed when calling this function
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
    rclone_base_cmd="rclone copy"' '"$DEST"' '"$SRC"
  elif [[ "$PUSHSYNC" == "true" ]]; then
    rclone_base_cmd="rclone sync"' '"$SRC"' '"$DEST"
  elif [[ "$PULLSYNC" == "true" ]]; then
    # SRC and DEST are switched on purpose here.
    rclone_base_cmd="rclone sync"' '"$DEST"' '"$SRC"
  elif [[ "$SYNC" == "true" ]]; then

    # https://blog.otterlord.dev/posts/proton-drive-rclone/
    # https://rclone.org/
    # https://rclone.org/bisync/

    # To be on the safe side, make directories in google drive manually first
    # via browser. You should be able to run `rclone mkdir
    # "$GOOGLE_DRIVE_REMOTE_NAME":dirname` too.

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

  if [[ "$FORCE" == "true" ]]; then
    EXTRA_FLAGS="$EXTRA_FLAGS"" --force"
  fi

  if [[ "$RESYNC" == "true" ]]; then
    EXTRA_FLAGS="$EXTRA_FLAGS"" --resync"
    # EXTRA_FLAGS="$EXTRA_FLAGS"" --resync-mode=newer"
  fi

  if [[ "$DRYRUN" == "true" ]]; then
    EXTRA_FLAGS="$EXTRA_FLAGS"" --dry-run"
  fi

  rclone_full_cmd="$rclone_base_cmd"' '"$EXTRA_FLAGS"' '"$EXTRA_PASSED_FLAGS"

  echo "Run summary:"
  echo "  SRC:                      "$SRC
  echo "  DEST:                     "$DEST
  echo "  GOOGLE_DRIVE_REMOTE_NAME: "$GOOGLE_DRIVE_REMOTE_NAME
  echo "  REMOTE_SYNC_ROOT_DIR:     "$REMOTE_SYNC_ROOT_DIR
  echo "  REMOTE_ARCHIVE_ROOT_DIR:  "$REMOTE_ARCHIVE_ROOT_DIR
  echo "  REMOTE_SYNC_BACKUP_DIR:   "$REMOTE_SYNC_BACKUP_DIR
  echo "  REMOTE_ARCHIVE_BACKUP_DIR:"$REMOTE_ARCHIVE_BACKUP_DIR
  echo "  RCLONE_BASE_CMD:          "$rclone_base_cmd
  echo "  EXTRA_FLAGS:              "$EXTRA_FLAGS
  echo "  EXTRA_PASSED_FLAGS:       "$EXTRA_PASSED_FLAGS
  echo
  echo "running ""$rclone_full_cmd"
  echo

  $rclone_full_cmd
}



# --------------------------
# Do the actual work
# --------------------------

if [[ "$WORK" == "true" || "$ALL" == "true" ]]; then
  rclone_cmd $HOME/Work "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Work
  rclone_cmd $HOME/Zotero "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Zotero
  rclone_cmd $HOME/calibre_library "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/calibre_library
  rclone_cmd $HOME/Durham/teaching "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Durham/teaching
else

  # See if we're syncing specific dirs then

  if [[ "$WORKDOCS" == "true" ]]; then
    rclone_cmd $HOME/Work "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Work
  fi
  if [[ "$TEACHING" == "true" ]]; then
    rclone_cmd $HOME/Durham/teaching "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Durham/teaching
  fi
  if [[ "$ZOTERO" == "true" ]]; then
    rclone_cmd $HOME/Zotero "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Zotero
  fi
  if [[ "$CALIBRE" == "true" ]]; then
    rclone_cmd $HOME/calibre_library "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/calibre_library
  fi
fi


if [[ "$PERSONAL" == "true" || "$ALL" == "true" ]]; then

  if [[ "$DO_PRIVATE_MACHINE" == "true" ]]; then
    rclone_cmd $HOME/Pictures/profile_pics "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/profile_pics

    rclone_cmd $HOME/Pictures/Memories/videos "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/videos
    rclone_cmd $HOME/Pictures/Memories/childhood "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/childhood
    rclone_cmd $HOME/Pictures/Memories/Pre-2018 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/Pre-2018
    rclone_cmd $HOME/Pictures/Memories/2018 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2018
    rclone_cmd $HOME/Pictures/Memories/2019 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2019
    rclone_cmd $HOME/Pictures/Memories/2020 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2020
    # rclone_cmd $HOME/Pictures/Memories/2021 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2021 # does not exist...
    rclone_cmd $HOME/Pictures/Memories/2022 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2022
    rclone_cmd $HOME/Pictures/Memories/2023 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2023
  fi

  rclone_cmd $HOME/Pictures/Memories/2024 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2024
  rclone_cmd $HOME/Pictures/Memories/2025 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2025

  rclone_cmd $HOME/Documents/important "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  if [[ "$DO_PRIVATE_MACHINE" == "true" ]]; then
    rclone_cmd $HOME/Documents/creative "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Documents/creative
  fi

  rclone_cmd $HOME/.ao3statscraper "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml

else

  # See if we're syncing specific dirs then

  if [[ "$PICTURES" == "true" ]]; then
    if [[ "$DO_PRIVATE_MACHINE" == "true" ]]; then
      rclone_cmd $HOME/Pictures/profile_pics "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/profile_pics

      rclone_cmd $HOME/Pictures/Memories/videos "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/videos
      rclone_cmd $HOME/Pictures/Memories/childhood "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/childhood
      rclone_cmd $HOME/Pictures/Memories/Pre-2018 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/Pre-2018
      rclone_cmd $HOME/Pictures/Memories/2018 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2018
      rclone_cmd $HOME/Pictures/Memories/2019 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2019
      rclone_cmd $HOME/Pictures/Memories/2020 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2020
      # rclone_cmd $HOME/Pictures/Memories/2021 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2021 # does not exist...
      rclone_cmd $HOME/Pictures/Memories/2022 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2022
      rclone_cmd $HOME/Pictures/Memories/2023 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2023
    fi

    rclone_cmd $HOME/Pictures/Memories/2024 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2024
    rclone_cmd $HOME/Pictures/Memories/2025 "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2025
  fi

  if [[ "$PERSONAL_DOCS" == "true" ]]; then
    rclone_cmd $HOME/Documents/important "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Documents/important --exclude=**/recovery/** --exclude=recovery/**
  fi

  if [[ "$AO3" == "true" ]]; then
    rclone_cmd $HOME/.ao3statscraper "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
  fi

fi



if [[ "$WORK_ARCHIVE" == "true" ]]; then

  if [[ "$DO_WORK_MACHINE" == "true" ]]; then
    echo "Are you sure you're on the right machine???"
    exit
  fi

  if [[ "$SYNC" == "true" ]]; then
    echo "Are you sure you want to bi-sync?"
    exit
  fi

  rclone_cmd $HOME/Documents/archive_work "$GOOGLE_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/archive_work

fi



if [[ "$DOCS_ARCHIVE" == "true" ]]; then

  if [[ "$DO_WORK_MACHINE" == "true" ]]; then
    echo "Are you sure you're on the right machine???"
    exit
  fi

  if [[ "$SYNC" == "true" ]]; then
    echo "Are you sure you want to bi-sync?"
    exit
  fi

  rclone_cmd $HOME/Documents/archive_docs "$GOOGLE_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/archive_docs

fi



if [[ "$MAIL_ARCHIVE" == "true" ]]; then

  if [[ "$DO_WORK_MACHINE" == "true" ]]; then
    echo "Are you sure you're on the right machine???"
    exit
  fi

  if [[ "$SYNC" == "true" ]]; then
    echo "Are you sure you want to bi-sync?"
    exit
  fi

  rclone_cmd $HOME/Documents/archive_mail "$GOOGLE_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/archive_mail

fi


if [[ "$TESTING" == "true" ]]; then
  # Setting up basics:
  # mkdir -p ~/tmp/testing_sync
  # mkdir -p ~/tmp/testing_sync/dir1
  # mkdir -p ~/tmp/testing_sync/exclude
  # echo "Hello there" > ~/tmp/testing_sync/dir1/file1.txt
  # echo "Hello there" > ~/tmp/testing_sync/dir1/file2.txt
  # echo "Hello there" > ~/tmp/testing_sync/exclude/file1.txt
  # echo "Hello there" > ~/tmp/testing_sync/exclude/file2.txt
  # echo "Hello there" > ~/tmp/testing_sync/file1.txt
  # echo "Hello there" > ~/tmp/testing_sync/file2.txt

  rclone_cmd $HOME/tmp/testing_sync "$GOOGLE_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR" --exclude=exclude/
fi


