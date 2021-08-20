################################################################################
## video_mode.py                                                              ##
## Converts video_mode.csv to VHDL.                                           ##
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

o.append("--------------------------------------------------------------------------------");
o.append("-- video_mode.vhd                                                             --");
o.append("-- Video mode table.                                                          --");
o.append("--------------------------------------------------------------------------------");
o.append("-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --");
o.append("-- This file is part of The Tyto Project. The Tyto Project is free software:  --");
o.append("-- you can redistribute it and/or modify it under the terms of the GNU Lesser --");
o.append("-- General Public License as published by the Free Software Foundation,       --");
o.append("-- either version 3 of the License, or (at your option) any later version.    --");
o.append("-- The Tyto Project is distributed in the hope that it will be useful, but    --");
o.append("-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --");
o.append("-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --");
o.append("-- License for more details. You should have received a copy of the GNU       --");
o.append("-- Lesser General Public License along with The Tyto Project. If not, see     --");
o.append("-- https://www.gnu.org/licenses/.                                             --");
o.append("--------------------------------------------------------------------------------");
o.append("");
o.append("library ieee;");
o.append("use ieee.std_logic_1164.all;");
o.append("");
o.append("package video_mode_pkg is");
o.append("");
o.append("    type video_clk_sel_t is (");
o.append("            CLK_SEL_25M2,");
o.append("            CLK_SEL_27M0,");
o.append("            CLK_SEL_74M25,");
o.append("            CLK_SEL_148M5");
o.append("        );");
o.append("");
o.append("    type aspect_t is (");
o.append("            ASPECT_NULL,");
o.append("            ASPECT_4_3,");
o.append("            ASPECT_16_9");
o.append("        );");
o.append("");
o.append('    constant MODE_640x480p60    : std_logic_vector(3 downto 0) := "0000";');
o.append('    constant MODE_720x480p60    : std_logic_vector(3 downto 0) := "0001";');
o.append('    constant MODE_720x480p60w   : std_logic_vector(3 downto 0) := "0010";');
o.append('    constant MODE_1280x720p60   : std_logic_vector(3 downto 0) := "0011";');
o.append('    constant MODE_1920x1080i60  : std_logic_vector(3 downto 0) := "0100";');
o.append('    constant MODE_720x480i60    : std_logic_vector(3 downto 0) := "0101";');
o.append('    constant MODE_720x480i60w   : std_logic_vector(3 downto 0) := "0110";');
o.append('    constant MODE_1920x1080p60  : std_logic_vector(3 downto 0) := "0111";');
o.append('    constant MODE_720x576p50    : std_logic_vector(3 downto 0) := "1000";');
o.append('    constant MODE_720x576p50w   : std_logic_vector(3 downto 0) := "1001";');
o.append('    constant MODE_1280x720p50   : std_logic_vector(3 downto 0) := "1010";');
o.append('    constant MODE_1920x1080i50  : std_logic_vector(3 downto 0) := "1011";');
o.append('    constant MODE_720x576i50    : std_logic_vector(3 downto 0) := "1100";');
o.append('    constant MODE_720x576i50w   : std_logic_vector(3 downto 0) := "1101";');
o.append('    constant MODE_1920x1080p50  : std_logic_vector(3 downto 0) := "1110";');
o.append("");
o.append("    component video_mode is");
o.append("        port (");
o.append("");
o.append("            mode        : in    std_logic_vector(3 downto 0);");
o.append("");
o.append("            clk_sel     : out   std_logic_vector(1 downto 0);   -- pixel frequency select");
o.append("            dmt         : out   std_logic;                      -- 1 = DMT, 0 = CEA");
o.append("            id          : out   std_logic_vector(7 downto 0);   -- DMT ID or CEA/CTA VIC");
o.append("            pix_rep     : out   std_logic;                      -- 1 = pixel doubling/repetition");
o.append("            aspect      : out   std_logic_vector(1 downto 0);   -- 0x = normal, 10 = force 16:9, 11 = force 4:3");
o.append("            interlace   : out   std_logic;                      -- interlaced/progressive scan");
o.append("            v_tot       : out   std_logic_vector(10 downto 0);  -- vertical total lines (must be odd if interlaced)");
o.append("            v_act       : out   std_logic_vector(10 downto 0);  -- vertical active lines");
o.append("            v_sync      : out   std_logic_vector(2 downto 0);   -- vertical sync width");
o.append("            v_bp        : out   std_logic_vector(5 downto 0);   -- vertical back porch");
o.append("            h_tot       : out   std_logic_vector(11 downto 0);  -- horizontal total");
o.append("            h_act       : out   std_logic_vector(10 downto 0);  -- horizontal active");
o.append("            h_sync      : out   std_logic_vector(6 downto 0);   -- horizontal sync width");
o.append("            h_bp        : out   std_logic_vector(7 downto 0);   -- horizontal back porch");
o.append("            vs_pol      : out   std_logic;                      -- vertical sync polarity (1 = high)");
o.append("            hs_pol      : out   std_logic                       -- horizontal sync polarity (1 = high)");
o.append("");
o.append("        );");
o.append("    end component video_mode;");
o.append("");
o.append("end package video_mode_pkg;");
o.append("");
o.append("----------------------------------------------------------------------");
o.append("");
o.append("library ieee;");
o.append("use ieee.std_logic_1164.all;");
o.append("use ieee.numeric_std.all;");
o.append("");
o.append("library xil_defaultlib;");
o.append("use xil_defaultlib.video_mode_pkg.all;");
o.append("");
o.append("entity video_mode is");
o.append("    port (");
o.append("");
o.append("        mode        : in    std_logic_vector(3 downto 0);");
o.append("");
o.append("        clk_sel     : out   std_logic_vector(1 downto 0);   -- pixel frequency select");
o.append("        dmt         : out   std_logic;                      -- 1 = DMT, 0 = CEA");
o.append("        id          : out   std_logic_vector(7 downto 0);   -- DMT ID or CEA/CTA VIC");
o.append("        pix_rep     : out   std_logic;                      -- 1 = pixel doubling/repetition");
o.append("        aspect      : out   std_logic_vector(1 downto 0);   -- 0x = normal, 10 = force 16:9, 11 = force 4:3");
o.append("        interlace   : out   std_logic;                      -- interlaced/progressive scan");
o.append("        v_tot       : out   std_logic_vector(10 downto 0);  -- vertical total lines (must be odd if interlaced)");
o.append("        v_act       : out   std_logic_vector(10 downto 0);  -- vertical active lines");
o.append("        v_sync      : out   std_logic_vector(2 downto 0);   -- vertical sync width");
o.append("        v_bp        : out   std_logic_vector(5 downto 0);   -- vertical back porch");
o.append("        h_tot       : out   std_logic_vector(11 downto 0);  -- horizontal total");
o.append("        h_act       : out   std_logic_vector(10 downto 0);  -- horizontal active");
o.append("        h_sync      : out   std_logic_vector(6 downto 0);   -- horizontal sync width");
o.append("        h_bp        : out   std_logic_vector(7 downto 0);   -- horizontal back porch");
o.append("        vs_pol      : out   std_logic;                      -- vertical sync polarity (1 = high)");
o.append("        hs_pol      : out   std_logic                       -- horizontal sync polarity (1 = high)");
o.append("");
o.append("    );");
o.append("end entity video_mode;");
o.append("");
o.append("architecture synth of video_mode is");
o.append("");
o.append("    type video_timing_t is record");
for i in range (0, len(names)):
    if types[i] != '':
        l = ' '*8;
        l += names[i]
        l += ' '*((4*(1+int(len(max(names, key=len))/4)))-len(names[i]))
        l += ': ' + types[i] + ';'
        o.append(l)
o.append("    end record video_timing_t;");
o.append("");
l = '    type video_timings_t is array (0 to '
l += str(len(r)-3)
l += ') of video_timing_t;'
o.append(l)
o.append("");
o.append("    constant video_timings : video_timings_t := (");
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
o.append("    );")
o.append("")
o.append("begin");
o.append("");
o.append("    -- should infer 16 x N async ROM");
o.append("    process(mode)");
o.append("        variable i : integer;");
o.append("        variable vt : video_timing_t;");
o.append("    begin");
o.append("");
o.append("        i := to_integer(unsigned(mode));");
o.append("        if i < 0 or i >= video_timings'length then");
o.append("            i := 0;");
o.append("        end if;");
o.append("        vt := video_timings(i);");
o.append("");
o.append("        clk_sel     <= std_logic_vector(to_unsigned(video_clk_sel_t'pos(vt.clk_sel),2));");
o.append("        if vt.dmt then");
o.append("            dmt <= '1';");
o.append("        else");
o.append("            dmt <= '0';");
o.append("        end if;");
o.append("        id          <= std_logic_vector(to_unsigned(vt.id,id'length));");
o.append("        if vt.pix_rep = 0 then");
o.append("            pix_rep <=  '0';");
o.append("        else");
o.append("            pix_rep <=  '1';");
o.append("        end if;");
o.append("        if vt.aspect = ASPECT_16_9 then");
o.append('            aspect <= "10";');
o.append("        elsif vt.aspect = ASPECT_4_3 then");
o.append('            aspect <= "01";');
o.append("        else");
o.append('            aspect <= "00";');
o.append("        end if;");
o.append("         if vt.interlace then");
o.append("            interlace <= '1';");
o.append("        else");
o.append("            interlace <= '0';");
o.append("        end if;");
o.append("        v_tot       <= std_logic_vector(to_unsigned(vt.v_tot,v_tot'length));");
o.append("        v_sync      <= std_logic_vector(to_unsigned(vt.v_sync,v_sync'length));");
o.append("        v_bp        <= std_logic_vector(to_unsigned(vt.v_bp,v_bp'length));");
o.append("        v_act       <= std_logic_vector(to_unsigned(vt.v_act,v_act'length));");
o.append("        h_tot       <= std_logic_vector(to_unsigned(vt.h_tot,h_tot'length));");
o.append("        h_sync      <= std_logic_vector(to_unsigned(vt.h_sync,h_sync'length));");
o.append("        h_bp        <= std_logic_vector(to_unsigned(vt.h_bp,h_bp'length));");
o.append("        h_act       <= std_logic_vector(to_unsigned(vt.h_act,h_act'length));");
o.append("        vs_pol      <= to_stdulogic(vt.vs_pol);");
o.append("        hs_pol      <= to_stdulogic(vt.hs_pol);");
o.append("");
o.append("    end process;");
o.append("");
o.append("end architecture synth;");

f = open('video_mode.vhd', 'w')
for l in o:
    f.write(l+'\n')
f.close()