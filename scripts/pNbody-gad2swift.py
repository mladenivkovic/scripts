#!/usr/bin/python3

usage="""
This script converts a gadget2 (non-hdf5) type initial condition file
(e.g. made with MUSIC) to a swift type IC file.
Needs pNbody to be installed.

Usage:
    pNbody-gad2swift.py gadget-IC.dat [outputfilename_swift.dat]

    outputfilename_swift.dat is optional. If you don't
    specify it, the script will create a file called
    <gadget-ic-filename-you-gave-as-first-argument>-SWIFT.dat
"""

from pNbody import *
import sys
from h5py import File
from sys import argv
import numpy as np

# number of particle type
N_type = 6
debug = True

#====================================
def get_filenames():
#====================================
    """
    Gets filename(s) from cmdline args.
    Inputfile must be specified as arg1, outputfile is optional
    and will be generated if not provided.
    """

    try:
        file_in = sys.argv[1]
    except IndexError:
        print(usage)
        quit()

    try:
        file_out = sys.argv[2]
    except IndexError:
        cut = 0
        append = '-SWIFT'
        for i in range(len(file_in)):
            if file_in[-i-1] == '.':
                cut = len(file_in)-i-1
                break
        if cut > 0:
            file_out = file_in[:cut]+append+file_in[cut:]
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

    f = File(file_out)

    changeType(f, 2, 1)
    changeType(f, 3, 1)
    changeType(f, 4, 1)

    countPart(f)

    f.close()


    #--------------------------------------------------------------
    def groupName(part_type):
        return "PartType%i" % part_type
    #--------------------------------------------------------------


    #--------------------------------------------------------------
    def changeType(f, old, new):

        # check if directory exists
        old_group = groupName(old)

        if old_group not in f:
            raise IOError("Cannot find group '%s'" % old)
        old = f[old_group]

        new_group = groupName(new)

        if new_group not in f:
            f.create_group(new_group)

        new = f[new_group]


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


    return


from pNbody import Nbody
from sys import argv
from os import path
import numpy as np



def convert_gadget_to_swift(file_in):

    filename = argv[-1]


    nb = Nbody(filename, ftype="gadget")
    #test = np.logical_and(nb.tpe == 0, nb.u == 0.)
    #nb = nb.selectc(np.logical_not(test))

    # change ftype
    nb = nb.set_ftype("swift")

    # set default parameters
    nb.boxsize = 1.2 * (nb.pos.max() - nb.pos.min())
    nb.periodic = 0
    nb.flag_entropy_ics = 0

    # compute smoothing length
    hsml = nb.get_rsp_approximation()
    nb.rsp = hsml

    # write new file
    filename = path.splitext(filename)[0]
    nb.rename(filename + ".hdf5")

    nb.write()



if __name__ == "__main__":

    file_in, file_out = get_filenames()




