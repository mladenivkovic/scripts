#!/bin/bash

# module purge
# spack uninstall --all
spack install lmod
spack install openmpi@3.0.3
# spack install mpich

for dep in openmpi; do
    for pack in fftw hdf5 parmetis; do
        spack install $pack ^$dep
    done;
done;

# for pack in jemalloc gsl metis; do
#     spack install $pack
# done;

