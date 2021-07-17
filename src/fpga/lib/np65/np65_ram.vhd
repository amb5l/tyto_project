--------------------------------------------------------------------------------
-- np65_ram.vhd                                                               --
-- Tightly coupled RAM for np65 CPU (64, 128 or 256kBytes).                   --
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
use ieee.numeric_std.all;
--use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library xil_defaultlib;
use xil_defaultlib.np65_types_pkg.all;
use xil_defaultlib.np65_ram_pkg.all;

entity np65_ram is
    port (

        clk_x1      : in    std_logic;                          -- CPU clock (typically 40-64MHz)
        clk_x2      : in    std_logic;                          -- system/RAM clock (always 2x CPU clock)

        -- clk_x1 domain

        advex       : in    std_logic;
        if_z        : in    std_logic;                          -- force zero (BRK) instruction fetch
        if_a        : in    std_logic_vector(apmsb downto 0);   -- instruction fetch address
        if_d        : out   slv_7_0_t(3 downto 0);              -- instruction fetch data
        ls_z        : in    std_logic;                          -- force load (read) data to zero e.g. because address is empty
        ls_wp       : in    std_logic;                          -- load/store address is write protected
        ls_ext      : in    std_logic;                          -- load/store address is external
        ls_we       : in    std_logic;                          -- load/store write enable (indicates store)
        ls_a        : in    std_logic_vector(apmsb downto 0);   -- load/store address
        ls_bwe      : in    std_logic_vector(3 downto 0);       -- store byte write enables
        ls_dw       : in    slv_7_0_t(3 downto 0);              -- store data
        ext_dr      : in    slv_7_0_t(3 downto 0);              -- load external data
        ls_dr       : out   slv_7_0_t(3 downto 0);              -- load data
        collision   : out   std_logic;                          -- store collides with instruction fetch (self modifying code)

        -- clk_x2 domain

        rst         : in    std_logic;                          -- synchronous reset

        dma_en      : in    std_logic;                          -- enable DMA access on this clk_x2 edge
        dma_a       : in    std_logic_vector(apmsb downto 3);   -- DMA address (Qword aligned)
        dma_bwe     : in    std_logic_vector(7 downto 0);       -- DMA byte write enables
        dma_dw      : in    slv_7_0_t(7 downto 0);              -- DMA write data
        dma_dr      : out   slv_7_0_t(7 downto 0)               -- DMA read data

    );
end entity np65_ram;

architecture synth of np65_ram is

    type ram_addr_t is array(3 downto 0) of std_logic_vector(apmsb downto 2);

    signal rst_1            : std_logic;
    signal advex_1          : std_logic;

    signal ram_ce_a         : std_logic;
    signal ram_we_a         : std_logic_vector(3 downto 0);
    signal ram_addr_a       : ram_addr_t;
    signal ram_din_a        : slv_7_0_t(3 downto 0);
    signal ram_dout_a       : slv_7_0_t(3 downto 0);

    signal ram_ce_b         : std_logic;
    signal ram_we_b         : std_logic_vector(3 downto 0);
    signal ram_addr_b       : ram_addr_t;
    signal ram_din_b        : slv_7_0_t(3 downto 0);
    signal ram_dout_b       : slv_7_0_t(3 downto 0);

    signal if_z_1           : std_logic;
    signal if_d_sel         : std_logic_vector(1 downto 0);     -- instruction data latch select
    signal if_d_u           : slv_7_0_t(3 downto 0);            -- instruction data, unlatched
    signal if_d_ge          : std_logic;                        -- instruction data latch gate enable

    signal ls_z_1           : std_logic;
    signal ls_ext_1         : std_logic;                        -- registered
    signal ls_dr_sel        : std_logic_vector(1 downto 0);     -- read data latch select
    signal ls_dr_u          : slv_7_0_t(3 downto 0);            -- read data, unlatched
    signal ls_dr_u_x        : slv_7_0_t(3 downto 0);            -- read data, unlatched, combined with external read data
    signal ls_dr_ge         : std_logic;                        -- read data latch gate enable

    signal z_we             : std_logic_vector(3 downto 0);     -- zero page cache RAM byte write enables
    signal z_raddr          : slv_7_2_t(3 downto 0);            -- zero page cache RAM byte bank read addresses
    signal z_rdata          : slv_7_0_t(3 downto 0);            -- zero page cache RAM byte bank read data

    signal s_we             : std_logic_vector(3 downto 0);     -- stack cache RAM byte write enables
    signal s_raddr          : slv_7_2_t(3 downto 0);            -- stack cache RAM byte bank read addresses
    signal s_rdata          : slv_7_0_t(3 downto 0);            -- stack cache RAM byte bank read data

    attribute keep_hierarchy : string;

begin

    ram_ce_a <= not rst; -- prevent writes during reset

    ram_ce_b <= not (rst or rst_1 or ls_ext or (ls_wp and ls_we)); -- prevent writes if reset or external access or write protect

    GEN_RAM: for i in 3 downto 0 generate
        attribute keep_hierarchy of RAM : label is "yes";
    begin

        ram_addr_a(i) <= dma_a & '0' when dma_en = '1' else
            std_logic_vector(unsigned(if_a(apmsb downto 2))+1) when i < to_integer(unsigned(if_a(1 downto 0))) else
            if_a(apmsb downto 2);

        ram_addr_b(i)(apmsb downto 8) <= dma_a(apmsb downto 8) when dma_en = '1' else
            ls_a(apmsb downto 8);
        ram_addr_b(i)(7 downto 2) <= dma_a(7 downto 3) & '1' when dma_en = '1' else
            std_logic_vector(unsigned(ls_a(7 downto 2))+1) when i < to_integer(unsigned(ls_a(1 downto 0))) else
            ls_a(7 downto 2);

        ram_we_a(i) <= dma_bwe(i) when dma_en = '1' else '0';

        ram_we_b(i) <= dma_bwe(4+i) when dma_en = '1' else
            ls_bwe((i+0) mod 4) when ls_a(1 downto 0) = "00" else
            ls_bwe((i+3) mod 4) when ls_a(1 downto 0) = "01" else
            ls_bwe((i+2) mod 4) when ls_a(1 downto 0) = "10" else
            ls_bwe((i+1) mod 4) when ls_a(1 downto 0) = "11" else
            '0';

        ram_din_a(i) <= dma_dw(i);

        ram_din_b(i) <= dma_dw(4+i) when dma_en = '1' else
            ls_dw((i+0) mod 4) when ls_a(1 downto 0) = "00" else
            ls_dw((i+3) mod 4) when ls_a(1 downto 0) = "01" else
            ls_dw((i+2) mod 4) when ls_a(1 downto 0) = "10" else
            ls_dw((i+1) mod 4) when ls_a(1 downto 0) = "11" else
            (others => '0');

        RAM: component np65_ram_bank
        generic map (
            init        => ram_init(i),
            rpm_name    => "RAM" & integer'image(i)
        )
        port map (
            clk     => clk_x2,
            clr_a	=> '0',
            ce_a    => ram_ce_a,
            we_a    => ram_we_a(i),
            addr_a  => ram_addr_a(i),
            din_a   => ram_din_a(i),
            dout_a  => ram_dout_a(i),
            clr_b	=> '0',
            ce_b    => ram_ce_b,
            we_b    => ram_we_b(i),
            addr_b  => ram_addr_b(i),
            din_b   => ram_din_b(i),
            dout_b  => ram_dout_b(i)
        );

        with if_d_sel select if_d_u(i) <=
            ram_dout_a((i+0) mod 4) when "00",
            ram_dout_a((i+1) mod 4) when "01",
            ram_dout_a((i+2) mod 4) when "10",
            ram_dout_a((i+3) mod 4) when others;

        with ls_dr_sel select ls_dr_u(i) <=
            ram_dout_b((i+0) mod 4) when "00",
            ram_dout_b((i+1) mod 4) when "01",
            ram_dout_b((i+2) mod 4) when "10",
            ram_dout_b((i+3) mod 4) when others;

        dma_dr(i) <= ram_dout_a(i);
        dma_dr(4+i) <= ram_dout_b(i);

    end generate gen_ram;

    process(clk_x1)
    begin
        if rising_edge(clk_x1) then
            rst_1 <= rst;
            advex_1 <= advex;
            if_z_1 <= if_z;
            if_d_sel <= if_a(1 downto 0);
            ls_z_1 <= ls_z;
            ls_dr_sel <= ls_a(1 downto 0);
            ls_ext_1 <= ls_ext;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- read data latches

	LD_GE: ldce_1
	port map (
		clr	=> '0',
		g	=> clk_x1,
		ge	=> '1',
		d	=> advex or collision or rst_1,
		q	=> if_d_ge
	);

    ls_dr_ge <= '1';
    ls_dr_u_x <= ext_dr when ls_ext_1 = '1' else ls_dr_u;

	GEN_LD_BYTE: for i in 3 downto 0 generate
		GEN_LD_BIT: for j in 0 to 7 generate
			IF_LD: ldce
			port map (
				clr	=> if_z_1,
				g	=> clk_x1,
				ge	=> if_d_ge,
				d	=> if_d_u(i)(j),
				q	=> if_d(i)(j)
			);
			LS_LD: ldce
			port map (
				clr	=> ls_z_1,
				g	=> clk_x1,
				ge	=> ls_dr_ge,
				d	=> ls_dr_u_x(i)(j),
				q	=> ls_dr(i)(j)
			);
		end generate GEN_LD_BIT;
	end generate GEN_LD_BYTE;

    --------------------------------------------------------------------------------
    -- collision avoidance (for self modifying code)
    -- if an instruction modifies the very next instruction to be executed,
    -- we need to allow a wait state for the RAM contents to update

    process(clk_x1)
        variable bump : std_logic;
    begin
        if rising_edge(clk_x1) then
            bump := '0';
            for i in 0 to 3 loop
                if ls_we = '1' and ram_addr_b(i) = ram_addr_a(i) then --  and ram_we_b(i) = '1' and dma_en = '0'
                    bump := '1';
                end if;
            end loop;
            collision <= bump;
        end if;
    end process;

    --------------------------------------------------------------------------------

end architecture synth;
