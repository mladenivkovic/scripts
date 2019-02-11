#!/usr/bin/python3


#------------------------------------------------
#   Change python2 print blabla to python3
#   print(blabla)
#   usage:
#   fix_python_print.py file1 file2 ...
#------------------------------------------------


#==================================
def fix_print(filename):
#==================================

    import os

    if not os.path.exists(filename):
        print("file", filename, " doesn't exist.")
        return

    f = open(filename, 'r')
    contents = f.readlines()
    f.close()

    
    #--------------------------
    # Search for print calls
    #--------------------------
    
    for i in range(len(contents)):
        line = contents[i]
        if 'print ' in line:
            newline = line.replace("print ", "print(")

            # find last character in line
            # last character is newline character, so skip that by default
            for j in range(len(newline)-2, 0, -1):
                if newline[j] != " ":
                    newline = newline[:j+1]
                    newline+=(")\n")
                    contents[i] = newline
                    break
        elif 'print\n' in line:
            newline = line.replace("print", "print()")
            contents[i] = newline


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
        fix_print(arg)
    

