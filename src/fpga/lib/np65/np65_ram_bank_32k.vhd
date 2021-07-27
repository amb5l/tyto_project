--------------------------------------------------------------------------------
-- np65_ram_bank_32k.vhd                                                      --
-- 32k x 8 RAM byte bank for np65 CPU with 128kbytes total RAM.               --
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

    signal doado        : slv_31_0_t(0 to 7);
    signal dobdo        : slv_31_0_t(0 to 7);
    signal diadi        : slv_31_0_t(0 to 7);
    signal dibdi        : slv_31_0_t(0 to 7);

    attribute U_SET : string;
    attribute RLOC : string;

begin

    GEN: for i in 0 to 7 generate

        attribute U_SET of RAM : label is rpm_name;
        attribute RLOC of RAM : label is "X0Y" & integer'image(i);

    begin

        diadi(i) <= (0 => din_a(i), others => '0');
        dibdi(i) <= (0 => din_b(i), others => '0');

        RAM : RAMB36E1
            generic map (
                RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",   -- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
                SIM_COLLISION_CHECK => "ALL",                   -- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
                DOA_REG => 0,                                   -- optional output register (0 or 1)
                DOB_REG => 0,                                   -- optional output register (0 or 1)
                EN_ECC_READ => FALSE,                           -- Enable ECC decoder (FALSE, TRUE)
                EN_ECC_WRITE => FALSE,                          -- Enable ECC encoder (FALSE, TRUE)
                INIT_A => X"000000000",                         -- initial values on output port A
                INIT_B => X"000000000",                         -- initial values on output port B
                INIT_FILE => "NONE",                            -- Initialization File: RAM initialization file
                RAM_MODE => "TDP",                              -- RAM Mode: "SDP" or "TDP"
                RAM_EXTENSION_A => "NONE",                      -- cascade mode ("UPPER", "LOWER", or "NONE")
                RAM_EXTENSION_B => "NONE",                      -- cascade mode ("UPPER", "LOWER", or "NONE")
                READ_WIDTH_A => 1,                              -- port width, 0-72
                READ_WIDTH_B => 1,                              -- port width, 0-36
                WRITE_WIDTH_A => 1,                             -- port width, 0-36
                WRITE_WIDTH_B => 1,                             -- port width, 0-72
                RSTREG_PRIORITY_A => "RSTREG",                  -- port A reset or enable priority ("RSTREG" or "REGCE")
                RSTREG_PRIORITY_B => "RSTREG",                  -- port B reset or enable priority ("RSTREG" or "REGCE")
                SRVAL_A => X"000000000",                        -- set/reset value for output
                SRVAL_B => X"000000000",                        -- set/reset value for output
                SIM_DEVICE => "7SERIES",                        -- must be set to "7SERIES" for simulation behavior
                WRITE_MODE_A => "READ_FIRST",                   -- value on read port A upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
                WRITE_MODE_B => "READ_FIRST",                   -- value on read port A upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
                INIT_00 => init(i)(0),                          -- INIT_00 to INIT_7F: Initial contents of the data memory array (64 x hex digits)
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
                INIT_3F => init(i)(63),
                INIT_40 => init(i)(64),
                INIT_41 => init(i)(65),
                INIT_42 => init(i)(66),
                INIT_43 => init(i)(67),
                INIT_44 => init(i)(68),
                INIT_45 => init(i)(69),
                INIT_46 => init(i)(70),
                INIT_47 => init(i)(71),
                INIT_48 => init(i)(72),
                INIT_49 => init(i)(73),
                INIT_4A => init(i)(74),
                INIT_4B => init(i)(75),
                INIT_4C => init(i)(76),
                INIT_4D => init(i)(77),
                INIT_4E => init(i)(78),
                INIT_4F => init(i)(79),
                INIT_50 => init(i)(80),
                INIT_51 => init(i)(81),
                INIT_52 => init(i)(82),
                INIT_53 => init(i)(83),
                INIT_54 => init(i)(84),
                INIT_55 => init(i)(85),
                INIT_56 => init(i)(86),
                INIT_57 => init(i)(87),
                INIT_58 => init(i)(88),
                INIT_59 => init(i)(89),
                INIT_5A => init(i)(90),
                INIT_5B => init(i)(91),
                INIT_5C => init(i)(92),
                INIT_5D => init(i)(93),
                INIT_5E => init(i)(94),
                INIT_5F => init(i)(95),
                INIT_60 => init(i)(96),
                INIT_61 => init(i)(97),
                INIT_62 => init(i)(98),
                INIT_63 => init(i)(99),
                INIT_64 => init(i)(100),
                INIT_65 => init(i)(101),
                INIT_66 => init(i)(102),
                INIT_67 => init(i)(103),
                INIT_68 => init(i)(104),
                INIT_69 => init(i)(105),
                INIT_6A => init(i)(106),
                INIT_6B => init(i)(107),
                INIT_6C => init(i)(108),
                INIT_6D => init(i)(109),
                INIT_6E => init(i)(110),
                INIT_6F => init(i)(111),
                INIT_70 => init(i)(112),
                INIT_71 => init(i)(113),
                INIT_72 => init(i)(114),
                INIT_73 => init(i)(115),
                INIT_74 => init(i)(116),
                INIT_75 => init(i)(117),
                INIT_76 => init(i)(118),
                INIT_77 => init(i)(119),
                INIT_78 => init(i)(120),
                INIT_79 => init(i)(121),
                INIT_7A => init(i)(122),
                INIT_7B => init(i)(123),
                INIT_7C => init(i)(124),
                INIT_7D => init(i)(125),
                INIT_7E => init(i)(126),
                INIT_7F => init(i)(127)
                -- INITP_00 to INITP_0F: Initial contents of the parity memory array (64 x hex digits)
            )
            port map (
                CASCADEOUTA => open,        -- 1 bit output: A port cascade (to create 64kx1)
                CASCADEOUTB => open,        -- 1 bit output: B port cascade (to create 64kx1)
                DBITERR => open,            -- 1 bit output: ECC - double bit error status
                ECCPARITY => open,          -- 8-bit output: Generated error correction parity
                RDADDRECC => open,          -- 9-bit output: ECC read address
                SBITERR => open,            -- 1-bit output: Single bit error status
                DOADO => doado(i),           -- 32-bit output: A port data/LSB data
                DOPADOP => open,            -- 4-bit output: A port parity/LSB parity
                DOBDO => dobdo(i),          -- 32-bit output: B port data/MSB data
                DOPBDOP => open,            -- 4-bit output: B port parity/MSB parity
                CASCADEINA => '0',          -- 1-bit input: A port cascade
                CASCADEINB => '0',          -- 1-bit input: B port cascade
                INJECTDBITERR => '0',       -- 1-bit input: Inject a double bit error
                INJECTSBITERR => '0',       -- 1-bit input: Inject a single bit error
                ADDRARDADDR => '1' & addr_a,-- 16-bit input: A port address/Read address
                CLKARDCLK => clk,           -- 1-bit input: A port clock/Read clock
                ENARDEN => ce_a,            -- 1-bit input: A port enable/Read enable
                REGCEAREGCE => '1',         -- 1-bit input: A port register enable/Register enable
                RSTRAMARSTRAM => clr_a,     -- 1-bit input: A port set/reset
                RSTREGARSTREG => '0',       -- 1-bit input: A port register set/reset
                WEA => "000" & we_a,        -- 4-bit input: A port write enable
                DIADI => diadi(i),          -- 32-bit input: A port data/LSB data
                DIPADIP => "0000",          -- 4-bit input: A port parity/LSB parity
                ADDRBWRADDR => '1' & addr_b,-- 16-bit input: B port address/Write address
                CLKBWRCLK => clk,           -- 1-bit input: B port clock/Write clock
                ENBWREN => ce_b,            -- 1-bit input: B port enable/Write enable
                REGCEB => '1',              -- 1-bit input: B port register enable
                RSTRAMB => clr_b,           -- 1-bit input: B port set/reset
                RSTREGB => '0',             -- 1-bit input: B port register set/reset
                WEBWE => "0000000" & we_b,  -- 8-bit input: B port write enable/Write enable
                DIBDI => dibdi(i)   ,       -- 32-bit input: B port data/MSB data
                DIPBDIP => "0000"           -- 4-bit input: B port parity/MSB parity
            );

        dout_a(i) <= doado(i)(0);
        dout_b(i) <= dobdo(i)(0);

    end generate GEN;

end architecture struct;

--------------------------------------------------------------------------------
-- end of file