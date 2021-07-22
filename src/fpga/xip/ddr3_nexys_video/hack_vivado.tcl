# hack IP generated wrapper file to use DDR3 MMCM to generate additional clocks:
# 200MHz ref clk for IODELAY, 50MHz and 8MHz for user

set filename "fpga.gen/sources_1/ip/ddr3/ddr3/user_design/rtl/ddr3_mig.vhd"
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
    set line [string map [list "-- Signal declarations"                            "-- Signal declarations\r\n\r\n  signal iodelay_rst   : std_logic;"                         ] $line]
    set line [string map [list "signal iodelay_rst   : std_logic;"                 "signal iodelay_rst   : std_logic;\r\n\r\n  signal mmcm_locked   : std_logic;"                ] $line]
    set line [string map [list "signal mmcm_locked   : std_logic;"                 "signal mmcm_locked   : std_logic;\r\n\r\n  signal ui_addn_clk_0 : std_logic;"              ] $line]
    set line [string map [list "ui_clk <= clk;"                                    "iodelay_rst <= sys_rst or not mmcm_locked;\r\n\r\n  ui_clk <= clk;"                        ] $line]    
    set line [string map [list "sys_rst          => sys_rst_o"                     "sys_rst          => temp"                                                                  ] $line]    
    set line [string map [list "sys_rst          => sys_rst"                       "sys_rst          => iodelay_rst"                                                           ] $line]    
    set line [string map [list "sys_rst          => temp"                          "sys_rst          => sys_rst_o"                                                             ] $line]    
    set line [string map [list "ui_addn_clk_0    => open,"                         "ui_addn_clk_0    => ui_addn_clk_0,"                                                        ] $line]    
    set line [string map [list "ui_addn_clk_1    => open,"                         "ui_addn_clk_1    => ui_addn_clk_1,"                                                        ] $line]    
    set line [string map [list "ui_addn_clk_2    => open,"                         "ui_addn_clk_2    => ui_addn_clk_2,"                                                        ] $line]    
    set line [string map [list "mmcm_locked      => open,"                         "mmcm_locked      => mmcm_locked,"                                                          ] $line]
    set line [string map [list "clk_ref_in <= mmcm_clk;"                           "clk_ref_in <= ui_addn_clk_0;"                                                              ] $line]
    lset lines $i $line
}
set f [open $filename "w"]
foreach line $lines {
    puts $f $line
}
close $f

set filename "fpga.gen/sources_1/ip/ddr3/ddr3/user_design/rtl/ddr3_mig_sim.vhd"
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
    set line [string map [list "-- Signal declarations"                            "-- Signal declarations\r\n\r\n  signal iodelay_rst   : std_logic;"                         ] $line]
    set line [string map [list "signal iodelay_rst   : std_logic;"                 "signal iodelay_rst   : std_logic;\r\n\r\n  signal mmcm_locked   : std_logic;"                ] $line]
    set line [string map [list "signal mmcm_locked   : std_logic;"                 "signal mmcm_locked   : std_logic;\r\n\r\n  signal ui_addn_clk_0 : std_logic;"              ] $line]
    set line [string map [list "ui_clk <= clk;"                                    "iodelay_rst <= sys_rst or not mmcm_locked;\r\n\r\n  ui_clk <= clk;"                        ] $line]    
    set line [string map [list "sys_rst          => sys_rst_o"                     "sys_rst          => temp"                                                                  ] $line]    
    set line [string map [list "sys_rst          => sys_rst"                       "sys_rst          => iodelay_rst"                                                           ] $line]    
    set line [string map [list "sys_rst          => temp"                          "sys_rst          => sys_rst_o"                                                             ] $line]    
    set line [string map [list "ui_addn_clk_0    => open,"                         "ui_addn_clk_0    => ui_addn_clk_0,"                                                        ] $line]    
    set line [string map [list "ui_addn_clk_1    => open,"                         "ui_addn_clk_1    => ui_addn_clk_1,"                                                        ] $line]    
    set line [string map [list "ui_addn_clk_2    => open,"                         "ui_addn_clk_2    => ui_addn_clk_2,"                                                        ] $line]    
    set line [string map [list "mmcm_locked      => open,"                         "mmcm_locked      => mmcm_locked,"                                                          ] $line]
    set line [string map [list "clk_ref_in <= mmcm_clk;"                           "clk_ref_in <= ui_addn_clk_0;"                                                              ] $line]
    lset lines $i $line
}
set f [open $filename "w"]
foreach line $lines {
    puts $f $line
}
close $f

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
