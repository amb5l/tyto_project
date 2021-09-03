/*******************************************************************************
** fb.c                                                                       **
** Simple frame buffer driver.                                                **
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

#include "peekpoke.h"
#include "axi_gpio.h"
#include "fb.h"

typedef struct {
	uint16_t width;
	uint16_t height;
} fb_dim_t;

const fb_dim_t fb_dims[] = {
		{640, 480},
		{720, 480},
		{720, 480},
		{1280, 720},
		{1920, 1080},
		{720, 480},
		{720, 480},
		{1920, 1080},
		{720, 576},
		{720, 576},
		{1280, 720},
		{1920, 1080},
		{720, 576},
		{720, 576},
		{1920, 1080}
};

void fb_init(uint8_t mode)
{
	uint32_t a, r;
	uint32_t fb_size;

	fb_mode = mode;
	fb_width = fb_dims[mode].width;
	fb_height = fb_dims[mode].height;
	fb_size = (fb_width * fb_height) << 2;
	r = axi_gpio_get_gpo(0);
	r = (r & ~0x0F) | (mode & 0x0F);
	axi_gpio_set_gpo(0, r);
	for (a = FB_BASE; a < FB_BASE+fb_size; a+=4)
		poke32(a, rand());
}
