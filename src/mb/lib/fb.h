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

#ifndef _FB_H_
#define _FB_H_

#include "xparameters.h"

#define FB_BASE XPAR_AXI_BASEADDR

#define FB_MODE_640x480p60		0
#define FB_MODE_720x480p60  	1
#define FB_MODE_720x480p60w 	2
#define FB_MODE_1280x720p60 	3
#define FB_MODE_1920x1080i60	4
#define FB_MODE_720x480i60  	5
#define FB_MODE_720x480i60w 	6
#define FB_MODE_1920x1080p60	7
#define FB_MODE_720x576p50  	8
#define FB_MODE_720x576p50w 	9
#define FB_MODE_1280x720p50 	10
#define FB_MODE_1920x1080i50	11
#define FB_MODE_720x576i50  	12
#define FB_MODE_720x576i50w 	13
#define FB_MODE_1920x1080p50	14

uint8_t fb_mode;
int16_t fb_width;
int16_t fb_height;

void fb_init(uint8_t mode);

#endif
