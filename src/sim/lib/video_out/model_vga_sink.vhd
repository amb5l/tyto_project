--------------------------------------------------------------------------------
-- model_vga_sink.vhd                                                         --
-- Simple simulation model of a VGA display. Captures BMP files.              --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;
use xil_defaultlib.sim_video_out_pkg.all;

entity model_vga_sink is
    generic (
        name    : string                                -- BMP filename prefix
    );
    port
    (
        vga_rst     : in    std_logic;                      -- pixel clock synchronous reset
        vga_clk     : in    std_logic;                      -- pixel clock
        vga_vs      : in    std_logic;                      -- vertical sync
        vga_hs      : in    std_logic;                      -- horizontal sync
        vga_de      : in    std_logic;                      -- pixel data enable
        vga_r       : in    std_logic_vector(7 downto 0);   -- red
        vga_g       : in    std_logic_vector(7 downto 0);   -- green
        vga_b       : in    std_logic_vector(7 downto 0);   -- blue
        cap_rst     : in    std_logic;                      -- capture reset
        cap_stb     : out   std_logic                       -- capture strobe
    );
end entity model_vga_sink;

architecture model of model_vga_sink is

    signal bmp_count    : integer := 0;
    signal bmp          : bmp_t(0 to 1919,0 to 1079); -- max size
    signal ax           : integer;
    signal ay           : integer;
    signal width        : integer;
    signal hieght       : integer;
    signal capturing    : boolean;
    signal interlaced   : boolean;

begin

    process(cap_rst,vga_rst,vga_clk,vga_vs,vga_de)
    begin

        if cap_rst = '1' then

            bmp_count <= 0;

        end if;
        
        if vga_rst = '1' then

            ax          <= 0;
            ay          <= 0;
            width       <= 0;
            hieght      <= 0;
            capturing   <= false;
            interlaced  <= false;

        else

            if capturing and vga_vs'event then
                if vga_hs'event then
                    write_bmp(name,bmp,bmp_count,width,hieght,interlaced);
                    bmp_count <= bmp_count + 1;
                    capturing <= false;
                    cap_stb <= '1';
                else
                    interlaced <= true;
                end if;
            end if;

            if rising_edge(vga_de) then
                if not capturing then
                    ax <= 0;
                    ay <= 0;
                    width <= 0;
                    hieght <= 0;
                    bmp <= (others => (others => (0,0,0)));
                end if;
                capturing <= true;
            end if;

            if falling_edge(vga_de) then
                hieght <= hieght+1;
                ay <= ay + 1;
                ax <= 0;
            end if;

            if rising_edge(vga_clk) then
                cap_stb <= '0';
                if vga_de = '1' then
                    if hieght = 0 then
                        width <= width+1;
                    end if;
                    bmp(ax,ay)(0) <= to_integer(unsigned(vga_r));
                    bmp(ax,ay)(1) <= to_integer(unsigned(vga_g));
                    bmp(ax,ay)(2) <= to_integer(unsigned(vga_b));
                    ax <= ax+1;
                end if;
            end if;

        end if;

    end process;

end architecture model;
----------------------------------------------------------------------
-- end of file