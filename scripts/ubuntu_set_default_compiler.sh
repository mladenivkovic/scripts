#!/bin/bash

# version=8
version=7

val=60
# val=30


for bin in gcc g++ gfortran gcc-ar gcc-nm gcov gcov-dump gcov-tool cpp; do
    sudo update-alternatives --install /usr/bin/"$bin" "$bin" /usr/bin/"$bin"-"$version" "$val"
done


# set in auto mode
for bin in gcc g++ gfortran gcc-ar gcc-nm gcov gcov-dump gcov-tool cpp c++ cc f77 f90; do
    sudo update-alternatives --auto $bin
done

echo
echo "Message from your own script:"
echo "To do it manually, call update-alternatives --config gcc"
echo "Don't forget to update your environment flags in the .bashrc!"
