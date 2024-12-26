#!/bin/bash

# run the commands for test files, generate html and open it.


make clean
rm src/tex_file.rst src/rst_file.rst
cp src/backup_tex_file src/tex_file.txt
cp src/backup_rst_file src/rst_file.rst

../tex2rst.sh src/tex_file.tex

../untex.sh src/rst_file.rst

make html

firefox build/html/index.html
