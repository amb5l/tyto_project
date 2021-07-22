library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;

entity ddr3_test is
    port (

        clk_100m    : in   std_logic;
        rst_100m    : in   std_logic;

        led         : out   std_logic_vector(7 downto 0);

        ui_cc       : in    std_logic;
        ui_rdy      : in    std_logic;
        ui_en       : out   std_logic;
        ui_r_w      : out   std_logic;
        ui_a        : out   std_logic_vector(28 downto 4);
        ui_wrdy     : in    std_logic;
        ui_we       : out   std_logic;
        ui_wbe      : out   std_logic_vector(15 downto 0);
        ui_wd       : out   std_logic_vector(127 downto 0);
        ui_rd       : in    std_logic_vector(127 downto 0);
        ui_rstb     : in    std_logic

    );
end entity ddr3_test;

architecture synth of ddr3_test is

    constant TEST_SIZE : std_logic_vector(28 downto 4) := '0' & x"000010";

    type slv_127_0_t is array(natural range <>) of std_logic_vector(127 downto 0);

    constant INIT_SEED : slv_127_0_t := (
            x"0123456789ABCDEF0123456789ABCDEF",
            x"123456789ABCDEF0123456789ABCDEF0",
            x"23456789ABCDEF0123456789ABCDEF01",
            x"3456789ABCDEF0123456789ABCDEF012"
        );
    signal prng_reseed  : std_logic;
    signal prng_seed    : slv_127_0_t(0 to 3);
    signal prng_ok      : std_logic;
    signal prng_en      : std_logic;
    signal prng_d       : std_logic_vector(127 downto 0);
    signal compare      : std_logic_vector(127 downto 0);
    signal count_data   : std_logic_vector(28 downto 4);
    signal count_passes : std_logic_vector(31 downto 0);
    signal count_errors : std_logic_vector(31 downto 0);
    signal errors       : boolean;

    type state_t is (
        INIT,       
        WRITE,
        WRITE_AFTER,
        READ,
        READ_AFTER
    );
    signal state_addr : state_t;
    signal state_data : state_t;

begin

    ui_wbe <= (others => '1');

    process(clk_100m)
    begin

        prng_reseed <= '0'; -- default

        case state_addr is

            when INIT =>
                if ui_cc = '1' and prng_ok = '1' then
                    state_addr <= WRITE;
                    ui_en <= '1';
                    ui_r_w <= '0';
                    ui_a <= (others => '0');
                end if;

            when WRITE =>
                if ui_rdy = '1' then
                    ui_a <= std_logic_vector(unsigned(ui_a)+1);                     
                    if ui_a = std_logic_vector(unsigned(TEST_SIZE)-1) then
                        state_addr <= WRITE_AFTER;
                        ui_en <= '0';
                        ui_a <= (others => '0');
                    end if;
                end if;

            when WRITE_AFTER => -- write data phase may be outstanding here
                if state_data = WRITE_AFTER then
                    state_addr <= READ; 
                    ui_en <= '1';
                    ui_r_w <= '1';                    
                end if;
                
            when READ =>
                if ui_rdy = '1' then
                    ui_a <= std_logic_vector(unsigned(ui_a)+1);                     
                    if ui_a = std_logic_vector(unsigned(TEST_SIZE)-1) then
                        state_addr <= READ_AFTER;
                        ui_en <= '0';
                        ui_r_w <= '0';
                        ui_a <= (others => '0');
                    end if;
                end if;

            when READ_AFTER => -- should definately be some reads outstanding
                if state_data = READ_AFTER then
                    state_addr <= WRITE;
                    ui_en <= '1';
                    ui_r_w <= '0';
                    ui_a <= (others => '0');
                end if;

        end case;

        case state_data is

            when INIT =>
                if ui_en = '1' then
                    state_data <= WRITE;
                    ui_we <= '1';
                    ui_wd <= prng_d;
                end if;

            when WRITE =>
                if ui_wrdy = '1' then
                    ui_wd <= prng_d;
                    count_data <= std_logic_vector(unsigned(count_data)+1);
                    if count_data = std_logic_vector(unsigned(TEST_SIZE)-1) then
                        state_data <= WRITE_AFTER; 
                        ui_we <= '0';
                        ui_wd <= (others => '0');
                        count_data <= (others => '0');
                        prng_reseed <= '1';                        
                    end if;
                end if;
                    
            when WRITE_AFTER =>            
                if ui_en = '1' then
                    state_data <= READ; 
                    ui_en <= '1';
                    ui_r_w <= '1';
                    count_data <= (others => '0');
                    prng_seed(0) <= prng_d;                    
                    prng_seed(1) <= prng_d(123 downto 0) & prng_d(127 downto 124);                    
                    prng_seed(2) <= prng_d(119 downto 0) & prng_d(127 downto 120);                    
                    prng_seed(3) <= prng_d(115 downto 0) & prng_d(127 downto 116);                    
                end if;
                
            when READ =>
                if ui_rstb = '1' then
                    compare <= ui_rd xor prng_d;
                    count_errors <= std_logic_vector(unsigned(count_errors)+1);
                    errors <= true;
                    count_data <= std_logic_vector(unsigned(count_data)+1);
                    if count_data = std_logic_vector(unsigned(TEST_SIZE)-1) then
                        state_data <= READ_AFTER;
                        count_data <= (others => '0');
                    end if;                                        
                end if;

            when READ_AFTER => -- should definately be some reads outstanding
                if not errors then
                    count_passes <= std_logic_vector(unsigned(count_passes)+1);
                end if;
                if ui_en = '1' then
                    state_addr <= WRITE;
                    ui_en <= '1';
                    ui_r_w <= '0';
                    ui_a <= (others => '0');
                    errors <= false;
                end if;

        end case;        

        if rst_100m = '1' then
            state_addr <= INIT; 
            state_data <= INIT; 
            ui_en <= '0';
            ui_r_w <= '0';                    
            ui_a <= (others => '0');
            ui_we <= '0';
            ui_wd <= (others => '0');
            count_data <= (others => '0');         
            prng_seed <= INIT_SEED;
            prng_reseed <= '1';
            errors <= false;
            count_errors <= (others => '0');
            count_passes <= (others => '0');
        end if;
        
    end process;

    prng_en <= (ui_we and ui_wrdy) or ui_rstb;

    GEN_PRNG: for i in 0 to 3 generate
        PRNG: entity xil_defaultlib.rng_xoshiro128plusplus
            generic map (
                init_seed   => INIT_SEED(i),
                pipeline    => true
            )
            port map (
                clk         => clk_100m,
                rst         => rst_100m,
                reseed      => prng_reseed,
                newseed     => prng_seed(i),
                out_ready   => prng_en,
                out_valid   => prng_ok,
                out_data    => prng_d(31+(i*32) downto i*32)
            );
    end generate;

end architecture synth;
