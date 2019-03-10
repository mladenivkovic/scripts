#!/usr/bin/python3


import pNbody as pn
from pNbody import ic
from numpy import random as r
import numpy as np


nfiles = 8
for i in range(nfiles):
    nb = ic.box(10, 1, 1, 1, ftype='gh5')
    fname = 'output.'+str(i).zfill(2)+'.gh5'
    nb.rename(fname)
    nb.translate([i, i, 0])
    nb.boxsize = nfiles

    nb.write()
    nb.display(size=(nfiles,nfiles),shape=(256,256),palette='light')

    nb.info()
