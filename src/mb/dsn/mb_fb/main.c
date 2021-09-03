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
	uint16_t w,h, a, b, x[3], y[3];
	color_t c;

	fb_init(FB_MODE_640x480p60);
	hagl_init();

	w = DISPLAY_WIDTH;
	h = DISPLAY_HEIGHT;
	for (i = 0; i < 100; i++) {
	    x[0] = rand() % DISPLAY_WIDTH;
	    y[0] = rand() % DISPLAY_HEIGHT;
	    x[1] = rand() % DISPLAY_WIDTH;
	    y[1] = rand() % DISPLAY_HEIGHT;
	    color_t c = rand() % 0xffffff;
		switch (rand() & 3 ) {
			case 0: // line
				hagl_draw_line(x[0], y[0], x[1], y[1], c);
				break;
			case 1: // triangle
			    x[2] = rand() % DISPLAY_WIDTH;
			    y[2] = rand() % DISPLAY_HEIGHT;
				hagl_fill_triangle(x[0], y[0], x[1], y[1], x[2], y[2], c);
				break;
			case 2: // rectangle
				hagl_fill_rectangle(x[0], y[0], x[1], y[1], c);
				break;
			case 3: // ellipse
				x[2] = (x[0]+x[1]) >> 1;
				y[2] = (y[0]+y[1]) >> 1;
				a = abs(x[0]-x[1]) >> 1;
				b = abs(y[0]-y[1]) >> 1;
				hagl_fill_ellipse(x[2], y[2], a, b, c);
				break;
		}
	}

	c = 0xFFFFFF;
	hagl_draw_rectangle(	0,		0,		w/2-1,		h/2-1,	c	);
	hagl_draw_rectangle(	w/2,	0,		w-1,		h/2-1,	c	);
	hagl_draw_rectangle(	0,		h/2,	w/2-1,		h-1,	c	);
	hagl_draw_rectangle(	w/2,	h/2,	w-1,		h-1,	c	);

	hagl_put_text(L"hello world!", 0, 0, 0xFFFFFF, font5x7);

	while(1)
		;
}
