#!/usr/bin/env python3

#================================================
#  Print all fields from a vtufile that you
#  provide as a cmdline arg
#================================================

import os, sys
import vtuIO

vtufilename = sys.argv[1]

if not os.path.exists(vtufilename):
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), vtufilename)

# 'interpolation_backend' is used to generate plots with seemingly
# continuous data. That's not what we're using this module for. We
# only want to read in particle data. So I use here the default
# 'interpolation_backend', which gets set anyway if it weren't
# specified, with the bonus that this way, no annoying warnings are
# printed.
vtufile = vtuIO.VTUIO(vtufilename, interpolation_backend="vtk")
point_field_names = vtufile.get_point_field_names()

print(point_field_names)

