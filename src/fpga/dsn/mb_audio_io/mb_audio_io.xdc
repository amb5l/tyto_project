#------------------------------------------------------------------------------
# demo_audio_io.xdc
#------------------------------------------------------------------------------

# clock renaming
create_generated_clock -name sys_clk [get_pins MAIN/CLOCK_100M/MMCM/CLKOUT0]
create_generated_clock -name pcm_clk [get_pins MAIN/AUDIO_CLOCK/MMCM/CLKOUT0]

# all pcm_clk -> sys_clk clock paths
set_multicycle_path 2 -setup -from [get_clocks pcm_clk] -to [get_clocks sys_clk]
set_multicycle_path 1 -hold -end -from [get_clocks pcm_clk] -to [get_clocks sys_clk]

# all sys_clk -> pcm_clk clock paths
set_multicycle_path 2 -setup -from [get_clocks sys_clk] -to [get_clocks pcm_clk]
set_multicycle_path 1 -hold -end -from [get_clocks sys_clk] -to [get_clocks pcm_clk]