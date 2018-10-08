#!/bin/bash


errmsg='
#==================================================================
# Convert scientific papers to a format
# for kindle.
# Usage: 
# convert_to_kindle.sh        : converts all pdf to kindle format
# convert_to_kindle.sh <file> : converts <file> to kindle format
#                               (expects pdf file)
#==================================================================
'

prepdir='prepare'
outputdir='k2pdfopt'

mkdir -p "$prepdir"
mkdir -p "$outputdir"

BRISS="$HOME/Programme/briss-0.9/briss-0.9.jar"



#=============================
function prepare {
#=============================
    # prepare pdf with briss
    # $1: filename
    java -jar "$BRISS" -s "$1" -d "$prepdir"/"$1"
}


#=============================
function convert {
#=============================
    # convert pdf with k2pdfopt
    # $1: filename
    k2pdfopt -dev kp3 -o "$outputdir"/"$1" "$1" -x 
}





#=============================
if [[ "$#" == 0 ]]; then
#=============================

        # do for all pdfs in directory

        # First prepare with briss

        for file in *.pdf; do
            if [[ ! -f "$prepdir"/"$file" ]]; then
                echo "PREPARING" "$file"
                prepare "$file"; 
            fi
        done



        # then convert using k2pdfopt
        
        for file in "$prepdir"/*.pdf; do
            # cut prepare dir out of filename
            fname="${file#"$prepdir"/}"

            if [[ ! -f "$outputdir"/"$fname" ]]; then
                echo "======================================"
                echo "CONVERTING" "$fname"
                echo "======================================"
                convert "$fname"
            fi
        done


#=============================
elif [[ "$#" == 1 ]]; then
#=============================

    # do for given file only
    file="$1"

    if [[ -f "$file" ]]; then

        prepare "$file"
        convert "$file"

    fi

#=============================
else
#=============================

    echo "Not recognizing your command."
    echo -e "$errmsg"

fi

echo "Done"
