/*******************************************************************************
** adau1761.c                                                                 **
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

#include <stdint.h>

#include "peekpoke.h"
#include "axi_iic.h"
#include "adau1761_p.h"

// poke single 8-bit register
void adau1761_poke(uint8_t a, uint8_t d)
{
    axi_iic_poke_sa16(SLAVE_ADDR, R_BASE+a, d);
}

// poke multiple registers e.g. PLL
void adau1761_pokem(uint8_t a, uint8_t *d, uint8_t n)
{
    axi_iic_pokem_sa16(SLAVE_ADDR, R_BASE+a, d, n);
}

// peek single 8-bit register
uint8_t adau1761_peek(uint16_t a)
{
    return axi_iic_peek_sa16(SLAVE_ADDR, R_BASE+a);
}

// peek multiple registers e.g. PLL
void adau1761_peekm(uint16_t a, uint8_t *d, uint8_t n)
{
    axi_iic_peekm_sa16(SLAVE_ADDR, R_BASE+a, d, n);
}

// initialise
void adau1761_init()
{
    uint8_t i;
    uint8_t pll_reg[6] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // PLL not used
    uint8_t r[6];

    adau1761_pokem(R1_PLL, pll_reg, 6);
    if (pll_reg[5] & 0x01) { // if PLL enabled...
		while(1) { // ...wait for lock
			adau1761_peekm(R1_PLL, r, 6);
			if (r[5] & 0x02) // PLL lock?
				break;
		}
    }
    adau1761_poke(R0_CLKCTRL, 0x01);
    i = 0;
    while (reg_init[i] != 0xFF) {
        adau1761_poke(reg_init[i], reg_init[i+1]);
        i += 2;
    }
}
