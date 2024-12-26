#!/bin/bash

#=======================================
# Update glossary contents.
#=======================================


scrpath=$PJ/scripts/tex-rst


#------------------------------------------
# first check and convert all tex files
#------------------------------------------

# only do if there is a file.
echo converting tex files
ls *.tex > /dev/null 2>&1 && for f in $PWD/*.tex; do
    $scrpath/tex2rst.sh $f
done


#-------------------------------------------------------------
# reformat files that have been changed since the last check
#-------------------------------------------------------------

echo reformatting rst files to remove tex remnants
for f in *.rst; do
    $scrpath/untex.sh $f
done


#------------------------------------
# Add new files to contents
#------------------------------------

echo checking for new files to add to table of contents
$scrpath/update-glossary-contents.py

