--------------------------------------------------------------------------------
-- hdmi_tpg.vhd                                                               --
-- HDMI video test pattern generator with audio test tone.                    --
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

entity hdmi_tpg is
    port (

        ext_rst     : in    std_logic;                      -- async reset
        ref_clk     : in    std_logic;                      -- reference clock (100MHz)

        mode        : in    std_logic_vector(3 downto 0);   -- video mode select
        dvi         : in    std_logic;                      -- 1 = DVI, 0 = HDMI

        led         : out   std_logic_vector(7 downto 0);

        hdmi_clk_p  : out   std_logic;
        hdmi_clk_n  : out   std_logic;
        hdmi_ch_p   : out   std_logic_vector(0 to 2);
        hdmi_ch_n   : out   std_logic_vector(0 to 2)

    );
end entity hdmi_tpg;

architecture synth of hdmi_tpg is

    signal sys_rst          : std_logic;
    signal sys_clk          : std_logic;

    signal pix_rst          : std_logic;
    signal pix_clk          : std_logic;
    signal pix_clk_x5       : std_logic;

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

    signal raw_ce           : std_logic;                      -- active area enable (toggles if pix_rep = 1)
    signal raw_f            : std_logic;                      -- field ID
    signal raw_vs           : std_logic;                      -- vertical sync
    signal raw_hs           : std_logic;                      -- horizontal sync
    signal raw_vblank       : std_logic;                      -- vertical blank
    signal raw_hblank       : std_logic;                      -- horizontal blank
    signal raw_ax           : std_logic_vector(11 downto 0);  -- active area X (signed)
    signal raw_ay           : std_logic_vector(11 downto 0);  -- active area Y (signed)

    signal vga_vs           : std_logic;                      -- vertical sync
    signal vga_hs           : std_logic;                      -- horizontal sync
    signal vga_vblank       : std_logic;                      -- vertical blank
    signal vga_hblank       : std_logic;                      -- horizontal blank
    signal vga_r            : std_logic_vector(7 downto 0);   -- red
    signal vga_g            : std_logic_vector(7 downto 0);   -- green
    signal vga_b            : std_logic_vector(7 downto 0);   -- blue
    signal vga_ax           : std_logic_vector(11 downto 0);
    signal vga_ay           : std_logic_vector(11 downto 0);

    signal pcm_n            : std_logic_vector(19 downto 0);
    signal pcm_cts          : std_logic_vector(19 downto 0);
    signal pcm_rst          : std_logic;
    signal pcm_clk          : std_logic;
    signal pcm_clken        : std_logic;
    signal pcm_l            : std_logic_vector(15 downto 0);
    signal pcm_r            : std_logic_vector(15 downto 0);

begin

    led(3 downto 0) <= mode(3 downto 0);
    led(4) <= dvi;
    led(5) <= not pcm_rst;
    led(6) <= not pix_rst;
    led(7) <= not sys_rst;

    SYSTEM_CLOCK: entity xil_defaultlib.clock_100m
        generic map (
            fref    => 100.0
        )
        port map (
            rsti    => ext_rst,
            clki    => ref_clk,
            rsto    => sys_rst,
            clko    => sys_clk
        );

    HDMI_MODE: entity xil_defaultlib.video_mode
        port map (
            mode        => mode,
            clk_sel     => mode_clk_sel,
            dmt         => mode_dmt,
            id          => mode_id,
            pix_rep     => mode_pix_rep,
            aspect      => mode_aspect,
            interlace   => mode_interlace,
            v_tot       => mode_v_tot,
            v_act       => mode_v_act,
            v_sync      => mode_v_sync,
            v_bp        => mode_v_bp,
            h_tot       => mode_h_tot,
            h_act       => mode_h_act,
            h_sync      => mode_h_sync,
            h_bp        => mode_h_bp,
            vs_pol      => mode_vs_pol,
            hs_pol      => mode_hs_pol
        );

    HDMI_CLOCK: entity xil_defaultlib.video_out_clock
        port map (

            rsti        => ext_rst,
            clki        => ref_clk,
            sys_rst     => sys_rst,
            sys_clk     => sys_clk,

            sel         => mode_clk_sel,
            rsto        => pix_rst,
            clko        => pix_clk,
            clko_x5     => pix_clk_x5

        );

    HDMI_OUT: entity xil_defaultlib.hdmi_out
        generic map (
            fs          => 48.0
        )
        port map (

            rst         => ext_rst,
            clk         => pix_clk,
            clk_x5      => pix_clk_x5,

            mode_dvi    => dvi,
            mode_id     => mode_id,
            mode_pixrep => mode_pix_rep,
            mode_aspect => mode_aspect,
            mode_ilace  => mode_interlace,
            mode_v_tot  => mode_v_tot,
            mode_v_act  => mode_v_act,
            mode_v_sync => mode_v_sync,
            mode_v_bp   => mode_v_bp,
            mode_h_tot  => mode_h_tot,
            mode_h_act  => mode_h_act,
            mode_h_sync => mode_h_sync,
            mode_h_bp   => mode_h_bp,
            mode_vs_pol => mode_vs_pol,
            mode_hs_pol => mode_hs_pol,

            raw_ce      => raw_ce,
            raw_vs      => raw_vs,
            raw_hs      => raw_hs,
            raw_vblank  => raw_vblank,
            raw_hblank  => raw_hblank,
            raw_ax      => raw_ax,
            raw_ay      => raw_ay,
            raw_align   => (others => '0'),

            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_vblank  => vga_vblank,
            vga_hblank  => vga_hblank,
            vga_r       => vga_r,
            vga_g       => vga_g,
            vga_b       => vga_b,
            vga_ax      => vga_ax,
            vga_ay      => vga_ay,

            pcm_n       => pcm_n,
            pcm_cts     => pcm_cts,
            pcm_rst     => pcm_rst,
            pcm_clk     => pcm_clk,
            pcm_clken   => pcm_clken,
            pcm_l       => pcm_l,
            pcm_r       => pcm_r,

            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_ch_p   => hdmi_ch_p,
            hdmi_ch_n   => hdmi_ch_n
        );

    TPG: entity xil_defaultlib.video_out_test_pattern
        port map (
            rst         => pix_rst,
            clk         => pix_clk,
            v_act       => mode_v_act,
            h_act       => mode_h_act,
            raw_vs      => raw_vs,
            raw_hs      => raw_hs,
            raw_vblank  => raw_vblank,
            raw_hblank  => raw_hblank,
            raw_ax      => raw_ax,
            raw_ay      => raw_ay,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_vblank  => vga_vblank,
            vga_hblank  => vga_hblank,
            vga_r       => vga_r,
            vga_g       => vga_g,
            vga_b       => vga_b,
            vga_ax      => vga_ax,
            vga_ay      => vga_ay
        );

    TONE: entity xil_defaultlib.audio_out_test_tone
        generic map (
            fref        => 100.0
        )
        port map (
            ref_rst     => ext_rst,
            ref_clk     => ref_clk,
            pcm_rst     => pcm_rst,
            pcm_clk     => pcm_clk,
            pcm_clken   => pcm_clken,
            pcm_l       => pcm_l,
            pcm_r       => pcm_r
        );

    pcm_n <= std_logic_vector(to_unsigned(6144,pcm_n'length));
    with mode_clk_sel select pcm_cts <=
        std_logic_vector(to_unsigned(148500,pcm_cts'length)) when "11",
        std_logic_vector(to_unsigned(74250,pcm_cts'length)) when "10",
        std_logic_vector(to_unsigned(27000,pcm_cts'length)) when "01",
        std_logic_vector(to_unsigned(25200,pcm_cts'length)) when others;

end architecture synth;
