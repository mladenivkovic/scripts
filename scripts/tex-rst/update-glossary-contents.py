#!/usr/bin/env python3

#-----------------------------------------------------------------
# Checkfor new files  in this directory by checking whether they 
# are mentioned in .checked_files file.
# If they are new, then for each file, ask to which glossary
# chapter you want to add them.
# Always adds it to the CONTENTS_*_all.rst by default.
#-----------------------------------------------------------------





#=======================
def get_filelist():
#=======================
    """
    Get list of .rst files and CONTENTS_* files.
    """

    import os

    allfiles = os.listdir(os.getcwd())

    rstcount = 0
    contentcount = 0
    for f in allfiles:
        if f.endswith('.rst'):
            rstcount += 1
            if f.startswith('CONTENTS_'):
                contentcount += 1


    if contentcount == 0:
        print('found no CONTENT_* files. exiting.')
        quit()
    if rstcount == 0:
        print('found no .rst files. exiting.')
        quit()



    filelist = ['' for i in range(rstcount-contentcount)]
    contentlist = ['' for i in range(contentcount)]

    rstcount = 0
    contentcount = 0
    for f in allfiles:
        if f.endswith('.rst'):
            if f.startswith('CONTENTS_'):
                contentlist[contentcount] = f
                contentcount += 1
            else:
                filelist[rstcount] = f
                rstcount += 1

    filelist = sorted(filelist, key=lambda s:s.lower())
    contentlist = sorted(contentlist, key=lambda s:s.lower())

    return filelist, contentlist



#========================================
def process_contentfiles(contentfiles):
#========================================
    """
    Get a dict of content names and filenames,
    and find the '_all.rst' file

    return the all-file, a dictionnary of nice names from
    the filename 
    """


    filedict = {}

    allfile = None
    subcontfiles = ['' for i in range(len(contentfiles)-1)]

    for c in contentfiles:
        if c.endswith('_ALL.rst'):
            allfile = c

        else:
            name=c.replace('CONTENTS_', '')
            name = name.replace('.rst', '')
            name = name.replace('_', ' ')
            name = name.replace('-', ' ')

            filedict[c] = name

    return allfile, filedict





#======================================
def read_contents(allfile, contnamedict):
#======================================
    """
    Read the current contents in the contents files
    """

    startinds = {}
    contents = {}
    
    print(allfile)

    for c in list(contnamedict.keys())+[allfile]:

        f = open(c)
        lines = f.readlines()
        for i, l in enumerate(lines):
            if '.. toctree::' in l:
                startind = i+1
                while ':' in lines[startind] or lines[startind].strip()=='':
                    startind += 1

                break
                # skip another line that has to be an empty line
                startind += 1

        endind = len(lines)
        for i in range(startind, len(lines)):
            if lines[i].strip()=='':
                endind = i
                print(c, endind)
                break

        clines = ['' for i in range(startind, endind)]
        for i in range(endind-startind):
            clines[i] = lines[i+startind].strip()+'.rst'

        startinds[c] = startind
        contents[c] = clines

        f.close()



    
    return contents, startinds



#=========================
def get_checkedfiles():
#=========================
    """
    Read in the list of checked files
    """

    import os

    if os.path.exists(os.path.join(os.getcwd(), '.checked_files')):
        f = open('.checked_files')
        checkedfiles = f.readlines()
        f.close()
        for i in range(len(checkedfiles)):
            checkedfiles[i] = checkedfiles[i].strip()
        return checkedfiles
    else:
        return []




#=====================================
def ask(newfile, contfilename):
#=====================================
    """
    Ask for user input whether to add newfile to contfile
    """

    satisfied = False
    while not satisfied:
        answer = input("Do you want to add "+newfile+" to "+contfilename+'? [y/n] ')
        if answer in ['y', 'Y']:
            return True
        elif answer in ['n', 'N']:
            return False
        else:
            print('I can only understand y or n')





#=============================================================================
def update_contents(contents, contnamedict, checkedfiles, filelist, allfile):
#=============================================================================
    """
    Update the contents.
    First check whether a file is in the checkedfile list.
    If not, check whether it is already in the content list.
    If not, ask whether to add it, unless it's the all-file, then add it anyway.
    """


    for f in filelist:
        if f not in checkedfiles:
            for c in list(contents.keys()):

                if f not in contents[c]:

                    if c==allfile:
                        print('adding', f, 'to all-file')
                        contents[c].append(f)

                    elif ask(f, contnamedict[c]):

                        print('adding', f, 'to', contnamedict[c])
                        contents[c].append(f)

            checkedfiles.append(f)


    


    return contents, checkedfiles




#======================================================
def write_files(checkedfiles, contents, startinds):
#======================================================
    """
    Write the resulting files.
    """

    # first the 'checkedfile'

    f = open('.checked_files', 'w')
    for line in checkedfiles:
        f.write(line+'\n')
    f.close()

    for c in list(contents.keys()):
        f = open(c, 'r')
        header = []
        for i in range(startinds[c]):
            header.append(f.readline())
        f.close()

        f = open(c, 'w')
        for line in header:
            f.write(line)

        sortedconts = sorted(contents[c], key=lambda s:s.lower())
        for line in sortedconts:
            f.write('    '+line.replace('.rst', '')+'\n')
        f.write('\n\n')


    return




#====================
def main():
#====================
    
    filelist, contentfiles = get_filelist()
    allfile, contnamedict = process_contentfiles(contentfiles)
    contents, startinds = read_contents(allfile, contnamedict)
    checkedfiles = get_checkedfiles()

    contents, checkedfiles = update_contents(contents, contnamedict, checkedfiles, filelist, allfile)

    write_files(checkedfiles, contents, startinds) 
    print('Finished updating glossary contents.')






if __name__ == '__main__':

    main()


