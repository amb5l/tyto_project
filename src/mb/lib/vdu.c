/*******************************************************************************
** vdu.c                                                                      **
** Simple VDU (character display) driver.                                     **
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

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "xil_types.h"
#include "xil_mem.h"

#include "peekpoke.h"
#include "axi_gpio.h"
#include "printf.h"
#include "vdu.h"

static uint8_t vdu_width = 0;
static uint8_t vdu_height = 0;
static uint8_t vdu_x = 0;
static uint8_t vdu_y = 0;
static uint8_t vdu_attr = 0x0F;

#define POKE_CHAR(x,y,c) poke8(VDU_BUF+((x+(y*vdu_width))<<1),c)
#define PEEK_CHAR(x,y) peek8(VDU_BUF+((x+(y*vdu_width))<<1))
#define POKE_ATTR(x,y,a) poke8(VDU_BUF+((x+(y*vdu_width))<<1)+1,a)
#define PEEK_ATTR(x,y) peek8(VDU_BUF+((x+(y*vdu_width))<<1)+1)
#define POKE_COL_FG(x,y,col) POKE_ATTR(x,y,(PEEK_ATTR(x,y) & 0xF0)|(col & 0x0F))
#define POKE_COL_BG(x,y,col) POKE_ATTR(x,y,(PEEK_ATTR(x,y) & 0x0F)|((col & 0x0F)<<4))
#define POKE_CHAR_ATTR(x,y,c,a) poke16(VDU_BUF+((x+(y*vdu_width))<<1),(a << 8)|c)

void vdu_init(uint8_t mode)
{
	uint32_t r;
	uint8_t x, y;

	r = axi_gpio_get_gpi(0);
	r = (r & ~1) | (mode & 1);
	axi_gpio_set_gpo(0, r);
	vdu_width = 80;
	vdu_height = mode ? 32 : 25;
	vdu_x = 0;
	vdu_y = 0;
	vdu_attr = 0x0F;
	for (x = 0; x < vdu_width; x++)
		for (y = 0; y < vdu_height; y++)
			POKE_CHAR_ATTR(x,y,0,vdu_attr);
    init_printf(NULL,vdu_putc);
}

void vdu_poke_char(uint8_t x, uint8_t y, uint8_t c)
{
	POKE_CHAR(x,y,c);
}

void vdu_poke_attr(uint8_t x, uint8_t y, uint8_t a)
{
	POKE_ATTR(x,y,a);
}

void vdu_poke_col_fg(uint8_t x, uint8_t y, uint8_t col)
{
	POKE_COL_FG(x,y,col);
}

void vdu_poke_col_bg(uint8_t x, uint8_t y, uint8_t col)
{
	POKE_COL_BG(x,y,col);
}

void vdu_poke_char_attr(uint8_t x, uint8_t y, uint8_t c, uint8_t a)
{
	POKE_CHAR_ATTR(x,y,c,a);
}

void vdu_set_pos(uint8_t x, uint8_t y)
{
	vdu_x = x;
	vdu_y = y;
}

void vdu_set_border(uint8_t col)
{
	uint32_t r;

	r = axi_gpio_get_gpi(0);
	r = (r & ~0xF0) | (col << 4);
	axi_gpio_set_gpo(0, r);
}

void vdu_set_attr(uint8_t attr)
{
	vdu_attr = attr;
}

void vdu_set_col(uint8_t fg, uint8_t bg)
{
	vdu_attr = ((bg & 0x0F) << 4) | (fg & 0x0F);
}

void vdu_set_col_fg(uint8_t col)
{
	vdu_attr = (vdu_attr & 0xF0) | (col & 0x0F);
}

void vdu_set_col_bg(uint8_t col)
{
	vdu_attr = (vdu_attr & 0x0F) | ((col & 0x0F) << 4);
}

void vdu_scroll_up()
{
	Xil_MemCpy((void *)VDU_BUF, (void *)(VDU_BUF+(vdu_width<<1)), (vdu_width<<1)*(vdu_height-1));
	memset((void *)VDU_BUF+((vdu_width<<1)*(vdu_height-1)), 0, (size_t)(vdu_width<<1));
}

void vdu_newline()
{
	vdu_x = 0;
	if (++vdu_y == vdu_height) {
		vdu_y--;
		vdu_scroll_up();
	}
}

void vdu_putc(void *p, char c)
{
	if (c >= 32) { // display characters 32..255
		POKE_CHAR_ATTR(vdu_x++, vdu_y, c, vdu_attr);
		if (vdu_x == vdu_width) {
			vdu_newline();
		}
	}
	else { // control characters 0..31
		switch(c) {
			case 10 :	// newline
				vdu_newline();
				break;
			case 13 :	// CR
				vdu_x = 0;
				break;
		}
	}
}
