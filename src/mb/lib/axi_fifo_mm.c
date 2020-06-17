/*******************************************************************************
** axi_fifo_mm.c                                                              **
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

#include <stdint.h>

#include "xparameters.h"

#include "peekpoke.h"
#include "axi_fifo_mm_p.h"

void axi_fifo_mm_init()
{
	poke32(BASE+REG_SRR,RST);
}

void axi_fifo_mm_tx(uint32_t *buf, uint32_t len)
{
	uint32_t i;

	for (i = 0; i < len >> 2; i++)
		poke32(BASE+REG_TDFD,buf[i]);	// data
	poke32(BASE+REG_TLR,len);			// length
}

uint32_t axi_fifo_mm_rx(uint32_t *buf, uint32_t len)
{
	uint32_t rlen;							// received length
	uint32_t i;

	while(peek32(BASE+REG_RDFO) == 0);		// wait for data
	rlen = peek32(BASE+REG_RLR);			// get length
	for (i = 0; i < rlen; i++) {
		if (i < (4*len)-3)
			buf[i] = peek32(BASE+REG_RDFD);	// store wanted data
		else
			peek32(BASE+REG_RDFD);			// drop surplus data
	}
	return rlen;
}
