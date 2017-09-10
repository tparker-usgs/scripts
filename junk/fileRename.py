#!/usr/bin/env python

import os.path
import sys
import re

dir = r" ".join(sys.argv[1:len(sys.argv)])
print(dir)

num = dir[-2:]

odir = os.getcwd()
os.chdir(dir)
for f in os.listdir('.'):

    f2 = re.sub(r"n - " + num, "n - s" + num + "e", f)
    print(num,f, f2)
    os.rename(f,f2)
os.chdir(odir)

