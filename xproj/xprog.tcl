set xprog_design [lindex $argv 0]
set xprog_board [lindex $argv 1]
if {$xprog_board == "nexys_video" || $xprog_board == "qmtech_wukong"} {
    open_hw
    connect_hw_server
    current_hw_target [lindex [get_hw_targets] 0]
    open_hw_target
    current_hw_device [lindex [get_hw_devices] 0]
} else {
    error "unsupported board"
}
set_property PROGRAM.FILE "xproj/vivado/${xprog_design}_${xprog_board}/${xprog_design}_${xprog_board}.bit" [current_hw_device]
program_hw_devices [current_hw_device]
exit