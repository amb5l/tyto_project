--------------------------------------------------------------------------------
-- clock_100m.vhd                                                             --
-- Simple 100MHz clock source.                                                --
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

library unisim;
use unisim.vcomponents.all;

entity clock_100m is
    generic (
        fref        : real                  -- reference clock frequency (MHz)
    );
    port (
        rsti    : in    std_logic;          -- reset in
        clki    : in    std_logic;          -- reference clock in
        rsto    : out   std_logic;          -- reset out (from MMCM lock status)
        clko    : out   std_logic           -- 100MHz clock out
    );
end entity clock_100m;

architecture synth of clock_100m is

    signal locked   : std_logic;    -- MMCM lock status
    signal clko_u   : std_logic;    -- unbuffered output clock
    signal clko_fb  : std_logic;    -- unbuffered feedback clock
    signal clki_fb  : std_logic;    -- feedback clock

    ----------------------------------------------------------------------
    -- edit these functions to add support for other ref clk frequencies

    impure function get_vco_mul return real is
        variable r : real;
    begin
        r := 0.0;
        if fref = 100.0 then
            r := 10.0;
        elsif fref = 50.0 then
            r := 20.0;
        end if;
        return r;
    end function get_vco_mul;

    impure function get_vco_div return integer is
        variable r : integer;
    begin
        r := 0;
        if fref = 100.0 then
            r := 1;
        elsif fref = 50.0 then
            r := 1;
        end if;
        return r;
    end function get_vco_div;

    impure function get_o_div return real is
        variable r : real;
    begin
        r := 0.0;
        if fref = 100.0 then
            r := 10.0;
        elsif fref = 50.0 then
            r := 10.0;
        end if;
        return r;
    end function get_o_div;

    constant mmcm_vco_mul   : real      := get_vco_mul;
    constant mmcm_vco_div   : integer   := get_vco_div;
    constant mmcm_o_div     : real      := get_o_div;

    ----------------------------------------------------------------------

begin

    MMCM: MMCME2_ADV
    generic map(
        BANDWIDTH               => "OPTIMIZED",
        CLKFBOUT_MULT_F         => mmcm_vco_mul,
        CLKFBOUT_PHASE          => 0.0,
        CLKFBOUT_USE_FINE_PS    => false,
        CLKIN1_PERIOD           => 1000.0/fref,
        CLKIN2_PERIOD           => 0.0,
        CLKOUT0_DIVIDE_F        => mmcm_o_div,
        CLKOUT0_DUTY_CYCLE      => 0.5,
        CLKOUT0_PHASE           => 0.0,
        CLKOUT0_USE_FINE_PS     => false,
        CLKOUT1_DIVIDE          => 1,
        CLKOUT1_DUTY_CYCLE      => 0.5,
        CLKOUT1_PHASE           => 0.0,
        CLKOUT1_USE_FINE_PS     => false,
        CLKOUT2_DIVIDE          => 1,
        CLKOUT2_DUTY_CYCLE      => 0.5,
        CLKOUT2_PHASE           => 0.0,
        CLKOUT2_USE_FINE_PS     => false,
        CLKOUT3_DIVIDE          => 1,
        CLKOUT3_DUTY_CYCLE      => 0.5,
        CLKOUT3_PHASE           => 0.0,
        CLKOUT3_USE_FINE_PS     => false,
        CLKOUT4_CASCADE         => false,
        CLKOUT4_DIVIDE          => 1,
        CLKOUT4_DUTY_CYCLE      => 0.5,
        CLKOUT4_PHASE           => 0.0,
        CLKOUT4_USE_FINE_PS     => false,
        CLKOUT5_DIVIDE          => 1,
        CLKOUT5_DUTY_CYCLE      => 0.5,
        CLKOUT5_PHASE           => 0.0,
        CLKOUT5_USE_FINE_PS     => false,
        CLKOUT6_DIVIDE          => 1,
        CLKOUT6_DUTY_CYCLE      => 0.5,
        CLKOUT6_PHASE           => 0.0,
        CLKOUT6_USE_FINE_PS     => false,
        COMPENSATION            => "ZHOLD",
        DIVCLK_DIVIDE           => mmcm_vco_div,
        IS_CLKINSEL_INVERTED    => '0',
        IS_PSEN_INVERTED        => '0',
        IS_PSINCDEC_INVERTED    => '0',
        IS_PWRDWN_INVERTED      => '0',
        IS_RST_INVERTED         => '0',
        REF_JITTER1             => 0.01,
        REF_JITTER2             => 0.01,
        SS_EN                   => "FALSE",
        SS_MODE                 => "CENTER_HIGH",
        SS_MOD_PERIOD           => 10000,
        STARTUP_WAIT            => false
    )
    port map (
        PWRDWN          => '0',
        RST             => rsti,
        LOCKED          => locked,
        CLKIN1          => clki,
        CLKIN2          => '0',
        CLKINSEL        => '1',
        CLKINSTOPPED    => open,
        CLKFBIN         => clki_fb,
        CLKFBOUT        => clko_fb,
        CLKFBOUTB       => open,
        CLKFBSTOPPED    => open,
        CLKOUT0         => clko_u,
        CLKOUT0B        => open,
        CLKOUT1         => open,
        CLKOUT1B        => open,
        CLKOUT2         => open,
        CLKOUT2B        => open,
        CLKOUT3         => open,
        CLKOUT3B        => open,
        CLKOUT4         => open,
        CLKOUT5         => open,
        CLKOUT6         => open,
        DCLK            => '0',
        DADDR           => (others => '0'),
        DEN             => '0',
        DWE             => '0',
        DI              => (others => '0'),
        DO              => open,
        DRDY            => open,
        PSCLK           => '0',
        PSDONE          => open,
        PSEN            => '0',
        PSINCDEC        => '0'
    );

    BUFG_O: unisim.vcomponents.BUFG
        port map (
            I   => clko_u,
            O   => clko
        );

    BUFG_F: unisim.vcomponents.BUFG
        port map (
            I   => clko_fb,
            O   => clki_fb
        );

    rsto <= not locked;

end architecture synth;
