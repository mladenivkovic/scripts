#!/bin/bash

# https://blog.otterlord.dev/posts/proton-drive-rclone/
# https://rclone.org/

# To be on the safe side, make directories in proton drive manually first via browser
# You should be able to run `rclone mkdir protondrive_remote:dirname` too.

# rclone sync -l -v $HOME/Work protondrive_remote:sync/Work
# rclone sync -l -v $HOME/Zotero protondrive_remote:sync/Zotero
# rclone sync -l -v $HOME/calibre_library protondrive_remote:sync/calibre_library

# Pictures/Memories videos childhood Pre-2018 2018 2019 2020 2021 2022
# rclone sync -l -v $HOME/Pictures/Memories/2023 protondrive_remote:sync/Pictures/Memories/2023
# rclone sync -l -v $HOME/Pictures/Memories/2024 protondrive_remote:sync/Pictures/Memories/2024
# rclone sync -l -v $HOME/Pictures/Memories/2025 protondrive_remote:sync/Pictures/Memories/2025

rclone sync -l -v $HOME/Documents/Wichtige_Dokumente protondrive_remote:sync/Documents/Wichtige_Dokumente --exclude=Wichtige_Dokumente/recovery
# rclone sync -l -v $HOME/.ao3statscraper protondrive_remote:sync/.ao3statscraper --exclude=ao3statscraper.conf.pkl --exclude=ao3statscraper.conf.yml
