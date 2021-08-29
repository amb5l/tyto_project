--------------------------------------------------------------------------------
-- video_out_clock_fixed.vhd                                                  --
-- Pixel and serialiser clock synthesiser.                                    --
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

package video_clock_out_fixed_pkg is

    component video_out_clock_fixed is
        generic (
            fref    : real;                     -- reference clock frequency (MHz)
            fpix    : real                      -- pixel clock frequency (MHz)
        );
        port (
            rsti    : in    std_logic;          -- reset
            clki    : in    std_logic;          -- reference clock
            rsto    : out   std_logic;          -- MMCM lock status
            clko    : out   std_logic;          -- pixel clock
            clko_x5 : out   std_logic           -- serialiser clock
        );
    end component video_out_clock_fixed;

end package video_clock_out_fixed_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity video_out_clock_fixed is
    generic (
        fref    : real;                     -- reference clock frequency (MHz)
        fpix    : real                      -- pixel clock frequency (MHz)
    );
    port (
        rsti    : in    std_logic;          -- reset
        clki    : in    std_logic;          -- reference clock
        rsto    : out   std_logic;          -- MMCM lock status
        clko    : out   std_logic;          -- pixel clock
        clko_x5 : out   std_logic           -- serialiser clock
    );
end entity video_out_clock_fixed;

architecture synth of video_out_clock_fixed is

    signal locked   : std_logic;    -- MMCM lock status
    signal clko_fb  : std_logic;    -- unbuffered feedback clock
    signal clki_fb  : std_logic;    -- feedback clock
    signal clk0     : std_logic;    -- unbuffered output clock 0
    signal clk1     : std_logic;    -- unbuffered output clock 0

    ----------------------------------------------------------------------
    -- edit these functions to add support for other frequencies

    impure function get_vco_mul return real is
        variable r : real;
    begin
        r := 0.0;
        if fref = 100.0 and fpix = 27.0 then        r := 47.25;
        elsif fref = 50.0 and fpix = 27.0 then      r := 13.5;
        end if;
        return r;
    end function get_vco_mul;

    impure function get_vco_div return integer is
        variable r : integer;
    begin
        r := 0;
        if fref = 100.0 and fpix = 27.0 then        r := 5;
        elsif fref = 50.0 and fpix = 27.0 then      r := 1;
        end if;
        return r;
    end function get_vco_div;

    impure function get_o0_div return real is
        variable r : real;
    begin
        r := 0.0;
        if fref = 100.0 and fpix = 27.0 then        r := 7.0;
        elsif fref = 50.0 and fpix = 27.0 then      r := 5.0;
        end if;
        return r;
    end function get_o0_div;

    impure function get_o1_div return integer is
        variable r : integer;
    begin
        r := 0;
        if fref = 100.0 and fpix = 27.0 then        r := 35;
        elsif fref = 50.0 and fpix = 27.0 then      r := 25;
        end if;
        return r;
    end function get_o1_div;

    ----------------------------------------------------------------------

begin

    MMCM: mmcme2_adv
    generic map(
        bandwidth               => "OPTIMIZED",
        clkfbout_mult_f         => get_vco_mul,
        clkfbout_phase          => 0.0,
        clkfbout_use_fine_ps    => false,
        clkin1_period           => 1000.0/fref,
        clkin2_period           => 0.0,
        clkout0_divide_f        => get_o0_div,
        clkout0_duty_cycle      => 0.5,
        clkout0_phase           => 0.0,
        clkout0_use_fine_ps     => false,
        clkout1_divide          => get_o1_div,
        clkout1_duty_cycle      => 0.5,
        clkout1_phase           => 0.0,
        clkout1_use_fine_ps     => false,
        clkout2_divide          => 1,
        clkout2_duty_cycle      => 0.5,
        clkout2_phase           => 0.0,
        clkout2_use_fine_ps     => false,
        clkout3_divide          => 1,
        clkout3_duty_cycle      => 0.5,
        clkout3_phase           => 0.0,
        clkout3_use_fine_ps     => false,
        clkout4_cascade         => false,
        clkout4_divide          => 1,
        clkout4_duty_cycle      => 0.5,
        clkout4_phase           => 0.0,
        clkout4_use_fine_ps     => false,
        clkout5_divide          => 1,
        clkout5_duty_cycle      => 0.5,
        clkout5_phase           => 0.0,
        clkout5_use_fine_ps     => false,
        clkout6_divide          => 1,
        clkout6_duty_cycle      => 0.5,
        clkout6_phase           => 0.0,
        clkout6_use_fine_ps     => false,
        compensation            => "ZHOLD",
        divclk_divide           => get_vco_div,
        is_clkinsel_inverted    => '0',
        is_psen_inverted        => '0',
        is_psincdec_inverted    => '0',
        is_pwrdwn_inverted      => '0',
        is_rst_inverted         => '0',
        ref_jitter1             => 0.01,
        ref_jitter2             => 0.01,
        ss_en                   => "FALSE",
        ss_mode                 => "CENTER_HIGH",
        ss_mod_period           => 10000,
        startup_wait            => false
    )
    port map (
        pwrdwn          => '0',
        rst             => rsti,
        locked          => locked,
        clkin1          => clki,
        clkin2          => '0',
        clkinsel        => '1',
        clkinstopped    => open,
        clkfbin         => clki_fb,
        clkfbout        => clko_fb,
        clkfboutb       => open,
        clkfbstopped    => open,
        clkout0         => clk0,
        clkout0b        => open,
        clkout1         => clk1,
        clkout1b        => open,
        clkout2         => open,
        clkout2b        => open,
        clkout3         => open,
        clkout3b        => open,
        clkout4         => open,
        clkout5         => open,
        clkout6         => open,
        dclk            => '0',
        daddr           => (others => '0'),
        den             => '0',
        dwe             => '0',
        di              => (others => '0'),
        do              => open,
        drdy            => open,
        psclk           => '0',
        psdone          => open,
        psen            => '0',
        psincdec        => '0'
    );

    BUFG_F: unisim.vcomponents.BUFG
        port map (
            I   => clko_fb,
            O   => clki_fb
        );

    BUFG_O0: unisim.vcomponents.BUFG
        port map (
            I   => clk0,
            O   => clko_x5
        );

    BUFG_O1: unisim.vcomponents.BUFG
        port map (
            I   => clk1,
            O   => clko
        );

    rsto <= not locked;

end architecture synth;
