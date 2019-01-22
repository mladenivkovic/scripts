#!/usr/bin/env python3

#=============================================
# Check the -DMTREEDEBUG output for isues
# Usage:
#   mtreedebug.py <outputnr>
#   or
#   mtreedebug.py output_XXXXX
#=============================================

import numpy as np
import os

#---------------------------
# global vars
#---------------------------
ncpu = 1
outnr = None
outputdir = None
verbose = False



#---------------------------
# Datatypes
#---------------------------

# unbinding data type
udtp = np.dtype([   ('id' , 'i'),
                    ('lid', 'i'),
                    ('hcorr', np.chararray),
                    ('parent', 'i'),
                    ('m', 'f'),
                    ('npcomp', 'i'),
                    ('npown', 'i'),
                    ('nclmppart', 'i'),
                    ('nclmpparttot', 'i') ])


#=======================================
def check_prog_metadata():
#=======================================
    """
    Check whether the correct metadata has been written.
    """
    
    nprogs = 0
    prog_ints = 0
    nprogs_written = 0
    npmprogs = 0


    levprint(0, "Checking progenitor metadata.")
    #----------------------------------------------------------------------------------
    if verbose:
        levprint(1, "Checking written progenitor metadata")
    #----------------------------------------------------------------------------------

    for cpu in range(ncpu):
        p, npw, i, pmp = np.loadtxt(debfile('prog_metadata', cpu+1),
                            skiprows=1, unpack=True, dtype=np.int)
        nprogs += p
        nprogs_written += npw
        prog_ints += i
        npmprogs += pmp

    p, npw,  i, pmp = np.loadtxt(debfile('prog_collective_metadata', 1),
                        skiprows=1, unpack=True, dtype=np.int)

    if nprogs != p:
        levprint(1, "Prog metadata: error in nprogs")
    if prog_ints != i:
        levprint(1, "Prog metadata: error in progenitor ints written (progenitorcount_written)")
    if nprogs_written != npw:
        levprint(1, "Prog metadata: error in nprogs_written")
    if npmprogs != pmp:
        levprint(1, "Prog metadata: error in npmprogs")

    if verbose:
        levprint(1, "finished.")

   
    #----------------------------------------------------------------------------------
    if verbose:
        levprint(1, "Comparing written progenitor data to snapshot data")
    #----------------------------------------------------------------------------------
    # Read in unbinding files from earlier snapshot and compare values

    #  pastdir = os.path.join(os.getcwd(), "output_"+str(outnr-1).zfill(5))
    #  if not os.path.exists(pastdir):
    #      levprint(1, "previous snapshot directory doesn't exists. Can't do explicit progenitor metadata checks.")
    #      levprint(1, "dir I look for is:", pastdir)
    #      levprint(0, "finished progenitor metadata check.")
    #      return
    fnames = [ os.path.join(outputdir, "debug_mtree-unbinding_dump_after.txt"+str(cpu+1).zfill(5)) for cpu in range(ncpu)]
    ids = [np.loadtxt(f, skiprows=2, usecols=[0], unpack=True, dtype=np.int) for f in fnames]
    ids = np.concatenate(ids)
    ids = np.unique(ids)

    if ids.shape[0] != nprogs:
        levprint(2, "ERROR: nprogs != nr of clumps in past snapshot: nprogs=", nprogs, "nclumps=", ids.shape[0], npw, nprogs_written)

    if verbose:
        levprint(1, "finished.")

    
    
    
    
    #----------------------------------------------------------------------------------
    if verbose:
        levprint(1, "Checking if metadata is consistent with written data")
    #----------------------------------------------------------------------------------

    files = [debfile('WRITTEN_PROGENITOR_DATA', cpu+1) for cpu in range(ncpu)]
    allfiles = [np.loadtxt(f, skiprows=2, usecols=[0,3], dtype=np.int) for f in files]
    written_data = np.concatenate(allfiles)

    pint = np.sum(written_data[:,1])+2*written_data.shape[0]
    if pint != nprogs_written:
        levprint(2, "ERROR: progenitorcount_written is", prog_ints, "should be", pint, "after recounting prog data dump")

    if verbose:
        levprint(1, "finished.")


    levprint(0, "finished progenitor metadata check.")
    return






#=========================
def check_unbinding():
#==========================
    """
    Check the unbinding data for errors.
    """
    
    print("Checking unbinding.")

    if verbose:
        levprint(1, "Reading in unbinding dumps")

    #  alldata = [unbread('unbinding_dump_init',  cpu) for cpu in range(ncpu)]
    #  unb_init = np.concatenate(alldata)

    alldata = [unbread('unbinding_dump_after', cpu) for cpu in range(ncpu)]
    unb_after = np.concatenate(alldata)

    unb_after_ids, id_ind, inv = np.unique(unb_after[:]['id'], return_index=True, return_inverse=True)

    if verbose:
        levprint(1, 'Checking if "is_halo correct?" is all true')
    is_correct = unb_after[:]['hcorr']
    for i,b in enumerate(is_correct):
        if not (b==b'T'):
            print("Found error in 'is_halo_correct', clump ID", unb_after[i]['id'])
            quit()

    if verbose:
        levprint(1, 'finished.')
        levprint(1, 'testing particle counts')
        levprint(2, 'testing sum all local particles = total particles')

    locals_tot = np.zeros(unb_after_ids.shape, dtype=np.int)
    for i, ind in enumerate(inv):
        locals_tot[ind] += unb_after[i]['npown']
        if unb_after_ids[ind] != unb_after[i]['id'] :
            print("ERROR")

    for i, ind in enumerate(unb_after_ids):
        if locals_tot[i] != unb_after[id_ind[i]]['npcomp']:
            levprint(2, "error in sum over local owned particles compared to total computed particles \n\tclump id", ind, "\t", "sum:", locals_tot[i],"\t", "computed from excl mass:", unb_after[id_ind[i]]['npcomp'])

    if verbose:
        levprint(2, 'finished.')



    if verbose:
        levprint(2, 'testing nclmppart <= nclmpparttot')
    for u in unb_after :
        if u['nclmppart'] > u['nclmpparttot']:
            levprint(2, "error: nclmppart > nclmpparttot for clump ", u['id'])
    if verbose:
        levprint(2, 'finished.')


    if verbose:
        levprint(2, 'testing nclmpparttot >= npart computed from mass')
    for u in unb_after :
        if u['npcomp'] > u['nclmpparttot']:
            levprint(2, "error: npart computed from mass > nclmpparttot for clump ", u['id'])
    if verbose:
        levprint(2, 'finished.')


    levprint(0, "finished unbinding check.")

    return



#==============================
def debfile(name, cpu):
#==============================
    """
    Generate debugging filename
    """
    fname = ''.join(['debug_mtree-', name, '.txt', str(cpu).zfill(5)])
    return os.path.join(outputdir, fname)



#==============================
def levprint(level=0, *obj):
#==============================
    """
    Print with indentation levels.
    """
    for i in range(level):
        print("  ", end='')
    print(*obj)
    return
    




#============================
def read_cmdlineargs():
#============================
    """
    Read cmd line arguments.
    """

    import argparse

    global outnr, outputdir, verbose

    parser = argparse.ArgumentParser(description='Check the -DMTREEDEBUG output for consistency.')
    parser.add_argument('output_number', help='snapshot number or output_XXXXX directory')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='verbosity of script')

    args = parser.parse_args()
    output_number = args.output_number
    verbose = args.verbose

    if 'output_' in output_number:
        outputdir = output_number
        outnr = int(output_number[:-5])
    else:
        try:
            outnr = int(output_number)
        except ValueError:
            print("Invalid output number/directory given.")
            quit()
        
        outputdir = 'output_'+str(outnr).zfill(5)
        outputdir = os.path.join(os.getcwd(), outputdir)
        if not os.path.exists(outputdir):
            print("didn't find output directory ", outputdir)
            print("Try again...")
            quit()

    if verbose:
        print("working for output", outputdir)

    return




#===========================
def read_info_file():
#===========================
    """
    Reads info file for ncpu
    """

    global ncpu

    infofile = outputdir+'/'+'info_'+outputdir[-5:]+'.txt'
    f = open(infofile, 'r')
    ncpuline = f.readline()
    line = ncpuline.split()
    f.close()
    
    ncpu = int(line[-1])

    if verbose:
        print("Found ncpu:", ncpu)

    return




#============================
def unbread(name, cpu):
#============================
    """
    Shorthand to read unbinding dumps in in a list generator
    """

    res = np.genfromtxt(
            debfile(name, cpu+1),
            dtype=udtp,
            skip_header=2,
            usecols=([0,1,2,3,4,5,6,7,8]),
            encoding='utf8',
            unpack=True
            )
    return res





#======================
def main():
#======================
    """
    Main calling sequence.
    """

    read_cmdlineargs()
    read_info_file()

    check_unbinding()
    check_prog_metadata()



#===================================
if __name__ == '__main__':
#===================================
    main()
