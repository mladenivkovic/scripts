#!/bin/bash

# Search for backup files and delete them

# Check for python artefacts
find . -name "._*" -exec rm -rfv {} \;
find . -name ".DS_Store" -exec rm -rfv {} \;
