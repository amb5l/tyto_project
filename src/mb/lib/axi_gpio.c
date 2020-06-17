/*******************************************************************************
** axi_gpio.c                                                                 **
** Simple driver AXI GPIO IP core.                                            **
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
#include "peekpoke.h"
#include "axi_gpio_p.h"

void axi_gpio_init()
{
    // empty for now
}

void axi_gpio_set_gpt(uint8_t channel, uint32_t data)
{
    poke32(BASE+(channel?REG_GPIO2_TRI:REG_GPIO_TRI),data);
}

void axi_gpio_set_gpo(uint8_t channel, uint32_t data)
{
    poke32(BASE+(channel?REG_GPIO2_DATA:REG_GPIO_DATA),data);
}

uint32_t axi_gpio_get_gpi(uint8_t channel)
{
    return peek32(BASE+(channel?REG_GPIO2_DATA:REG_GPIO_DATA));
}
