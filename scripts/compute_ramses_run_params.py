#!/usr/bin/env python3


nparttot = 1024**3
cores_per_node = 36
#  cores_per_node = 36
mem_per_node = 64
#  mem_per_node = 128 # largemem
fact_grid_part = 4./5 # ngrid / npart
fact_partmin = 1.7      # minimal multiplication factor for npart: npart = fact_partmin * npartmin

def ngridmax(npartmax):
    return fact_grid_part*npartmax

def memusage(npartmax):
    """ for DMO """
    return 0.7*(ngridmax(npartmax)*1e-6 + npartmax*1e-7)

minpart = fact_partmin * nparttot
minnodes = int(memusage(minpart)/mem_per_node)+1


for i in range(5):
    print("Number of nodes:\t", minnodes)
    print("Cores per node:\t", cores_per_node)
    minpart_per_cpu = minpart / minnodes / cores_per_node
    memrest_node = mem_per_node - memusage(minpart)/minnodes
    print("npartmax\t", minpart_per_cpu)
    print("ngridmax\t", ngridmax(minpart_per_cpu))
    print("Remaining memory per node:\t", memrest_node)
    print("                  per cpu:\t", memrest_node/cores_per_node)
    print("===============================================================")
    minnodes += 1 

