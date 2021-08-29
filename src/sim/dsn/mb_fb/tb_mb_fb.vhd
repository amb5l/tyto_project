--------------------------------------------------------------------------------
-- tb_mb_fb.vhd                                                               --
-- Simulation testbench for mb_fb.vhd.                                        --
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

library work;
use work.mb_fb_params_pkg.all;
use work.mb_fb_pkg.all;

entity tb_mb_fb is
end entity tb_mb_fb;

architecture sim of tb_mb_fb is

    signal xclk         : std_logic;
    signal xrst         : std_logic;
    signal sclk         : std_logic;
    signal srst         : std_logic;
    signal uart_txd     : std_logic;
    signal uart_rxd     : std_logic;
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
    signal mig_rvalid   : std_logic;
    signal dvi_clk_p    : std_logic;
    signal dvi_clk_n    : std_logic;
    signal dvi_d_p      : std_logic_vector(0 to 2);
    signal dvi_d_n      : std_logic_vector(0 to 2);
    signal vga_rst      : std_logic;
    signal vga_clk      : std_logic;
    signal vga_vs       : std_logic;
    signal vga_hs       : std_logic;
    signal vga_de       : std_logic;
    signal vga_r        : std_logic_vector(7 downto 0);
    signal vga_g        : std_logic_vector(7 downto 0);
    signal vga_b        : std_logic_vector(7 downto 0);
    signal cap_rst      : std_logic;
    signal cap_stb      : std_logic;    

begin

    xclk <=
        '1' after 5ns when xclk = '0' else
        '0' after 5ns when xclk = '1' else
        '0';

    process
    begin
        xrst <= '1';
        vga_rst <= '1';
        cap_rst <= '1';
        wait for 20ns;
        xrst <= '0';
        vga_rst <= '0';
        cap_rst <= '0';
        wait;
    end process;

    UUT: component mb_fb
        generic map (
            fref            => 100.0
        )
        port map (
            xclk            => xclk,
            xrst            => xrst,
            sclk            => sclk,
            srst            => srst,
            uart_txd        => open,
            uart_rxd        => '1',
            mig_cc          => mig_cc,
            mig_avalid      => mig_avalid,
            mig_r_w         => mig_r_w,
            mig_addr        => mig_addr,
            mig_aready      => mig_aready,
            mig_wvalid      => mig_wvalid,
            mig_wdata       => mig_wdata,
            mig_wbe         => mig_wbe,
            mig_wready      => mig_wready,
            mig_rdata       => mig_rdata,
            mig_rvalid      => mig_rvalid,
            dvi_clk_p       => dvi_clk_p,
            dvi_clk_n       => dvi_clk_n,
            dvi_d_p         => dvi_d_p,
            dvi_d_n         => dvi_d_n
        );

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
            mig_rdata       => mig_rdata,
            mig_raddr       => open,
            mig_rvalid      => mig_rvalid
        );

    DECODE: entity work.model_dvi_decoder
        port map (
            dvi_clk         => dvi_clk_p,
            dvi_d           => dvi_d_p,
            vga_clk         => vga_clk,
            vga_vs          => vga_vs,
            vga_hs          => vga_hs,
            vga_de          => vga_de,
            vga_p(2)        => vga_r,
            vga_p(1)        => vga_g,
            vga_p(0)        => vga_b
        );

    CAPTURE: entity work.model_vga_sink
        generic map (
            name    => "tb_mb_fb"
        )
        port map (
            vga_rst => vga_rst,
            vga_clk => vga_clk,
            vga_vs  => vga_vs,
            vga_hs  => vga_hs,
            vga_de  => vga_de,
            vga_r   => vga_r,
            vga_g   => vga_g,
            vga_b   => vga_b,
            cap_rst => cap_rst,
            cap_stb => cap_stb
        );

end architecture sim;

configuration cfg_tb_mb_fb of tb_mb_fb is
    for sim
        for UUT: mb_fb
            for synth
                for U_CRTC: crtc
                    for synth
                        for CLOCK: video_out_clock
                            use entity work.model_video_out_clock(model); -- slightly faster simulation
                        end for;
                    end for;
                end for;
            end for;
        end for;
    end for; 
end configuration cfg_tb_mb_fb;