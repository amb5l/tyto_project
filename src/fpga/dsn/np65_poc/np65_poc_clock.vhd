--------------------------------------------------------------------------------
-- np65_poc_clock.vhd                                                         --
-- MMCM recipes for creating CPU and system clocks from a 100MHz ref clock.   --
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

package np65_poc_clock_pkg is

    component np65_poc_clock is
        generic (
            fref        : real      := 100.0;   -- reference clock frequency (MHz)
            fsys        : integer   := 100      -- system clock frequency (MHz)
        );
        port (
    
            rst_ref     : in    std_logic;      -- external reset in
            clk_ref     : in    std_logic;      -- reference clock in
    
            rst         : out   std_logic;      -- reset based on MMCM lock
            clk_x2      : out   std_logic;      -- system (x2) clock
            clk_x1      : out   std_logic       -- CPU (x1) clock
    
        );
    end component np65_poc_clock;

end package np65_poc_clock_pkg;

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library xil_defaultlib;

entity np65_poc_clock is
    generic (
        fref        : real      := 100.0;   -- reference clock frequency (MHz)
        fsys        : integer   := 100      -- system clock frequency (MHz)
    );
    port (

        rst_ref     : in    std_logic;      -- external reset in
        clk_ref     : in    std_logic;      -- reference clock in

        rst         : out   std_logic;      -- reset based on MMCM lock
        clk_x2      : out   std_logic;      -- system (x2) clock
        clk_x1      : out   std_logic       -- CPU (x1) clock

    );
end entity np65_poc_clock;

architecture synth of np65_poc_clock is

    signal locked       : std_logic;    -- MMCM locked output
    signal clko_fb      : std_logic;    -- unbuffered feedback clock
    signal clki_fb      : std_logic;    -- feedback clock
    signal clku_x2      : std_logic;    -- unbuffered x2 clock
    signal clku_x1      : std_logic;    -- unbuffered x1 clock

    function CLKFBOUT_MULT_F return real is
    begin
        if fref = 100.0 and fsys = 100 then
            return 10.0;
        elsif fref = 100.0 and fsys = 128 then
            return 48.0;
        elsif fref = 100.0 and fsys = 160 then
            return 12.0;
        elsif fref = 100.0 and fsys = 200 then
            return 10.0;
        elsif fref = 100.0 and fsys = 256 then
            return 48.0;
        elsif fref = 50.0 and fsys = 100 then
            return 20.0;
        elsif fref = 50.0 and fsys = 128 then
            return 64.0;
        else
            return 0.0; -- error
        end if;
    end function CLKFBOUT_MULT_F;

    function DIVCLK_DIVIDE return integer is
    begin
        if fref = 100.0 and fsys = 100 then
            return 1;
        elsif fref = 100.0 and fsys = 128 then
            return 5;
        elsif fref = 100.0 and fsys = 160 then
            return 1;
        elsif fref = 100.0 and fsys = 200 then
            return 1;
        elsif fref = 100.0 and fsys = 256 then
            return 5;
        elsif fref = 50.0 and fsys = 100 then
            return 1;
        elsif fref = 50.0 and fsys = 128 then
            return 5;
        else
            return 0; -- error
        end if;
    end function DIVCLK_DIVIDE;

    function CLKOUT0_DIVIDE_F return real is
    begin
        if fref = 100.0 and fsys = 100 then
            return 10.0;
        elsif fref = 100.0 and fsys = 128 then
            return 7.5;
        elsif fref = 100.0 and fsys = 160 then
            return 7.5;
        elsif fref = 100.0 and fsys = 200 then
            return 5.0;
        elsif fref = 100.0 and fsys = 256 then
            return 3.75;
        elsif fref = 50.0 and fsys = 100 then
            return 10.0;
        elsif fref = 50.0 and fsys = 128 then
            return 5.0;
        else
            return 0.0; -- error
        end if;
    end function CLKOUT0_DIVIDE_F;

    function CLKOUT1_DIVIDE return integer is
    begin
        return integer(2.0 * CLKOUT0_DIVIDE_F);
    end function CLKOUT1_DIVIDE;

begin

    SYNC: entity xil_defaultlib.double_sync
        port map (
            rst => '0',
            clk => clk_x1,
            d   => not locked,
            q   => rst
        );

    MMCM: MMCME2_ADV
    generic map(
        BANDWIDTH               => "OPTIMIZED",
        CLKFBOUT_MULT_F         => CLKFBOUT_MULT_F,
        CLKFBOUT_PHASE          => 0.0,
        CLKFBOUT_USE_FINE_PS    => false,
        CLKIN1_PERIOD           => 10.0,
        CLKIN2_PERIOD           => 0.0,
        CLKOUT0_DIVIDE_F        => CLKOUT0_DIVIDE_F,
        CLKOUT0_DUTY_CYCLE      => 0.5,
        CLKOUT0_PHASE           => 0.0,
        CLKOUT0_USE_FINE_PS     => false,
        CLKOUT1_DIVIDE          => CLKOUT1_DIVIDE,
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
        DIVCLK_DIVIDE           => DIVCLK_DIVIDE,
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
        RST             => rst_ref,
        LOCKED          => locked,
        CLKIN1          => clk_ref,
        CLKIN2          => '0',
        CLKINSEL        => '1',
        CLKINSTOPPED    => open,
        CLKFBIN         => clki_fb,
        CLKFBOUT        => clko_fb,
        CLKFBOUTB       => open,
        CLKFBSTOPPED    => open,
        CLKOUT0         => clku_x2,
        CLKOUT0B        => open,
        CLKOUT1         => clku_x1,
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

    BUFG_0: unisim.vcomponents.BUFG
        port map (
            I   => clku_x2,
            O   => clk_x2
        );

    BUFG_1: unisim.vcomponents.BUFG
        port map (
            I   => clku_x1,
            O   => clk_x1
        );

    BUFG_F: unisim.vcomponents.BUFG
        port map (
            I   => clko_fb,
            O   => clki_fb
        );

end architecture synth;