--------------------------------------------------------------------------------
-- mig_bridge_axi.vhd                                                         --
-- Bridges from AXI master to MIG UI.                                         --
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
-- to do: read prefetching and write combining

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.global_pkg.all;

package mig_bridge_axi_pkg is

    component mig_bridge_axi is
        port (

            clk             : in    std_logic;
            rst             : in    std_logic;

            axi_awaddr  : in    std_logic_vector(31 downto 0);
            axi_awprot  : in    std_logic_vector(2 downto 0);
            axi_awvalid : in    std_logic_vector(0 to 0);
            axi_awready : out   std_logic_vector(0 to 0);
            axi_wdata   : in    std_logic_vector(31 downto 0);
            axi_wstrb   : in    std_logic_vector(3 downto 0);
            axi_wvalid  : in    std_logic_vector(0 to 0);
            axi_wready  : out   std_logic_vector(0 to 0);
            axi_bresp   : out   std_logic_vector(1 downto 0);
            axi_bvalid  : out   std_logic_vector(0 to 0);
            axi_bready  : in    std_logic_vector(0 to 0);
            axi_araddr  : in    std_logic_vector(31 downto 0);
            axi_arprot  : in    std_logic_vector(2 downto 0);
            axi_arvalid : in    std_logic_vector(0 to 0);
            axi_arready : out   std_logic_vector(0 to 0);
            axi_rdata   : out   std_logic_vector(31 downto 0);
            axi_rresp   : out   std_logic_vector(1 downto 0);
            axi_rvalid  : out   std_logic_vector(0 to 0);
            axi_rready  : in    std_logic_vector(0 to 0);

            mig_awvalid : out   std_logic;
            mig_awready : in    std_logic;
            mig_r_w     : out   std_logic;
            mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
            mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
            mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_rvalid  : in    std_logic;
            mig_rready  : out   std_logic

        );
    end component mig_bridge_axi;

end package mig_bridge_axi_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.global_pkg.all;

entity mig_bridge_axi is
    port (

        clk             : in    std_logic;
        rst             : in    std_logic;

        axi_awaddr  : in    std_logic_vector(31 downto 0);
        axi_awprot  : in    std_logic_vector(2 downto 0);
        axi_awvalid : in    std_logic_vector(0 to 0);
        axi_awready : out   std_logic_vector(0 to 0);
        axi_wdata   : in    std_logic_vector(31 downto 0);
        axi_wstrb   : in    std_logic_vector(3 downto 0);
        axi_wvalid  : in    std_logic_vector(0 to 0);
        axi_wready  : out   std_logic_vector(0 to 0);
        axi_bresp   : out   std_logic_vector(1 downto 0);
        axi_bvalid  : out   std_logic_vector(0 to 0);
        axi_bready  : in    std_logic_vector(0 to 0);
        axi_araddr  : in    std_logic_vector(31 downto 0);
        axi_arprot  : in    std_logic_vector(2 downto 0);
        axi_arvalid : in    std_logic_vector(0 to 0);
        axi_arready : out   std_logic_vector(0 to 0);
        axi_rdata   : out   std_logic_vector(31 downto 0);
        axi_rresp   : out   std_logic_vector(1 downto 0);
        axi_rvalid  : out   std_logic_vector(0 to 0);
        axi_rready  : in    std_logic_vector(0 to 0);

        mig_awvalid : out   std_logic;
        mig_awready : in    std_logic;
        mig_r_w     : out   std_logic;
        mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
        mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
        mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_rvalid  : in    std_logic;
        mig_rready  : out   std_logic

    );
end entity mig_bridge_axi;

architecture synth of mig_bridge_axi is

    constant ratio : integer := 2**(data_width_log2-2);

    signal sel : integer range 0 to ratio-1;

    -- signal cache_addr   : std_logic_vector(mig_addr'range);
    -- signal cache_data   : std_logic_vector(mig_wdata'range);
    -- signal cache_valid  : std_logic;
    -- signal cache_hit    : std_logic;

begin

    -- process(clk)
    -- begin
        -- if rising_edge(clk) then
            -- if axi_arvalid = '1' and axi_arready = '1' then
                -- cache_addr <= axi_araddr(mig_addr'range);
            -- end if;
            -- if mig_rvalid = '1' and mig_rready = '1' then
                -- cache_data <= mig_rdata;
                -- cache_valid <= '1';
            -- end if;

            -- if rst = '1' then
                -- cache_data <= (others => '0');
                -- cache_valid <= '0';
                -- cache_addr <= (others => '1');
            -- end if;
        -- end if;
    -- end process;

    -- cache_hit <= '1' when cache_valid = '1' and cache_addr = axi_araddr(mig_addr'range) else '0';

    sel <= to_integer(unsigned(axi_araddr(data_width_log2-1 downto 2)));

    axi_awready(0) <= axi_awvalid(0) and axi_wvalid(0) and mig_awready;
    axi_wready(0) <= axi_awvalid(0) and axi_wvalid(0) and mig_awready;
    axi_bresp <= (others => '0');
    axi_bvalid(0) <= axi_awvalid(0) and axi_wvalid(0) and mig_awready;
    axi_arready(0) <= axi_arvalid(0) and mig_awready;
    axi_rdata <= mig_rdata(31+(sel*32) downto sel*32);
    axi_rresp  <= (others => '0');
    axi_rvalid(0) <= mig_rvalid;

    mig_awvalid <= (axi_awvalid(0) and axi_wvalid(0)) or axi_arvalid(0);
    mig_r_w <= axi_arvalid(0) and not (axi_awvalid(0) and axi_wvalid(0));
    mig_addr <= axi_araddr(mig_addr'range) when (axi_arvalid(0) and not (axi_awvalid(0) and axi_wvalid(0))) = '1' else axi_awaddr(mig_addr'range);
    GEN_W: for i in 0 to ratio-1 generate
        mig_wdata(31+(i*32) downto i*32) <= axi_wdata;
        mig_wbe(3+(i*4) downto i*4) <= (others => '1') when i = sel else (others => '0');
    end generate GEN_W;    
    mig_rready <= '1';

end architecture synth;
