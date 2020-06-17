/*******************************************************************************
** axi_fifo_mm.h                                                              **
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

#ifndef _AXI_FIFO_MM_H_
#define _AXI_FIFO_MM_H_

#include "stdint.h"

void axi_fifo_mm_init();
void axi_fifo_mm_tx(uint32_t *buf, uint32_t len);
uint32_t axi_fifo_mm_rx(uint32_t *buf, uint32_t len);

#endif
