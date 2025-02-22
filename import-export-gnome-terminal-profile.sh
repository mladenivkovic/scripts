#!/bin/bash
#===================================================
# Export and import Gnome Terminal profiles
#===================================================

# taken from https://github.com/yktoo/yktools/blob/master/gnome-terminal-profile



# Displays usage info and exits
# Parameters:
#   1 - error message (if any)
usage() {
  [ -z "$1" ] || echo "ERROR: $1" >&2
  echo "Usage: $0 import|export <filename>" >&2
  exit 1
}

# Prints a failure message and exits
# Parameters:
#   1 - message
err() {
  echo "ERROR: $1" >&2
  exit 2
}

warning='
 This will load the selected profile into YOUR CURRENT 
 DEFAULT TERMINAL PROFILE. Do you wish to continue? (y/n) '

#------------------------------------------------------
#------------------------------------------------------

# Check variables
mode="$1"
filename="$2"
[[ -z "$mode"     ]] && usage "No mode specified"
[[ -z "$filename" ]] && usage "No filename specified"

# Get default profile ID
profile="$(gsettings get org.gnome.Terminal.ProfilesList default)"
profile="${profile:1:-1}" # remove leading and trailing single quotes

case "$mode" in
    # Export profile
    export)
        dconf dump "/org/gnome/terminal/legacy/profiles:/:$profile/" > "$filename"
        echo "Saved the default profile $profile in $filename"
        ;;

    # Import profile
    import)
        [[ ! -r "$filename" ]] && err "Failed to read from file $filename"

		while true; do
			read -p "$warning" yn
			case $yn in
				[Yy]* ) echo "Program continues."; break;;
				* ) echo "exiting."; exit;;
			esac
		done

        dconf load "/org/gnome/terminal/legacy/profiles:/:$profile/" < "$filename"
        echo "Loaded $filename into the default profile $profile"
        ;;

    *)
        usage "Incorrect mode: $mode"
        ;;
esac
