--------------------------------------------------------------------------------
-- dvi_out.vhd                                                                --
-- DVI output top level.                                                      --
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

package dvi_out_pkg is

    component dvi_out is
        port (

            rst         : in    std_logic;                      -- reset
            clk         : in    std_logic;                      -- pixel clock
            clk_x5      : in    std_logic;                      -- serialiser clock

            mode_pixrep : in    std_logic;                      -- 1 = pixel doubling/repetition
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

            raw_f       : out   std_logic;
            raw_vs      : out   std_logic;
            raw_hs      : out   std_logic;
            raw_vblank  : out   std_logic;
            raw_hblank  : out   std_logic;
            raw_ax      : out   std_logic_vector(11 downto 0);
            raw_ay      : out   std_logic_vector(11 downto 0);
            raw_align   : in    std_logic_vector(21 downto 0);

            vga_vs      : in    std_logic;
            vga_hs      : in    std_logic;
            vga_vblank  : in    std_logic;
            vga_hblank  : in    std_logic;
            vga_r       : in    std_logic_vector(7 downto 0);
            vga_g       : in    std_logic_vector(7 downto 0);
            vga_b       : in    std_logic_vector(7 downto 0);
            vga_ax      : in    std_logic_vector(11 downto 0);
            vga_ay      : in    std_logic_vector(11 downto 0);

            dvi_clk_p   : out   std_logic;
            dvi_clk_n   : out   std_logic;
            dvi_d_p     : out   std_logic_vector(0 to 2);
            dvi_d_n     : out   std_logic_vector(0 to 2)

        );
    end component dvi_out;

end package dvi_out_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;

entity dvi_out is
    port (

        rst         : in    std_logic;                      -- reset
        clk         : in    std_logic;                      -- pixel clock
        clk_x5      : in    std_logic;                      -- serialiser clock

        mode_pixrep : in    std_logic;                      -- 1 = pixel doubling/repetition
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

        raw_f       : out   std_logic;
        raw_vs      : out   std_logic;
        raw_hs      : out   std_logic;
        raw_vblank  : out   std_logic;
        raw_hblank  : out   std_logic;
        raw_ax      : out   std_logic_vector(11 downto 0);
        raw_ay      : out   std_logic_vector(11 downto 0);
        raw_align   : in    std_logic_vector(21 downto 0);

        vga_vs      : in    std_logic;
        vga_hs      : in    std_logic;
        vga_vblank  : in    std_logic;
        vga_hblank  : in    std_logic;
        vga_r       : in    std_logic_vector(7 downto 0);
        vga_g       : in    std_logic_vector(7 downto 0);
        vga_b       : in    std_logic_vector(7 downto 0);
        vga_ax      : in    std_logic_vector(11 downto 0);
        vga_ay      : in    std_logic_vector(11 downto 0);

        dvi_clk_p   : out   std_logic;
        dvi_clk_n   : out   std_logic;
        dvi_d_p     : out   std_logic_vector(0 to 2);
        dvi_d_n     : out   std_logic_vector(0 to 2)

    );
end entity dvi_out;

----------------------------------------------------------------------
architecture synth of dvi_out is

    signal tmds_p   : slv_7_0_t(0 to 2);    -- pixel data inputs to TMDS encoder
    signal tmds_c   : slv_1_0_t(0 to 2);    -- control inputs to TMDS encoder
    signal tmds_q   : slv_9_0_t(0 to 2);    -- TMDS symbols

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
            align       => raw_align,
            f           => raw_f,
            vs          => raw_vs,
            hs          => raw_hs,
            vblank      => raw_vblank,
            hblank      => raw_hblank,
            ax          => raw_ax,
            ay          => raw_ay
        );

    tmds_p <= (vga_b,vga_g,vga_r);
    tmds_c(0)(0) <= vga_hs xor (not mode_hs_pol);
    tmds_c(0)(1) <= vga_vs xor (not mode_vs_pol);
    tmds_c(1) <= (others => '0');
    tmds_c(2) <= (others => '0');

    GEN_DVI: for i in 0 to 2 generate
    begin
        ENCODER: entity xil_defaultlib.dvi_tx_encoder
            port map (
                rst     => rst,
                clk     => clk,
                de      => vga_vblank nor vga_hblank,
                d       => tmds_p(i),
                c       => tmds_c(i),
                q       => tmds_q(i)
            );
        SERIALISER: entity xil_defaultlib.serialiser_10to1_selectio
            port map (
                rst     => rst,
                clk     => clk,
                clk_x5  => clk_x5,
                d       => tmds_q(i),
                out_p   => dvi_d_p(i),
                out_n   => dvi_d_n(i)
            );
    end generate GEN_DVI;

    DVI_CLK: entity xil_defaultlib.serialiser_10to1_selectio
        port map (
            rst     => rst,
            clk     => clk,
            clk_x5  => clk_x5,
            d       => "0000011111",
            out_p   => dvi_clk_p,
            out_n   => dvi_clk_n
        );

end architecture synth;
