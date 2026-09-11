#!/bin/bash

# INSTRUCTIONS
# ===============
# 1) First configure proton drive: https://rclone.org/protondrive/
# 2) To be on the safe side, create all dirs below manually first,
#    i.e. PROTON_SYNC_ROOT_DIR, REMOTE_ARCHIVE_ROOT_DIR,
#    REMOTE_SYNC_ROOT_DIR, REMOTE_SYNC_BACKUP_DIR
#
#    You can also try running this script with the --mkdir flag.
# 3) When running for the first time, run with --resync flag


# as set up with `rclone config`
PROTON_DRIVE_REMOTE_NAME=protondrive_remote
# root dir on proton remote where to place syncs
REMOTE_SYNC_ROOT_DIR=sync
# root dir on proton remote where to place archives
REMOTE_ARCHIVE_ROOT_DIR=archive
# backup directory on remote for syncing process
REMOTE_SYNC_BACKUP_DIR=sync_backup
# backup directory on remote for syncing process
REMOTE_ARCHIVE_BACKUP_DIR=archive_backup



ERRMSG='
rclone_proton_drive.sh - sync local dirs with Proton Drive.

Usage:

 rclone_proton_drive.sh direction [options]

 direction:

  -u, --up --push       Push local changes to drive (copy, not sync)
  -d, --down, --pull    Pull changes from drive to local machine (copy, not sync)
  --pushsync            Push local changes to drive via sync (overwrite drive state with local state)
  --pullsync            Pull changes from drive via sync (overwrite local state with drive)
  -b, --sync, --bisync  Sync bi-directionally

 options:

  (selection of) directories to sync:

    -a, --all           Sync all (hardcoded) dirs. Equivalent to --work --personal --storage
    -w, --work          Sync (all) work dirs. Equivalent to --workdocs --zotero
    -p, --personal      Sync (all) private dirs. Equivalent to --docs --pics --ao3
    --docs              Sync private documents
    --pics, --pictures  Sync pictures
    --ao3               Sync ao3 stuff
    --code              Sync coding documents
    --workdocs          Sync work documents
    --zotero            Sync zotero dir

    --storage           Sync storage dir. This includes --archive and some other dirs not otherwise reachable by a flag
    --archive           Sync (all) archive dirs. Equivalent to --docs-archive --work-archive --mail-archive
    --docs-archive      Sync archive document dirs (not included in -w, -a, -p flags)
    --work-archive      Sync work archive dirs (not included in -w, -a, -p flags)
    --mail-archive      Sync mail archive dirs (not included in -w, -a, -p flags)

  rclone flags:

    --resync            Pass the --resync flag to rclone. Only works for --sync direction
    --force             Pass the --force flag to rclone. Only for bisync direction
    --dry-run           Pass the --force flag to rclone. Only for bisync direction

  Additional flags:

    -h, --help          Print help and exit.
    --mkdir             Use rclone to create necessary root directories on remote and exit.
'


PUSH="false"
PUSHSYNC="false"
PULL="false"
PULLSYNC="false"
SYNC="false"

ALL="false"
WORK="false"
PERSONAL="false"
PERSONAL_DOCS="false"
CODE="false"
PICTURES="false"
AO3="false"
WORKDOCS="false"
ZOTERO="false"
STORAGE="false"
ARCHIVE="false"
DOCS_ARCHIVE="false"
WORK_ARCHIVE="false"
MAIL_ARCHIVE="false"

RESYNC="false"
FORCE="false"
DRYRUN="false"
MKDIR="false"



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

      --docs)
        PERSONAL_DOCS="true"
      ;;

      --code)
        CODE="true"
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

      --archive)
        ARCHIVE="true"
      ;;

      --mail-archive)
        MAIL_ARCHIVE="true"
      ;;

      --docs-archive)
        DOCS_ARCHIVE="true"
      ;;

      --work-archive)
        WORK_ARCHIVE="true"
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

      --mkdir )
        MKDIR="true"
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



if [[ "$PUSH" == "false" && "$PULL" == "false" && "$SYNC" == "false" && "$PUSHSYNC" == "false" && "$PULLSYNC" == "false" && "$MKDIR" == "false" ]]; then
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



# Check for hostname.
# --------------------
HOST=`hostname`
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"
HOSTNAME_LENOVO_LEGION="mivkov-lenovo-legion"
HOSTNAME_HP_PROBOOK="mivkov-hpprobook"
HOSTNAME_ASUS_ZENBOOK="mivkov-asuszenbook14"

DO_PRIVATE_MACHINE="false"
DO_WORK_MACHINE="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD | $HOSTNAME_LENOVO_LEGION | $HOSTNAME_ASUS_ZENBOOK)
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




if [[ "$MKDIR" == "true" ]]; then
  rclone mkdir "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR";
  rclone mkdir "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_ARCHIVE_ROOT_DIR";
  rclone mkdir "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_BACKUP_DIR";
  rclone mkdir "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_ARCHIVE_BACKUP_DIR";
  exit
fi



if [[ "$ALL" == "true" ]]; then
  WORK="true"
  PERSONAL="true"
  STORAGE="true"
fi

if [[ "$WORK" == "true" ]]; then
  WORKDOCS="true"
  ZOTERO="true"
fi

if [[ "$PERSONAL" == "true" ]]; then
  PERSONAL_DOCS="true"
  PICTURES="true"
  AO3="true"
fi

if [[ "$ARCHIVE" == "true" ]]; then
  DOCS_ARCHIVE="true"
  WORK_ARCHIVE="true"
  MAIL_ARCHIVE="true"
fi



# Trying to hack this somewhat: Run a useless ls with an updated token,
# hoping that it'll keep the token updated
# Do this before defining rclone_cmd to get TWOFATOKEN
while true; do
  read -p "Enter 2FA code: " TWOFATOKEN
  break
done

rclone lsd "$PROTON_DRIVE_REMOTE_NAME":  --protondrive-2fa=$TWOFATOKEN > /dev/null




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

    # To be on the safe side, make directories in proton drive manually first
    # via browser.
    # You should be able to run
    #   `rclone mkdir "$PROTON_DRIVE_REMOTE_NAME":dirname`
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

  # determine backup dir on the drive.
  REMOTE_BACKUP_DIR="none"
  PREFIX="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"
  if [[ "$SRC" == "$PREFIX"* ]]; then
    REMOTE_BACKUP_DIR="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_BACKUP_DIR""${SRC#$PREFIX}"
  elif [[ "$DEST" == "$PREFIX"* ]]; then
    REMOTE_BACKUP_DIR="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_BACKUP_DIR""${DEST#$PREFIX}"
  fi
  PREFIX="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_ARCHIVE_ROOT_DIR"
  if [[ "$SRC" == "$PREFIX"* ]]; then
    REMOTE_BACKUP_DIR="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_ARCHIVE_BACKUP_DIR""${SRC#$PREFIX}"
  elif [[ "$DEST" == "$PREFIX"* ]]; then
    REMOTE_BACKUP_DIR="$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_ARCHIVE_BACKUP_DIR""${DEST#$PREFIX}"
  fi

  if [[ "$REMOTE_BACKUP_DIR" == "none" ]]; then
    echo "Something went wrong when determining remote backup dir."
    echo "SRC:" $SRC
    echo "DEST:" $DEST
    echo "PROTON_DRIVE_REMOTE_NAME": $PROTON_DRIVE_REMOTE_NAME
    echo "REMOTE_SYNC_ROOT_DIR": $REMOTE_SYNC_ROOT_DIR
    echo "REMOTE_ARCHIVE_ROOT_DIR": $REMOTE_ARCHIVE_ROOT_DIR
    exit 1
  fi


  EXTRA_FLAGS=""
  EXTRA_FLAGS="$EXTRA_FLAGS"" -l -v"
  EXTRA_FLAGS="$EXTRA_FLAGS"" --protondrive-replace-existing-draft=true"
  EXTRA_FLAGS="$EXTRA_FLAGS"" --protondrive-2fa=$TWOFATOKEN"
  # EXTRA_FLAGS="$EXTRA_FLAGS"" --backup-dir ""$REMOTE_BACKUP_DIR"

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
  echo "  PROTON_DRIVE_REMOTE_NAME: "$PROTON_DRIVE_REMOTE_NAME
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



if [[ "$WORKDOCS" == "true" ]]; then
  rclone_cmd $HOME/Work "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Work --exclude=**/.git/** --exclude=.git/**
fi

if [[ "$ZOTERO" == "true" ]]; then
  rclone_cmd $HOME/Zotero "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Zotero
fi


if [[ "$PICTURES" == "true" ]]; then
  if [[ "$DO_PRIVATE_MACHINE" == "true" ]]; then
    rclone_cmd $HOME/Pictures/profile_pics "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/profile_pics
    rclone_cmd $HOME/Pictures/screenshots_keep "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/screenshots_keep

    rclone_cmd $HOME/Pictures/Memories/videos "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/videos
    rclone_cmd $HOME/Pictures/Memories/childhood "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/childhood
    rclone_cmd $HOME/Pictures/Memories/Pre-2018 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/Pre-2018
    rclone_cmd $HOME/Pictures/Memories/2018 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2018
    rclone_cmd $HOME/Pictures/Memories/2019 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2019
    rclone_cmd $HOME/Pictures/Memories/2020 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2020
    # rclone_cmd $HOME/Pictures/Memories/2021 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2021 # does not exist...
    rclone_cmd $HOME/Pictures/Memories/2022 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2022
    rclone_cmd $HOME/Pictures/Memories/2023 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2023
    rclone_cmd $HOME/Pictures/Memories/2024 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2024
    rclone_cmd $HOME/Pictures/Memories/2025 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2025
  fi

  rclone_cmd $HOME/Pictures/Memories/2026 "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Pictures/Memories/2026
fi


if [[ "$PERSONAL_DOCS" == "true" ]]; then

  if [[ "$DO_PRIVATE_MACHINE" == "true" ]]; then
    rclone_cmd $HOME/Documents "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Documents --exclude=**/.git/** --exclude=**/.git
  else
    rclone_cmd $HOME/Documents/important "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/Documents/important
    # --exclude=**/recovery/** --exclude=recovery/**
  fi

fi

if [[ "$AO3" == "true" ]]; then
  rclone_cmd $HOME/.ao3statscraper "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml --exclude=ao3statscraper.session.pkl
fi


if [[ "$CODE" == "true" ]]; then
  rclone_cmd $HOME/Documents/creative "$PROTON_DRIVE_REMOTE_NAME":"$REMOTE_SYNC_ROOT_DIR"/coding --exclude=**/.git/** --exclude=**/.git
fi


if [[ "$STORAGE" == "true" ]]; then

  if [[ "$WORK_ARCHIVE" == "true" ]]; then
    echo "Syncing both --storage and --work-archive. Are you sure you want to do this?"
    exit
  fi
  if [[ "$DOCS_ARCHIVE" == "true" ]]; then
    echo "Syncing both --storage and --docs-archive. Are you sure you want to do this?"
    exit
  fi
  if [[ "$MAIL_ARCHIVE" == "true" ]]; then
    echo "Syncing both --storage and --mail-archive. Are you sure you want to do this?"
    exit
  fi
  if [[ "$DO_WORK_MACHINE" == "true" ]]; then
    echo "Syncing storage... Are you sure you're on the right machine???"
    exit
  fi

  rclone_cmd $HOME/storage "$PROTON_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/storage --exclude=**/.git.** --exclude=**/.git

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

  rclone_cmd $HOME/storage/archive_work "$PROTON_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/storage/archive_work --exclude=**/.git.** --exclude=**/.git

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

  rclone_cmd $HOME/storage/archive_docs "$PROTON_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/storage/archive_docs --exclude=**/.git.** --exclude=**/.git

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

  rclone_cmd $HOME/storage/archive_mail "$PROTON_DRIVE_REMOTE_NAME":$REMOTE_ARCHIVE_ROOT_DIR/storage/archive_mail

fi


