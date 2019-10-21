#!/bin/bash

# version=8
version=7

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"$version" 60
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-"$version" 60
sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-"$version" 60

sudo update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-"$version" 60
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-"$version" 60
sudo update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-"$version" 60
sudo update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-"$version" 60
sudo update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-"$version" 60

echo "To do it manually, call update-alternatives --config gcc"
echo "Don't forget to update your environment flags in the .bashrc!"
