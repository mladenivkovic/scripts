#!/usr/bin/env python3

###########################################################################################
#  package:   Gtools
#  file:      pNbody-gad2swift.py
#  brief:     convert binary gadget IC files to swift format
#  copyright: GPLv3
#             Copyright (C) 2019 EPFL (Ecole Polytechnique Federale de Lausanne)
#             LASTRO - Laboratory of Astrophysics of EPFL
#  author:    Loic Hausammann, Mladen Ivkovic
#
# This file is part of Gtools.
#
#  This script converts a gadget2 (non-hdf5) type initial condition file
#  (e.g. made with MUSIC) to a swift type IC file.
#  Needs pNbody to be installed.
#
#
#  It first saves the gadget IC file as a SWIFT type file. In a second step,
#  the newly created .hdf5 file is read back in and the particle types are
#  sorted out correctly.
#
#
#  Based on scripts written by Loic Hausammann.
#  Put together in this form by Mladen Ivkovic, Dec 2018
###########################################################################################


usage="""
This script converts a gadget2 (non-hdf5) type initial condition file
(e.g. made with MUSIC) to a swift type IC file.
Needs pNbody to be installed.

Usage:
    pNbody-gad2swift.py gadget-IC.dat [outputfilename_swift.dat]
 
    outputfilename_swift.dat is optional. If you don't
    specify it, the script will create a file called
    the script will create a file called
    <gadget-ic-filename-you-gave-as-first-argument>-SWIFT.dat
"""

from pNbody import *
from h5py import File
from sys import argv
import numpy as np
from os import path


# number of particle type
N_type = 6
debug = False   # helpful debugging flag. Prints more info at times, and skips repetitive questions.



#====================================
def get_filenames():
#====================================
    """
    Gets filename(s) from cmdline args.
    Inputfile must be specified as arg1, outputfile is optional
    and will be generated if not provided.
    """

    try:
        file_in = argv[1]
    except IndexError:
        print(usage)
        quit()

    try:
        file_out = argv[2]
    except IndexError:
        # If no second file was given, generate file_out filename
        # assume suffix is after last period in filename
        cut = 0
        append = '-SWIFT.hdf5'
        for i in range(len(file_in)):
            if file_in[-i-1] == '.':
                cut = len(file_in)-i-1
                break
        if cut > 0:
            file_out = file_in[:cut]+append
        else:
            file_out = file_in+append

    return file_in, file_out








#====================================
def fix_particle_types(file_out):
#====================================
    """
    Change particle types in order to match the implemented types.
    Changes the particle types in the hdf5 file itself and overwrites
    it.
    """

    #--------------------------------------------------------------
    def groupName(part_type):
        return "PartType%i" % part_type
    #--------------------------------------------------------------


    #--------------------------------------------------------------
    def changeType(f, old, new):
        """
        Change particle types in the file f.
        """

        # check if directory exists
        old_group = groupName(old)

        if old_group not in f:
            while True:
                print("Changing particle types - cannot find group '%s'" % old)
                print(" This is fine if your gadget file didn't contain any particles of that type.")
                ans = input("Should I continue? [y/n] ")
                if ans=='y' or ans == 'Y':
                    return
                elif ans == 'n' or ans == 'N':
                    raise IOError("Cannot find group '%s'" % old)

        old = f[old_group]

        new_group = groupName(new)

        if new_group not in f:
            f.create_group(new_group)

        new = f[new_group]

        print('check')
        for name in old:
            if debug:
                print("Moving '%s' from '%s' to '%s'"
                      % (name, old_group, new_group))


            tmp = old[name][:]
            del old[name]
            if name in new:
                new_tmp = new[name][:]
                if debug:
                    print("Found previous data:", tmp.shape, new_tmp.shape)
                tmp = np.append(tmp, new_tmp, axis=0)
                del new[name]

            if debug:
                print("With new shape:", tmp.shape)

            new.create_dataset(name, tmp.shape)
            new[name][:] = tmp

        del f[old_group]
    #--------------------------------------------------------------


    #--------------------------------------------------------------
    def countPart(f):
        """
        Count particles again.
        """

        npart = []

        for i in range(N_type):
            name = groupName(i)
            if name in f:
                grp = f[groupName(i)]
                N = grp["Masses"].shape[0]
            else:
                N = 0

            npart.append(N)

        f["Header"].attrs["NumPart_ThisFile"] = npart
        f["Header"].attrs["NumPart_Total"] = npart
        f["Header"].attrs["NumPart_Total_HighWord"] = [0]*N_type

        return
    #--------------------------------------------------------------




    f = File(file_out)

    changeType(f, 2, 1)
    changeType(f, 3, 1)
    changeType(f, 4, 1)
    changeType(f, 5, 1)

    # Re-count particles properly
    countPart(f)

    f.close()
    print("Finished changing SWIFT-type file appropriately for use.")



    return





#===================================================
def convert_gadget_to_swift(file_in, file_out):
#===================================================
    """
    Converts a non-hdf5 type gadget2 IC file to the SWIFT
    format.
    (it should also work with hdf5-type gadget files, 
    pNbody should figure out the initial file type by itself)
    """


    nb = Nbody(file_in, ftype="gadget")

    # change ftype
    nb = nb.set_ftype("swift")



    # Set units if necessary

    # wont work this way. Do unit setting manually.
    #  nb.set_local_system_of_units(UnitLength_in_cm=1,UnitVelocity_in_cm_per_s=1,UnitMass_in_g=1)

    units = ["UnitLength_in_cm", "UnitVelocity_in_cm_per_s", "UnitMass_in_g"]
    unitd = nb.unitsparameters.get_dic()

    if not debug:
        print("\nWARNING:")
        print("This script assumes gadget default units, which are:")
        for u in units:
            print("{0:30}{1:12.4E}".format(u, unitd[u]))

        while True:
            ans = input("Do you wish to change them manually? [y/n] ")
            if ans=='y' or ans == 'Y':
                i = 0
                while i<len(units):
                    u = units[i]
                    inp = input("Enter a value for "+u+": [leave empty to keep] ")
                    try:
                        val = float(inp)
                    except ValueError:
                        if (inp==""):
                            i+=1
                            continue
                        else:
                            print("Didn't understand input. Try again.")
                            continue
                    nb.unitsparameters.set(u, val)
                    i+=1
                print("Units are now:")
                for u in units:
                    unitd = nb.unitsparameters.get_dic()
                    print("{0:30}{1:12.4E}".format(u, unitd[u]))
                    
                break
            elif ans == 'n' or ans == 'N':
                break
        

    # set default parameters
    boxsizeguess =  1.2 * (nb.pos.max() - nb.pos.min())


    print("\nWARNING:")
    print("This script made a guess for the boxsize, which is ", boxsizeguess)
    print("If that is not correct, the computed density parameters Omega ")
    print("will be different from the ones in your MUSIC config file, and SWIFT")
    print("might not run if you specified the wrong density parameters in your SWIFT parameter file.")


    if not debug:
        while True:
            ans = input("Do you wish to change them manually? [y/n] ")
            if ans=='y' or ans == 'Y':
                inp = input("Enter a value for the boxsize: ")
                try:
                    val = float(inp)
                except ValueError:
                    print("Didn't understand input. Try again.")
                    continue
                nb.boxsize = val
                break

            elif ans == 'n' or ans == 'N':
                nb.boxsize = boxsizeguess 
                break


    nb.periodic = 0
    nb.flag_entropy_ics = 0

    # compute smoothing length
    print("\nWARNING:")
    print("SWIFT needs an initial guess for the particle smoothing lengths.")
    print("They don't need to be exact, SWIFT will fix them up, but they shouldn't")
    print("be zero. You can either do a proper estimate of the smoothing length")
    print("using the tree construction from pNbody, but that might fail for 'large' (>1GB)")
    print("IC file sizes. Or you can do a crude estimate over mean interparticle distances.")
 
    while True:
        ans = input("Should I try the tree code? (Might crash) [y/n]")
        if ans=='y' or ans == 'Y':
            do_tree = True
            break

        elif ans == 'n' or ans == 'N':
            do_tree = False
            break

    if do_tree:
        hsml = nb.get_rsp_approximation()
    else:
        partx = (nb.nbody_tot)**(1./3) # average number of particles in 1 direction
        hest = 2*nb.boxsize/partx # factor 2: just guessing here. Shouldn't matter
        hsml = np.zeros(nb.nbody_tot)
        # now assign the particles that need a smoothing length the guess
        start = 0
        for i,npart in enumerate(nb.npart):
            if i == 2 or i ==3:
                continue
            stop = start + npart
            hsml[start:stop] = hest
            start = stop
    


    nb.rsp = hsml

    # write new file
    nb.rename(file_out)

    nb.write()
    print("Written SWIFT-type file ", file_out)

    return


#==================================
if __name__ == "__main__":
#==================================

    file_in, file_out = get_filenames()
    convert_gadget_to_swift(file_in, file_out)
    fix_particle_types(file_out)

