--------------------------------------------------------------------------------
-- tb_crtc_etc.vhd                                                            --
-- Simulation testbench for crtc.vhd and mig_bridge_crtc.vhd.                 --
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

library work;
use work.mb_fb_params_pkg.all;
use work.crtc_pkg.all;
use work.mig_bridge_crtc_pkg.all;

entity tb_crtc_etc is
end entity tb_crtc_etc;

architecture sim of tb_crtc_etc is

    signal xclk         : std_logic;
    signal xrst         : std_logic;
    signal sclk         : std_logic;
    signal srst         : std_logic;
    signal pclk         : std_logic;
    signal prst         : std_logic;
    signal mode         : std_logic_vector(3 downto 0);
    signal crtc_llen    : std_logic_vector(10 downto 6);
    signal crtc_vs      : std_logic;
    signal crtc_hs      : std_logic;
    signal crtc_vblank  : std_logic;
    signal crtc_hblank  : std_logic;
    signal crtc_r       : std_logic_vector(7 downto 0);
    signal crtc_g       : std_logic_vector(7 downto 0);
    signal crtc_b       : std_logic_vector(7 downto 0);    
    signal mig_cc       : std_logic;
    signal mig_avalid   : std_logic;
    signal mig_r_w      : std_logic;
    signal mig_addr     : std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
    signal mig_aready   : std_logic;
    signal mig_wvalid   : std_logic;
    signal mig_wdata    : std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    signal mig_wbe      : std_logic_vector(2**data_width_log2-1 downto 0);
    signal mig_wready   : std_logic;
    signal mig_rdata    : std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    signal mig_raddr    : std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
    signal mig_rvalid   : std_logic;
    signal mig_awvalid  : std_logic;
    signal mig_awready  : std_logic;

begin

    -- 100MHz external (reference) clk
    xclk <=
        '1' after 5ns when xclk = '0' else
        '0' after 5ns when xclk = '1' else
        '0';

    -- external reset
    process
    begin
        xrst <= '1';
        wait for 20ns;
        xrst <= '0';
        wait;
    end process;

    mode <= "0000"; 

    U_CRTC: component crtc
        generic map (
            fref        => 100.0
        )
        port map (
            xclk        => xclk,
            xrst        => xrst,
            sclk        => sclk,
            srst        => srst,
            pclk        => pclk,
            pclk_x5     => open,
            prst        => prst,
            mode        => mode,
            fb_llen     => crtc_llen,
            fb_vs       => crtc_vs,
            fb_hs       => crtc_hs,
            fb_vblank   => crtc_vblank,
            fb_hblank   => crtc_hblank
        );

    U_BRIDGE_CRTC: component mig_bridge_crtc
        generic map (
            base_addr       => 0,
            size_log2       => 23   -- 2^23 = 8MBytes (enough for 1920 x 1080 x 32 bpp)
        )
        port map (
            crtc_clk        => pclk,
            crtc_rst        => prst,
            crtc_llen       => crtc_llen,
            crtc_vs         => crtc_vs,
            crtc_hs         => crtc_hs,
            crtc_vblank     => crtc_vblank,
            crtc_hblank     => crtc_hblank,
            crtc_r          => crtc_r,
            crtc_g          => crtc_g,
            crtc_b          => crtc_b,
            mig_clk         => sclk,
            mig_rst         => srst,
            mig_awvalid     => mig_awvalid,
            mig_awready     => mig_awready,
            mig_r_w         => mig_r_w,
            mig_addr        => mig_addr,
            mig_wdata       => mig_wdata,
            mig_wbe         => mig_wbe,
            mig_rdata       => mig_rdata,
            mig_rvalid      => mig_rvalid
        );

    -- simple shim in place of hub
    mig_avalid <= mig_awvalid;
    mig_wvalid <= mig_awvalid and not mig_r_w;
    mig_awready <= mig_aready and mig_wready;

    MIG: entity work.model_mig
        generic map (
            clk_period      => 10ns,
            data_width_log2 => 4,   -- 16 bytes
            addr_width_log2 => 25,  -- 16 * 2^25 = 512MBytes (4Gbits)
            sim_mem_log2    => 19   -- 16 * 2^19 = 8MBytes        
        )
        port map (
            xrst            => xrst,
            clk             => sclk,
            rst             => srst,
            mig_cc          => mig_cc,
            mig_avalid      => mig_avalid,
            mig_r_w         => mig_r_w,
            mig_addr        => mig_addr,
            mig_aready      => mig_aready,
            mig_wvalid      => mig_wvalid,
            mig_wdata       => mig_wdata,
            mig_wbe         => mig_wbe,
            mig_wready      => mig_wready,
            mig_rdata       => open,
            mig_raddr       => mig_raddr,
            mig_rvalid      => mig_rvalid
        );

    -- dummy read data is based on read address
    GEN_MIG_RDATA: for i in 0 to 3 generate
        mig_rdata(31+(i*32) downto 8+(i*32)) <= std_logic_vector(to_unsigned(to_integer(unsigned(mig_raddr)),24)); 
        mig_rdata(7+(i*32) downto i*32) <= std_logic_vector(to_unsigned(i,8)); 
    end generate GEN_MIG_RDATA;

end architecture sim;

configuration cfg_tb_crtc_etc of tb_crtc_etc is
    for sim
        for U_CRTC: crtc
            for synth
                for CLOCK: video_out_clock
                    use entity work.model_video_out_clock(model); -- slightly faster simulation
                end for;
            end for;
        end for;
    end for; 
end configuration cfg_tb_crtc_etc;
