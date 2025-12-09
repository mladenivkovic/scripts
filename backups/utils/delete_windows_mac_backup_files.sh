#!/bin/bash

# Search for backup files and delete them
find . -name "._*" -exec rm -rfv {} \;
find . -name ".DS_Store" -exec rm -rfv {} \;
