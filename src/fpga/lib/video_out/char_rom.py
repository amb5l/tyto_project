################################################################################
## char_rom.py                                                                ##
## Generates VHDL for character ROM from BMP files.                           ##
################################################################################
## (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of The Tyto Project. The Tyto Project is free software:  ##
## you can redistribute it and/or modify it under the terms of the GNU Lesser ##
## General Public License as published by the Free Software Foundation,       ##
## either version 3 of the License, or (at your option) any later version.    ##
## The Tyto Project is distributed in the hope that it will be useful, but    ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Tyto Project. If not, see     ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

import sys
import math

def get_uint32(offset):
    global bmp
    r = bmp[offset]
    r += bmp[offset+1] << 8
    r += bmp[offset+2] << 16
    r += bmp[offset+3] << 32
    return r

def get_uint16(offset):
    global bmp
    r = bmp[offset]
    r += bmp[offset+1] << 8
    return r

def check_uint32(offset, value, string):
    global bmp
    r = get_uint32(offset)
    if r != value:
        print('error: '+string+': expected'+str(value)+', found '+str(r))
        sys.exit(1)

def check_uint16(offset, value, string):
    global bmp
    r = get_uint16(offset)
    if r != value:
        print('error: '+string+': expected'+str(value)+', found '+str(r))
        sys.exit(1)

def get_pixel(x, y):
    global bmp
    global bmp_hdr_size
    global bmp_width
    global bmp_height
    i = 14+bmp_hdr_size+(x*3)+(((bmp_height-1)-y)*bmp_width*3)
    return (bmp[i+2],bmp[i+1],bmp[i])

if len(sys.argv) != 4:
    print('usage: char_rom.py filename.bmp w h')
    print('  filename.bmp = 24 bit BMP file containing rectangular array of 256 character patterns')
    print('  w,h = width,height of character in pixels')

bmp_filename = sys.argv[1]
w = int(sys.argv[2])
h = int(sys.argv[3])
out_filename = bmp_filename.replace('.bmp','.vhd')
filename_root = bmp_filename.replace('.bmp','')
r_width = math.ceil(math.log2(h))

print('reading '+str(w)+'x'+str(h)+' character patterns from '+bmp_filename);
with open(bmp_filename, 'rb') as f:
    bmp = bytearray(f.read())
print('writing to '+out_filename);

bmp_hdr_size = get_uint32(14)
bmp_width = get_uint32(18)
bmp_height = get_uint32(22)
check_uint16(26, 1, 'color planes')
check_uint16(28, 24, 'bits per pixel')
check_uint16(30, 0, 'compression method')
l = 14+bmp_hdr_size+(3*bmp_width*bmp_height)
if len(bmp) != l:
    print('error: bad length: expected '+str(l)+', found '+str(len(bmp)))
    sys.exit(1)
p = bmp_width*bmp_height/256
if p != w*h:
    print('error: pixels per character: expected '+str(w*h)+', found '+str(p))
    sys.exit(1)

colours_found = []
for x in range(0, bmp_width):
    for y in range(0, bmp_height):
        rgb = get_pixel(x,y)
        if rgb not in colours_found:
            colours_found.append(rgb)
if len(colours_found) != 2:
    print('error: colours: expected 2, found '+str(len(colours_found)))
    print(colours_found)
    sys.exit(1)
c1 = 0
c2 = 0
for x in range(0, bmp_width):
    for y in range(0, bmp_height):
        rgb = get_pixel(x,y)
        if rgb == colours_found[0]:
            c1 += 1
        else:
            c2 += 1
if c1 > c2:
    rgb_bg = colours_found[0]
    rgb_fg = colours_found[1]
else:
    rgb_bg = colours_found[1]
    rgb_fg = colours_found[0]

char_data = [[] for i in range(256)]
cw = int(bmp_width/w)
for c in range(0, 256):         # 256 characters
    cx = c % cw
    cy = int(c/cw)
    for py in range(0, h):       # h rows per character
        r = 0
        for px in range(0, w):   # w pixels per row
            x = (cx*w)+px
            y = (cy*h)+py
            rgb = get_pixel(x,y)
            if rgb == rgb_fg:
                r += 2**((w-1)-px)
        char_data[c].append('{:08b}'.format(r))

with open(out_filename,'w') as f:
    f.write('library ieee;\n')
    f.write('use ieee.std_logic_1164.all;\n')
    f.write('\n')
    f.write('entity '+filename_root+' is\n')
    f.write('    port (\n')
    f.write('        clk : in    std_logic;\n')
    f.write('        r   : in    std_logic_vector('+str(r_width-1)+' downto 0);\n')
    f.write('        a   : in    std_logic_vector(7 downto 0);\n')
    f.write('        d   : out   std_logic_vector(7 downto 0)\n')
    f.write('    );\n')
    f.write('end entity '+filename_root+';\n')
    f.write('\n')
    f.write('architecture infer_bram of '+filename_root+' is\n')
    f.write('begin\n')
    f.write('\n')
    f.write('    process(clk)\n')
    f.write('    begin\n')
    f.write('        if rising_edge(clk) then\n')
    f.write('            case a & r is\n')
    f.write('\n')
    rf = '{:0'+str(r_width)+'b}'
    for c in range(0,256):
        for r in range(0,2**r_width):
            f.write('                when x"'+'{:02x}'.format(c)+ \
                '" & "'+rf.format(r)+'" => d <= "'+char_data[c][r]+ \
                '"; -- '+(char_data[c][r].replace('0','.')).replace('1','#')+'\n')
        f.write('\n')
    f.write('                when others => d <= (others => \'0\');\n')
    f.write('\n')
    f.write('            end case;\n')
    f.write('        end if;\n')
    f.write('    end process;\n')
    f.write('\n')
    f.write('end architecture infer_bram;\n')

sys.exit(0)
