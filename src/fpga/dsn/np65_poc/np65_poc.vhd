--------------------------------------------------------------------------------
-- np65_poc.vhd                                                               --
-- Minimal proof of concept for np65 CPU. Requires board specific wrapper.    --
-- Can be built with 64k, 128k or 256k of physical RAM. Uses Acorn BBC Micro  --
-- approach to accessing RAM beyond 64k (16k "sideways" bank switching).      --
--------------------------------------------------------------------------------
-- (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        --
--                                                                            --
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
use xil_defaultlib.np65_pkg.all;
use xil_defaultlib.np65_poc_clock_pkg.all;

entity np65_poc is
    port (

        rst     : in    std_logic;
        clk_x2  : in    std_logic;
        clk_x1  : in    std_logic;
		hold    : in    std_logic;
		irq     : in    std_logic;
		nmi     : in    std_logic;
        dma_ti  : in    std_logic_vector(5 downto 0);
        dma_to  : out   std_logic_vector(7 downto 0);
        led     : out   std_logic_vector(7 downto 0)

    );
end entity np65_poc;

architecture synth of np65_poc is

    signal  if_al           : std_logic_vector(15 downto 0);
    signal  if_ap           : std_logic_vector(17 downto 0);
    signal  if_z            : std_logic;

    signal  ls_al           : std_logic_vector(15 downto 0);
    signal  ls_ap           : std_logic_vector(17 downto 0);
    signal  ls_en           : std_logic;
    signal  ls_re           : std_logic;
    signal  ls_we           : std_logic;
    signal  ls_z            : std_logic;
    signal  ls_wp           : std_logic;
    signal  ls_ext          : std_logic;
    signal  ext_dr          : std_logic_vector(7 downto 0);
    signal  ext_dw          : std_logic_vector(7 downto 0);

    signal  sideways_bank   : std_logic_vector(3 downto 0); -- MS bits of physical RAM address of sideways bank
    signal  sideways_z      : std_logic;                    -- 1 = sideways bank does not physically exist
    signal  sideways_wp     : std_logic;                    -- 1 = sideways bank is write protected

    signal  hw_reg_romsel    : std_logic_vector(3 downto 0);
    signal  hw_reg_wp       : std_logic_vector(15 downto 0);
    alias   hw_reg_wp0      : std_logic_vector(7 downto 0) is hw_reg_wp(7 downto 0);
    alias   hw_reg_wp1      : std_logic_vector(7 downto 0) is hw_reg_wp(15 downto 8);
    signal  hw_reg_led      : std_logic_vector(7 downto 0);
    signal  hw_reg_timer    : std_logic_vector(31 downto 0);
    alias   hw_reg_tim0     : std_logic_vector(7 downto 0) is hw_reg_timer(7 downto 0);
    signal  hw_reg_tim1     : std_logic_vector(7 downto 0);
    signal  hw_reg_tim2     : std_logic_vector(7 downto 0);
    signal  hw_reg_tim3     : std_logic_vector(7 downto 0);

    signal  dma_en          : std_logic;
    signal  dma_a           : std_logic_vector(np65_apmsb downto 3);
    signal  dma_bwe         : std_logic_vector(7 downto 0);
    signal  dma_dw          : std_logic_vector(63 downto 0);
    signal  dma_dr          : std_logic_vector(63 downto 0);

    attribute keep_hierarchy : string;
    attribute keep_hierarchy of CORE : label is "yes";

    -- hardware register addresses (offsets from FE00)
    constant RA_ROMSEL  : std_logic_vector(7 downto 0) := x"30";
    constant RA_WP0     : std_logic_vector(7 downto 0) := x"3E";
    constant RA_WP1     : std_logic_vector(7 downto 0) := x"3F";
    constant RA_LED     : std_logic_vector(7 downto 0) := x"70";
    constant RA_TIM0    : std_logic_vector(7 downto 0) := x"78";
    constant RA_TIM1    : std_logic_vector(7 downto 0) := x"79";
    constant RA_TIM2    : std_logic_vector(7 downto 0) := x"7A";
    constant RA_TIM3    : std_logic_vector(7 downto 0) := x"7B";

begin

    CORE: component np65
        generic map (

            vector_init     => x"FC00"

        )
        port map (

            clk_x1          => clk_x1,
            clk_x2          => clk_x2,
            clk_ph          => open,

            rst             => rst,
            hold            => hold,
            nmi             => nmi,
            irq             => irq,

            if_al           => if_al,
            if_ap           => if_ap(np65_apmsb downto 0),
            if_z            => if_z,

            ls_en           => ls_en,
            ls_re           => ls_re,
            ls_we           => ls_we,
            ls_al           => ls_al,
            ls_ap           => ls_ap(np65_apmsb downto 0),
            ls_z            => ls_z,
            ls_wp           => ls_wp,
            ls_ext          => ls_ext,

            ext_dr          => ext_dr,
            ext_dw          => ext_dw,

            dma_en          => dma_en,
            dma_a           => dma_a,
            dma_bwe         => dma_bwe,
            dma_dw          => dma_dw,
            dma_dr          => dma_dr,

            trace_stb       => open,
            trace_reg_pc    => open,
            trace_reg_s     => open,
            trace_reg_p     => open,
            trace_reg_a     => open,
            trace_reg_x     => open,
            trace_reg_y     => open

        );

    -- logical (CPU) memory map:
    --  region      contents
    --  0000-3FFF   lower 16k of fixed RAM
    --  4000-7FFF   upper 16k of fixed RAM
    --  8000-BFFF   sideways RAM banks (1, 4 or 12)
    --  C000-FBFF   ROM
    --  FC00-FEFF   hardware
    --  FF00-FFFF   ROM

    -- physical RAM memory map:
    --  region      contents                64k     128k    256k
    --  00000-03FFF lower 16k of fixed RAM
    --  04000-07FFF upper 16k of fixed RAM
    --  08000-0BFFF sideways RAM bank:      15      15      15
    --  0C000-0FFFF ROM
    --  10000-13FFF sideways RAM bank:       -      3       11
    --  14000-17FFF sideways RAM bank:       -      2       10
    --  18000-1BFFF sideways RAM bank:       -      1       9
    --  1C000-1FFFF sideways RAM bank:       -      0       8
    --  20000-23FFF sideways RAM bank:       -      -       7
    --  24000-27FFF sideways RAM bank:       -      -       6
    --  28000-2BFFF sideways RAM bank:       -      -       5
    --  2C000-2FFFF sideways RAM bank:       -      -       4
    --  30000-33FFF sideways RAM bank:       -      -       3
    --  34000-37FFF sideways RAM bank:       -      -       2
    --  38000-3BFFF sideways RAM bank:       -      -       1
    --  3C000-3FFFF sideways RAM bank:       -      -       0

    if_ap(13 downto 0) <= if_al(13 downto 0);
    with if_al(15 downto 14) select if_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sideways_bank when others;  -- sideways RAM banks

    if_z <= sideways_z when if_al(15 downto 14) = "10" else '0';

    ls_ap(13 downto 0) <= ls_al(13 downto 0);
    with ls_al(15 downto 14) select ls_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sideways_bank when others;  -- sideways RAM banks

    ls_z <= sideways_z when ls_al(15 downto 14) = "10" else '0';

    ls_wp <=
        '1' when ls_al(15 downto 14) = "11" else
        sideways_wp when ls_al(15 downto 14) = "10" else
        '0';

    ls_ext <= '1' when ls_al(15 downto 10) = "111111"
        and ls_al(9 downto 8) /= "11" else '0';

    -- hardware registers
    -- ROMSEL   sideways bank select (0..15)
    -- WP0      write protect for sideways banks 0..7
    -- WP1      write protect for sideways banks 8..15

    process(clk_x1)
    begin
        if rising_edge(clk_x1) then
            hw_reg_timer <= std_logic_vector(unsigned(hw_reg_timer)+1);
            if ls_al(15 downto 8) = x"FE" then
                if ls_we = '1' then -- writes
                    case ls_al(7 downto 0) is
                        when RA_ROMSEL =>
                            hw_reg_romsel <= ext_dw(3 downto 0);
                            sideways_bank <= "0010";
                            sideways_z <= '0';
                            sideways_wp <= hw_reg_wp(15);
                            if (np65_apmsb = 16) then
                                if ext_dw(3 downto 2) = "00" then
                                    sideways_bank <= "01" & not ext_dw(1 downto 0);
                                    sideways_wp <= hw_reg_wp(to_integer(unsigned(ext_dw(1 downto 0))));
                                else
                                    sideways_z <= '1';
                                    sideways_wp <= '1';
                                end if;
                            elsif (np65_apmsb = 17) then
                                if to_integer(unsigned(ext_dw(3 downto 0))) < 12 then
                                    sideways_bank <= std_logic_vector(to_unsigned(15-to_integer(unsigned(ext_dw(3 downto 0))),4));
                                    sideways_wp <= hw_reg_wp(to_integer(unsigned(ext_dw(3 downto 0))));
                                else
                                    sideways_z <= '1';
                                    sideways_wp <= '1';
                                end if;
                            end if;
                        when RA_WP0 =>
                            hw_reg_wp0 <= ext_dw;
                        when RA_WP1 =>
                            hw_reg_wp1 <= ext_dw;
                        when RA_LED =>
                            hw_reg_led <= ext_dw;
                        when RA_TIM0 =>
                        when RA_TIM1 =>
                        when RA_TIM2 =>
                        when RA_TIM3 =>
                            hw_reg_timer <= (others => '0');
                        when others =>
                            null;
                    end case;
                else -- reads
                    if ls_al(7 downto 0) = RA_TIM0 then
                        hw_reg_tim1 <= hw_reg_timer(15 downto 8);
                        hw_reg_tim2 <= hw_reg_timer(23 downto 16);
                        hw_reg_tim3 <= hw_reg_timer(31 downto 24);
                    end if;
                end if;
            end if;
            if rst = '1' then -- synchronous reset
                hw_reg_romsel <= (others => '1');
                sideways_bank <= (1 => '1', others => '0');
                sideways_z <= '0';
                sideways_wp <= '0';
                hw_reg_wp <= (others => '0');
                hw_reg_led <= (others => '0');
                hw_reg_timer <= (others => '0');
            end if;
        end if;
    end process;

    with ls_al(7 downto 0) select ext_dr <=
        "0000" & hw_reg_romsel  when RA_ROMSEL,
        hw_reg_wp0              when RA_WP0,
        hw_reg_wp1              when RA_WP1,
        hw_reg_led              when RA_LED,
        hw_reg_tim0             when RA_TIM0,
        hw_reg_tim1             when RA_TIM1,
        hw_reg_tim2             when RA_TIM2,
        hw_reg_tim3             when RA_TIM3,
        x"00"                   when others;

    led <= hw_reg_led;

    -- dummy DMA stuff

    process(clk_x2)
        variable i: integer;
    begin
        if rising_edge(clk_x2) then
        	dma_en <= dma_ti(0);
        	if dma_ti(1) = '1' then
        		dma_a <= (others => '0');
        	else
        		dma_a <= std_logic_vector(unsigned(dma_a)+1);
        	end if;
        	if dma_ti(1) = '1' then
        		dma_bwe <= (others => '0');
        	else
        		dma_bwe <= std_logic_vector(unsigned(dma_bwe)+1);
        	end if;
        	if dma_ti(2) = '1' then
        		dma_dw <= (others => '0');
        	else
        		dma_dw <= std_logic_vector(unsigned(dma_dw)+1);
        	end if;
            i := to_integer(unsigned(dma_ti(5 downto 3)));
            dma_to <= dma_dr(7+(i*8) downto i*8);
       end if;
    end process;

end architecture synth;
