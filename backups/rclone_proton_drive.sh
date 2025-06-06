#!/bin/bash

ALL="false"
WORK="false"
PERSONAL="true"

HOST=`hostname`
HOSTNAME_LENOVO_THINKPAD="mladen-lenovoThinkpad"

DO_LENOVO_THINKPAD="false"
DO_HP="false"

case $HOST in
  $HOSTNAME_LENOVO_THINKPAD )
    DO_LENOVO_THINKPAD="true"
  ;;
  *)
    echo "Unrecognized hostname. Adapt script before you break things."
    echo "hostname=$HOST"
    exit 1
  ;;
esac


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
# rclone_cmd="rclone bisync -l -v --checksum --resync --resync-mode=newer --dry-run"
rclone_cmd="rclone bisync -l -v --checksum --resync --resync-mode=newer"
# --protondrive-replace-existing-draft=true

if [[ "$WORK" == "true" || "$ALL" == "true" ]]; then
  $rclone_cmd $HOME/Work protondrive_remote:sync/Work
  $rclone_cmd $HOME/Zotero protondrive_remote:sync/Zotero
  $rclone_cmd $HOME/calibre_library protondrive_remote:sync/calibre_library
fi


if [[ "$PERSONAL" == "true" || "$ALL" == "true" ]]; then

  if [[ "$DO_LENOVO_THINKPAD" == "true" ]]; then
    $rclone_cmd $HOME/Pictures/Memories/videos protondrive_remote:sync/Pictures/Memories/videos
    $rclone_cmd $HOME/Pictures/Memories/childhood protondrive_remote:sync/Pictures/Memories/childhood
    $rclone_cmd $HOME/Pictures/Memories/Pre-2018 protondrive_remote:sync/Pictures/Memories/Pre-2018
    $rclone_cmd $HOME/Pictures/Memories/2018 protondrive_remote:sync/Pictures/Memories/2018
    $rclone_cmd $HOME/Pictures/Memories/2019 protondrive_remote:sync/Pictures/Memories/2019
    $rclone_cmd $HOME/Pictures/Memories/2020 protondrive_remote:sync/Pictures/Memories/2020
    $rclone_cmd $HOME/Pictures/Memories/2021 protondrive_remote:sync/Pictures/Memories/2021
    # $rclone_cmd $HOME/Pictures/Memories/2022 protondrive_remote:sync/Pictures/Memories/2022 # does not exist...
    $rclone_cmd $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
  fi

  $rclone_cmd $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
  $rclone_cmd $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025

  $rclone_cmd $HOME/Documents/important protondrive_remote:sync/Documents/important --exclude=important/recovery
  $rclone_cmd $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
fi
