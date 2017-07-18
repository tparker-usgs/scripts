#!/usr/bin/env python
import re
from datetime import datetime
import pandas as pd

date = None
f = open('testbuild.log.bak', 'r')
date_pattern = re.compile('.* UTC 2017')
time_pattern = re.compile('(\d{2})m(\d\d?\.\d*)s$')

#Date line: Tue Jul 11 18:00:01 UTC 2017

results = pd.Dataframe(columns=["date", "runtime"])
for line in f:
    m = date_pattern.match(line)
    if m:
        date = datetime.strptime(line, '%a %b %d %H:%M:%S UTC %Y\n')
        print "Date line: " + line,
        print "Date: " + str(date)
        continue

    m = time_pattern.match(line)
    if m:
        time = float(m.group(2))
        time += float(m.group(1)) * 60
        print "Time line: " + line,
        print "Time: " + str(time)
        if date:
            results.append((date, time))
            date = None
        continue

    print "Junk: " + line,
    time = None
    date = None
    
print results    
