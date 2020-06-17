/*******************************************************************************
** dalek.c                                                                    **
** demo_audio_io application.                                                 **
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

#include "global.h"
#include "dalek_p.h"

// modulate samples with a 30Hz sine wave

void dalek(sample_t *s)
{
    static uint16_t i = 0;  // wave quadrant index 0..399
    static uint8_t q = 0;   // full wave quadrant 0..3
    int32_t m;              // multiplier
    int32_t ml, mr;         // m x L/R samples

    i = (i + 1) % 400;
    if (i == 0)
    	q = (q + 1) % 4;
    switch(q) {
        case 0: m = wave[i]; break;
        case 1: m = wave[399-i]; break;
        case 2: m = -wave[i]; break;
        case 3: m = -wave[399-i]; break;
    }
    ml = s->frame.l * m;
    mr = s->frame.r * m;
    s->frame.l = ml >> 16;
    s->frame.r = mr >> 16;
}
