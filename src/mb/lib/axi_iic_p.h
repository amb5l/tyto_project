/*******************************************************************************
** axi_iic_p.h                                                                **
** Simple master mode driver AXI_IIC IP core.                                 **
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

#ifndef _AXI_IIC_P_H_
#define _AXI_IIC_P_H_

#define BASE XPAR_I2C_BASEADDR

#define REG_GIE          0x01C // Global Interrupt Enable Register
#define REG_ISR          0x020 // Interrupt Status Register
#define REG_IER          0x028 // Interrupt Enable Register
#define REG_SOFTR        0x040 // Soft Reset Register
#define REG_CR           0x100 // Control Register
#define REG_SR           0x104 // Status Register
#define REG_TX_FIFO      0x108 // Transmit FIFO Register
#define REG_RX_FIFO      0x10C // Receive FIFO Register
#define REG_ADR          0x110 // Slave Address Register
#define REG_TX_FIFO_OCY  0x114 // Transmit FIFO Occupancy Register
#define REG_RX_FIFO_OCY  0x118 // Receive FIFO Occupancy Register
#define REG_TEN_ADR      0x11C // Slave Ten Bit Address Register
#define REG_RX_FIFO_PIRQ 0x120 // Receive FIFO Programmable Depth Interrupt Register
#define REG_GPO          0x124 // General Purpose Output Register
#define REG_TSUSTA       0x128 // Timing Parameter Register
#define REG_TSUSTO       0x12C // Timing Parameter Register
#define REG_THDSTA       0x130 // Timing Parameter Register
#define REG_TSUDAT       0x134 // Timing Parameter Register
#define REG_TBUF         0x138 // Timing Parameter Register
#define REG_THIGH        0x13C // Timing Parameter Register
#define REG_TLOW         0x140 // Timing Parameter Register
#define REG_THDDAT       0x144 // Timing Parameter Register

#define SOFTR_KEY   0xA
#define CR_EN       (1 << 0)
#define CR_TXRST    (1 << 1)
#define CR_MSMS     (1 << 2)
#define CR_TX       (1 << 3)
#define CR_TXAK     (1 << 4)
#define CR_RSTA     (1 << 5)
#define SR_BB       (1 << 2)
#define SR_RXE      (1 << 6)
#define SR_TXE      (1 << 7)
#define TX_START    (1 << 8)
#define TX_STOP     (1 << 9)

#define CR(x) poke8(BASE+REG_CR,x)
#define SR(x) peek8(BASE+REG_SR)
#define TX(x) poke16(BASE+REG_TX_FIFO,x)
#define RX(x) peek8(BASE+REG_RX_FIFO)

#endif
