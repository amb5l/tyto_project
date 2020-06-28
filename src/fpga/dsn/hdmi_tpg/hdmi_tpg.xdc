################################################################################
## hdmi_tpg.xdc                                                               ##
## Constraints for the hdmi_tpg design.                                       ##
################################################################################
## (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of The Tyto Project. The Tyto Project is free software:  ##
## you can redistribute it and/or modify it under the terms of the GNU Lesser ##
## General Public License as published by the Free Software Foundation,       ##
## either version 3 of the License, or (at your option) any later version.    ##
## The Tyto Project is distributed in the hope that it will be useful, but    ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Tyto Project. If not, see     ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

# clock renaming
create_generated_clock -name sys_clk [get_pins MAIN/SYSTEM_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk_x5 [get_pins MAIN/HDMI_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk [get_pins MAIN/HDMI_CLOCK/MMCM/CLKOUT1]
create_generated_clock -name pcm_clk [get_pins MAIN/TONE/CLOCK/MMCM/CLKOUT0]

# asynchronous groups
set_clock_groups -asynchronous -group {sys_clk} -group {pix_clk pix_clk_x5} -group {pcm_clk}
