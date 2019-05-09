#!/bin/bash

#=================================================
# Change some tex shorthands to clean rst.
#=================================================

f=$1

$PJ/scripts/tex-rst/untex-title.py $f

sed -i "s/\`\`/\'/g" $f
sed -i "s/''/'/g" $f
# sed -i "s/\`/'/g" $f


while true; do
    grep '\$' "$f" > /dev/null
    if [ $? = 0 ]; then
        sed -i 's/\$/:math:`/' $f
        sed -i 's/\$/`/' $f
    else
        break
    fi
done

sed -i 's/\\begin{equation}/\n.. math::\n/g' $f
sed -i 's/\\begin{equation\*}/\n.. math::\n/g' $f
sed -i 's/\\begin{align}/\n.. math::\n/g' $f
sed -i 's/\\begin{align\*}/\n.. math::\n/g' $f
sed -i 's/\\end{equation}/\n/g' $f
sed -i 's/\\end{equation\*}/\n/g' $f
sed -i 's/\\end{align}/\n/g' $f
sed -i 's/\\end{align\*}/\n/g' $f

sed -i 's/\\begin{itemize}/\n/g' $f
sed -i 's/\\end{itemize}/\n/g' $f
sed -i 's/^\s*\\item/-/g' $f

# sed -i 's/\\msol/M_{\\odot}/g' $f
# sed -i 's/\\CONST/const./g' $f
