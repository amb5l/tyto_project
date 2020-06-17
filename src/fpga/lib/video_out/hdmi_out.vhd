--------------------------------------------------------------------------------
-- hdmi_out.vhd                                                               --
-- HDMI output top level.                                                     --
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

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;

entity hdmi_out is
    generic (
        fs          : real                                  -- audio sample rate (kHz)
    );
    port (

        rst         : in    std_logic;                      -- reset (synchronous to pixel clock)
        clk         : in    std_logic;                      -- pixel clock
        clk_x5      : in    std_logic;                      -- serializer clock (5x pixel clock)

        mode_dvi    : in    std_logic;                      -- 1 = DVI (no data islands or guardbands), 0 = HDMI
        mode_id     : in    std_logic_vector(7 downto 0);   -- CEA/CTA VIC
        mode_pixrep : in    std_logic;                      -- 1 = pixel doubling/repetition
        mode_aspect : in    std_logic_vector(1 downto 0);   -- 0x = normal, 10 = force 16:9, 11 = force 4:3
        mode_ilace  : in    std_logic;                      -- interlaced/progressive scan
        mode_v_tot  : in    std_logic_vector(10 downto 0);  -- vertical total lines (must be odd if interlaced)
        mode_v_act  : in    std_logic_vector(10 downto 0);  -- vertical active lines
        mode_v_sync : in    std_logic_vector(2 downto 0);   -- vertical sync width
        mode_v_bp   : in    std_logic_vector(5 downto 0);   -- vertical back porch
        mode_h_tot  : in    std_logic_vector(11 downto 0);  -- horizontal total
        mode_h_act  : in    std_logic_vector(10 downto 0);  -- horizontal active
        mode_h_sync : in    std_logic_vector(6 downto 0);   -- horizontal sync width
        mode_h_bp   : in    std_logic_vector(7 downto 0);   -- horizontal back porch
        mode_vs_pol : in    std_logic;                      -- vertical sync polarity (1 = high)
        mode_hs_pol : in    std_logic;                      -- horizontal sync polarity (1 = high)

        raw_ce      : out   std_logic;
        raw_f       : out   std_logic;
        raw_vs      : out   std_logic;
        raw_hs      : out   std_logic;
        raw_vblank  : out   std_logic;
        raw_hblank  : out   std_logic;
        raw_ax      : out   std_logic_vector(11 downto 0);
        raw_ay      : out   std_logic_vector(11 downto 0);
        raw_align   : in    std_logic_vector(21 downto 0);  -- alignment delay

        vga_vs      : in    std_logic;
        vga_hs      : in    std_logic;
        vga_vblank  : in    std_logic;
        vga_hblank  : in    std_logic;
        vga_r       : in    std_logic_vector(7 downto 0);
        vga_g       : in    std_logic_vector(7 downto 0);
        vga_b       : in    std_logic_vector(7 downto 0);
        vga_ax      : in    std_logic_vector(11 downto 0);
        vga_ay      : in    std_logic_vector(11 downto 0);

        pcm_n       : in    std_logic_vector(19 downto 0);  -- ACR N value
        pcm_cts     : in    std_logic_vector(19 downto 0);  -- ACR CTS value
        pcm_rst     : in    std_logic;
        pcm_clk     : in    std_logic;                      -- audio clock
        pcm_clken   : in    std_logic;                      -- audio clock enable
        pcm_l       : in    std_logic_vector(15 downto 0);
        pcm_r       : in    std_logic_vector(15 downto 0);

        hdmi_clk_p  : out   std_logic;
        hdmi_clk_n  : out   std_logic;
        hdmi_ch_p   : out   std_logic_vector(0 to 2);
        hdmi_ch_n   : out   std_logic_vector(0 to 2)

    );
end entity hdmi_out;

architecture synth of hdmi_out is

    signal hdmi_as_req   : std_logic;                       -- audio sample req
    signal hdmi_as_ack   : std_logic;                       -- audio sample ack
    signal hdmi_as_sync  : std_logic;                       -- b preamble (sync)
    signal hdmi_as_l     : std_logic_vector(23 downto 0);   -- left channel sample
    signal hdmi_as_lv    : std_logic;                       -- left channel status
    signal hdmi_as_lu    : std_logic;                       -- left user data
    signal hdmi_as_lc    : std_logic;                       -- left channel status
    signal hdmi_as_lp    : std_logic;                       -- left channel status
    signal hdmi_as_r     : std_logic_vector(23 downto 0);   -- right channel sample
    signal hdmi_as_rv    : std_logic;                       -- right channel status
    signal hdmi_as_ru    : std_logic;                       -- right user data
    signal hdmi_as_rc    : std_logic;                       -- right channel status
    signal hdmi_as_rp    : std_logic;                       -- right channel status

    signal hdmi_vs          : std_logic;
    signal hdmi_hs          : std_logic;
    signal hdmi_de          : std_logic;
    signal hdmi_p           : slv_7_0_t(0 to 2);            -- pixel data input to HDMI encoder
    signal hdmi_c           : slv_1_0_t(0 to 2);            -- control input to HDMI encoder
    signal hdmi_enc         : std_logic_vector(1 downto 0); -- HDMI encoding scheme
    signal hdmi_ctl         : std_logic_vector(3 downto 0); -- HDMI control bits for channels 1,2
    signal hdmi_d           : slv_3_0_t(0 to 2);            -- HDMI data (for islands)
    signal hdmi_q           : slv_9_0_t(0 to 2);            -- HDMI symbol (TMDS/TERC4)

begin

    TIMING: entity xil_defaultlib.video_out_timing
        port map (
            rst         => rst,
            clk         => clk,
            pix_rep     => mode_pixrep,
            interlace   => mode_ilace,
            v_tot       => mode_v_tot,
            v_act       => mode_v_act,
            v_sync      => mode_v_sync,
            v_bp        => mode_v_bp,
            h_tot       => mode_h_tot,
            h_act       => mode_h_act,
            h_sync      => mode_h_sync,
            h_bp        => mode_h_bp,
            align       => (others => '0'),
            ce          => raw_ce,
            f           => raw_f,
            vs          => raw_vs,
            hs          => raw_hs,
            vblank      => raw_vblank,
            hblank      => raw_hblank,
            ax          => raw_ax,
            ay          => raw_ay
        );

    PCM: entity xil_defaultlib.hdmi_tx_pcm
        generic map (
            fs          => fs
        )
        port map (

            rst         => pcm_rst,
            clk         => pcm_clk,
            clken       => pcm_clken,

            in_l        => pcm_l,
            in_r        => pcm_r,

            out_req     => hdmi_as_req,
            out_ack     => hdmi_as_ack,
            out_sync    => hdmi_as_sync,
            out_l       => hdmi_as_l,
            out_lv      => hdmi_as_lv,
            out_lu      => hdmi_as_lu,
            out_lc      => hdmi_as_lc,
            out_lp      => hdmi_as_lp,
            out_r       => hdmi_as_r,
            out_rv      => hdmi_as_rv,
            out_ru      => hdmi_as_ru,
            out_rc      => hdmi_as_rc,
            out_rp      => hdmi_as_rp

        );

    DATA: entity xil_defaultlib.hdmi_tx_data_injector
        generic map (
            pcm_clk_ratio => 256
        )
        port map (

            rst         => rst,
            clk         => clk,

            dvi         => mode_dvi,
            vic         => mode_id,
            aspect      => mode_aspect,
            pix_rep     => mode_pixrep,

            in_vs       => vga_vs xor (not mode_vs_pol),
            in_hs       => vga_hs xor (not mode_hs_pol),
            in_vblank   => vga_vblank,
            in_hblank   => vga_hblank,
            in_p(0)     => vga_b,
            in_p(1)     => vga_g,
            in_p(2)     => vga_r,
            in_ax       => vga_ax,
            in_ay       => vga_ay,

            pcm_rst     => pcm_rst,
            pcm_clk     => pcm_clk,
            pcm_req     => hdmi_as_req,
            pcm_ack     => hdmi_as_ack,
            pcm_sync    => hdmi_as_sync,
            pcm_l       => hdmi_as_l,
            pcm_lv      => hdmi_as_lv,
            pcm_lu      => hdmi_as_lu,
            pcm_lc      => hdmi_as_lc,
            pcm_lp      => hdmi_as_lp,
            pcm_r       => hdmi_as_r,
            pcm_rv      => hdmi_as_rv,
            pcm_ru      => hdmi_as_ru,
            pcm_rc      => hdmi_as_rc,
            pcm_rp      => hdmi_as_rp,
            pcm_n       => pcm_n,
            pcm_cts     => pcm_cts,

            out_vs      => hdmi_vs,
            out_hs      => hdmi_hs,
            out_de      => hdmi_de,
            out_p       => hdmi_p,
            out_enc     => hdmi_enc,
            out_ctl     => hdmi_ctl,
            out_d       => hdmi_d
        );

    hdmi_c(0)(0) <= hdmi_hs;
    hdmi_c(0)(1) <= hdmi_vs;
    hdmi_c(1) <= hdmi_ctl(1 downto 0);
    hdmi_c(2) <= hdmi_ctl(3 downto 2);

    GEN_HDMI: for i in 0 to 2 generate
    begin
        ENCODER: entity xil_defaultlib.hdmi_tx_encoder
            generic map (
                channel => i
            )
            port map (
                rst     => rst,
                clk     => clk,
                de      => hdmi_de,
                p       => hdmi_p(i),
                c       => hdmi_c(i),
                d       => hdmi_d(i),
                enc     => hdmi_enc,
                q       => hdmi_q(i)
            );
        SERIALISER: entity xil_defaultlib.serialiser_10to1_selectio
            port map (
                rst     => rst,
                clk     => clk,
                clk_x5  => clk_x5,
                d       => hdmi_q(i),
                out_p   => hdmi_ch_p(i),
                out_n   => hdmi_ch_n(i)
            );
    end generate GEN_HDMI;

    HDMI_CLK: entity xil_defaultlib.serialiser_10to1_selectio
        port map (
            rst     => rst,
            clk     => clk,
            clk_x5  => clk_x5,
            d       => "0000011111",
            out_p   => hdmi_clk_p,
            out_n   => hdmi_clk_n
        );

end architecture synth;
