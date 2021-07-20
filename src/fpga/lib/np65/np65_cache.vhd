--------------------------------------------------------------------------------
-- np65_cache.vhd                                                             --
-- 256 byte asynchronous SRAM cache organised as 32 x 64 bits.                --
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

library xil_defaultlib;
use xil_defaultlib.np65_types_pkg.all;
use xil_defaultlib.np65_ram_pkg.all;

package np65_cache_pkg is

    component np65_cache is
        generic (

            base        : std_logic_vector(15 downto 8)

        );
        port (

            -- coherency (write) port

            clk_x2      : in    std_logic;
            clk_ph      : in    std_logic;
            dma_en      : in    std_logic;
            dma_a       : in    std_logic_vector(apmsb downto 3);
            dma_bwe     : in    std_logic_vector(7 downto 0);
            dma_dw      : in    slv_7_0_t(7 downto 0);
            cpu_a       : in    std_logic_vector(15 downto 0);
            cpu_bwe     : in    std_logic_vector(3 downto 0);
            cpu_dw      : in    slv_7_0_t(3 downto 0);

            -- cache (read) port

            cache_a     : in    std_logic_vector(7 downto 0);
            cache_dr    : out   slv_7_0_t(3 downto 0)

        );
    end component np65_cache;

end package np65_cache_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library xil_defaultlib;
use xil_defaultlib.np65_types_pkg.all;
use xil_defaultlib.np65_ram_pkg.all;

entity np65_cache is
    generic (

        base        : std_logic_vector(15 downto 8)

    );
    port (

        clk_x2      : in    std_logic;
        clk_ph      : in    std_logic;
        dma_en      : in    std_logic;
        dma_a       : in    std_logic_vector(apmsb downto 3);
        dma_bwe     : in    std_logic_vector(7 downto 0);
        dma_dw      : in    slv_7_0_t(7 downto 0);
        cpu_a       : in    std_logic_vector(15 downto 0);
        cpu_bwe     : in    std_logic_vector(3 downto 0);
        cpu_dw      : in    slv_7_0_t(3 downto 0);

        cache_a     : in    std_logic_vector(7 downto 0);
        cache_dr    : out   slv_7_0_t(3 downto 0)

    );
end entity np65_cache;

architecture synth of np65_cache is

    constant dma_base : std_logic_vector(apmsb downto 8) := (15 downto 8 => base, others => '0');

    signal  cpu_bwe8    : std_logic_vector(7 downto 0); -- CPU bwe extended to 8 bytes
    signal  cs_n        : std_logic_vector(7 downto 0); -- pseudo chip select to RAM byte banks
    signal  we          : std_logic_vector(7 downto 0); -- RAM byte bank write enable
    signal  wa          : slv_7_3_t(7 downto 0);        -- RAM byte bank write address
    signal  dw          : slv_7_0_t(7 downto 0);        -- RAM byte bank write data
    signal  ra          : slv_7_2_t(3 downto 0);        -- read address, per byte bank (of 4)
    signal  dr64        : slv_7_0_t(7 downto 0);        -- raw 64 bit read data
--    signal  dr32        : slv_7_0_t(3 downto 0);        -- raw 32 bit read data

begin

    cpu_bwe8 <= "0000" & cpu_bwe;

    GEN_BIT: for n_bit in 0 to 7 generate
        GEN_BYTE: for n_byte in 0 to 3 generate

            ra(n_byte) <= std_logic_vector(unsigned(cpu_a(7 downto 2))+1)
                when n_byte < to_integer(unsigned(cpu_a(1 downto 0)))
                else cpu_a(7 downto 2);

            GEN_DWORD: for n_dword in 0 to 1 generate

                cs_n(n_byte+(4*n_dword)) <= '0' when
                    (dma_en = '1' and dma_a(apmsb downto 8) = dma_base) or
                    (clk_ph = '1' and dma_en = '0' and cpu_a(15 downto 8) = base)
                    else '1';

                wa(n_byte+(4*n_dword)) <= dma_a(7 downto 3) when dma_en = '1' else
                    std_logic_vector(unsigned(cpu_a(7 downto 3))+1) when n_byte+(4*n_dword) < to_integer(unsigned(cpu_a(2 downto 0))) else
                    cpu_a(7 downto 3);

                we(n_byte+(4*n_dword)) <= dma_bwe(n_byte+(4*n_dword)) when dma_en = '1' else
                    cpu_bwe8(((n_byte+(4*n_dword))+0) mod 8) when cpu_a(2 downto 0) = "000" else
                    cpu_bwe8(((n_byte+(4*n_dword))+7) mod 8) when cpu_a(2 downto 0) = "001" else
                    cpu_bwe8(((n_byte+(4*n_dword))+6) mod 8) when cpu_a(2 downto 0) = "010" else
                    cpu_bwe8(((n_byte+(4*n_dword))+5) mod 8) when cpu_a(2 downto 0) = "011" else
                    cpu_bwe8(((n_byte+(4*n_dword))+4) mod 8) when cpu_a(2 downto 0) = "100" else
                    cpu_bwe8(((n_byte+(4*n_dword))+3) mod 8) when cpu_a(2 downto 0) = "101" else
                    cpu_bwe8(((n_byte+(4*n_dword))+2) mod 8) when cpu_a(2 downto 0) = "110" else
                    cpu_bwe8(((n_byte+(4*n_dword))+1) mod 8) when cpu_a(2 downto 0) = "111" else
                    '0';

                dw(n_byte+(4*n_dword)) <= dma_dw(n_byte+(4*n_dword)) when dma_en = '1' else
                    cpu_dw((n_byte+0) mod 4) when cpu_a(1 downto 0) = "00" else
                    cpu_dw((n_byte+3) mod 4) when cpu_a(1 downto 0) = "01" else
                    cpu_dw((n_byte+2) mod 4) when cpu_a(1 downto 0) = "10" else
                    cpu_dw((n_byte+1) mod 4) when cpu_a(1 downto 0) = "11" else
                    (others => '0');

                -- we need 8 byte banks x 32 bytes = 256 bytes per cache
                -- could use RAM32x1 as building block, but RAM64x1 uses same resources (2 LUTs per)
                -- and we can therefore direct unwanted writes to the unused half (the MSB of the
                -- address becomes a chip select)

                RAM : component ram64x1d
                    port map (
                        wclk    => clk_x2,
                        a0      => wa(n_byte+(4*n_dword))(3),
                        a1      => wa(n_byte+(4*n_dword))(4),
                        a2      => wa(n_byte+(4*n_dword))(5),
                        a3      => wa(n_byte+(4*n_dword))(6),
                        a4      => wa(n_byte+(4*n_dword))(7),
                        a5      => cs_n(n_byte+(4*n_dword)),
                        we      => we(n_byte+(4*n_dword)),
                        d       => dw(n_byte+(4*n_dword))(n_bit),
                        spo     => open,
                        dpra0   => cache_a(3),
                        dpra1   => cache_a(4),
                        dpra2   => cache_a(5),
                        dpra3   => cache_a(6),
                        dpra4   => cache_a(7),
                        dpra5   => '0',
                        dpo     => dr64(n_byte+(4*n_dword))(n_bit)
                    );

                end generate GEN_DWORD;

--            MUX: component muxf7
--                port map (
--                    s  => cache_a(2),
--                    i0 => dr64(n_byte)(n_bit),
--                    i1 => dr64(n_byte+4)(n_bit),
--                    o  => dr32(n_byte)(n_bit)
--                );

        end generate GEN_BYTE;
    end generate GEN_BIT;

--    with cache_a(1 downto 0) select cache_dr <=
--        (3 => dr32(3), 2 => dr32(2), 1 => dr32(1), 0 => dr32(0)) when "00",
--        (3 => dr32(0), 2 => dr32(3), 1 => dr32(2), 0 => dr32(1)) when "01",
--        (3 => dr32(1), 2 => dr32(0), 1 => dr32(3), 0 => dr32(2)) when "10",
--        (3 => dr32(2), 2 => dr32(1), 1 => dr32(0), 0 => dr32(3)) when others;

    with cache_a(2 downto 0) select cache_dr <=
        (3 => dr64(3), 2 => dr64(2), 1 => dr64(1), 0 => dr64(0)) when "000",
        (3 => dr64(4), 2 => dr64(3), 1 => dr64(2), 0 => dr64(1)) when "001",
        (3 => dr64(5), 2 => dr64(4), 1 => dr64(3), 0 => dr64(2)) when "010",
        (3 => dr64(6), 2 => dr64(5), 1 => dr64(4), 0 => dr64(3)) when "011",
        (3 => dr64(7), 2 => dr64(6), 1 => dr64(5), 0 => dr64(4)) when "100",
        (3 => dr64(0), 2 => dr64(7), 1 => dr64(6), 0 => dr64(5)) when "101",
        (3 => dr64(1), 2 => dr64(0), 1 => dr64(7), 0 => dr64(6)) when "110",
        (3 => dr64(2), 2 => dr64(1), 1 => dr64(0), 0 => dr64(7)) when others;

end architecture synth;