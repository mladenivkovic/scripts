#!/bin/bash

#----------------
# cleanup
#----------------

# Re-installing?
#----------------------
# module purge
# spack uninstall --all

# my native compiler
native="gcc@9.3.0"

# First install lmod
#----------------------
# spack install -y lmod %"$native"

# make modules work
# source ~/.bashrc_modules
# exit
# make sure you configured everything right before continuing with next steps


# install compilers
#----------------------
# for compiler in gcc@10.2.0 gcc@11.2.0; do
#     spack install -y "$compiler" %"$native"
#
#     # make sure spack knows about its compilers
#     module purge
#     compiler_module=`echo "$compiler" | sed 's:@:/:'`
#     module load "$compiler_module"
#     spack compiler add
#     module purge
# done
# spack module tcl rm # I only want lmod files, no need to show me modules twice
# spack module lmod refresh --delete-tree -y # refresh lmod stuff
# make sure you configured everything right before continuing with next steps



# get all packages for all compilers
#------------------------------------------
for compiler in "$native" gcc@10.2.0 gcc@11.2.0; do

    module purge
    if [ "$compiler" == "$native" ]; then
        echo "skipping native compiler module:" $native
        compiler_module=""
    else
        compiler_module=`echo "$compiler" | sed 's:@:/:'`
        module load "$compiler_module"
    fi


    # clang needs extra flags
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
    # spack install -y mpich   cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
    # exit


    #-----------------------
    # individual packages
    #-----------------------

    # without dependencies
    #~~~~~~~~~~~~~~~~~~~~~~~~~~

    for pack in jemalloc gsl metis intel-tbb openblas cblas; do
        spack install -y $pack %$compiler
    done;

    spack install -y fftw@3.3.8 +openmp %$compiler
    spack install -y fftw@2.1.5 +openmp %$compiler
    spack install --reuse -y hdf5@1.10.7 +cxx +fortran +threadsafe -mpi +java %$compiler
    # spack install -y grackle@3.2 ^hdf5 %$compiler #can't do grackle without MPI



    # with dependencies
    #~~~~~~~~~~~~~~~~~~~~~~~~~~

    # for dep in openmpi mpich; do
    for dep in openmpi; do
        module load $dep

        for pack in parmetis; do
            spack install -y $pack ^$dep %$compiler
        done;

        # +openmp: install with openmp too
        # ^$dep needs to be after +openmp, otherwise all other
        # specifications are taken to be for the dependency
        spack install --reuse -y hdf5@1.10.7 +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
        module load hdf5
        spack install --reuse -y grackle@3.2 ^hdf5 ^$dep %$compiler
        # note: grackle-float is a fake package I made.
        # If you don't want to use this, use +float variant.
        spack install --reuse -y grackle-float@3.2 ^hdf5 ^$dep %$compiler
    done;

done;

spack module tcl rm # I only want lmod files, no need to show me modules twice
spack module lmod refresh --delete-tree -y # refresh lmod stuff
