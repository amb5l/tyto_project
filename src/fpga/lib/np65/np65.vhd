--------------------------------------------------------------------------------
-- np65.vhd                                                                   --
-- np65 CPU and RAM core top level.                                           --
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
use ieee.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.np65_types_pkg.all;
use xil_defaultlib.np65_ram_pkg.all;
use xil_defaultlib.np65_cache_pkg.all;
use xil_defaultlib.np65_decoder_pkg.all;

entity np65 is
    generic (
        vector_init : std_logic_vector(15 downto 0)
    );
    port (

        clk_x1          : in    std_logic;                          -- CPU clock (typically 40-64MHz)
        clk_x2          : in    std_logic;                          -- system/RAM clock (always 2x CPU clock)

        -- clk_x1 domain

        rst             : in    std_logic;                          -- reset
        hold            : in    std_logic;                          -- wait states, pause during DMA, debug halt
        nmi             : in    std_logic;                          -- NMI
        irq             : in    std_logic;                          -- IRQ

        if_al           : out   std_logic_vector(15 downto 0);      -- instruction fetch logical address
        if_ap           : in    std_logic_vector(apmsb downto 0);   -- instruction fetch physical address
        if_z            : in    std_logic;                          -- instruction fetch physical address is empty/bad (reads zero)

        ls_en           : out   std_logic;                          -- load/store enable
        ls_re           : out   std_logic;                          -- load/store read enable
        ls_we           : out   std_logic;                          -- load/store write enable
        ls_al           : out   std_logic_vector(15 downto 0);      -- load/store logical address
        ls_ap           : in    std_logic_vector(apmsb downto 0);   -- load/store physical address of data
        ls_z            : in    std_logic;                          -- load/store physical address is empty/bad (reads zero)
        ls_wp           : in    std_logic;                          -- load/store physical address is write protected (ROM)
        ls_ext          : in    std_logic;                          -- load/store physical address is external (e.g. hardware register)

        ext_dr          : in    std_logic_vector(7 downto 0);       -- external read data
        ext_dw          : out   std_logic_vector(7 downto 0);       -- external write data

        trace_stb       : out   std_logic;                          -- trace strobe
        trace_reg_pc    : out   std_logic_vector(15 downto 0);      -- trace register PC
        trace_reg_s     : out   std_logic_vector(7 downto 0);       -- trace register S
        trace_reg_p     : out   std_logic_vector(7 downto 0);       -- trace register P
        trace_reg_a     : out   std_logic_vector(7 downto 0);       -- trace register A
        trace_reg_x     : out   std_logic_vector(7 downto 0);       -- trace register X
        trace_reg_y     : out   std_logic_vector(7 downto 0);       -- trace register Y

        -- clk_x2 domain

        dma_en          : in    std_logic;                          -- enable DMA access on this clk_x2 edge
        dma_a           : in    std_logic_vector(apmsb downto 3);   -- DMA address (Qword aligned)
        dma_bwe         : in    std_logic_vector(7 downto 0);       -- DMA byte write enables
        dma_dw          : in    std_logic_vector(63 downto 0);      -- DMA write data
        dma_dr          : out   std_logic_vector(63 downto 0)       -- DMA read data

    );
end entity np65;

architecture synth of np65 is

    constant SEL_LOGIC_NOP      : std_logic_vector(2 downto 0) := "000";
    constant SEL_LOGIC_AND_M    : std_logic_vector(2 downto 0) := "001";
    constant SEL_LOGIC_OR_M     : std_logic_vector(2 downto 0) := "010";
    constant SEL_LOGIC_EOR_M    : std_logic_vector(2 downto 0) := "011";
    constant SEL_LOGIC_AND_I    : std_logic_vector(2 downto 0) := "100";
    constant SEL_LOGIC_OR_I     : std_logic_vector(2 downto 0) := "101";
    constant SEL_LOGIC_EOR_I    : std_logic_vector(2 downto 0) := "110";

    constant SEL_FLAG_C_NOP     : std_logic_vector(1 downto 0) := "00";
    constant SEL_FLAG_C_ADD     : std_logic_vector(1 downto 0) := "01";
    constant SEL_FLAG_C_SHF_A   : std_logic_vector(1 downto 0) := "10";
    constant SEL_FLAG_C_SHF_M   : std_logic_vector(1 downto 0) := "11";

    constant SEL_FLAG_ZN_NOP    : std_logic_vector(2 downto 0) := "000";
    constant SEL_FLAG_ZN_ADD    : std_logic_vector(2 downto 0) := "010";
    constant SEL_FLAG_ZN_RMW    : std_logic_vector(2 downto 0) := "011";
    constant SEL_FLAG_ZN_A      : std_logic_vector(2 downto 0) := "100";
    constant SEL_FLAG_ZN_X      : std_logic_vector(2 downto 0) := "101";
    constant SEL_FLAG_ZN_Y      : std_logic_vector(2 downto 0) := "110";
    constant SEL_FLAG_ZN_BIT    : std_logic_vector(2 downto 0) := "111";

    constant SEL_FLAG_V_NOP     : std_logic_vector(1 downto 0) := "00";
    constant SEL_FLAG_V_ADD     : std_logic_vector(1 downto 0) := "10";
    constant SEL_FLAG_V_BIT     : std_logic_vector(1 downto 0) := "11";

    constant SEL_REG_A_NOP      : std_logic_vector(2 downto 0) := "000"; -- NOP should really be OTHER or NOT_MEM?
    constant SEL_REG_A_MEM      : std_logic_vector(2 downto 0) := "100";
    constant SEL_REG_A_ADD      : std_logic_vector(2 downto 0) := "101";
    constant SEL_REG_A_LOG      : std_logic_vector(2 downto 0) := "110";
    constant SEL_REG_A_SHF      : std_logic_vector(2 downto 0) := "111";

    constant SEL_REG_X_NOP      : std_logic_vector(0 downto 0) := "0"; -- NOP should really be OTHER or NOT_MEM
    constant SEL_REG_X_MEM      : std_logic_vector(0 downto 0) := "1";

    constant SEL_REG_Y_NOP      : std_logic_vector(0 downto 0) := "0"; -- NOP should really be OTHER or NOT_MEM
    constant SEL_REG_Y_MEM      : std_logic_vector(0 downto 0) := "1";

    -- memory, vectors, caches

    signal s0_if_z          : std_logic;
    alias  s0_if_al         : std_logic_vector(15 downto 0) is if_al;
    alias  s0_if_ap         : std_logic_vector(apmsb downto 0) is if_ap;
    signal s1_if_d          : slv_7_0_t(3 downto 0);
    alias  s1_opcode        : std_logic_vector(7 downto 0) is s1_if_d(0);
    alias  s1_operand_8     : std_logic_vector(7 downto 0) is s1_if_d(1);

    alias  s1_ls_al         : std_logic_vector(15 downto 0) is ls_al;
    alias  s1_ls_ap         : std_logic_vector(apmsb downto 0) is ls_ap;
    alias  s1_ls_z          : std_logic is ls_z;
    alias  s1_ls_ext        : std_logic is ls_ext;
    alias  s1_ls_wp         : std_logic is ls_wp;
    alias  s1_ls_en         : std_logic is ls_en;
    alias  s1_ls_re         : std_logic is ls_re;
    alias  s1_ls_we         : std_logic is ls_we;

    signal s1_ls_bwe        : std_logic_vector(3 downto 0);                 -- CPU data access -- write enable (up to 4 bytes)
    signal s1_ls_dw         : slv_7_0_t(3 downto 0);                        -- CPU data access - write data
    signal ls_dr            : slv_7_0_t(3 downto 0);                        -- CPU data access - read - valid in s2 for reads, s1 for RMW
    alias  mr               : std_logic_vector(7 downto 0) is ls_dr(0);     -- alias for tidier code (memory read data)
    signal s2_ext_dr        : slv_7_0_t(3 downto 0);

    signal vector_nmi       : std_logic_vector(15 downto 0);                -- cached NMI vector
    signal vector_nmi_en    : std_logic_vector(1 downto 0);                 -- address decode for above
    signal vector_irq       : std_logic_vector(15 downto 0);                -- cached BRK/IRQ vector
    signal vector_irq_en    : std_logic_vector(1 downto 0);                 -- address decode for above
    signal vector_dw        : std_logic_vector(7 downto 0);                 -- delayed write data
    signal vector_we        : std_logic;                                    -- delayed write enable

    signal s1_zptr_a        : std_logic_vector(7 downto 0);                 -- address of zero page pointer
    signal cache_z_d        : slv_7_0_t(3 downto 0);                        -- raw zero page cache read data
    signal s1_zptr_d        : std_logic_vector(15 downto 0);                -- zero page pointer value

    signal cache_s_d        : slv_7_0_t(3 downto 0);                        -- raw stack cache read data
    signal s1_pull_d        : slv_7_0_t(2 downto 0);                        -- fast pull data

    signal dma_dw_v         : slv_7_0_t(7 downto 0);
    signal dma_dr_v         : slv_7_0_t(7 downto 0);

    -- instruction decoder outputs

    signal s1_id_valid      : std_logic;
    signal s1_id_fast       : std_logic;
    signal s1_id_isize      : std_logic_vector(ID_ISIZE_1'range);
    signal s1_id_iaddr      : std_logic_vector(ID_IADDR_NXT'range);
    signal s1_id_branch     : std_logic;
    signal s1_id_bfsel      : std_logic_vector(ID_BFSEL_C'range);
    signal s1_id_bfval      : std_logic;
    signal s1_id_sdelta     : std_logic_vector(ID_SDELTA_0'range);
    signal s1_id_dop        : std_logic_vector(ID_DOP_NOP'range);
    signal s1_id_daddr      : std_logic_vector(ID_DADDR_IMM'range);
    signal s1_id_iix        : std_logic;
    signal s1_id_dsize      : std_logic_vector(ID_DSIZE_1'range);
    signal s1_id_wdata      : std_logic_vector(ID_WDATA_A'range);
    signal s1_id_sreg       : std_logic_vector(ID_SREG_A'range);
    signal s1_id_cmp        : std_logic;
    signal s1_id_incdec     : std_logic;
    signal s1_id_addsub     : std_logic;
    signal s1_id_logic      : std_logic_vector(ID_LOGIC_AND'range);
    signal s1_id_shift      : std_logic_vector(ID_SHIFT_ASL'range);
    signal s1_id_rmw        : std_logic;
    signal s1_id_reg_s      : std_logic;
    signal s1_id_reg_p      : std_logic;
    signal s1_id_reg_a      : std_logic_vector(ID_REG_A_NOP'range);
    signal s1_id_reg_x      : std_logic_vector(ID_REG_X_NOP'range);
    signal s1_id_reg_y      : std_logic_vector(ID_REG_Y_NOP'range);
    signal s1_id_flag_c     : std_logic_vector(ID_FLAG_C_NOP'range);
    signal s1_id_flag_zn    : std_logic_vector(ID_FLAG_ZN_NOP'range);
    signal s1_id_flag_i     : std_logic_vector(ID_FLAG_I_NOP'range);
    signal s1_id_flag_d     : std_logic_vector(ID_FLAG_D_NOP'range);
    signal s1_id_flag_v     : std_logic_vector(ID_FLAG_V_NOP'range);

    -- execution

    signal rst_1            : std_logic;                    -- reset, 1 clock delayed
    signal nmi_1            : std_logic;
    signal nmi_2            : std_logic;
    signal force_brk        : std_logic;                    -- force opcode to BRK (00) to make NMI/IRQ happen
    signal s1_flag_i_clr    : std_logic;                    -- I flag is being cleared by this instruction (CLI or PLP)
    signal s1_brk           : std_logic;                    -- current instruction is BRK
    signal s_valid          : std_logic_vector(0 to 3);     -- valid indication for pipeline stages 0,1,2,3
    signal advex            : std_logic;                    -- ADVance EXecution
    signal cycle            : std_logic;
    signal s1_col           : std_logic;                    -- data write to same address as instruction fetch (self modifying code) => wait state required

    signal s2_operand_8     : std_logic_vector(7 downto 0);

    signal s2_imm           : std_logic;
    signal s2_bcd           : std_logic;

    signal s2_id_addsub     : std_logic;
    signal s2_id_shift      : std_logic_vector(1 downto 0);
    signal s2_sel_logic     : std_logic_vector(SEL_LOGIC_NOP'range);

    signal s2_sel_flag_c    : std_logic_vector(SEL_FLAG_C_NOP'range);
    signal s2_sel_flag_zn   : std_logic_vector(SEL_FLAG_ZN_NOP'range);
    signal s2_sel_flag_v    : std_logic_vector(SEL_FLAG_V_NOP'range);
    signal s2_sel_reg_a     : std_logic_vector(SEL_REG_A_NOP'range);
    signal s2_sel_reg_x     : std_logic_vector(SEL_REG_X_NOP'range);
    signal s2_sel_reg_y     : std_logic_vector(SEL_REG_Y_NOP'range);

    -- instruction address generation

    signal s1_if_a_next     : std_logic_vector(15 downto 0);
    signal s1_if_bxx        : std_logic;
    signal s1_if_a_bxx      : std_logic_vector(15 downto 0);
    signal s1_if_a_vector   : std_logic_vector(15 downto 0);
    signal s1_if_a_rts      : std_logic_vector(15 downto 0);

    -- ALU/RMW related

    signal s2_adder_ci     : std_logic;
    signal s2_adder_i0     : std_logic_vector(7 downto 0);
    signal s2_adder_i1     : std_logic_vector(7 downto 0);
    signal s2_adder_bs     : std_logic_vector(7 downto 0);  -- binary sum
    signal s2_adder_ds     : std_logic_vector(7 downto 0);  -- decimal sum
    signal s2_adder_bc3    : std_logic;
    signal s2_adder_dc3    : std_logic;
    signal s2_adder_hc     : std_logic;
    signal s2_adder_bc6    : std_logic;
    signal s2_adder_bc7    : std_logic;
    signal s2_adder_dc7    : std_logic;
    signal s2_adder        : std_logic_vector(7 downto 0);  -- result (i0 +/- i1)
    signal s2_adder_c      : std_logic;
    signal s2_adder_z      : std_logic;
    signal s2_adder_v      : std_logic;
    signal s2_adder_n      : std_logic;

    signal s2_logic         : std_logic_vector(7 downto 0);
    signal s2_logic_z       : std_logic;

    signal s2_shift_a       : std_logic_vector(7 downto 0);
    signal s2_shift_a_c     : std_logic;
    signal s2_shift_m_c     : std_logic;

    signal s1b_rmw          : std_logic_vector(7 downto 0);
    signal s1b_rmw_z        : std_logic;
    signal s2_rmw_z         : std_logic;
    signal s2_rmw_n         : std_logic;

    -- registers

    signal s1_reg_pc        : std_logic_vector(15 downto 0);
    signal s1_reg_pc1       : std_logic_vector(15 downto 0);
    signal s1_reg_pc2       : std_logic_vector(15 downto 0);
    alias  s1_reg_pch2      : std_logic_vector(7 downto 0)  is s1_reg_pc2(15 downto 8);
    alias  s1_reg_pcl2      : std_logic_vector(7 downto 0)  is s1_reg_pc2(7 downto 0);

    signal s2_reg_s         : std_logic_vector(7 downto 0);
    signal s2_reg_s_add1    : std_logic_vector(7 downto 0);

    signal s2_reg_p         : std_logic_vector(7 downto 0);
    signal s2_reg_p_next    : std_logic_vector(7 downto 0);

    signal s2_reg_a         : std_logic_vector(7 downto 0);
    signal s2_reg_a_next    : std_logic_vector(7 downto 0);
    signal s2_reg_a_z       : std_logic;

    signal s2_reg_x         : std_logic_vector(7 downto 0);
    signal s2_reg_x_next    : std_logic_vector(7 downto 0);
    signal s2_reg_x_z       : std_logic;

    signal s2_reg_y         : std_logic_vector(7 downto 0);
    signal s2_reg_y_next    : std_logic_vector(7 downto 0);
    signal s2_reg_y_z       : std_logic;

    --------------------------------------------------------------------------------
    -- aliases, and signals that behave as aliases

    signal s1_operand_16    : std_logic_vector(15 downto 0);

    alias s2_flag_c         : std_logic is s2_reg_p(0);
    alias s2_flag_z         : std_logic is s2_reg_p(1);
    alias s2_flag_i         : std_logic is s2_reg_p(2);
    alias s2_flag_d         : std_logic is s2_reg_p(3);
    alias s2_flag_b         : std_logic is s2_reg_p(4);
    alias s2_flag_x         : std_logic is s2_reg_p(5);
    alias s2_flag_v         : std_logic is s2_reg_p(6);
    alias s2_flag_n         : std_logic is s2_reg_p(7);

    alias s2_flag_c_next    : std_logic is s2_reg_p_next(0);
    alias s2_flag_z_next    : std_logic is s2_reg_p_next(1);
    alias s2_flag_if_next   : std_logic is s2_reg_p_next(2);
    alias s2_flag_d_next    : std_logic is s2_reg_p_next(3);
    alias s2_flag_b_next    : std_logic is s2_reg_p_next(4);
    alias s2_flag_x_next    : std_logic is s2_reg_p_next(5);
    alias s2_flag_v_next    : std_logic is s2_reg_p_next(6);
    alias s2_flag_n_next    : std_logic is s2_reg_p_next(7);

    attribute keep_hierarchy : string;
    attribute keep_hierarchy of RAM : label is "yes";
    attribute keep_hierarchy of CACHE_Z : label is "yes";
    attribute keep_hierarchy of CACHE_S : label is "yes";
    attribute keep_hierarchy of DECODER : label is "yes";

    attribute keep : string;
    attribute keep of s1_zptr_d : signal is "true";
    attribute keep of s1_pull_d : signal is "true";

begin

    gen_dma_d_v: for i in 0 to 7 generate
        dma_dw_v(i) <= dma_dw((i*8)+7 downto i*8);
        dma_dr((i*8)+7 downto i*8) <= dma_dr_v(i);
    end generate gen_dma_d_v;

    -- main RAM

    s0_if_z <= rst or force_brk or if_z;

    RAM: component np65_ram
        port map (
            clk_x1     => clk_x1,
            clk_x2     => clk_x2,
            advex       => advex,
            if_z        => s0_if_z,
            if_a        => s0_if_ap,
            if_d        => s1_if_d,
            ls_z        => s1_ls_z,
            ls_wp       => s1_ls_wp,
            ls_ext      => s1_ls_ext,
            ls_we       => s1_ls_we,
            ls_a        => s1_ls_ap,
            ls_bwe      => s1_ls_bwe,
            ls_dw       => s1_ls_dw,
            ls_dr       => ls_dr,
            ext_dr      => s2_ext_dr,
            collision   => s1_col,
            rst         => rst,
            dma_en      => dma_en,
            dma_a       => dma_a,
            dma_bwe     => dma_bwe,
            dma_dw      => dma_dw_v,
            dma_dr      => dma_dr_v
        );

    s1_operand_16 <= s1_if_d(2) & s1_if_d(1);

    -- zero page cache

    CACHE_Z: component np65_cache
        generic map (
            base        => x"00"
        )
        port map (
            clk_x2      => clk_x2,
            dma_en      => dma_en,
            dma_a       => dma_a,
            dma_bwe     => dma_bwe,
            dma_dw      => dma_dw_v,
            cpu_a       => s1_ls_al,
            cpu_bwe     => s1_ls_bwe,
            cpu_dw      => s1_ls_dw,
            cache_a     => s1_zptr_a,
            cache_dr    => cache_z_d
        );

        s1_zptr_d <= cache_z_d(1) &  cache_z_d(0);

    -- stack cache

    CACHE_S: component np65_cache
        generic map (
            base        => x"01"
        )
        port map (
            clk_x2      => clk_x2,
            dma_en      => dma_en,
            dma_a       => dma_a,
            dma_bwe     => dma_bwe,
            dma_dw      => dma_dw_v,
            cpu_a       => s1_ls_al,
            cpu_bwe     => s1_ls_bwe,
            cpu_dw      => s1_ls_dw,
            cache_a     => s2_reg_s_add1,
            cache_dr    => cache_s_d
        );

    s1_pull_d <= cache_s_d(2 downto 0);

    -- instruction decoder

    DECODER: entity xil_defaultlib.np65_decoder
        port map (

            opcode  => s1_opcode,
            valid   => s1_id_valid,     -- opcode is valid
            fast    => s1_id_fast,      -- this is a single cycle instruction
            isize   => s1_id_isize,     -- instruction length (0..3 => 1..4 bytes)
            iaddr   => s1_id_iaddr,
            branch  => s1_id_branch,
            bfsel   => s1_id_bfsel,
            bfval   => s1_id_bfval,
            sdelta  => s1_id_sdelta,
            dop     => s1_id_dop,
            daddr   => s1_id_daddr,
            iix     => s1_id_iix,
            dsize   => s1_id_dsize,
            wdata   => s1_id_wdata,
            sreg    => s1_id_sreg,
            cmp     => s1_id_cmp,
            incdec  => s1_id_incdec,
            addsub  => s1_id_addsub,
            logic   => s1_id_logic,
            shift   => s1_id_shift,
            rmw     => s1_id_rmw,
            reg_s   => s1_id_reg_s,
            reg_p   => s1_id_reg_p,
            reg_a   => s1_id_reg_a,
            reg_x   => s1_id_reg_x,
            reg_y   => s1_id_reg_y,
            flag_c  => s1_id_flag_c,
            flag_zn => s1_id_flag_zn,
            flag_i  => s1_id_flag_i,
            flag_d  => s1_id_flag_d,
            flag_v  => s1_id_flag_v

        );

    -- execution control
    --  almost all instructions are single cycle
    --  exceptions are RMW and JMP indirect; these take 2 cycles and always start with a load
    --  note that cycles can be extended by wait states when accessing external memory

    advex <= not rst_1 and not hold and not s1_col and s1_id_valid and (s1_id_fast or cycle);

    s1_flag_i_clr <= '1' when -- I flag will be cleared by next instruction (CLI, RTI or PLP)
        (s1_id_flag_i = ID_FLAG_I_CLR) or
        (s1_id_reg_p = '1' and s1_pull_d(0)(2) = '0')
        else '0';

    s1_brk <= '1' when s1_id_flag_i = ID_FLAG_I_BRK else '0';

    process(clk_x1)
    begin
        if rising_edge(clk_x1) then

            rst_1 <= rst;

            if rst = '1' then

                s_valid         <= (others => '0');
                cycle           <= '0';

                s2_sel_logic     <= (others => '0');
                s2_sel_reg_a     <= (others => '0');
                s2_sel_reg_x     <= (others => '0');
                s2_sel_reg_y     <= (others => '0');
                s2_sel_flag_c    <= (others => '0');
                s2_sel_flag_zn   <= (others => '0');
                s2_sel_flag_v    <= (others => '0');

                s2_reg_p_next  <= x"34";

                trace_stb       <= '0';
                nmi_1           <= '0';
                nmi_2           <= '0';
                force_brk       <= '0';

            else

                cycle <= ((not hold and not s1_id_fast) or cycle) and not advex;

                s2_ext_dr <= (0 => ext_dr, others => x"00");

                trace_stb <= '0';

                s2_id_addsub    <= '0';
                s2_imm          <= '0';
                s2_bcd          <= '0';
                s2_id_shift     <= (others => '0');
                s2_sel_logic     <= (others => '0');
                s2_sel_reg_a     <= (others => '0');
                s2_sel_reg_x     <= (others => '0');
                s2_sel_reg_y     <= (others => '0');
                s2_sel_flag_c    <= (others => '0');
                s2_sel_flag_zn   <= (others => '0');
                s2_sel_flag_v    <= (others => '0');
                s2_adder_ci        <= '0';
                s2_adder_i0         <= (others => '0');
                s2_shift_a         <= (others => '0');

                s2_reg_p_next <= s2_reg_p;
                s2_reg_a_next <= s2_reg_a;
                s2_reg_x_next <= s2_reg_x;
                s2_reg_y_next <= s2_reg_y;

                if advex = '1' then

                    s_valid <= '1' & s_valid(0 to 2);

                    nmi_1 <= nmi and s2_flag_x;
                    nmi_2 <= nmi_1;
                    force_brk <= (nmi_1 and not nmi_2) or (irq and (s1_flag_i_clr or not s2_flag_i));

                    s2_id_addsub    <= s1_id_addsub;
                    s2_id_shift     <= s1_id_shift;
                    s2_operand_8 <= s1_operand_8;
                    s2_rmw_z     <= s1b_rmw_z;
                    s2_rmw_n       <= s1b_rmw(7);
                    if s1_id_daddr = ID_DADDR_IMM then
                        s2_imm <= '1';
                    else
                        s2_imm <= '0';
                    end if;

                    s2_bcd <= s2_flag_d and not s1_id_cmp;

                    -- synchronous selects drive asynchronous muxes

                    s2_sel_logic <= SEL_LOGIC_NOP;
                    if      s1_id_daddr /= ID_DADDR_IMM and s1_id_logic = ID_LOGIC_AND then s2_sel_logic <= SEL_LOGIC_AND_M;
                    elsif   s1_id_daddr /= ID_DADDR_IMM and s1_id_logic = ID_LOGIC_OR  then s2_sel_logic <= SEL_LOGIC_OR_M;
                    elsif   s1_id_daddr /= ID_DADDR_IMM and s1_id_logic = ID_LOGIC_EOR then s2_sel_logic <= SEL_LOGIC_EOR_M;
                    elsif   s1_id_daddr =  ID_DADDR_IMM and s1_id_logic = ID_LOGIC_AND then s2_sel_logic <= SEL_LOGIC_AND_I;
                    elsif   s1_id_daddr =  ID_DADDR_IMM and s1_id_logic = ID_LOGIC_OR  then s2_sel_logic <= SEL_LOGIC_OR_I;
                    elsif   s1_id_daddr =  ID_DADDR_IMM and s1_id_logic = ID_LOGIC_EOR then s2_sel_logic <= SEL_LOGIC_EOR_I;
                    end if;

                    s2_sel_reg_a <= SEL_REG_A_NOP;
                    if      s1_id_reg_a = ID_REG_A_IMM then s2_reg_a_next <= s1_operand_8;
                    elsif   s1_id_reg_a = ID_REG_A_MEM then s2_sel_reg_a <= SEL_REG_A_MEM;
                    elsif   s1_id_reg_a = ID_REG_A_ADD then s2_sel_reg_a <= SEL_REG_A_ADD;
                    elsif   s1_id_reg_a = ID_REG_A_LOG then s2_sel_reg_a <= SEL_REG_A_LOG;
                    elsif   s1_id_reg_a = ID_REG_A_SHF then s2_sel_reg_a <= SEL_REG_A_SHF;
                    elsif   s1_id_reg_a = ID_REG_A_TXA then s2_reg_a_next <= s2_reg_x;
                    elsif   s1_id_reg_a = ID_REG_A_TYA then s2_reg_a_next <= s2_reg_y;
                    end if;

                    s2_sel_reg_x <= SEL_REG_X_NOP;
                    if      s1_id_reg_x = ID_REG_X_IMM then s2_reg_x_next <= s1_operand_8;
                    elsif   s1_id_reg_x = ID_REG_X_MEM then s2_sel_reg_x <= SEL_REG_X_MEM;
                    elsif   s1_id_reg_x = ID_REG_X_INX then s2_reg_x_next <= std_logic_vector(unsigned(s2_reg_x)+1);
                    elsif   s1_id_reg_x = ID_REG_X_DEX then s2_reg_x_next <= std_logic_vector(unsigned(s2_reg_x)-1);
                    elsif   s1_id_reg_x = ID_REG_X_TAX then s2_reg_x_next <= s2_reg_a;
                    elsif   s1_id_reg_x = ID_REG_X_TSX then s2_reg_x_next <= s2_reg_s;
                    else
                    end if;

                    s2_sel_reg_y <= SEL_REG_Y_NOP;
                    if      s1_id_reg_y = ID_REG_Y_IMM then s2_reg_y_next <= s1_operand_8;
                    elsif   s1_id_reg_y = ID_REG_Y_MEM then s2_sel_reg_y <= SEL_REG_Y_MEM;
                    elsif   s1_id_reg_y = ID_REG_Y_INY then s2_reg_y_next <= std_logic_vector(unsigned(s2_reg_y)+1);
                    elsif   s1_id_reg_y = ID_REG_Y_DEY then s2_reg_y_next <= std_logic_vector(unsigned(s2_reg_y)-1);
                    elsif   s1_id_reg_y = ID_REG_Y_TAY then s2_reg_y_next <= s2_reg_a;
                    end if;

                    s2_sel_flag_c <= SEL_FLAG_C_NOP;
                    if      s1_id_flag_c = ID_FLAG_C_CLR then                             s2_flag_c_next <= '0';               -- CLC
                    elsif   s1_id_flag_c = ID_FLAG_C_SET then                             s2_flag_c_next <= '1';               -- SEC
                    elsif   s1_id_flag_c = ID_FLAG_C_SHF and s1_id_rmw /= ID_RMW_SHF then s2_sel_flag_c <= SEL_FLAG_C_SHF_A;
                    elsif   s1_id_flag_c = ID_FLAG_C_SHF and s1_id_rmw =  ID_RMW_SHF then s2_sel_flag_c <= SEL_FLAG_C_SHF_M;
                    elsif   s1_id_flag_c = ID_FLAG_C_ADD then                             s2_sel_flag_c <= SEL_FLAG_C_ADD;
                    end if;

                    s2_sel_flag_zn <= SEL_FLAG_ZN_NOP;
                    if      s1_id_flag_zn = ID_FLAG_ZN_BIT then s2_sel_flag_zn <= SEL_FLAG_ZN_BIT;
                    elsif   s1_id_flag_zn = ID_FLAG_ZN_ADD then s2_sel_flag_zn <= SEL_FLAG_ZN_ADD;
                    elsif   s1_id_flag_zn = ID_FLAG_ZN_RMW then s2_sel_flag_zn <= SEL_FLAG_ZN_RMW;
                    elsif   s1_id_flag_zn = ID_FLAG_ZN_A then   s2_sel_flag_zn <= SEL_FLAG_ZN_A;
                    elsif   s1_id_flag_zn = ID_FLAG_ZN_X then   s2_sel_flag_zn <= SEL_FLAG_ZN_X;
                    elsif   s1_id_flag_zn = ID_FLAG_ZN_Y then   s2_sel_flag_zn <= SEL_FLAG_ZN_Y;
                    end if;

                    if      s1_id_flag_i = ID_FLAG_I_CLR then s2_flag_if_next <= '0';
                    elsif   s1_id_flag_i = ID_FLAG_I_SET then s2_flag_if_next <= '1';
                    elsif   s1_id_flag_i = ID_FLAG_I_BRK then s2_flag_if_next <= '1';
                    end if;

                    if      s1_id_flag_d = ID_FLAG_D_CLR then s2_flag_d_next <= '0';
                    elsif   s1_id_flag_d = ID_FLAG_D_SET then s2_flag_d_next <= '1';
                    end if;

                    s2_sel_flag_v <= SEL_FLAG_V_NOP;
                    if      s1_id_flag_v = ID_FLAG_V_CLR then s2_flag_v_next <= '0';
                    elsif   s1_id_flag_v = ID_FLAG_V_ADD then s2_sel_flag_v <= SEL_FLAG_V_ADD;
                    elsif   s1_id_flag_v = ID_FLAG_V_BIT then s2_sel_flag_v <= SEL_FLAG_V_BIT;
                    end if;

                    -- PLP/RTI

                    if s1_id_reg_p = '1' then
                        s2_reg_p_next <= s1_pull_d(0);
                        s2_flag_b_next <= '1';
                        if s2_flag_x = '1' then
                            s2_flag_x_next <= '1'; -- setting X flag cannot be undone
                        end if;
                    end if;

                    -- misc sync

                    s2_adder_ci <= s2_flag_c or s1_id_cmp;

                    if      s1_id_sreg = ID_SREG_A then s2_adder_i0 <= s2_reg_a;
                    elsif   s1_id_sreg = ID_SREG_X then s2_adder_i0 <= s2_reg_x;
                    elsif   s1_id_sreg = ID_SREG_Y then s2_adder_i0 <= s2_reg_y;
                    else                                s2_adder_i0 <= (others => '0');
                    end if;

                    if      s1_id_shift = ID_SHIFT_ASL then s2_shift_a <= s2_reg_a(6 downto 0) & '0';
                    elsif   s1_id_shift = ID_SHIFT_LSR then s2_shift_a <= '0' & s2_reg_a(7 downto 1);
                    elsif   s1_id_shift = ID_SHIFT_ROL then s2_shift_a <= s2_reg_a(6 downto 0) & s2_flag_c;
                    elsif   s1_id_shift = ID_SHIFT_ROR then s2_shift_a <= s2_flag_c & s2_reg_a(7 downto 1);
                    else                                    s2_shift_a <= (others => '0');
                    end if;

                    case s1_id_shift is
                        when ID_SHIFT_ASL => s2_shift_m_c <= mr(7);
                        when ID_SHIFT_LSR => s2_shift_m_c <= mr(0);
                        when ID_SHIFT_ROL => s2_shift_m_c <= mr(7);
                        when ID_SHIFT_ROR => s2_shift_m_c <= mr(0);
                        when others => null;
                    end case;

                    -- trace

                    if s_valid(1) = '1' then
                        trace_stb       <= '1';
                        trace_reg_pc    <= s1_reg_pc;   -- all registers as at start of instruction
                        trace_reg_s     <= s2_reg_s;    --
                        trace_reg_p     <= s2_reg_p;    --
                        trace_reg_a     <= s2_reg_a;    --
                        trace_reg_x     <= s2_reg_x;    --
                        trace_reg_y     <= s2_reg_y;    --
                    end if;

                end if; -- advex
            end if; -- rst
        end if; -- rising_edge(clk_x1)
    end process;

    -- instruction fetch address generation

    s1_if_bxx <= '1' when
        (s1_id_bfsel = ID_BFSEL_C and s1_id_bfval = s2_flag_c) or
        (s1_id_bfsel = ID_BFSEL_Z and s1_id_bfval = s2_flag_z) or
        (s1_id_bfsel = ID_BFSEL_V and s1_id_bfval = s2_flag_v) or
        (s1_id_bfsel = ID_BFSEL_N and s1_id_bfval = s2_flag_n)
        else '0';

    s1_if_a_bxx <= s1_reg_pc2 when s1_if_bxx = '0' else
        std_logic_vector(unsigned(s1_reg_pc2) + unsigned(resize(signed(s1_operand_8), 16)));

    s1_if_a_vector <=
        vector_init when rst_1 = '1' else
        vector_nmi  when nmi_1 = '1' and nmi_2 = '0' else
        vector_irq;

    s1_if_a_next <=
       std_logic_vector(unsigned(s1_reg_pc) + unsigned(s1_id_isize) + 1) when s1_col = '0'
       else s1_reg_pc;

    s1_if_a_rts <= std_logic_vector(unsigned(s1_pull_d(1)) & unsigned(s1_pull_d(0)) + 1);
        
    with s1_id_iaddr select if_al <=
        s1_if_a_vector              when ID_IADDR_BRK, -- reset, IRQ, BRK, NMI
        s1_if_a_next                when ID_IADDR_NXT, -- next instruction
        s1_if_a_bxx                 when ID_IADDR_BRX, -- branch
        s1_operand_16               when ID_IADDR_JMP, -- JMP/JSR absolute
        s1_if_a_rts                 when ID_IADDR_RTS, -- RTS
        s1_pull_d(2) & s1_pull_d(1) when ID_IADDR_RTI, -- RTI
        ls_dr(1) & ls_dr(0)         when ID_IADDR_IND, -- JMP indirect
        x"0000"                     when others;

    -- load/store address generation

    s1_zptr_a <= std_logic_vector(unsigned(s1_operand_8) + unsigned(s2_reg_x)) when s1_id_iix = '1' else s1_operand_8;

    with s1_id_daddr select ls_al <=
        x"01" & s2_reg_s_add1                                                 when ID_DADDR_PULL,  -- stack pull (not needed because of stack cache)
        x"01" & s2_reg_s                                                      when ID_DADDR_PUSH1, -- stack push 1 byte (PHA, PHP)
        x"01" & std_logic_vector(unsigned(s2_reg_s) - 1)                      when ID_DADDR_PUSH2, -- stack push 2 bytes (JSR)
        x"01" & std_logic_vector(unsigned(s2_reg_s) - 2)                      when ID_DADDR_PUSH3, -- stack push 3 bytes (BRK/IRQ/NMI)
        x"00" & s1_operand_8                                                  when ID_DADDR_ZP,    -- ZP
        x"00" & std_logic_vector(unsigned(s1_operand_8) + unsigned(s2_reg_x)) when ID_DADDR_ZP_X,  -- ZP,X
        x"00" & std_logic_vector(unsigned(s1_operand_8) + unsigned(s2_reg_y)) when ID_DADDR_ZP_Y,  -- ZP,Y
        s1_operand_16                                                         when ID_DADDR_ABS,   -- absolute
        std_logic_vector(unsigned(s1_operand_16) + unsigned(s2_reg_x))        when ID_DADDR_ABS_X, -- absolute,X
        std_logic_vector(unsigned(s1_operand_16) + unsigned(s2_reg_y))        when ID_DADDR_ABS_Y, -- absolute,Y
        s1_zptr_d                                                             when ID_DADDR_IIX,   -- (ZP,X)
        std_logic_vector(unsigned(s1_zptr_d) + unsigned(s2_reg_y))            when ID_DADDR_IIY,   -- (ZP),Y
        x"0000"                                                               when others;

    -- load/store strobes and byte write enables

    s1_ls_en <=
        '0' when (hold = '1') else
        '1' when (s1_id_dop /= ID_DOP_NOP) else
        '0';

    s1_ls_re <=
        '0' when (hold = '1') else
        '1' when (s1_id_dop = ID_DOP_R) or ((s1_id_dop = ID_DOP_RMW) and cycle = '0') else
        '0';

    s1_ls_we <=
        '0' when (hold = '1') else
        '1' when (s1_id_dop = ID_DOP_W) or ((s1_id_dop = ID_DOP_RMW) and cycle = '1') else
        '0';

    s1_ls_bwe(0) <=
        '0' when (hold = '1') else
        '0' when (s1_id_fast = '0') and (cycle = '0') else
        '1' when (s1_id_dop = ID_DOP_W) or (s1_id_dop = ID_DOP_RMW) else
        '0';
    s1_ls_bwe(1) <=
        '0' when (hold = '1') else
        '0' when (s1_id_fast = '0') and (cycle = '0') else
        '0' when (s1_id_dsize = "00") else
        '1' when (s1_id_dop = ID_DOP_W) or (s1_id_dop = ID_DOP_RMW) else
        '0';
    s1_ls_bwe(2) <=
        '0' when (hold = '1') else
        '0' when (s1_id_fast = '0') and (cycle = '0') else
        '0' when (s1_id_dsize(1) = '0') else
        '1' when (s1_id_dop = ID_DOP_W) or ((s1_id_dop = ID_DOP_RMW) and cycle = '1') else
        '0';
    s1_ls_bwe(3) <=
        '0' when (hold = '1') else
        '0' when (s1_id_fast = '0') and (cycle = '0') else
        '0' when (s1_id_dsize /= "11") else
        '1' when (s1_id_dop = ID_DOP_W) or ((s1_id_dop = ID_DOP_RMW) and cycle = '1') else
        '0';

    with s1_id_wdata select s1_ls_dw(0) <=
        s1b_rmw                                              when ID_WDATA_RMW, -- RMW
        s2_reg_a                                             when ID_WDATA_A,   -- STA, PHA
        s2_reg_x                                             when ID_WDATA_X,   -- STX
        s2_reg_y                                             when ID_WDATA_Y,   -- STY
        s2_reg_p                                             when ID_WDATA_P,   -- PHP
        s1_reg_pcl2                                          when ID_WDATA_JSR, -- JSR
        s2_reg_p(7 downto 5) & s1_brk & s2_reg_p(3 downto 0) when ID_WDATA_BRK, -- BRK/IRQ/NMI
        x"00"                                                when others;

    with s1_id_wdata select s1_ls_dw(1) <=
        s1_reg_pch2 when ID_WDATA_JSR,  -- JSR
        s1_reg_pcl2 when ID_WDATA_BRK,  -- BRK/IRQ/NMI
        x"00"       when others;

    s1_ls_dw(2) <= s1_reg_pch2 when s1_id_wdata = ID_WDATA_BRK else x"00"; -- INT

    s1_ls_dw(3) <= x"00";

    ext_dw <= s1_ls_dw(0);

    -- adder (ADC/SBC)

    s2_adder_i1 <=
        s2_operand_8     when s2_imm = '1' and s2_id_addsub = ID_ADDSUB_ADD else
        not s2_operand_8 when s2_imm = '1' and s2_id_addsub = ID_ADDSUB_SUB else
        mr               when s2_imm = '0' and s2_id_addsub = ID_ADDSUB_ADD else
        not mr           when s2_imm = '0' and s2_id_addsub = ID_ADDSUB_SUB else
        x"00";

    (s2_adder_bc3, s2_adder_bs(3 downto 0)) <= std_logic_vector(
        unsigned('0' & s2_adder_i0(3 downto 0)) +
        unsigned('0' & s2_adder_i1(3 downto 0)) +
        s2_adder_ci
        );

    s2_adder_dc3 <= '1' when unsigned(s2_adder_bc3 & s2_adder_bs(3 downto 0)) > "01001" else '0';

    s2_adder_hc <= s2_adder_bc3 or (s2_bcd and not s2_id_addsub and s2_adder_dc3);

    s2_adder_ds(3 downto 0) <=
        std_logic_vector(unsigned(s2_adder_bs(3 downto 0)) + "0110") when s2_bcd = '1' and s2_id_addsub = ID_ADDSUB_ADD and s2_adder_dc3 = '1' else
        std_logic_vector(unsigned(s2_adder_bs(3 downto 0)) + "1010") when s2_bcd = '1' and s2_id_addsub = ID_ADDSUB_SUB and s2_adder_bc3 = '0' else
        s2_adder_bs(3 downto 0);

    (s2_adder_bc6,s2_adder_bs(6 downto 4)) <= std_logic_vector(
        unsigned('0' & s2_adder_i0(6 downto 4)) +
        unsigned('0' & s2_adder_i1(6 downto 4)) +
        s2_adder_hc
        );

    (s2_adder_bc7,s2_adder_bs(7)) <= std_logic_vector(
        unsigned'('0' & s2_adder_i0(7)) +
        unsigned'('0' & s2_adder_i1(7)) +
        s2_adder_bc6
        );

    s2_adder_dc7 <= '1' when unsigned(s2_adder_bc7 & s2_adder_bs(7 downto 4)) > "01001" else '0';

    s2_adder_c <= s2_adder_bc7 or (s2_bcd and not s2_id_addsub and s2_adder_dc7);

    s2_adder_ds(7 downto 4) <=
        std_logic_vector(unsigned(s2_adder_bs(7 downto 4)) + "0110") when s2_bcd = '1' and s2_id_addsub = ID_ADDSUB_ADD and s2_adder_dc7 = '1' else
        std_logic_vector(unsigned(s2_adder_bs(7 downto 4)) + "1010") when s2_bcd = '1' and s2_id_addsub = ID_ADDSUB_SUB and s2_adder_bc7 = '0' else
        s2_adder_bs(7 downto 4);

    s2_adder_z <= '1' when s2_adder_bs = x"00" else '0';

    s2_adder_v <= not (((s2_adder_i0(7) nor s2_adder_i1(7)) and s2_adder_bc6) nor ((s2_adder_i0(7) nand s2_adder_i1(7)) nor s2_adder_bc6));

    s2_adder_n <= s2_adder_bs(7);

    s2_adder <= s2_adder_ds;

    -- logic (AND/OR/EOR)

    with s2_sel_logic select s2_logic <=
        s2_reg_a_next and mr           when SEL_LOGIC_AND_M,
        s2_reg_a_next or  mr           when SEL_LOGIC_OR_M,
        s2_reg_a_next xor mr           when SEL_LOGIC_EOR_M,
        s2_reg_a_next and s2_operand_8 when SEL_LOGIC_AND_I,
        s2_reg_a_next or  s2_operand_8 when SEL_LOGIC_OR_I,
        s2_reg_a_next xor s2_operand_8 when SEL_LOGIC_EOR_I,
        x"00"                     when others;

    s2_logic_z <= '1' when s2_logic = x"00" else '0';

    -- bit shifter (ASL/LSR/ROL/ROR)

    with s2_id_shift select s2_shift_a_c <=
        s2_reg_a_next(7) when ID_SHIFT_ASL,
        s2_reg_a_next(0) when ID_SHIFT_LSR,
        s2_reg_a_next(7) when ID_SHIFT_ROL,
        s2_reg_a_next(0) when ID_SHIFT_ROR,
        '0'         when others;

    -- read/modify/write (RMW) modified data

    s1b_rmw <=
        mr(6 downto 0) & '0'               when s1_id_rmw = ID_RMW_SHF and s1_id_shift = ID_SHIFT_ASL  else
        '0' & mr(7 downto 1)               when s1_id_rmw = ID_RMW_SHF and s1_id_shift = ID_SHIFT_LSR  else
        mr(6 downto 0) & s2_flag_c         when s1_id_rmw = ID_RMW_SHF and s1_id_shift = ID_SHIFT_ROL  else
        s2_flag_c & mr(7 downto 1)         when s1_id_rmw = ID_RMW_SHF and s1_id_shift = ID_SHIFT_ROR  else
        std_logic_vector(unsigned(mr) + 1) when s1_id_rmw = ID_RMW_ID and s1_id_incdec = ID_INCDEC_INC else
        std_logic_vector(unsigned(mr) - 1) when s1_id_rmw = ID_RMW_ID and s1_id_incdec = ID_INCDEC_DEC else
        x"00";

    s1b_rmw_z <= '1' when s1b_rmw = x"00" else '0';

    -- register PC (program counter)

    process(clk_x1)
    begin
        if rising_edge(clk_x1) then
            if rst = '1' then
                s1_reg_pc <= vector_init;
            elsif advex = '1' then
                s1_reg_pc <= if_al;
            end if;
        end if;
    end process;

    s1_reg_pc1 <= std_logic_vector(unsigned(s1_reg_pc) + 1);
    s1_reg_pc2 <= std_logic_vector(unsigned(s1_reg_pc) + 2);

    -- register S (stack pointer)

    process(clk_x1)
    begin
        if rising_edge(clk_x1) then
            if advex = '1' then
                if s1_id_reg_s = '1' then -- TXS
                    s2_reg_s <= s2_reg_x;
                    s2_reg_s_add1 <= std_logic_vector(unsigned(s2_reg_x) + 1);
                else
                    s2_reg_s      <= std_logic_vector(unsigned(s2_reg_s) + unsigned(resize(signed(s1_id_sdelta), 8)));
                    s2_reg_s_add1 <= std_logic_vector(unsigned(s2_reg_s) + unsigned(resize(signed(s1_id_sdelta), 8)) + 1);
                end if;
            end if;
        end if;
    end process;

    -- register P (status flags)

    with s2_sel_flag_c select s2_flag_c <=
        s2_adder_c      when SEL_FLAG_C_ADD,
        s2_shift_a_c    when SEL_FLAG_C_SHF_A, -- ASL/LSR/ROL/ROR A
        s2_shift_m_c    when SEL_FLAG_C_SHF_M, -- ASL/LSR/ROL/ROR mem
        s2_flag_c_next  when others;           -- NOP/clr/set/PLP/RTI

    with s2_sel_flag_zn select s2_flag_z <=
        s2_adder_z      when    SEL_FLAG_ZN_ADD,
        s2_rmw_z        when    SEL_FLAG_ZN_RMW,
        s2_reg_a_z      when    SEL_FLAG_ZN_A,
        s2_reg_x_z      when    SEL_FLAG_ZN_X,
        s2_reg_y_z      when    SEL_FLAG_ZN_Y,
        s2_logic_z      when    SEL_FLAG_ZN_BIT,
        s2_flag_z_next  when    others;    -- NOP/PLP/RTI

    s2_flag_i <= s2_flag_if_next;

    s2_flag_d <= s2_flag_d_next;

    s2_flag_b <= '1';

    s2_flag_x <= s2_flag_x_next;

    with s2_sel_flag_v select s2_flag_v <=
        s2_adder_v       when    SEL_FLAG_V_ADD,
        mr(6)            when    SEL_FLAG_V_BIT,
        s2_flag_v_next        when    others;    -- NOP/clr/PLP/RTI

    with s2_sel_flag_zn select s2_flag_n <=
        s2_adder_n      when    SEL_FLAG_ZN_ADD,
        s2_rmw_n        when    SEL_FLAG_ZN_RMW,
        s2_reg_a(7)     when    SEL_FLAG_ZN_A,
        s2_reg_x(7)     when    SEL_FLAG_ZN_X,
        s2_reg_y(7)     when    SEL_FLAG_ZN_Y,
        mr(7)           when     SEL_FLAG_ZN_BIT,
        s2_flag_n_next  when    others;    -- NOP/clr/set/PLP/RTI

    -- register A

    with s2_sel_reg_a select s2_reg_a <=
        mr              when SEL_REG_A_MEM, -- LDA mem
        s2_adder        when SEL_REG_A_ADD, -- ADC/SBC
        s2_logic        when SEL_REG_A_LOG, -- AND/OR/EOR
        s2_shift_a      when SEL_REG_A_SHF, -- ASL/LSR/ROL/ROR A
        s2_reg_a_next   when others;       -- no change/LDA imm/TXA/TYA

    s2_reg_a_z <= '1' when s2_reg_a = x"00" else '0';

    -- register X

    with s2_sel_reg_x select s2_reg_x <=
        mr              when SEL_REG_X_MEM, -- LDX mem
        s2_reg_x_next   when others;       -- no change/LDX imm/TAX/TSX

    s2_reg_x_z <= '1' when s2_reg_x = x"00" else '0';

    -- register Y

    with s2_sel_reg_y select s2_reg_y <=
        mr              when SEL_REG_Y_MEM, -- LDY mem
        s2_reg_y_next   when others;       -- no change/LDY imm/TAY

    s2_reg_y_z <= '1' when s2_reg_y = x"00" else '0';

    -- interrupt vector cacheing
    -- 1 cycle delayed write timing is OK here because this happens
    -- under controlled circumstances (pre-reset code)

    process(clk_x1, advex)
    begin
        if rising_edge(clk_x1) and advex = '1' then
            vector_nmi_en <= (others => '0');
            vector_irq_en <= (others => '0');
            vector_dw <= s1_ls_dw(0);
            vector_we <= s1_ls_we;
            case ls_al is
                when x"FFFA" => vector_nmi_en(0) <= '1';
                when x"FFFB" => vector_nmi_en(1) <= '1';
                when x"FFFE" => vector_irq_en(0) <= '1';
                when x"FFFF" => vector_irq_en(1) <= '1';
                when others => null;
            end case;
            if vector_we = '1' then
                if vector_nmi_en(0) = '1' then
                    vector_nmi(7 downto 0) <= vector_dw;
                end if;
                if vector_nmi_en(1) = '1' then
                    vector_nmi(15 downto 8) <= vector_dw;
                end if;
                if vector_irq_en(0) = '1' then
                    vector_irq(7 downto 0) <= vector_dw;
                end if;
                if vector_irq_en(1) = '1' then
                    vector_irq(15 downto 8) <= vector_dw;
                end if;
            end if;
        end if;
        if rst = '1' then
            vector_nmi <= (others => '0');
            vector_irq <= (others => '0');
        end if;
    end process;

end architecture synth;
