################################################################################
## video_mode.py                                                              ##
## Converts video_mode.csv to VHDL.                                           ##
################################################################################
## (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        ##
##                                                                            ##
## This file is part of The Barn Repository. The Barn Repository is free      ##
## software: you can redistribute it and/or modify it under the terms of the  ##
## GNU Lesser General Public License as published by the Free Software        ##
## Foundation, either version 3 of the License, or (at your option) any later ##
## version.                                                                   ##
## The Barn Repository is distributed in the hope that it will be useful, but ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Barn Repository. If not, see  ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

import sys

f = open('video_mode.csv', 'r')
r = []
for l in f:
    if ord(l[0]) == 239 \
    and ord(l[1]) == 187 \
    and ord(l[2]) == 191:
        l = l[3:] # remove byte order mark
    r.append(l.split(','))

types = []
names = []
for i in range(0, len(r[0])):
    if r[0][i] == '':
        types.append('')
        names.append('')
    else:
        types.append(r[0][i].rstrip())
        names.append(r[1][i].rstrip())

o = []
o.append('    type video_timing_t is record');
for i in range (0, len(names)):
    if types[i] != '':
        l = ' '*8;
        l += names[i]
        l += ' '*((4*(1+int(len(max(names, key=len))/4)))-len(names[i]))
        l += ': ' + types[i] + ';'
        o.append(l)
o.append('    end record video_timing_t;');
o.append('');
l = '    type video_timings_t is array (0 to '
l += str(len(r)-3)
l += ') of video_timing_t;'
o.append(l)
o.append('');
o.append('    constant video_timings : video_timings_t := (');
for i in range(2, len(r)):
    o.append(' '*8+'(')
    for j in range(0, len(names)):
        if names[j] != '':
            l = ' '*12;
            l += names[j]
            l += ' '*((4*(1+int(len(max(names, key=len))/4)))-len(names[j]))
            value = r[i][j].rstrip()
            if types[j][:6] == 'string':
                strlen = int(types[j].split()[-1].replace(')',''))
                value += ' '*(strlen - len(value))
                value = '"' + value + '"'
            if types[j] == 'real':
                value = '{:.1f}'.format(float(value))
            if types[j] == 'bit':
                value = value.replace("+","'1'")
                value = value.replace("-","'0'")
            l += '=> ' + value
            if j < len(names)-1:
                l += ','
            o.append(l)
    l = ' '*8+')'
    if i < len(r)-1:
        l += ','
    o.append(l)
o.append('    );')

f = open('temp.vhd', 'w')
for l in o:
    f.write(l+'\n')
f.close()