################################################################################
## hdmi_tpg_nexys_video.xdc                                                   ##
## Board specific constraints for the hdmi_tpg design.                        ##
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

# clock

create_clock -add -name clki_100m -period 10.00 -waveform {0 5} [get_ports clki_100m]

#------------------------------------------------------------------------------
# physical constraints

set_property -dict { PACKAGE_PIN R4 IOSTANDARD LVCMOS33 } [get_ports { clki_100m }];
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS25 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS25 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS25 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS25 } [get_ports { led[3] }];
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS25 } [get_ports { led[4] }];
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS25 } [get_ports { led[5] }];
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS25 } [get_ports { led[6] }];
set_property -dict { PACKAGE_PIN Y13 IOSTANDARD LVCMOS25 } [get_ports { led[7] }];
set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS12 } [get_ports { btn_c }];
set_property -dict { PACKAGE_PIN G4 IOSTANDARD LVCMOS15 } [get_ports { btn_rst_n }];
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS12 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN F21 IOSTANDARD LVCMOS12 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS12 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS12 } [get_ports { sw[3] }];
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS12 } [get_ports { sw[4] }];
set_property -dict { PACKAGE_PIN J16 IOSTANDARD LVCMOS12 } [get_ports { sw[5] }];
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS12 } [get_ports { sw[6] }];
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS12 } [get_ports { sw[7] }];
set_property -dict { PACKAGE_PIN U21 IOSTANDARD LVCMOS33 } [get_ports { oled_res_n }];
set_property -dict { PACKAGE_PIN W22 IOSTANDARD LVCMOS33 } [get_ports { oled_d_c }];
set_property -dict { PACKAGE_PIN W21 IOSTANDARD LVCMOS33 } [get_ports { oled_sclk }];
set_property -dict { PACKAGE_PIN Y22 IOSTANDARD LVCMOS33 } [get_ports { oled_sdin }];
set_property -dict { PACKAGE_PIN T1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_clk_p }];
set_property -dict { PACKAGE_PIN U1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_clk_n }];
set_property -dict { PACKAGE_PIN W1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_p[0] }];
set_property -dict { PACKAGE_PIN Y1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_n[0] }];
set_property -dict { PACKAGE_PIN AA1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_p[1] }];
set_property -dict { PACKAGE_PIN AB1 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_n[1] }];
set_property -dict { PACKAGE_PIN AB3 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_p[2] }];
set_property -dict { PACKAGE_PIN AB2 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_ch_n[2] }];
set_property -dict { PACKAGE_PIN U6 IOSTANDARD LVCMOS33 } [get_ports { ac_mclk }];
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { ac_dac_sdata }];
set_property -dict { PACKAGE_PIN AA19 IOSTANDARD LVCMOS33 } [get_ports { uart_rx_out }];
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { eth_rst_n }];
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports { ftdi_rd_n }];
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports { ftdi_wr_n }];
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports { ftdi_siwu_n }];
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { ftdi_oe_n }];
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { ps2_clk }];
set_property -dict { PACKAGE_PIN N13 IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { ps2_data }];
set_property -dict { PACKAGE_PIN T19 IOSTANDARD LVCMOS33 } [get_ports { qspi_cs_n }];

# unused IOs in this design
# set_property -dict { PACKAGE_PIN E6 } [get_ports { gtp_clk_n }];
# set_property -dict { PACKAGE_PIN F6 } [get_ports { gtp_clk_p }];
# set_property -dict { PACKAGE_PIN E10 } [get_ports { fmc_mgt_clk_n }];
# set_property -dict { PACKAGE_PIN F10 } [get_ports { fmc_mgt_clk_p }];
# set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { btn_d }];
# set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS12 } [get_ports { btn_l }];
# set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS12 } [get_ports { btn_r }];
# set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { btn_u }];
# set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS33 } [get_ports { oled_vbat_dis }];
# set_property -dict { PACKAGE_PIN V22 IOSTANDARD LVCMOS33 } [get_ports { oled_vdd_dis }];
# set_property -dict { PACKAGE_PIN V4 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_clk_p }];
# set_property -dict { PACKAGE_PIN W4 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_clk_n }];
# set_property -dict { PACKAGE_PIN Y3 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_p[0] }];
# set_property -dict { PACKAGE_PIN AA3 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_n[0] }];
# set_property -dict { PACKAGE_PIN W2 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_p[1] }];
# set_property -dict { PACKAGE_PIN Y2 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_n[1] }];
# set_property -dict { PACKAGE_PIN U2 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_p[2] }];
# set_property -dict { PACKAGE_PIN V2 IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_ch_n[2] }];
# set_property -dict { PACKAGE_PIN Y4 IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_scl }];
# set_property -dict { PACKAGE_PIN AB5 IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_sda }];
# set_property -dict { PACKAGE_PIN AA5 IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }];
# set_property -dict { PACKAGE_PIN AB12 IOSTANDARD LVCMOS25 } [get_ports { hdmi_rx_hpd }];
# set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_txen }];
# set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_scl }];
# set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_sda }];
# set_property -dict { PACKAGE_PIN AA4 IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }];
# set_property -dict { PACKAGE_PIN AB13 IOSTANDARD LVCMOS25 } [get_ports { hdmi_tx_hpd }];
# set_property -dict { PACKAGE_PIN B4 } [get_ports { dp_tx_p[0] }];
# set_property -dict { PACKAGE_PIN A4 } [get_ports { dp_tx_n[0] }];
# set_property -dict { PACKAGE_PIN D5 } [get_ports { dp_tx_p[1] }];
# set_property -dict { PACKAGE_PIN C5 } [get_ports { dp_tx_n[1] }];
# set_property -dict { PACKAGE_PIN AA9 IOSTANDARD TMDS_33 } [get_ports { dp_tx_aux_p }];
# set_property -dict { PACKAGE_PIN AB10 IOSTANDARD TMDS_33 } [get_ports { dp_tx_aux_n }];
# set_property -dict { PACKAGE_PIN AA10 IOSTANDARD TMDS_33 } [get_ports { dp_tx_aux_p }];
# set_property -dict { PACKAGE_PIN AA11 IOSTANDARD TMDS_33 } [get_ports { dp_tx_aux_n }];
# set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports { dp_tx_hpd }];
# set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports { ac_lrclk }];
# set_property -dict { PACKAGE_PIN T5 IOSTANDARD LVCMOS33 } [get_ports { ac_bclk }];
# set_property -dict { PACKAGE_PIN T4 IOSTANDARD LVCMOS33 } [get_ports { ac_adc_sdata }];
# set_property -dict { PACKAGE_PIN AB22 IOSTANDARD LVCMOS33 } [get_ports { ja[0] }];
# set_property -dict { PACKAGE_PIN AB21 IOSTANDARD LVCMOS33 } [get_ports { ja[1] }];
# set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS33 } [get_ports { ja[2] }];
# set_property -dict { PACKAGE_PIN AB18 IOSTANDARD LVCMOS33 } [get_ports { ja[3] }];
# set_property -dict { PACKAGE_PIN Y21 IOSTANDARD LVCMOS33 } [get_ports { ja[4] }];
# set_property -dict { PACKAGE_PIN AA21 IOSTANDARD LVCMOS33 } [get_ports { ja[5] }];
# set_property -dict { PACKAGE_PIN AA20 IOSTANDARD LVCMOS33 } [get_ports { ja[6] }];
# set_property -dict { PACKAGE_PIN AA18 IOSTANDARD LVCMOS33 } [get_ports { ja[7] }];
# set_property -dict { PACKAGE_PIN V9 IOSTANDARD LVCMOS33 } [get_ports { jb[0] }];
# set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { jb[1] }];
# set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports { jb[2] }];
# set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { jb[3] }];
# set_property -dict { PACKAGE_PIN W9 IOSTANDARD LVCMOS33 } [get_ports { jb[4] }];
# set_property -dict { PACKAGE_PIN Y9 IOSTANDARD LVCMOS33 } [get_ports { jb[5] }];
# set_property -dict { PACKAGE_PIN Y8 IOSTANDARD LVCMOS33 } [get_ports { jb[6] }];
# set_property -dict { PACKAGE_PIN Y7 IOSTANDARD LVCMOS33 } [get_ports { jb[7] }];
# set_property -dict { PACKAGE_PIN Y6 IOSTANDARD LVCMOS33 } [get_ports { jc[0] }];
# set_property -dict { PACKAGE_PIN AA6 IOSTANDARD LVCMOS33 } [get_ports { jc[1] }];
# set_property -dict { PACKAGE_PIN AA8 IOSTANDARD LVCMOS33 } [get_ports { jc[2] }];
# set_property -dict { PACKAGE_PIN AB8 IOSTANDARD LVCMOS33 } [get_ports { jc[3] }];
# set_property -dict { PACKAGE_PIN R6 IOSTANDARD LVCMOS33 } [get_ports { jc[4] }];
# set_property -dict { PACKAGE_PIN T6 IOSTANDARD LVCMOS33 } [get_ports { jc[5] }];
# set_property -dict { PACKAGE_PIN AB7 IOSTANDARD LVCMOS33 } [get_ports { jc[6] }];
# set_property -dict { PACKAGE_PIN AB6 IOSTANDARD LVCMOS33 } [get_ports { jc[7] }];
# set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS12 } [get_ports { xa_p[0] }];
# set_property -dict { PACKAGE_PIN H14 IOSTANDARD LVCMOS12 } [get_ports { xa_n[0] }];
# set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS12 } [get_ports { xa_p[1] }];
# set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS12 } [get_ports { xa_n[1] }];
# set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS12 } [get_ports { xa_p[2] }];
# set_property -dict { PACKAGE_PIN G16 IOSTANDARD LVCMOS12 } [get_ports { xa_n[2] }];
# set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS12 } [get_ports { xa_p[3] }];
# set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS12 } [get_ports { xa_n[3] }];
# set_property -dict { PACKAGE_PIN V18 IOSTANDARD LVCMOS33 } [get_ports { uart_tx_in }];
# set_property -dict { PACKAGE_PIN AA14 IOSTANDARD LVCMOS25 } [get_ports { eth_txck }];
# set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS25 } [get_ports { eth_txctl }];
# set_property -dict { PACKAGE_PIN Y12 IOSTANDARD LVCMOS25 } [get_ports { eth_txd[0] }];
# set_property -dict { PACKAGE_PIN W12 IOSTANDARD LVCMOS25 } [get_ports { eth_txd[1] }];
# set_property -dict { PACKAGE_PIN W11 IOSTANDARD LVCMOS25 } [get_ports { eth_txd[2] }];
# set_property -dict { PACKAGE_PIN Y11 IOSTANDARD LVCMOS25 } [get_ports { eth_txd[3] }];
# set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS25 } [get_ports { eth_rxck }];
# set_property -dict { PACKAGE_PIN W10 IOSTANDARD LVCMOS25 } [get_ports { eth_rxctl }];
# set_property -dict { PACKAGE_PIN AB16 IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[0] }];
# set_property -dict { PACKAGE_PIN AA15 IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[1] }];
# set_property -dict { PACKAGE_PIN AB15 IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[2] }];
# set_property -dict { PACKAGE_PIN AB11 IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[3] }];
# set_property -dict { PACKAGE_PIN AA16 IOSTANDARD LVCMOS25 } [get_ports { eth_mdc }];
# set_property -dict { PACKAGE_PIN Y16 IOSTANDARD LVCMOS25 } [get_ports { eth_mdio }];
# set_property -dict { PACKAGE_PIN Y14 IOSTANDARD LVCMOS25 } [get_ports { eth_int_n }];
# set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS25 } [get_ports { eth_pme_n }];
# set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS25 } [get_ports { fan_pwm }];
# set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports { ftdi_clko }];
# set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { ftdi_rxf_n }];
# set_property -dict { PACKAGE_PIN Y19 IOSTANDARD LVCMOS33 } [get_ports { ftdi_txe_n }];
# set_property -dict { PACKAGE_PIN U20 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[0] }];
# set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[1] }];
# set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[2] }];
# set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[3] }];
# set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[4] }];
# set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[5] }];
# set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[6] }];
# set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { ftdi_d[7] }];
# set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { ftdi_spien }];
# set_property -dict { PACKAGE_PIN P22 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }];
# set_property -dict { PACKAGE_PIN R22 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }];
# set_property -dict { PACKAGE_PIN P21 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }];
# set_property -dict { PACKAGE_PIN R21 IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }];
# set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports { sd_cclk }];
# set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { sd_cd }];
# set_property -dict { PACKAGE_PIN W20 IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }];
# set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { sd_d[0] }];
# set_property -dict { PACKAGE_PIN T21 IOSTANDARD LVCMOS33 } [get_ports { sd_d[1] }];
# set_property -dict { PACKAGE_PIN T20 IOSTANDARD LVCMOS33 } [get_ports { sd_d[2] }];
# set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { sd_d[3] }];
# set_property -dict { PACKAGE_PIN V20 IOSTANDARD LVCMOS33 } [get_ports { sd_reset }];
# set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { i2c_scl }];
# set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { i2c_sda }];
# set_property -dict { PACKAGE_PIN AA13 IOSTANDARD LVCMOS25 } [get_ports { set_vadj[0] }];
# set_property -dict { PACKAGE_PIN AB17 IOSTANDARD LVCMOS25 } [get_ports { set_vadj[1] }];
# set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS25 } [get_ports { vadj_en }];
# set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS12 } [get_ports { fmc_clk0_m2c_n }];
# set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS12 } [get_ports { fmc_clk0_m2c_p }];
# set_property -dict { PACKAGE_PIN C19 IOSTANDARD LVCMOS12 } [get_ports { fmc_clk1_m2c_n }];
# set_property -dict { PACKAGE_PIN C18 IOSTANDARD LVCMOS12 } [get_ports { fmc_clk1_m2c_p }];
# set_property -dict { PACKAGE_PIN K19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[0] }];
# set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[0] }];
# set_property -dict { PACKAGE_PIN J21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[1] }];
# set_property -dict { PACKAGE_PIN J20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[1] }];
# set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[2] }];
# set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[2] }];
# set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[3] }];
# set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[3] }];
# set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[4] }];
# set_property -dict { PACKAGE_PIN N20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[4] }];
# set_property -dict { PACKAGE_PIN L21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[5] }];
# set_property -dict { PACKAGE_PIN M21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[5] }];
# set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[6] }];
# set_property -dict { PACKAGE_PIN N22 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[6] }];
# set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[7] }];
# set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[7] }];
# set_property -dict { PACKAGE_PIN M16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[8] }];
# set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[8] }];
# set_property -dict { PACKAGE_PIN G20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[9] }];
# set_property -dict { PACKAGE_PIN H20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[9] }];
# set_property -dict { PACKAGE_PIN K22 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[10] }];
# set_property -dict { PACKAGE_PIN K21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[10] }];
# set_property -dict { PACKAGE_PIN L15 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[11] }];
# set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[11] }];
# set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[12] }];
# set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[12] }];
# set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[13] }];
# set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[13] }];
# set_property -dict { PACKAGE_PIN H22 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[14] }];
# set_property -dict { PACKAGE_PIN J22 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[14] }];
# set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[15] }];
# set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[15] }];
# set_property -dict { PACKAGE_PIN G18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[16] }];
# set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[16] }];
# set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[17] }];
# set_property -dict { PACKAGE_PIN B17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[17] }];
# set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[18] }];
# set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[18] }];
# set_property -dict { PACKAGE_PIN A19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[19] }];
# set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[19] }];
# set_property -dict { PACKAGE_PIN F20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[20] }];
# set_property -dict { PACKAGE_PIN F19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[20] }];
# set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[21] }];
# set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[21] }];
# set_property -dict { PACKAGE_PIN D21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[22] }];
# set_property -dict { PACKAGE_PIN E21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[22] }];
# set_property -dict { PACKAGE_PIN A21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[23] }];
# set_property -dict { PACKAGE_PIN B21 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[23] }];
# set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[24] }];
# set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[24] }];
# set_property -dict { PACKAGE_PIN E17 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[25] }];
# set_property -dict { PACKAGE_PIN F16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[25] }];
# set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[26] }];
# set_property -dict { PACKAGE_PIN F18 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[26] }];
# set_property -dict { PACKAGE_PIN A20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[27] }];
# set_property -dict { PACKAGE_PIN B20 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[27] }];
# set_property -dict { PACKAGE_PIN B13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[28] }];
# set_property -dict { PACKAGE_PIN C13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[28] }];
# set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[29] }];
# set_property -dict { PACKAGE_PIN C14 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[29] }];
# set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[30] }];
# set_property -dict { PACKAGE_PIN A13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[30] }];
# set_property -dict { PACKAGE_PIN E14 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[31] }];
# set_property -dict { PACKAGE_PIN E13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[31] }];
# set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[32] }];
# set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[32] }];
# set_property -dict { PACKAGE_PIN F14 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[33] }];
# set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[33] }];

#------------------------------------------------------------------------------
# misc

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
