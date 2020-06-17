/*******************************************************************************
** peekpoke.h                                                                 **
** Peek and Poke macros.                                                      **
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

#ifndef _PEEKPOKE_H_
#define _PEEKPOKE_H_

#include "stdint.h"

#define peek32(a) (*(volatile uint32_t *)(a))
#define peek16(a) (*(volatile uint16_t *)(a))
#define peek8(a) (*(volatile uint8_t *)(a))

#define poke32(a,d) {*(volatile uint32_t *)(a) = d;}
#define poke16(a,d) {*(volatile uint16_t *)(a) = d;}
#define poke8(a,d) {*(volatile uint8_t *)(a) = d;}

#endif
