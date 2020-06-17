/*******************************************************************************
** axi_fifo_mm_p.h                                                            **
** Simple driver for AXI-Stream FIFO IP core.                                 **
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

#ifndef _AXI_FIFO_MM_P_H_
#define _AXI_FIFO_MM_P_H_

#define BASE XPAR_FIFO_MM_BASEADDR

#define REG_ISR  0x00
#define REG_IER  0x04
#define REG_TDFR 0x08
#define REG_TDFV 0x0C
#define REG_TDFD 0x10
#define REG_TLR  0x14
#define REG_RDFR 0x18
#define REG_RDFO 0x1C
#define REG_RDFD 0x20
#define REG_RLR  0x24
#define REG_SRR  0x28
#define REG_TDR  0x2C
#define REG_RDR  0x30

#define RST 0x000000A5

#endif
