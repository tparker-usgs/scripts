#!/usr/bin/env python

import socket

s = socket.socket()
host = 'pubavo1.wr.usgs.gov'
port = 16023

s.connect((host, port))
s.send("MENU: 0 SCNL\n")
char = ''
str = ''
while char != '\n':
    old_char = char
    char = s.recv(1);
    if old_char == ' ' and char == ' ':
        #print(str)
        words = str.split(" " )
        if len(words) > 2:
            sid = int(words[0])
            st = float(words[5])
            et = float(words[6])
            if et <= st:
                print("found: " + str)
        str = ''
    else:
        str += char
print(str)
s.close                     # Close the socket when done
