#!/bin/bash

#=================================================
# Change some tex shorthands to clean rst.
#=================================================

f=$1

$PJ/scripts/tex-rst/untex-title.py $f



cat $f | \

    sed "s/\`\`/\'/g" | \
    sed "s/''/'/g" | \
    sed 's/\$\([^$]*\)\$/:math:`\1`/g' | \
    sed -E "s/:ref:'(.*)'/:ref:\`\1\`/g" | \


    sed 's/\\begin{equation}/\n.. math::\n/g' | \
    sed 's/\\begin{equation\*}/\n.. math::\n/g' | \
    sed 's/\\begin{align}/\n.. math::\n/g' | \
    sed 's/\\begin{align\*}/\n.. math::\n/g' | \
    sed 's/\\end{equation}/\n/g' | \
    sed 's/\\end{equation\*}/\n/g' | \
    sed 's/\\end{align}/\n/g' | \
    sed 's/\\end{align\*}/\n/g' | \

    sed 's/\\begin{itemize}/\n/g' | \
    sed 's/\\end{itemize}/\n/g' | \
    sed 's/^\s*\\item/-/g' \
    > $f

    # sed 's/\\msol/M_{\\odot}/g' | \
    # sed 's/\\CONST/const./g' | \


