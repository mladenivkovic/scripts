#!/bin/bash

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 60
sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-8 60

sudo update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-8 60
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-8 60
sudo update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-8 60
sudo update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-8 60
sudo update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-8 60

echo "To do it manually, call update-alternatives --config gcc"
echo "Don't forget to update your environment flags in the .bashrc!"
