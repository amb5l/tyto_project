#------------------------------------------------------------------------------
# hdmi_tpg.xdc
#------------------------------------------------------------------------------

# clock renaming
create_generated_clock -name sys_clk [get_pins MAIN/SYSTEM_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk_x5 [get_pins MAIN/HDMI_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk [get_pins MAIN/HDMI_CLOCK/MMCM/CLKOUT1]
create_generated_clock -name pcm_clk [get_pins MAIN/TONE/CLOCK/MMCM/CLKOUT0]

# asynchronous groups
set_clock_groups -asynchronous -group {sys_clk} -group {pix_clk pix_clk_x5} -group {pcm_clk}
