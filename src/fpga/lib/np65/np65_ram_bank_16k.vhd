--------------------------------------------------------------------------------
-- np65_ram_bank_16k.vhd                                                      --
-- 16k x 8 RAM byte bank for np65 CPU with 64kbytes total RAM.                --
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

library unisim;
use unisim.vcomponents.all;

library xil_defaultlib;
use xil_defaultlib.np65_types_pkg.all;
use xil_defaultlib.np65_ram_pkg.all;

entity np65_ram_bank is
    generic (
        init        : ram_init_bank_t;
        rpm_name    : string := ""
    );
    port (
        clk     : in    std_logic;
        clr_a   : in    std_logic;
        ce_a    : in    std_logic;
        we_a    : in    std_logic;
        addr_a  : in    std_logic_vector(apmsb downto 2);
        din_a   : in    std_logic_vector(7 downto 0);
        dout_a  : out   std_logic_vector(7 downto 0);
        clr_b   : in    std_logic;
        ce_b    : in    std_logic;
        we_b    : in    std_logic;
        addr_b  : in    std_logic_vector(apmsb downto 2);
        din_b   : in    std_logic_vector(7 downto 0);
        dout_b  : out   std_logic_vector(7 downto 0)
    );
end entity np65_ram_bank;

architecture struct of np65_ram_bank is

    signal doado : slv_15_0_t(0 to 7);
    signal dobdo : slv_15_0_t(0 to 7);

    attribute U_SET : string;
    attribute RLOC : string;

begin

    GEN: for i in 0 to 7 generate

        attribute U_SET of RAM : label is rpm_name;
        attribute RLOC of RAM : label is "X0Y" & integer'image(i);

    begin

        RAM : RAMB18E1
            generic map (
                RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE", -- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
                SIM_COLLISION_CHECK => "ALL",                 -- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
                DOA_REG => 0,                                 -- optional output register (0 or 1)
                DOB_REG => 0,                                 -- optional output register (0 or 1)
                INIT_A => X"00000",                           -- initial values on output port A
                INIT_B => X"00000",                           -- initial values on output port B
                INIT_FILE => "NONE",                          -- Initialization File: RAM initialization file
                RAM_MODE => "TDP",                            -- RAM Mode: "SDP" or "TDP"
                READ_WIDTH_A => 1,                            -- port width, 0-72
                READ_WIDTH_B => 1,                            -- port width, 0-36
                WRITE_WIDTH_A => 1,                           -- port width, 0-36
                WRITE_WIDTH_B => 1,                           -- port width, 0-72
                RSTREG_PRIORITY_A => "RSTREG",                -- port A reset or enable priority ("RSTREG" or "REGCE")
                RSTREG_PRIORITY_B => "RSTREG",                -- port B reset or enable priority ("RSTREG" or "REGCE")
                SRVAL_A => X"00000",                          -- set/reset value for output
                SRVAL_B => X"00000",                          -- set/reset value for output
                SIM_DEVICE => "7SERIES",                      -- must be set to "7SERIES" for simulation behavior
                WRITE_MODE_A => "READ_FIRST",                 -- value on read port A upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
                WRITE_MODE_B => "READ_FIRST",                 -- value on read port A upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
                INIT_00 => init(i)(0),                        -- INIT_00 to INIT_3F: Initial contents of the data memory array (64 x hex digits)
                INIT_01 => init(i)(1),
                INIT_02 => init(i)(2),
                INIT_03 => init(i)(3),
                INIT_04 => init(i)(4),
                INIT_05 => init(i)(5),
                INIT_06 => init(i)(6),
                INIT_07 => init(i)(7),
                INIT_08 => init(i)(8),
                INIT_09 => init(i)(9),
                INIT_0A => init(i)(10),
                INIT_0B => init(i)(11),
                INIT_0C => init(i)(12),
                INIT_0D => init(i)(13),
                INIT_0E => init(i)(14),
                INIT_0F => init(i)(15),
                INIT_10 => init(i)(16),
                INIT_11 => init(i)(17),
                INIT_12 => init(i)(18),
                INIT_13 => init(i)(19),
                INIT_14 => init(i)(20),
                INIT_15 => init(i)(21),
                INIT_16 => init(i)(22),
                INIT_17 => init(i)(23),
                INIT_18 => init(i)(24),
                INIT_19 => init(i)(25),
                INIT_1A => init(i)(26),
                INIT_1B => init(i)(27),
                INIT_1C => init(i)(28),
                INIT_1D => init(i)(29),
                INIT_1E => init(i)(30),
                INIT_1F => init(i)(31),
                INIT_20 => init(i)(32),
                INIT_21 => init(i)(33),
                INIT_22 => init(i)(34),
                INIT_23 => init(i)(35),
                INIT_24 => init(i)(36),
                INIT_25 => init(i)(37),
                INIT_26 => init(i)(38),
                INIT_27 => init(i)(39),
                INIT_28 => init(i)(40),
                INIT_29 => init(i)(41),
                INIT_2A => init(i)(42),
                INIT_2B => init(i)(43),
                INIT_2C => init(i)(44),
                INIT_2D => init(i)(45),
                INIT_2E => init(i)(46),
                INIT_2F => init(i)(47),
                INIT_30 => init(i)(48),
                INIT_31 => init(i)(49),
                INIT_32 => init(i)(50),
                INIT_33 => init(i)(51),
                INIT_34 => init(i)(52),
                INIT_35 => init(i)(53),
                INIT_36 => init(i)(54),
                INIT_37 => init(i)(55),
                INIT_38 => init(i)(56),
                INIT_39 => init(i)(57),
                INIT_3A => init(i)(58),
                INIT_3B => init(i)(59),
                INIT_3C => init(i)(60),
                INIT_3D => init(i)(61),
                INIT_3E => init(i)(62),
                INIT_3F => init(i)(63)
                -- INITP_00 to INITP_07: Initial contents of the parity memory array (64 x hex digits)
                -- INIT_00 to INIT_3F: Initial contents of the data memory array (64 x hex digits)
            )
            port map (
                DOADO => doado(i),                     -- 16-bit output: A port data/LSB data
                DOPADOP => open,                       -- 2-bit output: A port parity/LSB parity
                DOBDO => dobdo(i),                     -- 16-bit output: B port data/MSB data
                DOPBDOP => open,                       -- 2-bit output: B port parity/MSB parity
                ADDRARDADDR => addr_a,                 -- 14-bit input: A port address/Read address
                CLKARDCLK => clk,                      -- 1-bit input: A port clock/Read clock
                ENARDEN => ce_a,                       -- 1-bit input: A port enable/Read enable
                REGCEAREGCE => '1',                    -- 1-bit input: A port register enable/Register enable
                RSTRAMARSTRAM => clr_a,     -- 1-bit input: A port set/reset
                RSTREGARSTREG => '0',                  -- 1-bit input: A port register set/reset
                WEA(0) => we_a,                        -- 2-bit input: A port write enable
                WEA(1) => '0',
                DIADI(0) => din_a(i),                  -- 16-bit input: A port data/LSB data
                DIADI(15 downto 1) => (others => '0'),
                DIPADIP => "00",                       -- 2-bit input: A port parity/LSB parity
                ADDRBWRADDR => addr_b,                 -- 14-bit input: B port address/Write address
                CLKBWRCLK => clk,                      -- 1-bit input: B port clock/Write clock
                ENBWREN => ce_b,                       -- 1-bit input: B port enable/Write enable
                REGCEB => '1',                         -- 1-bit input: B port register enable
                RSTRAMB => clr_b,                      -- 1-bit input: B port set/reset
                RSTREGB => '0',                        -- 1-bit input: B port register set/reset
                WEBWE(0) => we_b,                      -- 4-bit input: B port write enable/Write enable
                WEBWE(3 downto 1) => "000",
                DIBDI(0) => din_b(i),                  -- 16-bit input: B port data/MSB data
                DIBDI(15 downto 1) => (others => '0'),
                DIPBDIP => "00"                        -- 2-bit input: B port parity/MSB parity
            );

        dout_a(i) <= doado(i)(0);
        dout_b(i) <= dobdo(i)(0);

    end generate GEN;

end architecture struct;

--------------------------------------------------------------------------------
-- end of file