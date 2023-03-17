#!/bin/bash

#======================================================
# SETUP
#======================================================

# my native compiler
native_compiler="gcc@12.1.0"

MYHDF5="hdf5@1.12.2"

# list of compilers you want to 
declare -a compiler_list 
# compiler_list=($native_compiler)
# compiler_list+=(oneapi@2023.0.0)
# compiler_list+=(clang@14.0.0)
# compiler_list=(oneapi@2023.0.0)
compiler_list=(clang@14.0.0)


declare -a MPI_list 
MPI_list=(openmpi)
MPI_list+=(mpich)
# MPI_list=(mpich)



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
    # for compiler in ${compiler_list[@]}; do
    #
    #     if [ "$compiler" == "$native_compiler" ]; then
    #         echo "skipping native compiler"
    #         continue
    #     fi
    #
    #     spack install -y "$compiler" %"$native_compiler"
    #
    #     # make sure spack knows about its compilers
    #     # module purge
    #     # compiler_module=$(spack_string_to_module_string $compiler)
    #     # module load "$compiler_module"
    # done

    spack install -y intel-oneapi-compilers@2023.0.0 %$native_compiler
    spack install -y intel-oneapi-compilers-classic@2021.8.0 %$native_compiler
    # spack install -y llvm +flang +ipo +omp_debug +omp_tsan +python  %$native_compiler

    # DONT INSTALL LLVM. USE SYTEM LLVM. It's set up in the packages file to use
    # the external one. Just run a spack install on it anyway, so spack registers
    # it as a spack package, and consequently modules are built.
    # Also add gcc this way.

    spack module tcl rm -y # I only want lmod files, no need to show me modules twice
    spack module lmod refresh --delete-tree -y # refresh lmod stuff
    exit
    # make sure you configured everything right before continuing with next steps
}




load_compiler_module_only() {

    compiler=$1

    module purge
    if [ "$compiler" == "$native_compiler" ]; then
        echo "skipping native compiler module:" $native_compiler
        compiler_module=""
    else
        # compiler_module=$(spack_string_to_module_string $compiler)
        # TODO: hardcoded for now
        compiler_module=intel-oneapi-compilers
        module load "$compiler_module"
    fi
}


#======================================================
install_packages() {
#======================================================

    # get all packages for all compilers
    #------------------------------------------

    for compiler in ${compiler_list[@]}; do

        load_compiler_module_only $compiler

        # clang needs extra flags
        # TODO: is this still up to date? Shouldn't you add this to compilers.yml?
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

        additional_specs=""
        if [[ "$compiler" == "clang"* ]]; then
            additional_specs="~fortran"
        fi

        for mpi_vendor in ${MPI_list[@]}; do
            spack install -y $mpi_vendor $additional_specs %"$compiler"
        done
        # # spack install -y mpich   cflags="$CFLAGS" cxxflags="$CXXFLAGS" fflags="$FFLAGS" %"$compiler"

        spack module tcl rm -y # I only want lmod files, no need to show me modules twice
        spack module lmod refresh --delete-tree -y # refresh lmod stuff


        #-----------------------
        # individual packages
        #-----------------------

        # without dependencies
        #~~~~~~~~~~~~~~~~~~~~~~~~~~

        # packages without fortran variants go here
        for pack in jemalloc gsl metis intel-tbb; do
            spack install -y $pack %$compiler
        done;

        # packages with fortran variants go here
        for pack in openblas; do
            spack install -y $pack $additional_specs %$compiler
        done;


        spack install -y fftw@3.3.8 +openmp ~mpi %$compiler
        spack install -y fftw@2.1.5 +openmp ~mpi %$compiler
        if [[ "$compiler" == "clang"* ]]; then
            spack install -y "$MYHDF5" +cxx ~fortran +threadsafe ~mpi +java %$compiler
        else
            spack install -y "$MYHDF5" +cxx +fortran +threadsafe ~mpi +java %$compiler
        fi
        # spack install -y grackle@3.2 ^"$MYHDF5" %$compiler #can't do grackle without MPI

        # gdb doesn't work at the moment...
        # spack install -y gdb
        # valgrind has no fortran variant
        spack install valgrind ~mpi %$compiler

        # with dependencies
        #~~~~~~~~~~~~~~~~~~~~~~~~~~

        for dep in ${MPI_list[@]}; do

            if [[ "$compiler" == "clang"* ]]; then
                if [[ "$dep" == "openmpi"* ]]; then
                    echo skipping clang + openmpi due to no fortran compiler
                    continue
                fi
            fi

            load_compiler_module_only $compiler
            module load $dep

            # packages without any further specifications
            for pack in parmetis valgrind; do
                # neither valgrind nor parmetis have fortran variant
                spack install -y $pack ^$dep $additional_specs %$compiler
            done;

            # +openmp: install with openmp too
            # ^$dep needs to be after +openmp, otherwise all other
            # specifications are taken to be for the dependency
            if [[ "$compiler" == "clang"* ]]; then
                spack install -y "$MYHDF5" +cxx ~fortran +threadsafe +mpi +java ^$dep %$compiler
            else
                spack install -y "$MYHDF5" +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler
            fi
            # spack install --reuse -y hdf5-mladen@1.10.7 +cxx +fortran +threadsafe +mpi +java ^$dep %$compiler

            spack module tcl rm -y # I only want lmod files, no need to show me modules twice
            spack module lmod refresh --delete-tree -y # refresh lmod stuff
            module purge

            module load $compiler_module
            module load hdf5/${MYHDF5#hdf5@}

            spack install -y fftw@3.3.8 +openmp +mpi ^$dep $additional_specs %$compiler
            spack install -y fftw@2.1.5 +openmp +mpi ^$dep $additional_specs %$compiler


            spack install --reuse -y grackle@3.2 ^$MYHDF5 ^$dep $additional_specs %$compiler
            # note: grackle-float is a fake package I made.
            # If you don't want to use this, use +float variant.
            # spack install --reuse -y grackle-float@3.2 ^hdf5@1.13.1 ^$dep %$compiler
            # spack install --reuse -y grackle-float@3.2 ^$MYHDF5 ^$dep %$compiler
            spack install --reuse -y sundials@5.1.0 $additional_specs ^$dep $additional_specs %$compiler

        done;

    done;

    spack module tcl rm -y # I only want lmod files, no need to show me modules twice
    spack module lmod refresh --delete-tree -y # refresh lmod stuff
}




#======================================================
# MAIN COURSE
#======================================================

# first find external, already existing packages
# spack external find
# uninstall_everything
# install_modules
# install_compilers # remember to manually add system compilers by making them unbuildable in packages.yaml, but installing them with spack anyway.
install_packages
