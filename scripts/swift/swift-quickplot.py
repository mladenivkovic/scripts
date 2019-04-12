#!/usr/bin/env python3

#=====================================
# a quick plot for swift outputs
#=====================================


import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors as mcolors

import h5py
import fast_histogram as fh
import subprocess
import argparse

from mpl_toolkits.axes_grid1 import make_axes_locatable, axes_size 


infile = None
weight = None
weighted = False
ptype = None

weightarraynames = {};
weightarraynames['sl'] = 'SmoothingLength'
weightarraynames['mass'] = 'Mass'
weightarraynames['dens'] = 'Density'

outfile = None

nbinsdefault = 200
nbins = nbinsdefault


#==========================
def getargs():
#==========================
    """
    Read cmd line args.
    """

    parser = argparse.ArgumentParser(description='''
        A program to quickly plot swift outputs.
        Will histogram by default number density on xy plane.
            ''')


    #  parser.add_help(True)
    parser.add_argument('filename')
    parser.add_argument('--mass', 
            dest='weight', 
            action='store_const', 
            const='mass', 
            help='use mass as weight')
    parser.add_argument('--sl', 
            dest='weight', 
            action='store_const', 
            const='h', 
            help='use smoothing length as weight')
    parser.add_argument('--dens', 
            dest='weight', 
            action='store_const', 
            const='dens', 
            help='use particle density as weight')
    parser.add_argument('--pt',
            dest='ptype', 
            action='store',
            default='PartType0',
            help='PartType to use. Default=PartType0')
    parser.add_argument('--dm', 
            dest='ptype', 
            action='store_const', 
            const='PartType1', 
            help='use dark matter particle type (PartType1)')
    parser.add_argument('--nx', 
            dest='nx', 
            type=int,
            action='store', 
            default=nbinsdefault,
            help='How many histogram bins to use.')

    args = parser.parse_args()

    global infile, weight, weighted, ptype, nbins
    infile = args.filename
    weight = args.weight
    ptype = args.ptype
    nbins = args.nx

    if weight is not None:
        weighted = True

    return




#===============================
def histogram():
#===============================
    """
    Read in data, histogram them
    """

    global nbins

    f = h5py.File(infile)

    x = f[ptype]['Coordinates'][:, 0]
    y = f[ptype]['Coordinates'][:, 1]

    try:
        xmax = f['Header'].attrs['BoxSize'][0]
        ymax = f['Header'].attrs['BoxSize'][1]
    except IndexError:
        xmax = f['Header'].attrs['BoxSize']
        ymax = xmax

    if weighted:
        w = f[ptype][weightarraynames[weight]][:] 
    else:
        w = None

    hist = fh.histogram2d(x, y, range=[[0, xmax], [0, ymax]], bins=[nbins+1, nbins+1], weights=w)

    return [hist, xmax, ymax]






#===============================
def make_plot(histdata):
#===============================
    """
    plot and save.
    """

    global outfile

    hist = histdata[0]
    xmax = histdata[1]
    ymax = histdata[2]

    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(111, aspect='equal')

    # shift the x/y values:
    # hist[0,0] should be plotted at (dx, dy)
    dx = 0.5*xmax/nbins
    dy = 0.5*ymax/nbins

    minval = np.abs(hist).min()

    norm = mcolors.Normalize()

    if minval == 0:
        linthresh = 1e-3
    else:
        linthresh =  minval

    im=ax.imshow(hist.T, origin='lower', 
            extent=(-dx, xmax+dx, -dy, ymax+dy), 
            cmap='YlGnBu_r', 
            interpolation='bicubic',
            norm=mcolors.SymLogNorm(linthresh))

    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="2%", pad=0.05)
    fig.colorbar(im, cax=cax)



    ax.set_xlabel('x')
    ax.set_ylabel('y')
    
    if weighted:
        ax.set_title('Weighted by '+weight)
    else:
        ax.set_title('Number density')


    fig.suptitle(infile)
    plt.tight_layout(rect=(0, 0, 1, 0.97))



    if infile[-5:] == '.hdf5':
        outfile = infile.replace('.hdf5', '') 
    elif infile[-3:] == '.h5':
        outfile = infile.replace('.h5', '') 
    if weighted:
        outfile+=weight
    if nbins != nbinsdefault:
        outfile+='_nx='+str(nbins)
    outfile += '.png'

    plt.savefig(outfile, dpi=200)
    

    return




#==========================
def main():
#==========================

    getargs()
    histdata = histogram()
    make_plot(histdata)

    subprocess.run(['eog', outfile])




if __name__ == '__main__':
    main()
