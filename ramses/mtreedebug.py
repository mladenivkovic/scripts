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
ncpu             = 1
outnr            = None
outputdir        = None
verbose          = False
identical_masses = False  

np.warnings.filterwarnings('ignore') # ignore 'empty file' warnings

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

#==================================
def check_mostbounds():
#==================================
    """
    check whether the most_bound particle lists correspond to the
    particle lists that are written in progenitor particle lists
    """

    levprint(0, 'Checking most_bound lists.')

    nmost_bound = 0
    nmlist = os.path.join(outputdir, 'namelist.txt')

    if os.path.exists(nmlist):
        f = open(nmlist, 'r')
        for line in f.readlines():
            if 'nmost_bound' in line:
                nmb, eq, rest = line.partition("=")
                nmost_bound = int(rest.split()[0])
        f.close()

    if nmost_bound == 0:
        levprint(1, "Didn't find nmost_bound in namelist. Setting nmost_bound to default value 200")
        nmost_bound = 200

   
    for cpu in range(ncpu):

        myid = cpu+1

        #-----------------------------------------
        # Read in mostbound_particles data
        #-----------------------------------------

        mbl = np.atleast_2d(np.loadtxt(debfile('mostbound_particles', myid), skiprows=1, dtype=np.int))

        # check for virtuals in mostbound_particles without local mostbound particles
        to_remove = []
        for i in range(mbl.shape[0]):
            if mbl[i, 0] == -1:
                if mbl[i,2] < 1:
                    levprint(2, "WARNING: found halo with no local particles but excl_mass > 0 on myid", myid)
                to_remove.append(i)
        # remove unnecessary lines from data
        if len(to_remove) > 0:
            mbl = np.delete(mbl, np.array(to_remove), axis=0)

        nprogs = mbl.shape[0]

        #-----------------------------------------
        # Read in WRITTEN_PROGENITOR_DATA data
        #-----------------------------------------
        progfile = debfile('WRITTEN_PROGENITOR_DATA', myid)
        f = open(progfile, 'r')
        proglines = f.readlines()

        pnprogs = len(proglines) - 2

        pclid = np.empty(pnprogs, dtype=np.int)
        pnp   = np.empty(pnprogs, dtype=np.int)
        pgal  = np.empty(pnprogs, dtype=np.int)
        ppart = np.zeros((pnprogs,nmost_bound), dtype=np.int)

        for i in range(pnprogs):
            linedata = proglines[i+2].split()
            pclid[i] = int(linedata[0])
            pnp[i] = int(linedata[3])
            g = int(linedata[4])
            if g<0:
                pgal[i] = g
                # replace positive value for particle to compare with mostbound_particles output
                linedata[4] = str(-g)
            else:
                pgal[i] = 0

            for j, p in enumerate(linedata[4:]):
                ppart[i,j] = int(p)


        
        #--------------------------------
        # PERFORM CHECKS
        #--------------------------------

        # check for correct galaxies in mostbound_particles
        for i in range(nprogs):
            if mbl[i,2] == 1: # first_bound = 1
                if mbl[i,3]  > 0:
                    levprint(2, "ERROR: first_bound=1, but no galaxy for Clump ID", mld[i,0], "on myid=", myid)

        # check that you have the same number of progenitors
        if pnprogs != nprogs:
            levprint(2, "ERROR: Not equal number of progenitors in WRITTEN_PROGENITOR_DATA (", pnprogs, 
            ") and mostbound_particles (", nprogs, ") files for myid", myid)
        progmin = min(nprogs, pnprogs)
        if nprogs > pnprogs:
            levprint(2, "WARNING: won't fully check mostbound_particles file because nprogs > pnprogs")
        if nprogs < pnprogs:
            levprint(2, "WARNING: won't fully check WRITTEN_PROGENITOR_DATA file because nprogs < pnprogs")


        # check that number of particles is correct
        for i in range(progmin):
            np_mbl = 0
            np_pw = 0
            for j in range(nmost_bound):
                if mbl[i, j+4] > 0:
                    np_mbl += 1
                if ppart[i, j] > 0:
                    np_pw += 1

            if np_mbl != mbl[i,1]:
                levprint(2, "ERROR: incorrect number of particles in mostbound_particles for clump", mbl[i,0], "at myid", myid)
            if np_pw != pnp[i]:
                levprint(2, "ERROR: incorrect number of particles in WRITTEN_PROGENITOR_DATA for clump", pclid[i], "at myid", myid)


        # check for identical clump IDs and identical particles
        for i in range(progmin):
            if mbl[i,0] != pclid[i]:
                levprint(2, "ERROR: Not identical clump IDs found for myid", myid, ":", mbl[i,0], " in mostbound_particles and", pclid[i], "WRITTEN_PROGENITOR_DATA")
            else:
                add = 0
                for j in range(nmost_bound):
                    while (mbl[i, 4+j+add] == 0) and (j+add < nmost_bound-1):
                        add += 1
                    if ppart[i,j] != mbl[i, j+4+add]:
                        levprint(2, "ERROR: Not identical particles for clump", pclid[i], "on myid", myid, ppart[i,j], mbl[i, j+4+add])
                    if j+add == nmost_bound-1:
                        break

    levprint(0, "finished most_bound check.")


    return


#===================================
def check_particle_masses():
#===================================
    """
    Check whether particles have identical masses
    """
    import scipy.io

    levprint(0,"Checking for identical particle masses")

    mpart = None

    for cpu in range(ncpu):
        srcfile = outputdir+'/part_'+str(outnr).zfill(5)+'.out'+str(cpu+1).zfill(5)
        if verbose:
            levprint(1, "Looking through file", srcfile)

        ffile = scipy.io.FortranFile(srcfile, 'r')

        #-----------------------
        # First read headers
        #-----------------------

        ncpu_f      = ffile.read_ints()
        ndim        = ffile.read_ints()
        nparts      = ffile.read_ints()
        localseed   = ffile.read_ints()
        nstar_tot   = ffile.read_ints()
        mstar_tot   = ffile.read_reals('d')
        mstar_lost  = ffile.read_reals('d')
        nsink       = ffile.read_ints()

        del ncpu_f, ndim, localseed, nstar_tot, mstar_tot, mstar_lost, nsink # don't need this stuff

        # m = np.empty(nparts, dtype=np.float)


        #----------------------
        # Read particle data
        #----------------------

        m = ffile.read_reals('d') # x
        m = ffile.read_reals('d') # y
        m = ffile.read_reals('d') # z
        m = ffile.read_reals('d') # vx
        m = ffile.read_reals('d') # vy
        m = ffile.read_reals('d') # vz
        m = ffile.read_reals('d') # mass
        ffile.close()

        masses = np.unique(m)
        if masses.shape[0] > 1 :
            levprint(2, "WARNING: found non-identical masses:", masses)
            levprint(1, "finished.")
            return False
        
        if mpart is None:
            mpart = masses
        else:
            if mpart[0] != masses[0]:
                levprint(2, "WARNING: found non-identical masses:", masses[0], mpart[0])
                levprint(1, "finished.")
                return False

    return True



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
    ids = [np.atleast_1d(np.loadtxt(f, skiprows=2, usecols=[0], unpack=True, dtype=np.int)) for f in fnames]
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
    allfiles = np.array([np.loadtxt(f, skiprows=2, usecols=[0,3], dtype=np.int, ndmin=2) for f in files])
    nonempty = []
    for f in allfiles:
        if f.size > 0:
            nonempty.append(f)
    written_data = np.concatenate(nonempty)

    pint = np.sum(written_data[:,1])+2*written_data.shape[0]
    if pint != prog_ints:
        levprint(2, "ERROR: progenitorcount_written is", prog_ints, "should be", pint, "after recounting prog data dump")

    if verbose:
        levprint(1, "finished.")



    
    #----------------------------------------------------------------------------------
    if verbose:
        levprint(1, "Checking if past merged metadata is consistent with written data")
    #----------------------------------------------------------------------------------

    files = [debfile('WRITTEN_PAST_MERGED_PROGENITOR_DATA', cpu+1) for cpu in range(ncpu)]
    allfiles = [np.loadtxt(f, skiprows=2, usecols=[0,3], dtype=np.int) for f in files]
    written_data = np.concatenate(allfiles)

    pmprogs = written_data.shape[0]
    if pmprogs != npmprogs:
        levprint(2, "ERROR: npmprogs is", npmprogs, "should be", pmprogs, "after recounting pmprog data dump")

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

    if identical_masses:
        if verbose:
            levprint(2, 'testing sum all local particles = total computed particles')

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
    else:
        if verbose:
            levprint(2, 'skipping sum local particles = total computed from mass because non-identical particle masses')



    if verbose:
        levprint(2, 'testing nclmppart <= nclmpparttot')
    for u in unb_after :
        if u['nclmppart'] > u['nclmpparttot']:
            levprint(2, "error: nclmppart > nclmpparttot for clump ", u['id'])
    if verbose:
        levprint(2, 'finished.')


    if identical_masses:
        if verbose:
            levprint(2, 'testing nclmpparttot >= npart computed from mass')
        for u in unb_after :
            if u['npcomp'] > u['nclmpparttot']:
                levprint(2, "error: npart computed from mass > nclmpparttot for clump ", u['id'])
        if verbose:
            levprint(2, 'finished.')
    else:
        levprint(2, 'skipping test nclmparttot >= npart computed from mass because non-identical particle masses')


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
        if output_number[-1] == "/":
            output_number = output_number[:-1]
        outputdir = output_number
        outnr = int(output_number[-5:])
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
    return np.atleast_1d(res)





#======================
def main():
#======================
    """
    Main calling sequence.
    """

    global identical_masses

    read_cmdlineargs()
    read_info_file()

    identical_masses = check_particle_masses()
    check_unbinding()
    check_prog_metadata()
    check_mostbounds()



#===================================
if __name__ == '__main__':
#===================================
    main()
