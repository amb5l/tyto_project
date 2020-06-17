#------------------------------------------------------------------------------
# mb_display_sd.xdc
#------------------------------------------------------------------------------

# clock renaming
create_generated_clock -name sys_clk [get_pins MAIN/SYSTEM_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk_x5 [get_pins MAIN/DISPLAY/VIDEO_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk [get_pins MAIN/DISPLAY/VIDEO_CLOCK/MMCM/CLKOUT1]

# asynchronous groups
set_clock_groups -name async1 -asynchronous -group {sys_clk} -group {pix_clk}
set_clock_groups -name async2 -asynchronous -group {sys_clk} -group {pix_clk_x5}
