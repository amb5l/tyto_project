/*******************************************************************************
** global.h                                                                   **
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

#ifndef _GLOBAL_H_
#define _GLOBAL_H_

typedef struct {
    int16_t l;
    int16_t r;
} __attribute__ ((aligned (4), packed)) i2s_frame_t;

typedef union {
    uint32_t raw;
    i2s_frame_t frame;
} __attribute__ ((aligned (4))) sample_t;

#endif
