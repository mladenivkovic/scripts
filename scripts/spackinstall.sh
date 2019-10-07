#!/bin/bash

#----------------
# cleanup
#----------------

# module purge
# spack uninstall --all


#--------------------
# core dependencies
#--------------------

# spack install lmod
# spack install openmpi@3.0.3
# spack install mpich


#-----------------------
# individual packages
#-----------------------


# with dependencies

for dep in openmpi mpich; do

    for pack in parmetis; do
        spack install $pack ^$dep
    done;

    # +openmp: install with openmp too
    # ^$dep needs to be after +openmp, otherwise all other
    # specifications are taken to be for the dependency
    spack install fftw@3.3.8 +openmp ^$dep
    spack install fftw@2.1.5 +openmp ^$dep
done;


# without

# for pack in jemalloc gsl metis; do
#     spack install $pack
# done;

spack install hdf5 +cxx +fortran +threadsafe
