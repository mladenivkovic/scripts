#!/usr/bin/env python3


#--------------------------------------------------------------
# Compute galaxy cluster number and stellar mass profile
# of a given cluster/halo.
# Intended for my thesis paper, to be used with ramses output.
#
# Usage:
#   cluster_profile.py output_XXXXX <halo-id>
#--------------------------------------------------------------

import os
import numpy as np
from scipy.io import FortranFile



# global vars
outputdir = None
halo = None

outputNrString = None

ncpu = 0

ids = [] # clump IDs to look out for

# halo particle arrays
x = None
y = None
z = None
clumpidp = None
idp = None


# galaxy data
xg = None
yg = None
yg = None
mg = None

# orphan galaxy data
xo = None
yo = None
zo = None
mo = None

class cosmo:
    
    def __init__(self):
        self.z = 0.
        self.a = 0.
        self.H = 0.
        self.rhoC = 0.
        self.OmegaM = 0.
        self.OmegaLambda = 0.
        self.Omegak = 0.
        self.OmegaB = 0.


class units:
    def __init__(self):
        self.L = 0.
        self.rho = 0.
        self.t = 0.
        self.m = 0.


cosmo = cosmo()
units = units()





# ----------------------------------
def get_cmdlineargs():
# ----------------------------------
    """
    The code expects output_XXXXX and <halo-id> as cmdline args.
    Check that we got them and that they exist
    """

    from sys import argv
    global outputdir, halo, outputNrString

    if len(argv) != 3:
        print("Error: I expect 2 cmdline args: output_dir and halo-ID. Can't work like this.")
        quit()

    outputdir = argv[1]
    try:
        halo = int(argv[2])
    except ValueError:
        print("Error: Halo ID must be an integer, you gave me", argv[2])
        quit()

    if not os.path.isdir(outputdir):
        print("Error: Couldn't find directory", outputdir)
        quit()

    if outputdir[-1] == '/':
        outputdir = outputdir[:-1]
    outputNrString = outputdir[-5:]

    return

    




# ----------------------------------
def read_infofile():
# ----------------------------------
    """
    Read the info file
    """

    global ncpu, cosmo, units

    fname = os.path.join(outputdir, "info_"+outputNrString+".txt")

    f = open(fname, 'r')
    ncpuline = f.readline()
    line = ncpuline.split()
    ncpu = int(line[-1])


    # skip 8 lines
    for i in range(8):
        f.readline()

    # read aexp
    aexpline = f.readline()
    line = aexpline.split()
    cosmo.a = float(line[-1])

    # get redshift
    cosmo.z = 1./cosmo.a - 1.

    # get H0
    H0line = f.readline()
    line = H0line.split()
    cosmo.H = float(line[-1])

    # get omegas
    lline = f.readline()
    line = lline.split()
    cosmo.OmegaM = float(line[-1])
    lline = f.readline()
    line = lline.split()
    cosmo.OmegaLambda = float(line[-1])
    lline = f.readline()
    line = lline.split()
    cosmo.Omegak = float(line[-1])
    lline = f.readline()
    line = lline.split()
    cosmo.OmegaB = float(line[-1])


    # get units
    lline = f.readline()
    line = lline.split()
    units.l = float(line[-1])
    lline = f.readline()
    line = lline.split()
    units.rho = float(line[-1])
    lline = f.readline()
    line = lline.split()
    units.t = float(line[-1])

    units.m = units.rho * units.l**3


    f.close()
    
    print("ncpu ", ncpu)
    print("aexp ", cosmo.a)
    print("z    ", cosmo.z)
    print("H    ", cosmo.H)
    return





# ----------------------------------
def find_children():
# ----------------------------------
    """
    Find the children for given clump ID.
    clumpid: clump ID for which to work for
    store halo ID and all children IDs in 'ids' list

    """

    global ids

    # first read in clump data
    raw_data = [None for i in range(ncpu)]

    i = 0
    for cpu in range(ncpu):
        fname = os.path.join(outputdir, 'clump_' + outputNrString + '.txt' + str(cpu + 1).zfill(5))
        new_data = np.loadtxt(fname, dtype='int', skiprows=1, usecols=[0, 1, 2])
        if new_data.ndim == 2:
            raw_data[i] = new_data
            i += 1
        elif new_data.shape[0] == 3:  # if only 1 row is present in file
            raw_data[i] = np.atleast_2d(new_data)
            i += 1

    fulldata = np.concatenate(raw_data[:i], axis=0)

    clumpid = fulldata[:, 0]
    level = fulldata[:, 1]
    parent = fulldata[:, 2]



    ids = [halo]
    not_finished = True

    while not_finished:
        for i, cid in enumerate(clumpid):
            if cid in ids:
                continue
            elif parent[i] in ids:
                ids.append(cid)
                break  # restart loop to find children's children
        else:
            not_finished = False

    print("Chlidren of halo", halo, "are", ids[1:])

    return






#----------------------------------
def get_particle_data():
#----------------------------------
    """
    Reads in the particle data from directory outputdir.
    NOTE: requires part_XXXXX.outYYYYY and unbinding_XXXXX.outYYYYY files

    """
    from os import listdir

    global x, y, z, idp, clumpidp

    srcdirlist = listdir(outputdir)

    if 'unbinding_'+outputNrString+'.out00001' not in srcdirlist:
        print("Couldn't find unbinding_"+outputNrString+".out00001 in", outputdir)
        print("To plot particles, I require the unbinding output.")
        quit()





    #-----------------------
    # First read headers
    #-----------------------
    nparts = np.zeros(ncpu, dtype='int')
    partfiles = [0]*ncpu

    for cpu in range(ncpu):
        srcfile = outputdir+'/part_'+outputNrString+'.out'+str(cpu+1).zfill(5)
        partfiles[cpu] = FortranFile(srcfile)


        ncpu_junk = partfiles[cpu].read_ints()
        ndim = partfiles[cpu].read_ints()
        nparts[cpu] = partfiles[cpu].read_ints()
        localseed = partfiles[cpu].read_ints()
        nstar_tot = partfiles[cpu].read_ints()
        mstar_tot = partfiles[cpu].read_reals(dtype=np.float64)
        mstar_lost = partfiles[cpu].read_reals(dtype=np.float64)
        nsink = partfiles[cpu].read_ints()


    #  nparttot = np.sum(nparts)
    nparttot = 0



    #----------------------
    # Read particle data
    #----------------------

    x_list = []
    y_list = []
    z_list = []
    clumpidp_list = []
    idp_list = []

    for cpu in range(ncpu):
        # read each file individually
        x_file = partfiles[cpu].read_reals(dtype=np.float64)
        y_file = partfiles[cpu].read_reals(dtype=np.float64)
        z_file = partfiles[cpu].read_reals(dtype=np.float64)
        m_file = partfiles[cpu].read_reals(dtype=np.float64)
        nparttot += m_file.shape[0]
        idp_file = partfiles[cpu].read_ints(dtype=np.int64)
        #  idp_file = partfiles[cpu].read_ints()
        print(m_file.shape, idp_file.shape)

        unbfile = outputdir+'/unbinding_'+outputNrString+'.out'+str(cpu+1).zfill(5)
        unbffile = FortranFile(unbfile)

        clumpid_file = unbffile.read_ints()

        for i, ID in enumerate(clumpid_file):
            if ID in ids:
                x_list.append(x_file[i])
                y_list.append(y_file[i])
                z_list.append(z_file[i])
                idp_list.append(idp_file[i])
                clumpidp_list.append(np.absolute(clumpid_file[i]))

    x = np.array(x_list)
    y = np.array(y_list)
    z = np.array(z_list)
    idp = np.array(idp_list)
    clumpidp = np.array(clumpidp_list)


    print("Keeping", idp.shape[0], "particles out of", nparttot)
    print(idp)

    return







#--------------------------------------
def get_galaxy_data():
#--------------------------------------
    """
    reads in galaxy data as written by the mergertree patch.
    NOTE: requires galaxies_XXXXX.txtYYYYY files.
    """

    import warnings
    import gc
    from os import listdir

    srcdirlist = listdir(outputdir)

    if 'galaxies_'+outputNrString+'.txt00001' not in srcdirlist:
        print("Couldn't find galaxies_"+outputNrString+".txt00001 in", outputdir)
        print("To plot particles, I require the galaxies output.")
        quit()

    xg_list = []
    yg_list = []
    zg_list = []
    mg_list = []

    xo_list = []
    yo_list = []
    zo_list = []
    mo_list = []

    ngaltot = 0
    norphtot = 0

    for cpu in range(ncpu):
        srcfile = outputdir+'/galaxies_'+outputNrString+'.txt'+str(cpu+1).zfill(5)

        data = np.atleast_2d(np.loadtxt(srcfile, usecols=[0,1,2,3,4,5], skiprows=1, dtype='float'))

        if data.shape[1] > 0 :

            ids_gal = data[:,0].astype('int')
            m = data[:,1]
            x = data[:,2]
            y = data[:,3]
            z = data[:,4]
            idp_gal = data[:,5].astype('int')


            # sort out galaxies in halo
            galinds = ids_gal > 0
            ng = m[galinds].shape[0]
            ngaltot += ng
            for i in range(ng):
                if ids_gal[galinds][i] in ids:
                    mg_list.append(m[galinds][i])
                    xg_list.append(x[galinds][i])
                    yg_list.append(y[galinds][i])
                    zg_list.append(z[galinds][i])

            # sort out orphans in halo
            orphs = ids_gal == 0
            no = m[orphs].shape[0]
            norphtot += no
            for i in range(no):
                if idp_gal[orphs][i] in idp:
                    mo_list.append(m[orphs][i])
                    xo_list.append(x[orphs][i])
                    yo_list.append(y[orphs][i])
                    zo_list.append(z[orphs][i])

    print("Keeping", len(mg_list), "galaxies out of", ngaltot)
    print("Keeping", len(mo_list), "orphans out of", norphtot)



    #  if i > 0:
    #      xg     = np.concatenate(xlist[:i])
    #      yg     = np.concatenate(ylist[:i])
    #      zg     = np.concatenate(zlist[:i])
    #      galid  = np.concatenate(idlist[:i])
    #
    #  else:
    #      xg = None
    #      yg = None
    #      zg = None
        #  galid = None

    return






if __name__ == "__main__":

   get_cmdlineargs() 
   read_infofile()
   find_children()
   get_particle_data()
   get_galaxy_data()
