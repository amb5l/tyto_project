/*******************************************************************************
** main.c                                                                     **
** MicroBlaze demo application for mb_audio_io design.                        **
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

// the Debug configuration (in which the BUILD_CONFIG_DEBUG symbol is defined)
// is for simulation purposes only

#ifndef BUILD_CONFIG_DEBUG
#include <stdlib.h>
#include <stdint.h>
#include "xil_printf.h"
#include "axi_iic.h"
#include "adau1761.h"
#endif
#include "axi_fifo_mm.h"

#include "global.h"
#ifndef BUILD_CONFIG_DEBUG
#include "dalek.h"
#endif

int main()
{
    sample_t sample;
#ifndef BUILD_CONFIG_DEBUG
    sample_t peak;
    uint16_t i;
	uint8_t gpo; // GPOs 0..4 go to LEDs
#else
	int16_t test;
#endif

#ifndef BUILD_CONFIG_DEBUG
	xil_printf("MicroBlaze demo application for mb_audio_io design...\n");
#endif
    axi_iic_init();
    axi_iic_gpo(0x55);
#ifndef BUILD_CONFIG_DEBUG
    adau1761_init();

    i = 0;
	peak.raw = 0;
    gpo = 0;
#else
    test = 0xAB00;
#endif
	while(1) {
		axi_fifo_mm_rx((uint32_t *)&sample, 4);
#ifndef BUILD_CONFIG_DEBUG
        if (abs(sample.frame.l) > peak.frame.l)
            peak.frame.l = abs(sample.frame.l);
        if (abs(sample.frame.r) > peak.frame.r)
            peak.frame.r = abs(sample.frame.r);
        dalek(&sample);
#else
        sample.frame.r = sample.frame.l;
        sample.frame.l = test++;
#endif
		axi_fifo_mm_tx((uint32_t *)&sample,4);
#ifndef BUILD_CONFIG_DEBUG
		i = (i + 1) % 48000;
		if (i == 0) {
			xil_printf("%d %d\n\r", peak.frame.l, peak.frame.r);
            peak.raw = 0;
			gpo++;
			axi_iic_gpo(gpo);
		}
#endif
	}
}
