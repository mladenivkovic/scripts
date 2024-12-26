#!/usr/bin/env python3

#===================================================
# create title link for rst file based on filename
#===================================================


import sys

fname = sys.argv[1]


f = open(fname)

lines = f.readlines()

indstart = 0
cleanup = ''


def rreplace(s, old, new, occurrence=1):
    """
    Replace old with new starting from behind
    """
    li = s.rsplit(old, occurrence)
    return new.join(li)



for l in range(len(lines)):
    cleanup = lines[l].strip()

    if '.. _' in cleanup and ':' in cleanup:

        # already has title
        quit()

    # otherwise, if you find a title before a link
    elif '=====' in cleanup:
        break
    elif '-----' in cleanup:
        break
    elif '~~~~~' in cleanup:
        break

f.close()



# generate link name from filename
link = fname.replace('.tex', '')
link = fname.replace('.rst', '')
link = link.replace(' ', '_')
link = '.. _'+link+': \n\n\n'


# write file
f = open(fname, 'w')
f.write(link)
for l in lines:
    f.write(l)

f.write('\n\n')
f.close()
