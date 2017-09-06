#!/usr/bin/env python

import socket

s = socket.socket()
host = 'pubavo1.wr.usgs.gov'
port = 16023

s.connect((host, port))
s.send("MENU: GS SCNL\n")
char = ''
str = ''
while char != '\n':
    old_char = char
    char = s.recv(1);
    if old_char == ' ' and char == ' ':
        print(str)
        str = ''
    else:
        str += char
print(str)
s.close                     # Close the socket when done
