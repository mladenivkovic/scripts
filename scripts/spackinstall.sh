#!/bin/bash

#======================================================
# SETUP
#======================================================

# my native compiler
native_compiler="gcc@12.1.0"

MYHDF5="hdf5@1.12.2"

# list of compilers you want to 
declare -a compiler_list 
compiler_list=($native_compiler)
# compiler_list+=(gcc@11.3.0)

declare -a MPI_list 
MPI_list=(openmpi)
# MPI_list+=(mpich)



#-----------------------------------------
spack_string_to_module_string() {
#-----------------------------------------
    # convert spack requirement string lib@version to module
    # like string lib/version
    # NOTE: this heavily depends on your module setup.

    spackstr=$1
    modulestr=${spackstr/@/\/}
    echo $modulestr
}



#======================================================
uninstall_everything() {
#======================================================

    # Re-installing?
    #----------------------

    module purge
    spack uninstall --all
}



#======================================================
install_modules() {
#======================================================

    # First install lmod
    #----------------------
    spack install -y lmod %"$native_compiler"

    # make modules work
    source ~/.bashrc_modules
    exit

    # make sure you configured everything right before continuing with next steps
    # Note: lmod may have some issues if the 'Core' directory doesn't exist yet.
    # that directory gets created once a hierarchy exists, i.e. once you have
    # an MPI installed. If you're not at this point yet, don't panic.
    # Note: Make sure you set up the 'core compilers' correctly in 
    # .spack/modules.yaml. Otherwise, lmod will not find any module files to add.

}


#======================================================
install_compilers() {
#======================================================

    # install compilers
    #----------------------
    for compiler in ${compiler_list[@]}; do

        if [ "$compiler" == "$native_compiler" ]; then
            echo "skipping native compiler"
            continue
        fi

        spack install -y "$compiler" %"$native_compiler"

        # make sure spack knows about its compilers
        module purge
        compiler_module=$(spack_string_to_module_string $compiler)
        module load "$compiler_module"
        spack compiler add
        module purge
    done
    spack module tcl rm # I only want lmod files, no need to show me modules twice
    spack module lmod refresh --delete-tree -y # refresh lmod stuff
    exit
    # make sure you configured everything right before continuing with next steps
}



#======================================================
install_packages() {
#======================================================

    # get all packages for all compilers
    #------------------------------------------

    for compiler in ${compiler_list[@]}; do

        module purge
        if [ "$compiler" == "$native_compiler" ]; then
            echo "skipping native compiler module:" $native_compiler
            compiler_module=""
        else
            compiler_module=$(spack_string_to_module_string $compiler)
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

        # spack install -y openmpi %"$compiler"
        # # spack install -y mpich   cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"
        #
        # spack module tcl rm -y # I only want lmod files, no need to show me modules twice
        # spack module lmod refresh --delete-tree -y # refresh lmod stuff
        #
        #
        # #-----------------------
        # # individual packages
        # #-----------------------

        # # without dependencies
        # #~~~~~~~~~~~~~~~~~~~~~~~~~~
        #
        # # cblas: doesn't compile...
        # for pack in jemalloc gsl metis intel-tbb openblas; do
        #     spack install -y $pack %$compiler
        # done;
        #
        # spack install -y fftw@3.3.8 +openmp %$compiler
        # spack install -y fftw@2.1.5 +openmp %$compiler
        # spack install --reuse -y "$MYHDF5" +cxx +fortran +threadsafe -mpi +java %$compiler
        # # spack install -y grackle@3.2 ^"$MYHDF5" %$compiler #can't do grackle without MPI
        #
        # spack install -y gdb@12.1
        # spack install -y valgrind
        # # spack install elfutils@0.188 -nls %gcc@12.1.0 # temporary manual fix for elfutils, needed by gdb
        # # spack install -y gdb@13.1 ^elfutils@0.188 -nls %$compiler
        # # spack install -y valgrind ^elfutils@0.188 -nls %$compiler
        #
 
        # with dependencies
        #~~~~~~~~~~~~~~~~~~~~~~~~~~

        # for dep in openmpi mpich; do
        for dep in ${MPI_list[@]}; do
            module load $dep

            # packages without any further specifications
            for pack in parmetis; do
                spack install -y $pack ^$dep %$compiler
            done;

            # +openmp: install with openmp too
            # ^$dep needs to be after +openmp, otherwise all other
            # specifications are taken to be for the dependency
            spack install --reuse -y "$MYHDF5" +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
            # spack install --reuse -y hdf5-mladen@1.10.7 +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
            spack module tcl rm -y # I only want lmod files, no need to show me modules twice
            spack module lmod refresh --delete-tree -y # refresh lmod stuff
            module load hdf5/${MYHDF5#hdf5@}

            
            spack install --reuse -y grackle@3.2 ^$MYHDF5 ^$dep %$compiler
            # note: grackle-float is a fake package I made.
            # If you don't want to use this, use +float variant.
            # spack install --reuse -y grackle-float@3.2 ^hdf5@1.13.1 ^$dep %$compiler
            spack install --reuse -y grackle-float@3.2 ^$MYHDF5 ^$dep %$compiler
            spack install --reuse -y sundials@5.1.0 ^$dep %$compiler
        done;

    done;

    spack module tcl rm -y # I only want lmod files, no need to show me modules twice
    spack module lmod refresh --delete-tree -y # refresh lmod stuff
}




#======================================================
# MAIN COURSE
#======================================================

# uninstall_everything
# install_modules
# # install_compilers
install_packages
