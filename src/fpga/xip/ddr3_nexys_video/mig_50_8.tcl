# script to generate DDR3 IP core
# 100MHz ref clk, 400MHz memory clock (DDR3-800), 128 bit user interface @ 100MHz
# MMCM used to generate IODELAYCTRL ref clk (200MHz)
#  as well as 50MHz and 8MHz user clocks

create_ip -name mig_7series -vendor xilinx.com -library ip -version 4.2 -module_name ddr3
set_property -dict [list CONFIG.XML_INPUT_FILE {../../../../../../../src/fpga/xip/ddr3_nexys_video/mig_a.prj} CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom} CONFIG.SYSTEM_RESET.INSERT_VIP {0} CONFIG.CLK_REF_I.INSERT_VIP {0} CONFIG.RESET.INSERT_VIP {0} CONFIG.DDR3_RESET.INSERT_VIP {0} CONFIG.DDR2_RESET.INSERT_VIP {0} CONFIG.LPDDR2_RESET.INSERT_VIP {0} CONFIG.QDRIIP_RESET.INSERT_VIP {0} CONFIG.RLDII_RESET.INSERT_VIP {0} CONFIG.RLDIII_RESET.INSERT_VIP {0} CONFIG.CLOCK.INSERT_VIP {0} CONFIG.MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S_AXI_CTRL.INSERT_VIP {0} CONFIG.S_AXI.INSERT_VIP {0} CONFIG.SYS_CLK_I.INSERT_VIP {0} CONFIG.ARESETN.INSERT_VIP {0} CONFIG.C0_RESET.INSERT_VIP {0} CONFIG.C0_DDR3_RESET.INSERT_VIP {0} CONFIG.C0_DDR2_RESET.INSERT_VIP {0} CONFIG.C0_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C0_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C0_RLDII_RESET.INSERT_VIP {0} CONFIG.C0_RLDIII_RESET.INSERT_VIP {0} CONFIG.C0_CLOCK.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S0_AXI_CTRL.INSERT_VIP {0} CONFIG.S0_AXI.INSERT_VIP {0} CONFIG.C0_SYS_CLK_I.INSERT_VIP {0} CONFIG.C0_ARESETN.INSERT_VIP {0} CONFIG.C1_RESET.INSERT_VIP {0} CONFIG.C1_DDR3_RESET.INSERT_VIP {0} CONFIG.C1_DDR2_RESET.INSERT_VIP {0} CONFIG.C1_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C1_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C1_RLDII_RESET.INSERT_VIP {0} CONFIG.C1_RLDIII_RESET.INSERT_VIP {0} CONFIG.C1_CLOCK.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S1_AXI_CTRL.INSERT_VIP {0} CONFIG.S1_AXI.INSERT_VIP {0} CONFIG.C1_SYS_CLK_I.INSERT_VIP {0} CONFIG.C1_ARESETN.INSERT_VIP {0} CONFIG.C2_RESET.INSERT_VIP {0} CONFIG.C2_DDR3_RESET.INSERT_VIP {0} CONFIG.C2_DDR2_RESET.INSERT_VIP {0} CONFIG.C2_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C2_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C2_RLDII_RESET.INSERT_VIP {0} CONFIG.C2_RLDIII_RESET.INSERT_VIP {0} CONFIG.C2_CLOCK.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S2_AXI_CTRL.INSERT_VIP {0} CONFIG.S2_AXI.INSERT_VIP {0} CONFIG.C2_SYS_CLK_I.INSERT_VIP {0} CONFIG.C2_ARESETN.INSERT_VIP {0} CONFIG.C3_RESET.INSERT_VIP {0} CONFIG.C3_DDR3_RESET.INSERT_VIP {0} CONFIG.C3_DDR2_RESET.INSERT_VIP {0} CONFIG.C3_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C3_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C3_RLDII_RESET.INSERT_VIP {0} CONFIG.C3_RLDIII_RESET.INSERT_VIP {0} CONFIG.C3_CLOCK.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S3_AXI_CTRL.INSERT_VIP {0} CONFIG.S3_AXI.INSERT_VIP {0} CONFIG.C3_SYS_CLK_I.INSERT_VIP {0} CONFIG.C3_ARESETN.INSERT_VIP {0} CONFIG.C4_RESET.INSERT_VIP {0} CONFIG.C4_DDR3_RESET.INSERT_VIP {0} CONFIG.C4_DDR2_RESET.INSERT_VIP {0} CONFIG.C4_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C4_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C4_RLDII_RESET.INSERT_VIP {0} CONFIG.C4_RLDIII_RESET.INSERT_VIP {0} CONFIG.C4_CLOCK.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S4_AXI_CTRL.INSERT_VIP {0} CONFIG.S4_AXI.INSERT_VIP {0} CONFIG.C4_SYS_CLK_I.INSERT_VIP {0} CONFIG.C4_ARESETN.INSERT_VIP {0} CONFIG.C5_RESET.INSERT_VIP {0} CONFIG.C5_DDR3_RESET.INSERT_VIP {0} CONFIG.C5_DDR2_RESET.INSERT_VIP {0} CONFIG.C5_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C5_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C5_RLDII_RESET.INSERT_VIP {0} CONFIG.C5_RLDIII_RESET.INSERT_VIP {0} CONFIG.C5_CLOCK.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S5_AXI_CTRL.INSERT_VIP {0} CONFIG.S5_AXI.INSERT_VIP {0} CONFIG.C5_SYS_CLK_I.INSERT_VIP {0} CONFIG.C5_ARESETN.INSERT_VIP {0} CONFIG.C6_RESET.INSERT_VIP {0} CONFIG.C6_DDR3_RESET.INSERT_VIP {0} CONFIG.C6_DDR2_RESET.INSERT_VIP {0} CONFIG.C6_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C6_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C6_RLDII_RESET.INSERT_VIP {0} CONFIG.C6_RLDIII_RESET.INSERT_VIP {0} CONFIG.C6_CLOCK.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S6_AXI_CTRL.INSERT_VIP {0} CONFIG.S6_AXI.INSERT_VIP {0} CONFIG.C6_SYS_CLK_I.INSERT_VIP {0} CONFIG.C6_ARESETN.INSERT_VIP {0} CONFIG.C7_RESET.INSERT_VIP {0} CONFIG.C7_DDR3_RESET.INSERT_VIP {0} CONFIG.C7_DDR2_RESET.INSERT_VIP {0} CONFIG.C7_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C7_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C7_RLDII_RESET.INSERT_VIP {0} CONFIG.C7_RLDIII_RESET.INSERT_VIP {0} CONFIG.C7_CLOCK.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S7_AXI_CTRL.INSERT_VIP {0} CONFIG.S7_AXI.INSERT_VIP {0} CONFIG.C7_SYS_CLK_I.INSERT_VIP {0} CONFIG.C7_ARESETN.INSERT_VIP {0}] [get_ips ddr3]
generate_target all [get_files fpga.srcs/sources_1/ip/ddr3/ddr3.xci]

proc hack_ddr3_mig {filename} {
    set f [open $filename "r"]
    set lines [split [read $f] "\n"]
    close $f
    for { set i 0 } { $i < [llength $lines] } { incr i } {
        set line [lindex $lines $i]
        set line [string map [list "REFCLK_TYPE           : string  := \"NO_BUFFER\";" "REFCLK_TYPE           : string  := \"USE_SYSTEM_CLOCK\";"                                  ] $line]
        set line [string map [list "UI_EXTRA_CLOCKS : string := \"FALSE\";"            "UI_EXTRA_CLOCKS : string := \"TRUE\";"                                                     ] $line]
        set line [string map [list "MMCM_CLKOUT0_EN     : string := \"FALSE\";"        "MMCM_CLKOUT0_EN     : string := \"TRUE\";"                                                 ] $line]
        set line [string map [list "MMCM_CLKOUT1_EN     : string := \"FALSE\";"        "MMCM_CLKOUT1_EN     : string := \"TRUE\";"                                                 ] $line]
        set line [string map [list "MMCM_CLKOUT2_EN     : string := \"FALSE\";"        "MMCM_CLKOUT2_EN     : string := \"TRUE\";"                                                 ] $line]
        set line [string map [list "MMCM_CLKOUT0_DIVIDE : integer := 1;"               "MMCM_CLKOUT0_DIVIDE : integer := 4;"                                                       ] $line]
        set line [string map [list "MMCM_CLKOUT1_DIVIDE : integer := 1;"               "MMCM_CLKOUT1_DIVIDE : integer := 16;"                                                      ] $line]
        set line [string map [list "MMCM_CLKOUT2_DIVIDE : integer := 1;"               "MMCM_CLKOUT2_DIVIDE : integer := 100;"                                                     ] $line]
        set line [string map [list "ui_clk               : out   std_logic;"           "ui_clk               : out   std_logic;\r\n\r\n   ui_addn_clk_1        : out   std_logic;" ] $line]
        set line [string map [list "ui_addn_clk_1        : out   std_logic;"           "ui_addn_clk_1        : out   std_logic;\r\n\r\n   ui_addn_clk_2        : out   std_logic;" ] $line]
        set line [string map [list "-- Signal declarations"                            "-- Signal declarations\r\n\r\n  signal ui_addn_clk_0 : std_logic;"                         ] $line]
        set line [string map [list "ui_addn_clk_0    => open,"                         "ui_addn_clk_0    => ui_addn_clk_0,"                                                        ] $line]    
        set line [string map [list "ui_addn_clk_1    => open,"                         "ui_addn_clk_1    => ui_addn_clk_1,"                                                        ] $line]    
        set line [string map [list "ui_addn_clk_2    => open,"                         "ui_addn_clk_2    => ui_addn_clk_2,"                                                        ] $line]    
        set line [string map [list "clk_ref_in <= mmcm_clk;"                           "clk_ref_in <= ui_addn_clk_0;"                                                              ] $line]
        lset lines $i $line
    }
    set f [open $filename "w"]
    foreach line $lines {
        puts $f $line
    }
    close $f    
}

hack_ddr3_mig "fpga.gen/sources_1/ip/ddr3/ddr3/user_design/rtl/ddr3_mig.vhd"
hack_ddr3_mig "fpga.gen/sources_1/ip/ddr3/ddr3/user_design/rtl/ddr3_mig_sim.vhd"

set filename "fpga.gen/sources_1/ip/ddr3/ddr3/user_design/rtl/ddr3.vhd"
set f [open $filename "r"]
set lines [split [read $f] "\n"]
close $f
for { set i 0 } { $i < [llength $lines] } { incr i } {
    set line [lindex $lines $i]
    set line [string map [list "ui_clk                    : out   std_logic;"     "ui_clk                    : out   std_logic;\r\n\r\n      ui_addn_clk_1             : out   std_logic;"   ] $line]
    set line [string map [list "ui_addn_clk_1             : out   std_logic;"     "ui_addn_clk_1             : out   std_logic;\r\n\r\n      ui_addn_clk_2             : out   std_logic;"   ] $line]
    set line [string map [list "ui_clk                         => ui_clk,"        "ui_clk                         => ui_clk,\r\n\r\n       ui_addn_clk_1                  => ui_addn_clk_1," ] $line]
    set line [string map [list "ui_addn_clk_1                  => ui_addn_clk_1," "ui_addn_clk_1                  => ui_addn_clk_1,\r\n\r\n       ui_addn_clk_2                  => ui_addn_clk_2," ] $line]
    lset lines $i $line
}
set f [open $filename "w"]
foreach line $lines {
    puts $f $line
}
close $f
