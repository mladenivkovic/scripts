#!/bin/bash


# Reformat given .tex file (from my glossary project)
# to a .rst file for the sphinx glossary project


f=$1

# change title, add link, change suffix

$PJ/scripts/tex2rst-title.py $f

newname=${f%.tex}.rst

sed -i "s/\`\`/\'/g" $newname
sed -i "s/''/'/g" $newname
sed -i "s/\`/'/g" $newname


while true; do
    grep '\$' "$newname" > /dev/null
    if [ $? = 0 ]; then
        sed -i 's/\$/:math:`/' $newname
        sed -i 's/\$/`/' $newname
    else
        break
    fi
done

sed -i 's/\\begin{equation}/\n.. math::\n/g' $newname
sed -i 's/\\begin{equation\*}/\n.. math::\n/g' $newname
sed -i 's/\\begin{align}/\n.. math::\n/g' $newname
sed -i 's/\\begin{align\*}/\n.. math::\n/g' $newname
sed -i 's/\\end{equation}/\n/g' $newname
sed -i 's/\\end{equation\*}/\n/g' $newname
sed -i 's/\\end{align}/\n/g' $newname
sed -i 's/\\end{align\*}/\n/g' $newname

sed -i 's/\\begin{itemize}/\n/g' $newname
sed -i 's/\\end{itemize}/\n/g' $newname
sed -i 's/^\s*\\item/-/g' $newname

# sed -i 's/\\msol/M_{\\odot}/g' $newname
# sed -i 's/\\CONST/const./g' $newname
