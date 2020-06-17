/*******************************************************************************
** adau1761_p.h                                                               **
** Simple driver for ADAU1761 audio codec.                                    **
********************************************************************************
** (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        **
** This file is part of The Tyto Project. The Tyto Project is free software:  **
** you can redistribute it and/or modify it under the terms of the GNU Lesser **
** General Public License as published by the Free Software Foundation,       **
** either version 3 of the License, or (at your option) any later version.    **
** The Tyto Project is distributed in the hope that it will be useful, but    **
** WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY **
** or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     **
** License for more details. You should have received a copy of the GNU       **
** Lesser General Public License along with The Tyto Project. If not, see     **
** https://www.gnu.org/licenses/.                                             **
*******************************************************************************/

#ifndef _ADAU1761_P_H_
#define _ADAU1761_P_H_

#define SLAVE_ADDR 0b0111011

#define R_BASE        0x4000

#define R0_CLKCTRL    0x00 // Clock control                       rsvd,CLKSRC,INFREQ[1:0],COREN                    00000000
#define R1_PLL        0x02 // PLL control                         M[15:8]                                          00000000
                           //                                     M[7:0]                                           11111101
                           //                                     N[15:8]                                          00000000
                           //                                     N[7:0]                                           00001100
                           //                                     rsvd,R[3:0],X[1:0],Type                          00010000
                           //                                     rsvd,Lock,PLLEN                                  00000000
#define R2_MICJACK    0x08 // Dig mic/jack detect                 JDDB[1:0],JDFUNC[1:0],rsvd,JDPOL                 00000000
#define R3_REC        0x09 // Rec power mgmt                      rsvd,MXBIAS[1:0],ADCBIAS[1:0],RBIAS[1:0],rsvd    00000000
#define R4_RECMXL0    0x0A // Rec Mixer Left 0                    rsvd,LINPG[2:0],LINNG[2:0],MX1EN                 00000000
#define R5_RECMXL1    0x0B // Rec Mixer Left 1                    rsvd,LDBOOST[1:0],MX1AUXG[2:0]                   00000000
#define R6_RECMXR0    0x0C // Rec Mixer Right 0                   rsvd,RINPG[2:0],RINNG[2:0],MX2EN                 00000000
#define R7_RECMXR1    0x0D // Rec Mixer Right 1                   rsvd,RDBOOST[1:0],MX2AUXG[2:0]                   00000000
#define R8_LDVOL      0x0E // Left diff input vol                 LDVOL[5:0],LDMUTE,LDEN                           00000000
#define R9_RDVOL      0x0F // Right diff input vol                RDVOL[5:0],RDMUTE,RDEN                           00000000
#define R10_RECMIC    0x10 // Record mic bias                     rsvd,MPERF,MBI,rsvd,MBIEN                        00000000
#define R11_ALC0      0x11 // ALC 0                               PGASLEW[1:0],ALCMAX[2:0],ALCSEL[2:0]             00000000
#define R12_ALC1      0x12 // ALC 1                               ALCHOLD[3:0],ALCTARG[3:0]                        00000000
#define R13_ALC2      0x13 // ALC 2                               ALCATCK[3:0],ALCDEC[3:0]                         00000000
#define R14_ALC3      0x14 // ALC 3                               NGTYP[1:0],NGEN,NGTHR[4:0]                       00000000
#define R15_SP0       0x15 // Serial Port 0                       rsvd,SPSRS,LRMOD,BPOL,LRPOL,CHPF[1:0],MS         00000000
#define R16_SP1       0x16 // Serial Port 1                       BPF[2:0],ADTDM,DATDM,MSBP,LRDEL[1:0]             00000000
#define R17_CONV0     0x17 // Converter 0                         rsvd,DAPAIR[1:0],DAOSR,ADOSR,CONVSR[2:0]         00000000
#define R18_CONV1     0x18 // Converter 1                         rsvd,ADPAIR[1:0],                                00000000
#define R19_ADCCTRL   0x19 // ADC control                         rsvd,ADCPOL,HPF,DMPOL,DMSW,INSEL,ADCEN[1:0]      00010000
#define R20_LADVOL    0x1A // Left digital vol                    LADVOL[7:0]                                      00000000
#define R21_RADVOL    0x1B // Right digital vol                   RADVOL[7:0]                                      00000000
#define R22_PLAYMXL0  0x1C // Play Mixer Left 0                   rsvd,MX3RM,MX3LM,MX3AUXG[3:0],MX3EN              00000000
#define R23_PLAYMXL1  0x1D // Play Mixer Left 1                   MX3G2[3:0],MX3G1[3:0]                            00000000
#define R24_PLAYMXR0  0x1E // Play Mixer Right 0                  rsvd,MX4RM,MX4LM,MX4AUXG[3:0],MX4EN              00000000
#define R25_PLAYMXR1  0x1F // Play Mixer Right 1                  MX4G2[3:0],MX4G1[3:0]                            00000000
#define R26_PLAYLRMXL 0x20 // Play L/R mixer left                 rsvd,MX5G4[1:0],MX5G3[1:0],MX5EN                 00000000
#define R27_PLAYLRMXR 0x21 // Play L/R mixer right                rsvd,MX6G4[1:0],MX6G3[1:0],MX6EN                 00000000
#define R28_PLAYLRMXM 0x22 // Play L/R mixer mono                 rsvd,MX7[1:0],MX7EN                              00000000
#define R29_PLAYHLVOL 0x23 // Play HP left vol                    LHPVOL[5:0],LHPM,HPEN                            00000010
#define R30_PLAYHRVOL 0x24 // Play HP right vol                   RHPVOL[5:0],RHPM,HPMODE                          00000010
#define R31_LOLVOL    0x25 // Line output left vol                LOUTVOL[5:0],LOUTM,LOMODE                        00000010
#define R32_LORVOL    0x26 // Line output right vol               ROUTVOL[5:0],ROUTM,ROMODE                        00000010
#define R33_PLAYMO    0x27 // Play mono output                    MONOVOL[5:0],MONOM,MOMODE                        00000010
#define R34_POP       0x28 // Pop/click suppress                  rsvd,POPMODE,POPLESS,ASLEW[1:0],rsvd             00000000
#define R35_PLAYPWR   0x29 // Play power mgmt                     HPBIAS[1:0],DACBIAS[1:0],PBIAS[1:0],PREN,PLEN    00000000
#define R36_DACCTRL0  0x2A // DAC Control 0                       DACMONO[1:0],DACPOL,rsvd,DEMPH,DACEN[1:0]        00000000
#define R37_DACCTRL1  0x2B // DAC Control 1                       LDAVOL[7:0]                                      00000000
#define R38_DACCTRL2  0x2C // DAC Control 2                       RDAVOL[7:0]                                      00000000
#define R39_SERPAD    0x2D // Serial port pad                     ADCSDP[1:0],DACSDP[1:0],LRCLKP[1:0],BCLKP[1:0]   10101010
#define R40_CTRLPAD0  0x2F // Control Port Pad 0                  CDATP[1:0],CLCHP[1:0],SCLP[1:0],SDAP[1:0]        10101010
#define R41_CTRLPAD1  0x30 // Control Port Pad 1                  rsvd,SDASTR                                      00000000
#define R42_JACKPIN   0x31 // Jack detect pin                     rsvd,JDSTR,rsvd,JDP[1:0],rsvd                    00001000
#define R67_DEJITTER  0x36 // Dejitter control                    DEJIT[7:0]                                       00000011
#define R43_CRC3      0xC0 // Cyclic redundancy check             CRC[31:24]                                       00000000
#define R44_CRC2      0xC1 // Cyclic redundancy check             CRC[23:16]                                       00000000
#define R45_CRC1      0xC2 // Cyclic redundancy check             CRC[15:8]                                        00000000
#define R46_CRC0      0xC3 // Cyclic redundancy check             CRC[7:0]                                         00000000
#define R47_CRCEN     0xC4 // CRC enable                          rsvd,CRCEN                                       00000000
#define R48_GPIO0     0xC6 // GPIO0 pin control                   rsvd,GPIO0[3:0]                                  00000000
#define R49_GPIO1     0xC7 // GPIO1 pin control                   rsvd,GPIO1[3:0]                                  00000000
#define R50_GPIO2     0xC8 // GPIO2 pin control                   rsvd,GPIO2[3:0]                                  00000000
#define R51_GPIO3     0xC9 // GPIO3 pin control                   rsvd,GPIO3[3:0]                                  00000000
#define R52_DOGEN     0xD0 // Watchdog enable                     rsvd,DOGEN                                       00000000
#define R53_DOGVAL2   0xD1 // Watchdog value                      DOG[23:16]                                       00000000
#define R54_DOGVAL1   0xD2 // Watchdog value                      DOG[15:8]                                        00000000
#define R55_DOGVAL0   0xD3 // Watchdog value                      DOG[7:0]                                         00000000
#define R56_DOGERR    0xD4 // Watchdog error                      rsvd,DOGER                                       00000000
#define R57_DSPSR     0xEB // DSP sampling rate setting           rsvd,DSPSR[3:0]                                  00000001
#define R58_SINRT     0xF2 // Serial input route control          rsvd,SINRT[3:0]                                  00000000
#define R59_SOUTRT    0xF3 // Serial output route control         rsvd,SOUTRT[3:0]                                 00000000
#define R60_SGPIN     0xF4 // Serial data/GPIO pin configuration  rsvd,LRGP3,BGP2,SDOGP1,SDIGP0                    00000000
#define R61_DSPEN     0xF5 // DSP enable                          rsvd,DSPEN                                       00000000
#define R62_DSPRUN    0xF6 // DSP run                             rsvd,DSPRUN                                      00000000
#define R63_DSPSLEW   0xF7 // DSP slew modes                      rsvd,MOSLW,ROSLW,LOSLW,RHPSLW,LHPSLW             00000000
#define R64_SPSR      0xF8 // Serial port sampling rate           rsvd,SPSR[2:0]                                   00000000
#define R65_CLKEN0    0xF9 // Clock Enable 0                      rsvd,SLEWPD,ALCPD,DECPD,SOUTPD,INTPD,SINPD,SPPD  00000000
#define R66_CLKEN1    0xFA // Clock Enable 1                      rsvd,CLK1,CLK0                                   00000000

const uint8_t reg_init[] = {
                                 // Default   Diff      Description                         Bit Fields
                                 // ========  ========  ==================================  ===============================================
	R2_MICJACK    , 0b00000000,  // 00000000  --------  Dig mic/jack detect                 JDDB[1:0],JDFUNC[1:0],rsvd,JDPOL
	R3_REC        , 0b00000000,  // 00000000  --------  Rec power mgmt                      rsvd,MXBIAS[1:0],ADCBIAS[1:0],RBIAS[1:0],rsvd
	R4_RECMXL0    , 0b00000001,  // 00000000  -------*  Rec Mixer Left 0                    rsvd,LINPG[2:0],LINNG[2:0],MX1EN
	R5_RECMXL1    , 0b00000101,  // 00000000  -----*-*  Rec Mixer Left 1                    rsvd,LDBOOST[1:0],MX1AUXG[2:0]
	R6_RECMXR0    , 0b00000001,  // 00000000  -------*  Rec Mixer Right 0                   rsvd,RINPG[2:0],RINNG[2:0],MX2EN
	R7_RECMXR1    , 0b00000101,  // 00000000  -----*-*  Rec Mixer Right 1                   rsvd,RDBOOST[1:0],MX2AUXG[2:0]
	R8_LDVOL      , 0b00000000,  // 00000000  --------  Left diff input vol                 LDVOL[5:0],LDMUTE,LDEN
	R9_RDVOL      , 0b00000000,  // 00000000  --------  Right diff input vol                RDVOL[5:0],RDMUTE,RDEN
	R10_RECMIC    , 0b00000000,  // 00000000  --------  Record mic bias                     rsvd,MPERF,MBI,rsvd,MBIEN
	R11_ALC0      , 0b00000000,  // 00000000  --------  ALC 0                               PGASLEW[1:0],ALCMAX[2:0],ALCSEL[2:0]
	R12_ALC1      , 0b00000000,  // 00000000  --------  ALC 1                               ALCHOLD[3:0],ALCTARG[3:0]
	R13_ALC2      , 0b00000000,  // 00000000  --------  ALC 2                               ALCATCK[3:0],ALCDEC[3:0]
	R14_ALC3      , 0b00000000,  // 00000000  --------  ALC 3                               NGTYP[1:0],NGEN,NGTHR[4:0]
	R15_SP0       , 0b00000000,  // 00000000  --------  Serial Port 0                       rsvd,SPSRS,LRMOD,BPOL,LRPOL,CHPF[1:0],MS
	R16_SP1       , 0b00000000,  // 00000000  --------  Serial Port 1                       BPF[2:0],ADTDM,DATDM,MSBP,LRDEL[1:0]
	R17_CONV0     , 0b00000000,  // 00000000  --------  Converter 0                         rsvd,DAPAIR[1:0],DAOSR,ADOSR,CONVSR[2:0]
	R18_CONV1     , 0b00000000,  // 00000000  --------  Converter 1                         rsvd,ADPAIR[1:0],
	R19_ADCCTRL   , 0b00010011,  // 00010000  ------**  ADC control                         rsvd,ADCPOL,HPF,DMPOL,DMSW,INSEL,ADCEN[1:0]
	R20_LADVOL    , 0b00000000,  // 00000000  --------  Left digital vol                    LADVOL[7:0]
	R21_RADVOL    , 0b00000000,  // 00000000  --------  Right digital vol                   RADVOL[7:0]
	R22_PLAYMXL0  , 0b00100001,  // 00000000  --*----*  Play Mixer Left 0                   rsvd,MX3RM,MX3LM,MX3AUXG[3:0],MX3EN
	R23_PLAYMXL1  , 0b00000000,  // 00000000  --------  Play Mixer Left 1                   MX3G2[3:0],MX3G1[3:0]
	R24_PLAYMXR0  , 0b01000001,  // 00000000  -*-----*  Play Mixer Right 0                  rsvd,MX4RM,MX4LM,MX4AUXG[3:0],MX4EN
	R25_PLAYMXR1  , 0b00000000,  // 00000000  --------  Play Mixer Right 1                  MX4G2[3:0],MX4G1[3:0]
	R26_PLAYLRMXL , 0b00000101,  // 00000000  -----*-*  Play L/R mixer left                 rsvd,MX5G4[1:0],MX5G3[1:0],MX5EN
	R27_PLAYLRMXR , 0b00010001,  // 00000000  ---*---*  Play L/R mixer right                rsvd,MX6G4[1:0],MX6G3[1:0],MX6EN
	R28_PLAYLRMXM , 0b00000000,  // 00000000  --------  Play L/R mixer mono                 rsvd,MX7[1:0],MX7EN
	R29_PLAYHLVOL , 0b11100111,  // 00000010  ***--*-*  Play HP left vol                    LHPVOL[5:0],LHPM,HPEN
	R30_PLAYHRVOL , 0b11100111,  // 00000010  ***--*-*  Play HP right vol                   RHPVOL[5:0],RHPM,HPMODE
	R31_LOLVOL    , 0b11100110,  // 00000010  ***--*--  Line output left vol                LOUTVOL[5:0],LOUTM,LOMODE
	R32_LORVOL    , 0b11100110,  // 00000010  ***--*--  Line output right vol               ROUTVOL[5:0],ROUTM,ROMODE
	R33_PLAYMO    , 0b00000000,  // 00000010  ------*-  Play mono output                    MONOVOL[5:0],MONOM,MOMODE
	R34_POP       , 0b00000000,  // 00000000  --------  Pop/click suppress                  rsvd,POPMODE,POPLESS,ASLEW[1:0],rsvd
	R35_PLAYPWR   , 0b00000011,  // 00000000  ------**  Play power mgmt                     HPBIAS[1:0],DACBIAS[1:0],PBIAS[1:0],PREN,PLEN
	R36_DACCTRL0  , 0b00000011,  // 00000000  ------**  DAC Control 0                       DACMONO[1:0],DACPOL,rsvd,DEMPH,DACEN[1:0]
	R37_DACCTRL1  , 0b00000000,  // 00000000  --------  DAC Control 1                       LDAVOL[7:0]
	R38_DACCTRL2  , 0b00000000,  // 00000000  --------  DAC Control 2                       RDAVOL[7:0]
	R39_SERPAD    , 0b10101010,  // 10101010  --------  Serial port pad                     ADCSDP[1:0],DACSDP[1:0],LRCLKP[1:0],BCLKP[1:0]
	R40_CTRLPAD0  , 0b10101010,  // 10101010  --------  Control Port Pad 0                  CDATP[1:0],CLCHP[1:0],SCLP[1:0],SDAP[1:0]
	R41_CTRLPAD1  , 0b00000000,  // 00000000  --------  Control Port Pad 1                  rsvd,SDASTR
	R42_JACKPIN   , 0b00001000,  // 00001000  --------  Jack detect pin                     rsvd,JDSTR,rsvd,JDP[1:0],rsvd
	R67_DEJITTER  , 0b00000000,  // 00000011  ------**  Dejitter control                    DEJIT[7:0]
	R43_CRC3      , 0b00000000,  // 00000000  --------  Cyclic redundancy check             CRC[31:24]
	R44_CRC2      , 0b00000000,  // 00000000  --------  Cyclic redundancy check             CRC[23:16]
	R45_CRC1      , 0b00000000,  // 00000000  --------  Cyclic redundancy check             CRC[15:8]
	R46_CRC0      , 0b00000000,  // 00000000  --------  Cyclic redundancy check             CRC[7:0]
	R47_CRCEN     , 0b00000000,  // 00000000  --------  CRC enable                          rsvd,CRCEN
	R48_GPIO0     , 0b00000000,  // 00000000  --------  GPIO0 pin control                   rsvd,GPIO0[3:0]
	R49_GPIO1     , 0b00000000,  // 00000000  --------  GPIO1 pin control                   rsvd,GPIO1[3:0]
	R50_GPIO2     , 0b00000000,  // 00000000  --------  GPIO2 pin control                   rsvd,GPIO2[3:0]
	R51_GPIO3     , 0b00000000,  // 00000000  --------  GPIO3 pin control                   rsvd,GPIO3[3:0]
	R52_DOGEN     , 0b00000000,  // 00000000  --------  Watchdog enable                     rsvd,DOGEN
	R53_DOGVAL2   , 0b00000000,  // 00000000  --------  Watchdog value                      DOG[23:16]
	R54_DOGVAL1   , 0b00000000,  // 00000000  --------  Watchdog value                      DOG[15:8]
	R55_DOGVAL0   , 0b00000000,  // 00000000  --------  Watchdog value                      DOG[7:0]
	R56_DOGERR    , 0b00000000,  // 00000000  --------  Watchdog error                      rsvd,DOGER
	R57_DSPSR     , 0b00000001,  // 00000001  --------  DSP sampling rate setting           rsvd,DSPSR[3:0]
	R58_SINRT     , 0b00000001,  // 00000000  -------*  Serial input route control          rsvd,SINRT[3:0]
	R59_SOUTRT    , 0b00000001,  // 00000000  -------*  Serial output route control         rsvd,SOUTRT[3:0]
	R60_SGPIN     , 0b00000000,  // 00000000  --------  Serial data/GPIO pin configuration  rsvd,LRGP3,BGP2,SDOGP1,SDIGP0
	R61_DSPEN     , 0b00000000,  // 00000000  --------  DSP enable                          rsvd,DSPEN
	R62_DSPRUN    , 0b00000000,  // 00000000  --------  DSP run                             rsvd,DSPRUN
	R63_DSPSLEW   , 0b00000000,  // 00000000  --------  DSP slew modes                      rsvd,MOSLW,ROSLW,LOSLW,RHPSLW,LHPSLW
	R64_SPSR      , 0b00000000,  // 00000000  --------  Serial port sampling rate           rsvd,SPSR[2:0]
	R65_CLKEN0    , 0b01111111,  // 00000000  -*******  Clock Enable 0                      rsvd,SLEWPD,ALCPD,DECPD,SOUTPD,INTPD,SINPD,SPPD
	R66_CLKEN1    , 0b00000011,  // 00000000  ------**  Clock Enable 1                      rsvd,CLK1,CLK0
	0xFF                         // end
};

#endif
