/*******************************************************************************
** axi_gpio_p.h                                                                 **
** Simple driver AXI GPIO IP core.                                            **
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

#ifndef _AXI_GPIO_P_H_
#define _AXI_GPIO_P_H_

#include "xparameters.h"

#define BASE XPAR_GPIO_BASEADDR

#define REG_GPIO_DATA   0x0000 // Channel 1 AXI GPIO Data Register
#define REG_GPIO_TRI    0x0004 // Channel 1 AXI GPIO 3-state Control Register
#define REG_GPIO2_DATA  0x0008 // Channel 2 AXI GPIO Data Register
#define REG_GPIO2_TRI   0x000C // Channel 2 AXI GPIO 3-state Control Register
#define REG_GIER        0x011C // Global Interrupt Enable Register
#define REG_IP_IER      0x0128 // IP Interrupt Enable Register
#define REG_IP_ISR      0x0120 // IP Interrupt Status Register

#endif
