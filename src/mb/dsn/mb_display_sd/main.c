/*******************************************************************************
** main.c                                                                     **
** MicroBlaze demo application for mb_display_sd design.                      **
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
#include <string.h>
#include "vdu.h"

#define MODE 0 // 0 = 80x25 (NTSC), 1 = 80x32 (PAL)

int main()
{
	int i;
	uint8_t attr;
	unsigned int u;
	char s[256];

	vdu_init(MODE);
	vdu_set_border(VDU_LIGHT_BLUE);
	vdu_set_col(VDU_YELLOW, VDU_BLUE);
	printf("MicroBlaze demo application for mb_display_sd design...\n");

	strcpy(s, "HELLO! ");
	attr = 0x34;
	u = (80*((MODE?32:25)-1))/strlen(s);
	for (i = 0; i < u; i++) {
		vdu_set_attr(attr++);
		printf("%s", s);
	}

	while(1)
		;
}
