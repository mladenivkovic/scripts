#!/usr/bin/env python3

#=====================================
# Print out particle data for a swift
# hdf5 file.
# usage:
#   swift-printparticles.py <fname>
#=====================================


import numpy as np
import argparse
import h5py



errormsg ='''
I need a file as a cmd line arg to print it.
Usage:
    swift-printparticles.py <fname>
'''


tosort = None
sort_by = None



#==========================
def getargs():
#==========================

    """
    Read cmd line args.
    """

    import sys
    import os

    parser = argparse.ArgumentParser(description='''
        A program to print particle data.
            ''')

    parser.add_argument('filename')
    parser.add_argument('--pt',
            dest='ptype', 
            action='store',
            default='PartType0',
            help='PartType to use. Default=PartType0')
    parser.add_argument('-s',
            dest='tosort', 
            action='store_const',
            const='ids',
            help='Flag to sort particles by ID')
    parser.add_argument('--sort-id',
            dest='sort_by', 
            action='store_const',
            const='ids',
            help='Flag to sort particles by ID')
 
    args = parser.parse_args()

    global tosort, sort_by

    fname = args.filename
    tosort = args.tosort
    ptype = args.ptype

    try:
        fname = sys.argv[1]  
        if not os.path.isfile(fname):
            print("Given filename, '", fname, "' is not a file.")
            print(errormsg)
            quit(2)
    except IndexError:
        print(errormsg)
        quit(2)



    if tosort: # -s flag; set sort_by to ids
        sort_by = 'ids'  

    if args.sort_by is not None:
        tosort = True
        sort_by = args.sort_by

    return fname, ptype






#==========================================
def read_file(srcfile, ptype):
#==========================================
    """
    Read swift output hdf5 file.
    """

    import h5py

    f = h5py.File(srcfile)

    x = f[ptype]['Coordinates'][:,0]
    y = f[ptype]['Coordinates'][:,1]
    z = f[ptype]['Coordinates'][:,2]
    m = f[ptype]['Masses'][:]
    ids = f[ptype]['ParticleIDs'][:]

    try:
        # old SWIFT header versions
        rho = f[ptype]['Density'][:]
    except KeyError:
        # new SWIFT header versions
        try:
            rho = f[ptype]['Densities'][:]
        except KeyError:
            print("This file doesn't have a density dataset (Could be the case for IC files.). Skipping it.")
            rho = None


    try:
        # old SWIFT header versions
        h = f[ptype]['SmoothingLength'][:]
    except KeyError:
        # new SWIFT header versions
        h = f[ptype]['SmoothingLengths'][:]


    f.close()

    return x, y, z, h, rho, m, ids






#================================================
def print_particles(x, y, z, h, rho, m, ids):
#================================================

    if tosort:
        if sort_by == 'ids':
            inds = np.argsort(ids)
    else:
        inds = range(x.shape[0])

    
    if rho is not None:
        print(
            "{0:6} | {1:10} {2:10} {3:10} | {4:10} {5:10} {6:10} |".format(
                    "ID", "x", "y", "z", 'h', 'm', 'rho'
                )
            )
        print("------------------------------------------------------------------------------")

        for i in inds:
            print(
                "{0:6d} | {1:10.4f} {2:10.4f} {3:10.4f} | {4:10.4f} {5:10.4f} {6:10.4f} |".format(
                        ids[i], x[i], y[i], z[i], h[i], m[i], rho[i]
                    )
                )

    else:
        print(
            "{0:6} | {1:10} {2:10} {3:10} | {4:10} {5:10} |".format(
                    "ID", "x", "y", "z", 'h', 'm'
                )
            )
        print("-------------------------------------------------------------------")

        for i in inds:
            print(
                "{0:6d} | {1:10.4f} {2:10.4f} {3:10.4f} | {4:10.4f} {5:10.4f} |".format(
                        np.asscalar(ids[i]), 
                        np.asscalar(x[i]), 
                        np.asscalar(y[i]), 
                        np.asscalar(z[i]), 
                        np.asscalar(h[i]), 
                        np.asscalar(m[i])
                    )
                )



    return






#==========================
def main():
#==========================

    fname, ptype = getargs()
    x, y, z, h, rho, m, ids = read_file(fname, ptype)

    print_particles(x,y,z,h,rho,m,ids)




    return




if __name__ == '__main__':
    main()
