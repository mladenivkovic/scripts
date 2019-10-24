#!/bin/bash

#----------------
# cleanup
#----------------

# module purge
# spack uninstall --all

spack install -y lmod %gcc@8.3.0
# spack install -y gcc@8.3.0 %gcc@7.4.0

# for compiler in clang@6.0.0 clang@8.0.0-3; do
# for compiler in gcc@7.4.0 gcc@8.2.0 clang@6.0.0-1ubuntu2 clang@8.0.0-3~ubuntu18.04.1; do
# for compiler in gcc@7.4.0 gcc@8.2.0 ; do
for compiler in gcc@8.3.0 ; do

# if [[ $compiler == "clang"* ]]; then
#     echo got clang
#     CFLAGS=-fPIC
#     CXXFLAGS=-fPIC
#     FFLAGS=-fPIC
# else
#     CFLAGS=
#     CXXFLAGS=
#     FFLAGS=
# fi

#--------------------
# core dependencies
#--------------------

# spack install -y openmpi cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
spack install -y mpich   cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
exit


#-----------------------
# individual packages
#-----------------------


# with dependencies

for dep in openmpi mpich; do

    for pack in parmetis; do
        spack install -y $pack ^$dep %$compiler
    done;

    # +openmp: install with openmp too
    # ^$dep needs to be after +openmp, otherwise all other
    # specifications are taken to be for the dependency
    spack install -y fftw@3.3.8 +openmp %$compiler ^$dep
    spack install -y fftw@2.1.5 +openmp %$compiler ^$dep
done;


# without

for pack in jemalloc gsl metis; do
    spack install -y $pack %$compiler
done;

spack install -y hdf5 +cxx +fortran +threadsafe %$compiler

done;
