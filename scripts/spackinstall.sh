#!/bin/bash

#----------------
# cleanup
#----------------

# module purge
# spack uninstall --all

# spack install -y lmod %gcc@7.5.0

# for compiler in clang@6.0.0; do
# for compiler in gcc@7.5.0 ; do
# for compiler in gcc@8.4.0 ; do
# for compiler in gcc@9.2.0 ; do
for compiler in gcc@10.2.0 ; do

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

spack install -y openmpi %"$compiler"
# spack install -y openmpi cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
# spack install -y mpich   cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
# exit


#-----------------------
# individual packages
#-----------------------



# without dependencies
#~~~~~~~~~~~~~~~~~~~~~~~~~~

for pack in jemalloc gsl metis; do
    spack install -y $pack %$compiler
done;

spack install -y hdf5 +cxx +fortran +threadsafe %$compiler
spack install -y fftw@3.3.8 +openmp %$compiler
spack install -y fftw@2.1.5 +openmp %$compiler



# with dependencies
#~~~~~~~~~~~~~~~~~~~~~~~~~~

# for dep in openmpi mpich; do
for dep in openmpi; do

    for pack in parmetis; do
        spack install -y $pack ^$dep %$compiler
    done;

    # +openmp: install with openmp too
    # ^$dep needs to be after +openmp, otherwise all other
    # specifications are taken to be for the dependency
    spack install -y hdf5 +cxx +fortran +threadsafe +mpi ^$dep %$compiler 
    spack install -y grackle@3.2 ^hdf5 ^$dep %$compiler
done;


done;

spack module tcl rm
spack module lmod refresh --delete-tree -y
