--------------------------------------------------------------------------------
-- crtc.vhd                                                                   --
-- Video clock generation and timing for various display modes.               --
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

package crtc_pkg is

    component crtc is
        generic (
            fref        : real                                  -- reference clock frequency (MHz)
        );
        port (

            xclk        : in    std_logic;                      -- reference clock
            xrst        : in    std_logic;                      -- external reset (asynchronous)

            sclk        : in    std_logic;                      -- system clock (typically 100MHz)
            srst        : in    std_logic;                      -- system clock synchronous reset

            pclk        : out   std_logic;                      -- pixel clock
            pclk_x5     : out   std_logic;                      -- serialiser clock
            prst        : out   std_logic;                      -- pixel clock synchronous reset

            mode        : in    std_logic_vector(3 downto 0);   -- video mode select

            fb_llen     : out    std_logic_vector(10 downto 6);
            fb_vs       : out    std_logic;
            fb_hs       : out    std_logic;
            fb_vblank   : out    std_logic;
            fb_hblank   : out    std_logic

        );
    end component crtc;

end package crtc_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_mode_pkg.all;
use work.video_out_clock_pkg.all;
use work.video_out_timing_pkg.all;
use work.dvi_tx_encoder_pkg.all;
use work.serialiser_10to1_selectio_pkg.all;
use work.types_pkg.all;

entity crtc is
    generic (
        fref        : real                                  -- reference clock frequency (MHz)
    );
    port (

        xclk        : in    std_logic;                      -- reference clock
        xrst        : in    std_logic;                      -- external reset (asynchronous)

        sclk        : in    std_logic;                      -- system clock (100MHz)
        srst        : in    std_logic;                      -- system clock synchronous reset

        pclk        : out   std_logic;                      -- pixel clock
        pclk_x5     : out   std_logic;                      -- serialiser clock
        prst        : out   std_logic;                      -- pixel clock synchronous reset

        mode        : in    std_logic_vector(3 downto 0);   -- video mode select

        fb_llen     : out    std_logic_vector(10 downto 6);
        fb_vs       : out    std_logic;
        fb_hs       : out    std_logic;
        fb_vblank   : out    std_logic;
        fb_hblank   : out    std_logic

    );
end entity crtc;

architecture synth of crtc is

    signal mode_clk_sel     : std_logic_vector(1 downto 0);     -- pixel frequency select
    signal mode_dmt         : std_logic;                        -- 1 = DMT, 0 = CEA
    signal mode_id          : std_logic_vector(7 downto 0);     -- DMT ID or CEA/CTA VIC
    signal mode_pix_rep     : std_logic;                        -- 1 = pixel doubling/repetition
    signal mode_aspect      : std_logic_vector(1 downto 0);     -- 0x = normal, 10 = force 16:9, 11 = force 4:3
    signal mode_interlace   : std_logic;                        -- interlaced/progressive scan
    signal mode_v_tot       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_v_act       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_v_sync      : std_logic_vector(2 downto 0);     -- vertical sync width
    signal mode_v_bp        : std_logic_vector(5 downto 0);     -- vertical back porch
    signal mode_h_tot       : std_logic_vector(11 downto 0);    -- horizontal total
    signal mode_h_act       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_h_sync      : std_logic_vector(6 downto 0);     -- horizontal sync width
    signal mode_h_bp        : std_logic_vector(7 downto 0);     -- horizontal back porch
    signal mode_vs_pol      : std_logic;                        -- vertical sync polarity (1 = high)
    signal mode_hs_pol      : std_logic;                        -- horizontal sync polarity (1 = high)

    signal fb_ax            : std_logic_vector(11 downto 0);    -- active area X (signed)
    signal fb_ay            : std_logic_vector(11 downto 0);    -- active area Y (signed)

    signal tmds             : slv_9_0_t(0 to 2);                -- parallel TMDS channels

begin

    -- video mode timings

    MODE_TABLE: component video_mode
        port map (
            mode      => mode,
            clk_sel   => mode_clk_sel,
            dmt       => mode_dmt,
            id        => mode_id,
            pix_rep   => mode_pix_rep,
            aspect    => mode_aspect,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            vs_pol    => mode_vs_pol,
            hs_pol    => mode_hs_pol
        );

    fb_llen <= mode_h_act(10 downto 6);

    -- reconfigurable MMCM: 100MHz ref => 25.2MHz, 27MHz, 74.25MHz or 148.5MHz

    CLOCK: component video_out_clock
        port map (
            rsti    => xrst,
            clki    => xclk,
            sys_rst => srst,
            sys_clk => sclk,
            sel     => mode_clk_sel,
            rsto    => prst,
            clko    => pclk,
            clko_x5 => pclk_x5
        );

    -- basic video timing generation

    TIMING: component video_out_timing
        port map (
            rst       => prst,
            clk       => pclk,
            pix_rep   => mode_pix_rep,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            align     => (others => '0'),
            f         => open,
            vs        => fb_vs,
            hs        => fb_hs,
            vblank    => fb_vblank,
            hblank    => fb_hblank,
            ax        => open,
            ay        => open
        );

end architecture synth;
