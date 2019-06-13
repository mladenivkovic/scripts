#!/bin/bash


#========================================================
# Reformat given .tex file (from my glossary project)
# to a .rst file for the sphinx glossary project
#========================================================


f=$1

# change title, add link anchor, change suffix
# this copies the .tex file to same_name.rst
$PJ/scripts/tex-rst/tex2rst-title.py $f


newname=${f%.tex}.rst

if [ "$newname" = *".rst.rst" ]; then
    newname=${newname%.rst.rst}.rst
fi


cat $newname | \
    sed "s/\`\`/\'/g" | \
    sed "s/''/'/g" | \
    sed "s/\`/'/g" | \
    sed 's/\\\\/\n/g' | \
    sed 's/\$\([^$]*\)\$/:math:`\1`/g' | \
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
    sed 's/^\s*\\item/-/g' | \

    # sed 's/\\msol/M_{\\odot}/g' | \
    # sed 's/\\CONST/const./g' | \

    # replace errorneous :ref:'<blabla>' with :ref:`<blabla>`
    sed -E "s/:ref:'(.*)'/:ref:\`\1\`/g" > foo

mv foo $newname
