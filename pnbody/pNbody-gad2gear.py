#!/usr/bin/env python3

###########################################################################################
#  package:   Gtools
#  file:      pNbody-gad2gear.py
#  brief:     convert gadget binary IC file to gear type IC file
#  copyright: GPLv3
#             Copyright (C) 2019 EPFL (Ecole Polytechnique Federale de Lausanne)
#             LASTRO - Laboratory of Astrophysics of EPFL
#  author:    Loic Hausammann, Mladen Ivkovic
#
# This file is part of Gtools.
###########################################################################################


from pNbody import *


usage="""
This script converts a gadget2 type initial condition file
to a GEAR type IC file.
Needs pNbody to be installed.

Usage:
    pNbody-gad2gear.py gadget-IC.dat [outputfilename_gear.dat]

    outputfilename_gear.dat is optional. If you don't
    specify it, the script will create a file called
    <gadget-ic-filename-you-gave-as-first-argument>-GEAR.dat
"""


try:
    file1 = sys.argv[1]
except IndexError:
    print(usage)
    quit()

try:
    file2 = sys.argv[2]
except IndexError:
    cut = 0
    append = '-GEAR'
    for i in range(len(file1)):
        if file1[-i-1] == '.':
            cut = len(file1)-i-1
            break
    if cut > 0:
        file2 = file1[:cut]+append+file1[cut:]
    else:
        file2 = file1+append



nb = Nbody(file1,ftype='gadget')

nb.tpe = where(nb.tpe==1,2,nb.tpe)

nb.init()
nb.rename(file2)
nb.write()
