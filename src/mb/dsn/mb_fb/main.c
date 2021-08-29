/*******************************************************************************
** main.c                                                                     **
** MicroBlaze demo application for mb_fb design.                              **
********************************************************************************
** (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        **
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
#include <stdlib.h>

#include "fb.h"
#include "hagl.h"
#include "font5x7.h"

int main()
{
	int i;

	fb_init(FB_MODE_640x480p60);
	hagl_init();

	//for (uint16_t i = 1; i < 1000; i++) {
	for (i = 0; i < 1000; i++) {
	    int16_t x0 = rand() % DISPLAY_WIDTH;
	    int16_t y0 = rand() % DISPLAY_HEIGHT;
	    int16_t x1 = rand() % DISPLAY_WIDTH;
	    int16_t y1 = rand() % DISPLAY_HEIGHT;
	    color_t color = rand() % 0xffffff;

	    hagl_draw_line(x0, y0, x1, y1, color);
	}

	hagl_put_text(L"hello world!", 0, 0, 0xFFFFFF, font5x7);

	while(1)
		;
}
