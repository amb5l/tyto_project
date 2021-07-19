--------------------------------------------------------------------------------
-- np65_pkg.vhd                                                               --
-- Include this package to use the np65 CPU and RAM core.                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        --
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

library xil_defaultlib;
use xil_defaultlib.np65_ram_pkg.all;

package np65_pkg is

    constant np65_apmsb : integer := apmsb;                                 -- physical address msb (128kbytes -> 16)

    component np65 is
        generic (
        
            vector_init : std_logic_vector(15 downto 0)

        );
        port (

            clk_x1          : in    std_logic;                              -- CPU clock (typically 40-64MHz)
            clk_x2          : in    std_logic;                              -- system/RAM clock (always 2x CPU clock)
            clk_ph          : out   std_logic;                              -- clock phase, valid on clk_2x edges: 1 = clk_1x/CPU edge

            -- clk_x1 domain

            rst             : in    std_logic;                              -- reset
            hold            : in    std_logic;                              -- wait states, pause during DMA, debug halt
            nmi             : in    std_logic;                              -- NMI
            irq             : in    std_logic;                              -- IRQ

            if_al           : out   std_logic_vector(15 downto 0);          -- instruction fetch logical address
            if_ap           : in    std_logic_vector(apmsb downto 0);       -- instruction fetch physical address
            if_z            : in    std_logic;                              -- instruction fetch physical address is empty/bad (reads zero)

            ls_en           : out   std_logic;                              -- load/store enable
            ls_re           : out   std_logic;                              -- load/store read enable
            ls_we           : out   std_logic;                              -- load/store write enable
            ls_al           : out   std_logic_vector(15 downto 0);          -- load/store logical address
            ls_ap           : in    std_logic_vector(apmsb downto 0);       -- load/store physical address of data
            ls_z            : in    std_logic;                              -- load/store physical address is empty/bad (reads zero)
            ls_wp           : in    std_logic;                              -- load/store physical address is write protected (ROM)
            ls_ext          : in    std_logic;                              -- load/store physical address is external (e.g. hardware register)

            ext_dr          : in    std_logic_vector(7 downto 0);           -- external read data
            ext_dw          : out   std_logic_vector(7 downto 0);           -- external write data

            trace_stb       : out   std_logic;                              -- trace strobe
            trace_reg_pc    : out   std_logic_vector(15 downto 0);          -- trace register PC
            trace_reg_s     : out   std_logic_vector(7 downto 0);           -- trace register S
            trace_reg_p     : out   std_logic_vector(7 downto 0);           -- trace register P
            trace_reg_a     : out   std_logic_vector(7 downto 0);           -- trace register A
            trace_reg_x     : out   std_logic_vector(7 downto 0);           -- trace register X
            trace_reg_y     : out   std_logic_vector(7 downto 0);           -- trace register Y

            -- clk_x2 domain

            dma_en          : in    std_logic;                              -- enable DMA access on this clk_x2 edge
            dma_a           : in    std_logic_vector(apmsb downto 3);       -- DMA address (Qword aligned)
            dma_bwe         : in    std_logic_vector(7 downto 0);           -- DMA byte write enables
            dma_dw          : in    std_logic_vector(63 downto 0);          -- DMA write data
            dma_dr          : out   std_logic_vector(63 downto 0)           -- DMA read data

        );
    end component np65;

end package np65_pkg;