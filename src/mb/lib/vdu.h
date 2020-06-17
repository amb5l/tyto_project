/*******************************************************************************
** vdu.h                                                                      **
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

#ifndef _VDU_H_
#define _VDU_H_

#include "printf.h"

#include "xparameters.h"
#define VDU_BUF	XPAR_BRAM_S_AXI_BASEADDR

#define VDU_BLACK			0x0
#define VDU_BLUE			0x1
#define VDU_GREEN			0x2
#define VDU_CYAN			0x3
#define VDU_RED				0x4
#define VDU_MAGENTA			0x5
#define VDU_BROWN			0x6
#define VDU_LIGHT_GRAY		0x7
#define VDU_DARK_GRAY		0x8
#define VDU_LIGHT_BLUE		0x9
#define VDU_LIGHT_GREEN		0xA
#define VDU_LIGHT_CYAN		0xB
#define VDU_LIGHT_RED		0xC
#define VDU_LIGHT_MAGENTA	0xD
#define VDU_YELLOW			0xE
#define VDU_WHITE			0xF

void vdu_init(uint8_t mode);
void vdu_poke_char(uint8_t x, uint8_t y, uint8_t c);
void vdu_poke_attr(uint8_t x, uint8_t y, uint8_t a);
void vdu_poke_col_fg(uint8_t x, uint8_t y, uint8_t col);
void vdu_poke_col_bg(uint8_t x, uint8_t y, uint8_t col);
void vdu_poke_char_attr(uint8_t x, uint8_t y, uint8_t c, uint8_t a);
void vdu_set_pos(uint8_t x, uint8_t y);
void vdu_set_border(uint8_t col);
void vdu_set_attr(uint8_t attr);
void vdu_set_col(uint8_t fg, uint8_t bg);
void vdu_set_col_fg(uint8_t col);
void vdu_set_col_bg(uint8_t col);
void vdu_scroll_up();
void vdu_newline();
void vdu_putc(void *p, char c);

#endif
