#!/bin/bash

#================================================
# generate and print out entries for .c or .f90
# files in this directory. Is printed to screen.
#================================================



which=c

errmsg="\n generate and print out make recepies for c or fortran files in this dir.\n
Usage: \n
\t makefile_get_entries.sh f|c \n
\t f for fortran90, f03 for fortran 2003, c for C"




if [ "$#" == 0 ]; then
    echo Going with default C format? [hit any key to continue]
    read x
elif [ "$#" == 1 ]; then
    case "$1" in
        f | -f | --fortran | -f90 | f90 | fort | F | -F)
            which=fort
        ;;

        f03 | -f03 | --f03)
            which=f03
        ;;

        c | -c | --c | C | -C | --C )
            which=c
        ;;

        -h | --help )
            echo -e $errmsg
            exit
        ;;

        * )
            echo "didn't understand your cmdline arg."
            echo -e $errmsg
            exit
        ;;
    esac
else
    echo "didn't understand your cmdline arg."
    echo -e $errmsg
    exit
fi



if [ "$which" == fort ]; then
    #---------------------
    # FORTRAN
    #---------------------
    for file in *.f90; do
        echo ${file%.f90}.o: $file
        echo -e "\t"'$(F90) -o $(notdir $@) $< $(F90FLAGS)' # the tab here is vital.
        echo
    done
elif [ "$which" == f03 ]; then
    #---------------------
    # FORTRAN 2003
    #---------------------
    for file in *.f03; do
        echo ${file%.f03}.o: $file
        echo -e "\t"'$(F03) -o $(notdir $@) $< $(F03FLAGS)' # the tab here is vital.
        echo
    done
elif [ "$which" == c ]; then
    #---------------------
    # C
    #---------------------
    for file in *.c; do
        echo ${file%.f90}.o: $file
        echo -e "\t"'$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)' # the tab here is vital.
        echo
    done
fi



