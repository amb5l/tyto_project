--------------------------------------------------------------------------------
-- mb_display_sd.vhd                                                          --
-- MicroBlaze CPU with standard definition text display.                      --
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

entity mb_display_sd is
    generic (
        fref        : real                                   -- reference clock frequency (MHz)
    );
    port (

        ext_rst     : in    std_logic;                      -- external reset
        ref_clk     : in    std_logic;                      -- reference clock (100MHz)

        heartbeat   : out   std_logic;                      -- 1Hz
        status      : out   std_logic_vector(2 downto 0);   -- status

        uart_tx     : out   std_logic;                      -- UART transmit
        uart_rx     : in    std_logic;                      -- UART receive

        dvi_clk_p   : out   std_logic;                      -- DVI TMDS clock (differential, P)
        dvi_clk_n   : out   std_logic;                      -- DVI TMDS clock (differential, N)
        dvi_ch_p    : out   std_logic_vector(0 to 2);       -- DVI TMDS channels 0..2 (differential, P)
        dvi_ch_n    : out   std_logic_vector(0 to 2)        -- DVI TMDS channels 0..2 (differential, N)

    );
end entity mb_display_sd;

architecture synth of mb_display_sd is

    signal sys_clk          : std_logic;
    signal sys_clk_lock     : std_logic;
    signal sys_rst          : std_logic;
    signal cpu_rst          : std_logic;
    signal pix_rst          : std_logic;

    signal gpi              : std_logic_vector(7 downto 0);
    signal gpo              : std_logic_vector(7 downto 0);

    signal bram_addr        : std_logic_vector(15 downto 0);
    signal bram_clk         : std_logic;
    signal bram_din         : std_logic_vector(31 downto 0);
    signal bram_dout        : std_logic_vector(31 downto 0);
    signal bram_en          : std_logic;
    signal bram_rst         : std_logic;
    signal bram_we          : std_logic_vector(3 downto 0);

begin

    process(sys_rst,sys_clk)
        variable counter : integer range 0 to 99999999;
    begin
        if sys_rst = '1' then
            counter := 0;
            heartbeat <= '1';
        elsif rising_edge(sys_clk) then
            if counter = 49999999 then
                counter := counter + 1;
                heartbeat <= '0';
            elsif counter = 99999999 then
                counter := 0;
                heartbeat <= '1';
            else
                counter := counter + 1;
            end if;
        end if;
    end process;

    status(0) <= not sys_rst;
    status(1) <= not pix_rst;
    status(2) <= not cpu_rst;

    gpi(7 downto 0) <= (others => '0');

    SYSTEM_CLOCK: entity xil_defaultlib.clock_100m
        generic map (
            fref    => fref
        )
        port map (
            rsti    => ext_rst,
            clki    => ref_clk,
            rsto    => sys_rst,
            clko    => sys_clk
        );

    CPU: entity xil_defaultlib.microblaze_wrapper
        port map (
            clk         => sys_clk,
            rsti_n      => '1',
            lock        => not sys_rst,
            rsto(0)     => cpu_rst,
            gpo_tri_o   => gpo,
            gpi_tri_i   => gpi,
            uart_txd    => uart_tx,
            uart_rxd    => uart_rx,
            bram_addr   => bram_addr,
            bram_clk    => bram_clk,
            bram_din    => bram_din,
            bram_dout   => bram_dout,
            bram_en     => bram_en,
            bram_rst    => bram_rst,
            bram_we     => bram_we
        );

    DISPLAY: entity xil_defaultlib.display_sd
        generic map (
            fref        => fref
        )
        port map (
            ref_rst     => ext_rst,
            ref_clk     => ref_clk,
            sys_rst     => sys_rst,
            sys_clk     => sys_clk,
            pix_rst     => pix_rst,
            bram_en     => bram_en,
            bram_we     => bram_we,
            bram_addr   => bram_addr,
            bram_din    => bram_din,
            bram_dout   => bram_dout,
            pal_ntsc    => gpo(0),
            border      => gpo(7 downto 4),
            dvi_clk_p   => dvi_clk_p,
            dvi_clk_n   => dvi_clk_n,
            dvi_ch_p    => dvi_ch_p,
            dvi_ch_n    => dvi_ch_n
        );

end architecture synth;
