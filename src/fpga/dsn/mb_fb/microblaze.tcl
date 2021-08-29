
################################################################
# This is a generated script based on design: microblaze
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set current_vivado_version [version -short]

if { ([string first 2020.1 $current_vivado_version] == -1) && ([string first 2020.2 $current_vivado_version] == -1) } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source microblaze_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tsbg484-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name microblaze

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: ram
proc create_hier_cell_ram { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_ram() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net cpu_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net cpu_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net cpu_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net cpu_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net cpu_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net cpu_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net cpu_Clk [get_bd_pins Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set axi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.CLK_DOMAIN {microblaze_clk} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $axi

  set gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio ]

  set uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart ]


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {axi} \
   CONFIG.CLK_DOMAIN {microblaze_clk} \
 ] $clk
  set rsti_n [ create_bd_port -dir I -type rst rsti_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $rsti_n
  set rsto [ create_bd_port -dir O -from 0 -to 0 -type rst rsto ]

  # Create instance: cpu, and set properties
  set cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 cpu ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.G_TEMPLATE_LIST {8} \
 ] $cpu

  # Create instance: debug, and set properties
  set debug [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 debug ]
  set_property -dict [ list \
   CONFIG.C_ADDR_SIZE {32} \
   CONFIG.C_M_AXI_ADDR_WIDTH {32} \
   CONFIG.C_USE_UART {0} \
 ] $debug

  # Create instance: gpio, and set properties
  set gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio ]

  # Create instance: interconnect, and set properties
  set interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 interconnect ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.NUM_MI {3} \
 ] $interconnect

  # Create instance: ram
  create_hier_cell_ram [current_bd_instance .] ram

  # Create instance: rstctrl, and set properties
  set rstctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rstctrl ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rstctrl

  # Create instance: uart, and set properties
  set uart [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 uart ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
 ] $uart

  # Create interface connections
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart] [get_bd_intf_pins uart/UART]
  connect_bd_intf_net -intf_net cpu_M_AXI_DP [get_bd_intf_pins cpu/M_AXI_DP] [get_bd_intf_pins interconnect/S00_AXI]
  connect_bd_intf_net -intf_net cpu_debug [get_bd_intf_pins cpu/DEBUG] [get_bd_intf_pins debug/MBDEBUG_0]
  connect_bd_intf_net -intf_net cpu_dlmb_1 [get_bd_intf_pins cpu/DLMB] [get_bd_intf_pins ram/DLMB]
  connect_bd_intf_net -intf_net cpu_ilmb_1 [get_bd_intf_pins cpu/ILMB] [get_bd_intf_pins ram/ILMB]
  connect_bd_intf_net -intf_net gpio_GPIO [get_bd_intf_ports gpio] [get_bd_intf_pins gpio/GPIO]
  connect_bd_intf_net -intf_net interconnect_M00_AXI [get_bd_intf_ports axi] [get_bd_intf_pins interconnect/M00_AXI]
  connect_bd_intf_net -intf_net interconnect_M01_AXI [get_bd_intf_pins interconnect/M01_AXI] [get_bd_intf_pins uart/S_AXI]
  connect_bd_intf_net -intf_net interconnect_M02_AXI [get_bd_intf_pins gpio/S_AXI] [get_bd_intf_pins interconnect/M02_AXI]

  # Create port connections
  connect_bd_net -net cpu_Clk [get_bd_ports clk] [get_bd_pins cpu/Clk] [get_bd_pins gpio/s_axi_aclk] [get_bd_pins interconnect/ACLK] [get_bd_pins interconnect/M00_ACLK] [get_bd_pins interconnect/M01_ACLK] [get_bd_pins interconnect/M02_ACLK] [get_bd_pins interconnect/S00_ACLK] [get_bd_pins ram/Clk] [get_bd_pins rstctrl/slowest_sync_clk] [get_bd_pins uart/s_axi_aclk]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins debug/Debug_SYS_Rst] [get_bd_pins rstctrl/mb_debug_sys_rst]
  connect_bd_net -net reset_rtl_1 [get_bd_ports rsti_n] [get_bd_pins rstctrl/ext_reset_in]
  connect_bd_net -net rst_Clk_100M_bus_struct_reset [get_bd_pins ram/SYS_Rst] [get_bd_pins rstctrl/bus_struct_reset]
  connect_bd_net -net rst_Clk_100M_mb_reset [get_bd_pins cpu/Reset] [get_bd_pins rstctrl/mb_reset]
  connect_bd_net -net rstctrl_peripheral_reset [get_bd_ports rsto] [get_bd_pins rstctrl/peripheral_reset]
  connect_bd_net -net sysrst_interconnect_aresetn [get_bd_pins gpio/s_axi_aresetn] [get_bd_pins interconnect/ARESETN] [get_bd_pins interconnect/M00_ARESETN] [get_bd_pins interconnect/M01_ARESETN] [get_bd_pins interconnect/M02_ARESETN] [get_bd_pins interconnect/S00_ARESETN] [get_bd_pins rstctrl/interconnect_aresetn] [get_bd_pins uart/s_axi_aresetn]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs axi/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs ram/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Instruction] [get_bd_addr_segs ram/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs uart/S_AXI/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.538356",
   "Default View_TopLeft":"-206,160",
   "ExpandedHierarchyInLayout":"",
   "PinnedBlocks":"/cpu|/debug|/interconnect|/ram|/rstctrl|/uart|",
   "PinnedPorts":"rsti_n|rsto|uart|clk|gpio|",
   "guistr":"# # String gsaved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS
#  -string -flagsOSRD
preplace port axi -pg 1 -lvl 5 -x 1670 -y 850 -defaultsOSRD
preplace port uart -pg 1 -lvl 5 -x 1670 -y 960 -defaultsOSRD
preplace port gpio -pg 1 -lvl 5 -x 1670 -y 1130 -defaultsOSRD
preplace port clk -pg 1 -lvl 0 -x 0 -y 670 -defaultsOSRD
preplace port rsti_n -pg 1 -lvl 0 -x 0 -y 690 -defaultsOSRD
preplace portBus rsto -pg 1 -lvl 5 -x 1670 -y 710 -defaultsOSRD
preplace inst cpu -pg 1 -lvl 2 -x 770 -y 450 -defaultsOSRD
preplace inst debug -pg 1 -lvl 1 -x 383 -y 540 -defaultsOSRD
preplace inst interconnect -pg 1 -lvl 3 -x 1213 -y 870 -defaultsOSRD
preplace inst ram -pg 1 -lvl 3 -x 1213 -y 550 -defaultsOSRD
preplace inst rstctrl -pg 1 -lvl 2 -x 770 -y 900 -defaultsOSRD
preplace inst uart -pg 1 -lvl 4 -x 1528 -y 970 -defaultsOSRD
preplace inst gpio -pg 1 -lvl 4 -x 1528 -y 1130 -defaultsOSRD
preplace netloc cpu_Clk 1 0 4 N 670 510 560 1030 1030 1370
preplace netloc mdm_1_debug_sys_rst 1 1 1 500 550n
preplace netloc reset_rtl_1 1 0 2 NJ 690 490
preplace netloc rst_Clk_100M_bus_struct_reset 1 2 1 1020J 580n
preplace netloc rst_Clk_100M_mb_reset 1 1 2 520 540 1000
preplace netloc rstctrl_peripheral_reset 1 2 3 1040J 710 NJ 710 NJ
preplace netloc sysrst_interconnect_aresetn 1 2 2 1050 1040 1380
preplace netloc cpu_dlmb_1 1 2 1 1040 430n
preplace netloc axi_uartlite_0_UART 1 4 1 NJ 960
preplace netloc cpu_debug 1 1 1 500 440n
preplace netloc cpu_ilmb_1 1 2 1 1030 450n
preplace netloc interconnect_M02_AXI 1 3 1 1360 890n
preplace netloc interconnect_M01_AXI 1 3 1 1380 870n
preplace netloc interconnect_M00_AXI 1 3 2 NJ 850 N
preplace netloc gpio_GPIO 1 4 1 N 1130
preplace netloc cpu_M_AXI_DP 1 2 1 1010 470n
levelinfo -pg 1 0 383 770 1213 1528 1670
pagesize -pg 1 -db -bbox -sgen -100 -10 1790 1710
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


