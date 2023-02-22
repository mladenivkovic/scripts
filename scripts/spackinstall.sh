#!/bin/bash

#----------------
# cleanup
#----------------

# Re-installing?
#----------------------
# module purge
# spack uninstall --all

# my native compiler
native="gcc@12.1.0"

# First install lmod
#----------------------
spack install -y lmod %"$native"

# make modules work
# source ~/.bashrc_modules
# exit

# make sure you configured everything right before continuing with next steps
# Note: lmod may have some issues if the 'Core' directory doesn't exist yet.
# that directory gets created once a hierarchy exists, i.e. once you have
# an MPI installed. If you're not at this point yet, don't panic.
# Note: Make sure you set up the 'core compilers' correctly in 
# .spack/modules.yaml. Otherwise, lmod will not find any module files to add.


# install compilers
#----------------------
# for compiler in gcc@10.2.0 gcc@11.2.0 gcc@12.1.0; do
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
# exit
# make sure you configured everything right before continuing with next steps



# get all packages for all compilers
#------------------------------------------
# for compiler in "$native" gcc@10.2.0 gcc@11.2.0 gcc@12.1.0; do
# for compiler in "gcc@11.2.0"; do
# for compiler in "gcc@12.1.0" "gcc@10.2.0"; do
for compiler in "$native"; do

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
 
    spack module tcl rm # I only want lmod files, no need to show me modules twice
    spack module lmod refresh --delete-tree -y # refresh lmod stuff


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
    spack install --reuse -y hdf5@1.12.2 +cxx +fortran +threadsafe -mpi +java %$compiler
    # spack install -y grackle@3.2 ^hdf5 %$compiler #can't do grackle without MPI
    spack install -y gdb@12.1 %$compiler
    spack install -y valgrind %$compiler


    # with dependencies
    #~~~~~~~~~~~~~~~~~~~~~~~~~~

    # for dep in openmpi mpich; do
    for dep in openmpi; do
        module load $dep

        packages without any further specifications
        for pack in parmetis; do
            spack install -y $pack ^$dep %$compiler
        done;

        # +openmp: install with openmp too
        # ^$dep needs to be after +openmp, otherwise all other
        # specifications are taken to be for the dependency
        spack install --reuse -y hdf5@1.12.2 +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
        # spack install --reuse -y hdf5-mladen@1.10.7 +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
        module load hdf5/1.13.1
        spack install --reuse -y grackle@3.2 ^hdf5@1.13.1 ^$dep %$compiler
        # note: grackle-float is a fake package I made.
        # If you don't want to use this, use +float variant.
        # spack install --reuse -y grackle-float@3.2 ^hdf5@1.13.1 ^$dep %$compiler
        spack install --reuse -y grackle-float@3.2 ^hdf5@1.13.1 ^$dep %$compiler
        spack install --reuse -y sundials@5.1.0 ^$dep %$compiler
    done;

done;

spack module tcl rm # I only want lmod files, no need to show me modules twice
spack module lmod refresh --delete-tree -y # refresh lmod stuff
