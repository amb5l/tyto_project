--------------------------------------------------------------------------------
-- dvi_tx.vhd                                                                 --
-- TMDS encoders and serialisers.                                             --
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

package dvi_tx_pkg is

    component dvi_tx is
        port (

            vga_clk     : in    std_logic;                      -- pixel clock
            vga_clk_x5  : in    std_logic;                      -- serialiser clock
            vga_rst     : in    std_logic;                      -- synchronous reset
            vga_vs      : in     std_logic;                     -- vertical sync
            vga_hs      : in     std_logic;                     -- horizontal sync
            vga_vblank  : in     std_logic;                     -- vertical blank
            vga_hblank  : in     std_logic;                     -- horizontal blank
            vga_r       : in     std_logic_vector(7 downto 0);  -- red pixel data
            vga_g       : in     std_logic_vector(7 downto 0);  -- green pixel data
            vga_b       : in     std_logic_vector(7 downto 0);  -- blue pixel data

            dvi_clk_p   : out   std_logic;                      -- DVI (TMDS) clock output (+ve)
            dvi_clk_n   : out   std_logic;                      -- DVI (TMDS) clock output (-ve)
            dvi_d_p     : out   std_logic_vector(0 to 2);       -- DVI (TMDS) data output channels 0..2 (+ve)
            dvi_d_n     : out   std_logic_vector(0 to 2)        -- DVI (TMDS) data output channels 0..2 (-ve)

        );
    end component dvi_tx;

end package dvi_tx_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.types_pkg.all;
use work.dvi_tx_encoder_pkg.all;
use work.serialiser_10to1_selectio_pkg.all;

entity dvi_tx is
    port (

        vga_clk     : in    std_logic;                      -- pixel clock
        vga_clk_x5  : in    std_logic;                      -- serialiser clock
        vga_rst     : in    std_logic;                      -- synchronous reset
        vga_vs      : in     std_logic;                     -- vertical sync
        vga_hs      : in     std_logic;                     -- horizontal sync
        vga_vblank  : in     std_logic;                     -- vertical blank
        vga_hblank  : in     std_logic;                     -- horizontal blank
        vga_r       : in     std_logic_vector(7 downto 0);  -- red pixel data
        vga_g       : in     std_logic_vector(7 downto 0);  -- green pixel data
        vga_b       : in     std_logic_vector(7 downto 0);  -- blue pixel data

        dvi_clk_p   : out   std_logic;                      -- DVI (TMDS) clock output (+ve)
        dvi_clk_n   : out   std_logic;                      -- DVI (TMDS) clock output (-ve)
        dvi_d_p     : out   std_logic_vector(0 to 2);       -- DVI (TMDS) data output channels 0..2 (+ve)
        dvi_d_n     : out   std_logic_vector(0 to 2)        -- DVI (TMDS) data output channels 0..2 (-ve)

    );
end entity dvi_tx;

architecture synth of dvi_tx is

    signal tmds : slv_9_0_t(0 to 2);

begin

    DVI_CH0: component dvi_tx_encoder
            port map (
                rst     => vga_rst,
                clk     => vga_clk,
                de      => vga_vblank nor vga_hblank,
                c       => vga_vs & vga_hs,
                d       => vga_b,
                q       => tmds(0)
            );

    DVI_CH1: component dvi_tx_encoder
            port map (
                rst     => vga_rst,
                clk     => vga_clk,
                de      => vga_vblank nor vga_hblank,
                c       => "00",
                d       => vga_g,
                q       => tmds(1)
            );

    DVI_CH2: component dvi_tx_encoder
            port map (
                rst     => vga_rst,
                clk     => vga_clk,
                de      => vga_vblank nor vga_hblank,
                c       => "00",
                d       => vga_r,
                q       => tmds(2)
            );

    GEN_DVI_DATA: for i in 0 to 2 generate
        DVI_DATA: component serialiser_10to1_selectio
            port map (
                rst     => vga_rst,
                clk     => vga_clk,
                clk_x5  => vga_clk_x5,
                d       => tmds(i),
                out_p   => dvi_d_p(i),
                out_n   => dvi_d_n(i)
            );
    end generate GEN_DVI_DATA;
    DVI_CLK: component serialiser_10to1_selectio
        port map (
            rst     => vga_rst,
            clk     => vga_clk,
            clk_x5  => vga_clk_x5,
            d       => "0000011111",
            out_p   => dvi_clk_p,
            out_n   => dvi_clk_n
        );

end architecture synth;
