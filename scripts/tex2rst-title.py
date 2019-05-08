#!/usr/bin/env python3

# Change the title from glosary project from tex
# to rst

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
    if cleanup.endswith('&'):
        cleanup=cleanup.replace('\\textbf{', '')
        cleanup=rreplace(cleanup, '}', '')
        cleanup=rreplace(cleanup, '&', '')
        cleanup=cleanup.strip()

        indstart = l
        break

f.close()

cleanup +='\n'


# generate underscore to format for title
underscore = ''
for i in cleanup:
    underscore+='='

if '$' in cleanup:
    for i in range(12):
        underscore += '='


underscore += '===\n\n'

# generate link name from filename
link = fname.replace('.tex', '')
link = link.replace(' ', '_')
link = '.. _'+link+': \n\n'


# write file
frst = fname.replace('.tex', '.rst')
f = open(frst, 'w')
f.write(link)
f.write(cleanup)
f.write(underscore)
for l in range(indstart+1, len(lines)):
    f.write(lines[l])

f.write('\n')
f.close()
