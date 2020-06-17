/*******************************************************************************
** axi_iic.h                                                                  **
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

#ifndef _AXI_IIC_H_
#define _AXI_IIC_H_

#include "stdint.h"

void axi_iic_init();
void axi_iic_sa8(uint8_t a, uint8_t sa);
void axi_iic_sa16(uint8_t a, uint16_t sa);
void axi_iic_pokem_sa8(uint8_t a, uint8_t sa, uint8_t *d, uint8_t n);
void axi_iic_poke_sa8(uint8_t a, uint8_t sa, uint8_t d);
void axi_iic_pokem_sa16(uint8_t a, uint16_t sa, uint8_t *d, uint8_t n);
void axi_iic_poke_sa16(uint8_t a, uint16_t sa, uint8_t d);
void axi_iic_peekm_sa8(uint8_t a, uint8_t sa, uint8_t *d, uint8_t n);
uint8_t axi_iic_peek_sa8(uint8_t a, uint8_t sa);
void axi_iic_peekm_sa16(uint8_t a, uint16_t sa, uint8_t *d, uint8_t n);
uint8_t axi_iic_peek_sa16(uint8_t a, uint16_t sa);
void axi_iic_gpo(uint8_t d);

#endif
