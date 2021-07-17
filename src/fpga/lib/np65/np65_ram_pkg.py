################################################################################
## np65_ram_pkg.py                                                            ##
## Generates np65_ram_Xk_pkg.vhd where X = RAM size (kbytes).                 ##
## Builds RAM initialisation constants from specified binary files.           ##
################################################################################
## (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        ##
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

import sys, math

banks = 4 # might be 8 one day
init_vector_size = 256 # BRAM init vector size

if len(sys.argv) < 2:
    print('usage: np65_ram_pkg.py <ram size> [<address> <file>] [outpath]')
    print('example:')
    print('  np65_ram_pkg.py 128 0 test.bin 0xFC00 prereset.bin')
    print('final address/file correspond to prereset init code')
    print('default output path is the current directory')
    sys.exit(1)

ram_size = int(sys.argv[1], 0)
if ram_size != 64 and ram_size != 128 and ram_size != 256:
    print('unsupported RAM size ('+ram_size+')')
    print('supported RAM sizes: 64, 128 or 256')
    sys.exit(1)
print('RAM size = '+str(ram_size)+' kbytes')

contents = []
i = 2
while i < len(sys.argv)-1:
    addr = int(sys.argv[i], 16)
    if addr < 0 or addr >= (1024*ram_size):
        print('bad address (%s)' % sys.argv[i])
        sys.exit(1)
    i += 1
    if i >= len(sys.argv):
        print('missing filename after address '+sys.argv[i-1])
        sys.exit(1)
    filename = sys.argv[i]
    i += 1
    contents.append([addr,filename])

output_path = './'
if i < len(sys.argv):
    output_path = sys.argv[-1]

vector_prereset,_ = contents[-1]
if vector_prereset >= 2**16:
    print('init vector outside bottom 64k')
    sys.exit(1)

name = 'ram_init'
data = [0x00] * (ram_size * 1024)

# load binary file(s)

print('loading...')
for addr, filename in contents:
    print('  %s -> 0x%05X...' % (filename, addr))
    i = 0
    with open(filename, 'rb') as f:
        byte = f.read(1)
        while byte != b'':
            data[addr+i] = ord(byte)
            i += 1
            byte = f.read(1)
    f.close()

# write VHDL

if ram_size == 64:
    bram_size = 16384
else:
    bram_size = 32768
vectors_per_bram = int(bram_size/init_vector_size)
if ram_size == 256:
    brams_per_bit = 2
else:
    brams_per_bit = 1

f = open(output_path+'np65_ram_'+str(ram_size)+'k'+'_pkg.vhd', 'w')
f.write('--------------------------------------------------------------------------------\n')
f.write('-- np65_ram_'+str(ram_size)+'k'+'_pkg.vhd\n')
f.write('--\n')
f.write('-- initial RAM contents:\n')
for base_address, filename in contents:
    f.write('--   %s @ %05X\n' % (filename, base_address))
f.write('--------------------------------------------------------------------------------\n')
f.write('\n')
f.write('library ieee;\n')
f.write('use ieee.std_logic_1164.all;\n')
f.write('\n')
f.write('library xil_defaultlib;\n')
f.write('use xil_defaultlib.np65_types_pkg.all;\n')
f.write('\n')
f.write('package np65_ram_pkg is\n')
f.write('\n')
f.write('  constant ram_size : integer := '+str(ram_size)+';\n')
f.write('  constant apmsb : integer := '+str(9+int(math.log(ram_size,2)))+';\n')
f.write('  constant vector_prereset : std_logic_vector(15 downto 0) := x"%04X";\n' % vector_prereset)
f.write('\n')
f.write('  type '+name+'_prim_t is array(0 to '+str(vectors_per_bram-1)+') of bit_vector(255 downto 0); -- individual BRAM ('+str(bram_size)+' bits)\n')
if brams_per_bit == 2:
    f.write('  type '+name+'_pair_t is array(0 to 1) of '+name+'_prim_t; -- BRAM pair ('+str(2*bram_size)+' bits)\n')
    f.write('  type '+name+'_bank_t is array(0 to 7) of '+name+'_pair_t; -- 8 bit bank = 8 BRAM pairs per bank\n')
else:
    f.write('  type '+name+'_bank_t is array(0 to 7) of '+name+'_prim_t; -- 8 bit bank = 8 BRAMs per bank\n')
f.write('  type '+name+'_t is array(0 to 3) of '+name+'_bank_t; -- 4 banks\n')
f.write('\n')
f.write('  constant '+name+' : '+name+'_t :=\n')
f.write('    ( -- %d banks...\n' % banks)
for bank in range(banks):
    f.write('      ( -- 8 bits per bank...\n')
    for bank_bit in range(8):
        if brams_per_bit == 2:
            f.write('        ( -- pair of BRAMs (lower and upper)...\n')
            indent = '  '
        else:
            indent = ''
        for bit_bram in range(brams_per_bit):
            f.write(indent+'        ( -- %d vectors per BRAM...\n' % vectors_per_bram)
            for init_vector in range(vectors_per_bram):
                v = [0] * init_vector_size
                for v_bit in range(init_vector_size):
                    i = bank + (banks * (v_bit + (init_vector * init_vector_size) + (bit_bram * bram_size)))
                    v[v_bit] = (data[i] >> bank_bit) & 1
                f.write(indent+'          x"')
                for i in range(32):
                    b = 0
                    for j in range(8):
                        b += ((2**j)*v[j+(8*(31-i))])
                    f.write('%02X' % b)
                f.write('"')
                if init_vector == vectors_per_bram-1:
                    f.write('  ') # last element
                else:
                    f.write(', ')
                f.write(' -- INIT_%0.2X, ' % init_vector)
                if brams_per_bit == 2:
                    f.write('LOWER, ' if bit_bram == 0 else 'UPPER, ')
                f.write('bit %d, ' % bank_bit)
                f.write('bank %d\n' % bank)
            if brams_per_bit == 2:
                f.write(indent+'        )')
                f.write('\n' if bit_bram == brams_per_bit-1 else ',\n')
        f.write('        )')
        f.write('\n' if bank_bit == 7 else ',\n')
    f.write('      )')
    f.write('\n' if bank == banks-1 else ',\n')
f.write('    );\n')
f.write('\n');
f.write('  component np65_ram is\n');
f.write('      port (\n');
f.write('          clk_x1      : in    std_logic;\n');
f.write('          clk_x2      : in    std_logic;\n');
f.write('          advex       : in    std_logic;\n');
f.write('          if_z        : in    std_logic;\n');
f.write('          if_a        : in    std_logic_vector(apmsb downto 0);\n');
f.write('          if_d        : out   slv_7_0_t(3 downto 0);\n');
f.write('          ls_z        : in    std_logic;\n');
f.write('          ls_wp       : in    std_logic;\n');
f.write('          ls_ext      : in    std_logic;\n');
f.write('          ls_we       : in    std_logic;\n');
f.write('          ls_a        : in    std_logic_vector(apmsb downto 0);\n');
f.write('          ls_bwe      : in    std_logic_vector(3 downto 0);\n');
f.write('          ls_dw       : in    slv_7_0_t(3 downto 0);\n');
f.write('          ext_dr      : in    slv_7_0_t(3 downto 0);\n');
f.write('          ls_dr       : out   slv_7_0_t(3 downto 0);\n');
f.write('          collision   : out   std_logic;\n');
f.write('          rst         : in    std_logic;\n');
f.write('          dma_en      : in    std_logic;\n');
f.write('          dma_a       : in    std_logic_vector(apmsb downto 3);\n');
f.write('          dma_bwe     : in    std_logic_vector(7 downto 0);\n');
f.write('          dma_dw      : in    slv_7_0_t(7 downto 0);\n');
f.write('          dma_dr      : out   slv_7_0_t(7 downto 0)\n');
f.write('      );\n');
f.write('  end component np65_ram;\n');
f.write('\n');
f.write('  component np65_ram_bank is\n');
f.write('      generic (\n');
f.write('          init        : ram_init_bank_t;\n');
f.write('          rpm_name    : string := ""\n');
f.write('      );\n');
f.write('      port (\n');
f.write('          clk     : in    std_logic;\n');
f.write('          clr_a   : in    std_logic;\n');
f.write('          ce_a    : in    std_logic;\n');
f.write('          we_a    : in    std_logic;\n');
f.write('          addr_a  : in    std_logic_vector(apmsb downto 2);\n');
f.write('          din_a   : in    std_logic_vector(7 downto 0);\n');
f.write('          dout_a  : out   std_logic_vector(7 downto 0);\n');
f.write('          clr_b   : in    std_logic;\n');
f.write('          ce_b    : in    std_logic;\n');
f.write('          we_b    : in    std_logic;\n');
f.write('          addr_b  : in    std_logic_vector(apmsb downto 2);\n');
f.write('          din_b   : in    std_logic_vector(7 downto 0);\n');
f.write('          dout_b  : out   std_logic_vector(7 downto 0)\n');
f.write('      );\n');
f.write('  end component np65_ram_bank;\n');
f.write('\n');
f.write('end package np65_ram_pkg;\n');
f.close()
