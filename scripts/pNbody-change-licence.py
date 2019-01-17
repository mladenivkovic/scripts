#!/usr/bin/python3


#------------------------------------------------
# Change the licence to a new format
# Usage:
#   pNbody-change-licence.py file1 file2 ...
#------------------------------------------------


#==================================
def change_license(filename):
#==================================

    import os
    if not os.path.exists(filename):
        print("file", filename, " doesn't exist.")
        return

    f = open(filename, 'r')
    contents = f.readlines()
    f.close()

    #-------------------------------
    # Check for correct shebang
    #-------------------------------

    shebang = '#!/usr/bin/env python3\n\n'
    if "#!/" in contents[0]:
        contents[0] = shebang
    else:
        contents.insert(0, shebang)


    #-------------------------------------
    # Replace stuff now
    #-------------------------------------

    # Look for first and last ''' or """
    first = 0
    last = 0
    
    for i,line in enumerate(contents):
        if "'''" in line or '"""' in line:
            if first==0:
                first = i
            else:
                last = i
                break


    #----------------------------
    # Check if licence exists
    #----------------------------

    check = False
    if first>0 and last>0:
        # check that this isn't some random docstring

        docstring = ''
        for line in contents[first:last]:
            docstring += line


        check = check or  ('author'  in docstring)
        check = check and ('pNbody'  in docstring)
        check = check and ('file'    in docstring)
        check = check and ('package' in docstring)

    
    bar = '###########################################################################################\n'





    #----------------------------
    # If licence is there
    #----------------------------
    
    if check:

        # replace first and last
        for ind in [first, last]:
            contents[ind] = bar
        
        # Replace @keywords
        kwds = [' @package   ',
                ' @file      ',
                ' @brief     ',
                ' @copyright ',
                ' @author    '
                ]

        replacements = ['#  package:   ',
                        '#  file:      ',
                        '#  brief:     ',
                        '#  copyright: ',
                        '#  author:    '
                ]

        to_insert = []
        for j, kw in enumerate(kwds):
            i = j+1
            if kw in contents[first+i]:
                contents[first+i] = contents[first+i].replace(kw, replacements[j])
            else:
                if contents[first+i].startswith(' @'):
                    contents[first+i] = replacements[j] + '\n'
                else:
                    contents.insert(first+i, replacements[j] + '\n')

        contents[first+i] += '#\n'

        # remove '@section line'
        contents.pop(first+6) 
        
        # insert LASTRO and year stuff
        contents.insert(first+5, "#             Copyright (C) 2019 EPFL (Ecole Polytechnique Federale de Lausanne)\n")
        contents.insert(first+6, "#             LASTRO - Laboratory of Astrophysics of EPFL\n")
        
        # you inserted one more line -> increase last
        last += 1

        # Comment out everything else until the end
        # starts at first+8: inserted 1 more line, last change was at first+6, after which comes '#  author:'
        for i in range(first+8, last):
            contents[i] = '# '+contents[i]


    #----------------------------
    # If licence isn't there
    #----------------------------
    else:
        add = bar
        add += '#  package:   pNbody\n'
        add += '#  file:      '+arg+'\n'
        add += '#  brief:     Image example\n'
        add += '#  copyright: GPLv3\n'
        add += '#             Copyright (C) 2019 EPFL (Ecole Polytechnique Federale de Lausanne)\n'
        add += '#             LASTRO - Laboratory of Astrophysics of EPFL\n'
        add += '#  author:    Yves Revaz <yves.revaz@epfl.ch>\n'
        add += '#\n'
        add += '# This file is part of pNbody.\n'
        add += bar
        
        contents.insert(1, add)



    #---------------------
    # Write file
    #---------------------
    f = open(filename, 'w')
    for line in contents:
        f.write(line)
    f.close()





#======================================
if __name__ == '__main__':
#======================================
    
    import sys, os

    for arg in sys.argv[1:]:
        change_license(arg)
    

