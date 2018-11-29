#!/bin/bash

# Download, unzip and move built html files to the right directory.
# This script is either to be called by a cronjob or to be used by hand.


wd=`pwd`
cd /tmp

for page in debugging instructions; do
    rm artifacts.zip # in case there is already one, curl will fail
    curl -O -J -L https://gitlab.com/mivkov/notes/-/jobs/artifacts/master/download?job=$page 
    unzip artifacts.zip
    if [[ $? -ne 0 ]]; then continue; fi;
    cp -r public/$page/* /www/people/ivkovic/public/$page/
    rm -r public/
done

cd $wd
