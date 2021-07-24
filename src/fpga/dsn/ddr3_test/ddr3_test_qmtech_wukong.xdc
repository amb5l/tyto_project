################################################################################
## ddr3_test_qmtech_wukong.xdc                                                ##
## Board specific constraints for the ddr3_test design.                       ##
################################################################################
## (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        ##
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

# ref clock

create_clock -add -name clki_50m -period 20.00 [get_ports clki_50m]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clki_50m_IBUF}]

#------------------------------------------------------------------------------
# physical constraints

set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS33 }              [get_ports { clki_50m }];           # net SYS_CLK
set_property -dict { PACKAGE_PIN J6 IOSTANDARD LVCMOS33 }               [get_ports { led_n[0] }];           # D5, net LED0
set_property -dict { PACKAGE_PIN H6 IOSTANDARD LVCMOS33 }               [get_ports { led_n[1] }];           # D6, net LED1
set_property -dict { PACKAGE_PIN H7 IOSTANDARD LVCMOS33 }               [get_ports { key_n[0] }];           # SW2, net KEY0
set_property -dict { PACKAGE_PIN J8 IOSTANDARD LVCMOS33 }               [get_ports { key_n[1] }];           # SW3, net KEY1
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 }               [get_ports { ser_tx }];             # net BANK35_E3
# set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 }               [get_ports { ser_rx }];             # net BANK35_F3
# set_property -dict { PACKAGE_PIN D4 IOSTANDARD TMDS_33 }                [get_ports { hdmi_clk_p }];         # net BANK35_D4
# set_property -dict { PACKAGE_PIN C4 IOSTANDARD TMDS_33 }                [get_ports { hdmi_clk_n }];         # net BANK35_C4
# set_property -dict { PACKAGE_PIN E1 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_p[0] }];        # net BANK35_E1
# set_property -dict { PACKAGE_PIN D1 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_n[0] }];        # net BANK35_D1
# set_property -dict { PACKAGE_PIN F2 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_p[1] }];        # net BANK35_F2
# set_property -dict { PACKAGE_PIN E2 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_n[1] }];        # net BANK35_E2
# set_property -dict { PACKAGE_PIN G2 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_p[2] }];        # net BANK35_G2
# set_property -dict { PACKAGE_PIN G1 IOSTANDARD TMDS_33 }                [get_ports { hdmi_d_n[2] }];        # net BANK35_G1
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 PULLUP TRUE }   [get_ports { hdmi_scl }];           # net BANK35_B2
set_property -dict { PACKAGE_PIN A2 IOSTANDARD LVCMOS33 PULLUP TRUE }   [get_ports { hdmi_sda }];           # net BANK35_A2
# set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 }               [get_ports { hdmi_cec }];           # net BANK35_B1
# set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 }               [get_ports { hdmi_hpd }];           # net BANK35_A3
set_property -dict { PACKAGE_PIN R1 IOSTANDARD LVCMOS33 }               [get_ports { eth_rst_n }];          # net BANK34_R1
# set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 }               [get_ports { eth_gtx_clk }];        # net BANK34_U1
# set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txclk }];          # net BANK34_M2
# set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txen }];           # net BANK34_T2
# set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 }               [get_ports { eth_txer }];           # net BANK34_J1
# set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[0] }];         # net BANK34_R2
# set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[1] }];         # net BANK34_P1
# set_property -dict { PACKAGE_PIN N2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[2] }];         # net BANK34_N2
# set_property -dict { PACKAGE_PIN N1 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[3] }];         # net BANK34_N1
# set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[4] }];         # net BANK34_M1
# set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[5] }];         # net BANK34_L2
# set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[6] }];         # net BANK34_K2
# set_property -dict { PACKAGE_PIN K1 IOSTANDARD LVCMOS33 }               [get_ports { eth_txd[7] }];         # net BANK34_K1
# set_property -dict { PACKAGE_PIN P4 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxclk }];          # net BANK34_P4
# set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxdv }];           # net BANK34_L3
# set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxer }];           # net BANK34_U5
# set_property -dict { PACKAGE_PIN M4 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[0] }];         # net BANK34_M4
# set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[1] }];         # net BANK34_N3
# set_property -dict { PACKAGE_PIN N4 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[2] }];         # net BANK34_N4
# set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[3] }];         # net BANK34_P3
# set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[4] }];         # net BANK34_R3
# set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[5] }];         # net BANK34_T3
# set_property -dict { PACKAGE_PIN T4 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[6] }];         # net BANK34_T4
# set_property -dict { PACKAGE_PIN T5 IOSTANDARD LVCMOS33 }               [get_ports { eth_rxd[7] }];         # net BANK34_T5
# set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 }               [get_ports { eth_crs }];            # net BANK34_U2
# set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 }               [get_ports { eth_col }];            # net BANK34_U4
# set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 }               [get_ports { eth_mdc }];            # net BANK34_H2
# set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 }               [get_ports { eth_mdio }];           # net BANK34_H1
# set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS15 }              [get_ports { ddr3_rst_n }];         # net DDR_RESETN
# set_property -dict { PACKAGE_PIN F18}                                   [get_ports { ddr3_clk_p }];         # net DDR_CLK+
# set_property -dict { PACKAGE_PIN F19}                                   [get_ports { ddr3_clk_n }];         # net DDR_CLK-
# set_property -dict { PACKAGE_PIN E18}                                   [get_ports { ddr3_cke }];           # net DDR_CKE
# set_property -dict { PACKAGE_PIN A19}                                   [get_ports { ddr3_ras_n }];         # net DDR_RAS
# set_property -dict { PACKAGE_PIN B19}                                   [get_ports { ddr3_cas_n }];         # net DDR_CAS
# set_property -dict { PACKAGE_PIN A18}                                   [get_ports { ddr3_we_n }];          # net DDR_WE
# set_property -dict { PACKAGE_PIN G19}                                   [get_ports { ddr3_odt }];           # net DDR_ODT
# set_property -dict { PACKAGE_PIN E17}                                   [get_ports { ddr3_a[0] }];          # net DDR_A0
# set_property -dict { PACKAGE_PIN G17}                                   [get_ports { ddr3_a[1] }];          # net DDR_A1
# set_property -dict { PACKAGE_PIN F17}                                   [get_ports { ddr3_a[2] }];          # net DDR_A2
# set_property -dict { PACKAGE_PIN C17}                                   [get_ports { ddr3_a[3] }];          # net DDR_A3
# set_property -dict { PACKAGE_PIN G16}                                   [get_ports { ddr3_a[4] }];          # net DDR_A4
# set_property -dict { PACKAGE_PIN D16}                                   [get_ports { ddr3_a[5] }];          # net DDR_A5
# set_property -dict { PACKAGE_PIN H16}                                   [get_ports { ddr3_a[6] }];          # net DDR_A6
# set_property -dict { PACKAGE_PIN E16}                                   [get_ports { ddr3_a[7] }];          # net DDR_A7
# set_property -dict { PACKAGE_PIN H14}                                   [get_ports { ddr3_a[8] }];          # net DDR_A8
# set_property -dict { PACKAGE_PIN F15}                                   [get_ports { ddr3_a[9] }];          # net DDR_A9
# set_property -dict { PACKAGE_PIN F20}                                   [get_ports { ddr3_a[10] }];         # net DDR_A10
# set_property -dict { PACKAGE_PIN H15}                                   [get_ports { ddr3_a[11] }];         # net DDR_A11
# set_property -dict { PACKAGE_PIN C18}                                   [get_ports { ddr3_a[12] }];         # net DDR_A12
# set_property -dict { PACKAGE_PIN G15}                                   [get_ports { ddr3_a[13] }];         # net DDR_A13
# set_property -dict { PACKAGE_PIN B17}                                   [get_ports { ddr3_ba[0] }];         # net DDR_BA0
# set_property -dict { PACKAGE_PIN D18}                                   [get_ports { ddr3_ba[1] }];         # net DDR_BA1
# set_property -dict { PACKAGE_PIN A17}                                   [get_ports { ddr3_ba[2] }];         # net DDR_BA2
# set_property -dict { PACKAGE_PIN A22}                                   [get_ports { ddr3_dqm[0] }];        # net DDR_DQM0
# set_property -dict { PACKAGE_PIN C22}                                   [get_ports { ddr3_dqm[1] }];        # net DDR_DQM1
# set_property -dict { PACKAGE_PIN D21}                                   [get_ports { ddr3_d[0] }];          # net DDR_D0
# set_property -dict { PACKAGE_PIN C21}                                   [get_ports { ddr3_d[1] }];          # net DDR_D1
# set_property -dict { PACKAGE_PIN B22}                                   [get_ports { ddr3_d[2] }];          # net DDR_D2
# set_property -dict { PACKAGE_PIN B21}                                   [get_ports { ddr3_d[3] }];          # net DDR_D3
# set_property -dict { PACKAGE_PIN D19}                                   [get_ports { ddr3_d[4] }];          # net DDR_D4
# set_property -dict { PACKAGE_PIN E20}                                   [get_ports { ddr3_d[5] }];          # net DDR_D5
# set_property -dict { PACKAGE_PIN C19}                                   [get_ports { ddr3_d[6] }];          # net DDR_D6
# set_property -dict { PACKAGE_PIN D20}                                   [get_ports { ddr3_d[7] }];          # net DDR_D7
# set_property -dict { PACKAGE_PIN C23}                                   [get_ports { ddr3_d[8] }];          # net DDR_D8
# set_property -dict { PACKAGE_PIN D23}                                   [get_ports { ddr3_d[9] }];          # net DDR_D9
# set_property -dict { PACKAGE_PIN B24}                                   [get_ports { ddr3_d[10] }];         # net DDR_D10
# set_property -dict { PACKAGE_PIN B25}                                   [get_ports { ddr3_d[11] }];         # net DDR_D11
# set_property -dict { PACKAGE_PIN C24}                                   [get_ports { ddr3_d[12] }];         # net DDR_D12
# set_property -dict { PACKAGE_PIN C26}                                   [get_ports { ddr3_d[13] }];         # net DDR_D13
# set_property -dict { PACKAGE_PIN A25}                                   [get_ports { ddr3_d[14] }];         # net DDR_D14
# set_property -dict { PACKAGE_PIN B26}                                   [get_ports { ddr3_d[15] }];         # net DDR_D15
# set_property -dict { PACKAGE_PIN B20}                                   [get_ports { ddr3_dqs_p[0] }];      # net DDR_DQS0+
# set_property -dict { PACKAGE_PIN A20}                                   [get_ports { ddr3_dqs_n[0] }];      # net DDR_DQS0-
# set_property -dict { PACKAGE_PIN A23}                                   [get_ports { ddr3_dqs_p[1] }];      # net DDR_DQS1+
# set_property -dict { PACKAGE_PIN A24}                                   [get_ports { ddr3_dqs_n[1] }];      # net DDR_DQS1-
set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS33 }               [get_ports { j10[0] }];             # J10 pin 1, net BANK35_D5
set_property -dict { PACKAGE_PIN G5 IOSTANDARD LVCMOS33 }               [get_ports { j10[1] }];             # J10 pin 2, net BANK35_G5
set_property -dict { PACKAGE_PIN G7 IOSTANDARD LVCMOS33 }               [get_ports { j10[2] }];             # J10 pin 3, net BANK35_G7
set_property -dict { PACKAGE_PIN G8 IOSTANDARD LVCMOS33 }               [get_ports { j10[3] }];             # J10 pin 4, net BANK35_G8
set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 }               [get_ports { j10[4] }];             # J10 pin 7, net BANK35_E5
set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS33 }               [get_ports { j10[5] }];             # J10 pin 9, net BANK35_E6
set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS33 }               [get_ports { j10[6] }];             # J10 pin 9, net BANK35_D6
set_property -dict { PACKAGE_PIN G6 IOSTANDARD LVCMOS33 }               [get_ports { j10[7] }];             # J10 pin 10, net BANK35_G6
# set_property -dict { PACKAGE_PIN H4 IOSTANDARD LVCMOS33 }               [get_ports { j11[0] }];             # J11 pin 1, net BANK35_H4
# set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 }               [get_ports { j11[1] }];             # J11 pin 2, net BANK35_F4
# set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 }               [get_ports { j11[2] }];             # J11 pin 3, net BANK35_A4
# set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 }               [get_ports { j11[3] }];             # J11 pin 4, net BANK35_A5
# set_property -dict { PACKAGE_PIN J4 IOSTANDARD LVCMOS33 }               [get_ports { j11[4] }];             # J11 pin 7, net BANK35_J4
# set_property -dict { PACKAGE_PIN G4 IOSTANDARD LVCMOS33 }               [get_ports { j11[5] }];             # J11 pin 8, net BANK35_G4
# set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 }               [get_ports { j11[6] }];             # J11 pin 9, net BANK35_B4
# set_property -dict { PACKAGE_PIN B5 IOSTANDARD LVCMOS33 }               [get_ports { j11[7] }];             # J11 pin 10, net BANK35_B5
# set_property -dict { PACKAGE_PIN H21 IOSTANDARD LVCMOS33 }              [get_ports { jp2[0] }];             # JP2 pin 3, net BANK15_H21
# set_property -dict { PACKAGE_PIN H22 IOSTANDARD LVCMOS33 }              [get_ports { jp2[1] }];             # JP2 pin 4, net BANK15_H22
# set_property -dict { PACKAGE_PIN K21 IOSTANDARD LVCMOS33 }              [get_ports { jp2[2] }];             # JP2 pin 5, net BANK15_K21
# set_property -dict { PACKAGE_PIN J21 IOSTANDARD LVCMOS33 }              [get_ports { jp2[3] }];             # JP2 pin 6, net BANK15_J21
# set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 }              [get_ports { jp2[4] }];             # JP2 pin 7, net BANK15_H26
# set_property -dict { PACKAGE_PIN G26 IOSTANDARD LVCMOS33 }              [get_ports { jp2[5] }];             # JP2 pin 8, net BANK15_G26
# set_property -dict { PACKAGE_PIN G25 IOSTANDARD LVCMOS33 }              [get_ports { jp2[6] }];             # JP2 pin 9, net BANK15_G25
# set_property -dict { PACKAGE_PIN F25 IOSTANDARD LVCMOS33 }              [get_ports { jp2[7] }];             # JP2 pin 10, net BANK15_F25
# set_property -dict { PACKAGE_PIN G20 IOSTANDARD LVCMOS33 }              [get_ports { jp2[8] }];             # JP2 pin 11, net BANK15_G20
# set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS33 }              [get_ports { jp2[9] }];             # JP2 pin 12, net BANK15_G21
# set_property -dict { PACKAGE_PIN F23 IOSTANDARD LVCMOS33 }              [get_ports { jp2[10] }];            # JP2 pin 13, net BANK15_F23
# set_property -dict { PACKAGE_PIN E23 IOSTANDARD LVCMOS33 }              [get_ports { jp2[11] }];            # JP2 pin 14, net BANK15_E23
# set_property -dict { PACKAGE_PIN E26 IOSTANDARD LVCMOS33 }              [get_ports { jp2[12] }];            # JP2 pin 15, net BANK15_E26
# set_property -dict { PACKAGE_PIN D26 IOSTANDARD LVCMOS33 }              [get_ports { jp2[13] }];            # JP2 pin 16, net BANK15_D26
# set_property -dict { PACKAGE_PIN E25 IOSTANDARD LVCMOS33 }              [get_ports { jp2[14] }];            # JP2 pin 17, net BANK15_E25
# set_property -dict { PACKAGE_PIN D25 IOSTANDARD LVCMOS33 }              [get_ports { jp2[15] }];            # JP2 pin 18, net BANK15_D25
# set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVCMOS33 }             [get_ports { j12[0] }];             # J12 pin 3, net BANK13_AB26
# set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVCMOS33 }             [get_ports { j12[1] }];             # J12 pin 4, net BANK13_AC26
# set_property -dict { PACKAGE_PIN AB24 IOSTANDARD LVCMOS33 }             [get_ports { j12[2] }];             # J12 pin 5, net BANK13_AB24
# set_property -dict { PACKAGE_PIN AC24 IOSTANDARD LVCMOS33 }             [get_ports { j12[3] }];             # J12 pin 6, net BANK13_AC24
# set_property -dict { PACKAGE_PIN AA24 IOSTANDARD LVCMOS33 }             [get_ports { j12[4] }];             # J12 pin 7, net BANK13_AA24
# set_property -dict { PACKAGE_PIN AB25 IOSTANDARD LVCMOS33 }             [get_ports { j12[5] }];             # J12 pin 8, net BANK13_AB25
# set_property -dict { PACKAGE_PIN AA22 IOSTANDARD LVCMOS33 }             [get_ports { j12[6] }];             # J12 pin 9, net BANK13_AA22
# set_property -dict { PACKAGE_PIN AA23 IOSTANDARD LVCMOS33 }             [get_ports { j12[7] }];             # J12 pin 10, net BANK13_AA23
# set_property -dict { PACKAGE_PIN Y25 IOSTANDARD LVCMOS33 }              [get_ports { j12[8] }];             # J12 pin 11, net BANK13_Y25
# set_property -dict { PACKAGE_PIN AA25 IOSTANDARD LVCMOS33 }             [get_ports { j12[9] }];             # J12 pin 12, net BANK13_AA25
# set_property -dict { PACKAGE_PIN W25 IOSTANDARD LVCMOS33 }              [get_ports { j12[10] }];            # J12 pin 13, net BANK13_W25
# set_property -dict { PACKAGE_PIN Y26 IOSTANDARD LVCMOS33 }              [get_ports { j12[11] }];            # J12 pin 14, net BANK13_Y26
# set_property -dict { PACKAGE_PIN Y22 IOSTANDARD LVCMOS33 }              [get_ports { j12[12] }];            # J12 pin 15, net BANK13_Y22
# set_property -dict { PACKAGE_PIN Y23 IOSTANDARD LVCMOS33 }              [get_ports { j12[13] }];            # J12 pin 16, net BANK13_Y23
# set_property -dict { PACKAGE_PIN W21 IOSTANDARD LVCMOS33 }              [get_ports { j12[14] }];            # J12 pin 17, net BANK13_W21
# set_property -dict { PACKAGE_PIN Y21 IOSTANDARD LVCMOS33 }              [get_ports { j12[15] }];            # J12 pin 18, net BANK13_Y21
# set_property -dict { PACKAGE_PIN V26 IOSTANDARD LVCMOS33 }              [get_ports { j12[16] }];            # J12 pin 19, net BANK13_V26
# set_property -dict { PACKAGE_PIN W26 IOSTANDARD LVCMOS33 }              [get_ports { j12[17] }];            # J12 pin 20, net BANK13_W26
# set_property -dict { PACKAGE_PIN U25 IOSTANDARD LVCMOS33 }              [get_ports { j12[18] }];            # J12 pin 21, net BANK13_U25
# set_property -dict { PACKAGE_PIN U26 IOSTANDARD LVCMOS33 }              [get_ports { j12[19] }];            # J12 pin 22, net BANK13_U26
# set_property -dict { PACKAGE_PIN V23 IOSTANDARD LVCMOS33 }              [get_ports { j12[20] }];            # J12 pin 23, net BANK13_V23
# set_property -dict { PACKAGE_PIN W24 IOSTANDARD LVCMOS33 }              [get_ports { j12[21] }];            # J12 pin 24, net BANK13_W24
# set_property -dict { PACKAGE_PIN V24 IOSTANDARD LVCMOS33 }              [get_ports { j12[22] }];            # J12 pin 25, net BANK13_V24
# set_property -dict { PACKAGE_PIN W23 IOSTANDARD LVCMOS33 }              [get_ports { j12[23] }];            # J12 pin 26, net BANK13_W23
# set_property -dict { PACKAGE_PIN V18 IOSTANDARD LVCMOS33 }              [get_ports { j12[24] }];            # J12 pin 27, net BANK13_V18
# set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 }              [get_ports { j12[25] }];            # J12 pin 28, net BANK13_W18
# set_property -dict { PACKAGE_PIN U22 IOSTANDARD LVCMOS33 }              [get_ports { j12[26] }];            # J12 pin 29, net BANK13_U22
# set_property -dict { PACKAGE_PIN V22 IOSTANDARD LVCMOS33 }              [get_ports { j12[27] }];            # J12 pin 30, net BANK13_V22
# set_property -dict { PACKAGE_PIN U21 IOSTANDARD LVCMOS33 }              [get_ports { j12[28] }];            # J12 pin 31, net BANK13_U21
# set_property -dict { PACKAGE_PIN V21 IOSTANDARD LVCMOS33 }              [get_ports { j12[29] }];            # J12 pin 32, net BANK13_V21
# set_property -dict { PACKAGE_PIN T20 IOSTANDARD LVCMOS33 }              [get_ports { j12[30] }];            # J12 pin 33, net BANK13_T20
# set_property -dict { PACKAGE_PIN U20 IOSTANDARD LVCMOS33 }              [get_ports { j12[31] }];            # J12 pin 34, net BANK13_U20
# set_property -dict { PACKAGE_PIN T19 IOSTANDARD LVCMOS33 }              [get_ports { j12[32] }];            # J12 pin 35, net BANK13_T19
# set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 }              [get_ports { j12[33] }];            # J12 pin 36, net BANK13_U19
# set_property -dict { PACKAGE_PIN AA13}                                  [get_ports { mgt_clk_p[0] }];       # net MGT_CLK0_P
# set_property -dict { PACKAGE_PIN AB13}                                  [get_ports { mgt_clk_n[0] }];       # net MGT_CLK0_N
# set_property -dict { PACKAGE_PIN AB11}                                  [get_ports { mgt_clk_p[1] }];       # JP3 pin 14, net MGT_CLK1_P
# set_property -dict { PACKAGE_PIN AA11}                                  [get_ports { mgt_clk_n[1] }];       # JP3 pin 13, net MGT_CLK1_N
# set_property -dict { PACKAGE_PIN AC10}                                  [get_ports { mgt_tx_p[0] }];        # JP3 pin 10, net MGT_TXP0
# set_property -dict { PACKAGE_PIN AD10}                                  [get_ports { mgt_tx_n[0] }];        # JP3 pin 9, net MGT_TXN0
# set_property -dict { PACKAGE_PIN AE9}                                   [get_ports { mgt_tx_p[1] }];        # JP3 pin 8, net MGT_TXP1
# set_property -dict { PACKAGE_PIN AF9}                                   [get_ports { mgt_tx_n[1] }];        # JP3 pin 7, net MGT_TXN1
# set_property -dict { PACKAGE_PIN AC8}                                   [get_ports { mgt_tx_p[2] }];        # JP3 pin 6, net MGT_TXP2
# set_property -dict { PACKAGE_PIN AD8}                                   [get_ports { mgt_tx_n[2] }];        # JP3 pin 5, net MGT_TXN2
# set_property -dict { PACKAGE_PIN AE7}                                   [get_ports { mgt_tx_p[3] }];        # JP3 pin 4, net MGT_TXP3
# set_property -dict { PACKAGE_PIN AF7}                                   [get_ports { mgt_tx_n[3] }];        # JP3 pin 3, net MGT_TXN3
# set_property -dict { PACKAGE_PIN AC12}                                  [get_ports { mgt_rx_p[0] }];        # JP3 pin 24, net MGT_RXP0
# set_property -dict { PACKAGE_PIN AD12}                                  [get_ports { mgt_rx_n[0] }];        # JP3 pin 23, net MGT_RXN0
# set_property -dict { PACKAGE_PIN AE13}                                  [get_ports { mgt_rx_p[1] }];        # JP3 pin 22, net MGT_RXP1
# set_property -dict { PACKAGE_PIN AF13}                                  [get_ports { mgt_rx_n[1] }];        # JP3 pin 21, net MGT_RXN1
# set_property -dict { PACKAGE_PIN AC14}                                  [get_ports { mgt_rx_p[2] }];        # JP3 pin 20, net MGT_RXP2
# set_property -dict { PACKAGE_PIN AD14}                                  [get_ports { mgt_rx_n[2] }];        # JP3 pin 19, net MGT_RXN2
# set_property -dict { PACKAGE_PIN AE11}                                  [get_ports { mgt_rx_p[3] }];        # JP3 pin 18, net MGT_RXP3
# set_property -dict { PACKAGE_PIN AF11}                                  [get_ports { mgt_rx_n[3] }];        # JP3 pin 17, net MGT_RXN3

#------------------------------------------------------------------------------
# misc

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
