#!/usr/bin/env bash

# https://askubuntu.com/questions/674976/check-for-and-remove-unused-ppas

#-------------------------------------------
# lists manually added PPAs
# --delete option removes all of them
# which have only 1 package installed
# NOT RECOMMENDED TO DO THO.
#-------------------------------------------

for f in /etc/apt/sources.list.d/*.list; do
    grep -Po "(?<=^deb\s).*?(?=#|$)" "$f" | while read -r ENTRY ; do
    echo "ENTRY: $ENTRY"
        HOST=$(cut -d/ -f3 <<< "$ENTRY")

        if [ "ppa.launchpad.net" = "$HOST" ]; then
          USER=$(cut -d/ -f4 <<< "$ENTRY")
          PPA=$(cut -d/ -f5 <<< "$ENTRY")
          packageCount=$(awk '$1=="Package:" {if (a[$2]++ == 0) {system("dpkg -l "$2)}}' /var/lib/apt/lists/*"$USER"*"$PPA"*Packages 2>/dev/null | awk '/^ii/' | wc -l)
          echo "PPA: ppa:$USER/$PPA"
          echo "FILENAME: $f"
          echo "$packageCount package(s) installed"
          if [ "$packageCount" -eq 0 ] && [ "$1" == "--delete" ]; then
            sudo rm "$f" && echo "$f deleted"
          fi
          echo
        else 
          USER=$(cut -d/ -f3 <<< "$ENTRY")
          PPA=$(cut -d/ -f4 <<< "$ENTRY")
          packageCount=$(awk '$1=="Package:" {if (a[$2]++ == 0) {system("dpkg -l "$2)}}' /var/lib/apt/lists/*"$USER"*Packages 2>/dev/null | awk '/^ii/' | wc -l)
          echo "REPOSITORY: $USER/$PPA"
          echo "FILENAME: $f"
          echo "$packageCount package(s) installed"
          if [ "$packageCount" -eq 0 ] && [ "$1" == "--delete" ]; then
            sudo rm "$f" && echo "$f deleted" 
          fi
          echo
        fi
    done
done
