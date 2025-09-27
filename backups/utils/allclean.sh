#!/bin/bash

# Search for generated/compiled files and clean them up.



texclean() {
  CWD=`pwd`
  FILE=$1
  DIR=`dirname "$FILE"`
  cd "$CWD"/"$DIR"
  echo "=== TEX CLEAN $DIR"
  rm -fv *.aux *.bbl *.log *.out *.gz *.toc *.blg *.lot *.lof *.run.xml *.snm *.nav *-blx.bib
  cd "$CWD"
}

# need to export the function so that sub-shells will recognize it.
# can't use `find` to run it otherwise.
export -f texclean

# -exec needs to be terminated with an escaped \; otherwise the shell interprets it as line end.
find . -name "*.tex" -exec bash -c 'texclean "$0"' {} \;



# Check for makefiles
CWD=`pwd`
for MKFILE in `find . -name "Makefile"`; do
  MK_DIR=`dirname "$MKFILE"`
  cd "$MK_DIR"

  # Check that we don't have tex files in this directory. If so, running a
  # make clean could delete the pdf, which is not what we want.
  if [[ `find -maxdepth 1 -name "*.tex"` ]]; then
    cd "$CWD"
    continue
  fi

  echo "=== MAKE CLEAN $MK_DIR"
  make distclean || make clean

  cd "$CWD"
done



# Check for python artefacts
find . -name "__pycache__" -exec rm -rfv {} \;
find . -name "*.pyc" -exec rm -rfv {} \;


# check for open office lock files
find . -name ".~lock.*" -exec rm -rfv {} \;


