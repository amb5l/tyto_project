/*******************************************************************************
** axi_iic.c                                                                  **
** Simple master mode driver AXI_IIC IP core.                                 **
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

#include "xparameters.h"

#include "peekpoke.h"
#include "axi_iic_p.h"

void axi_iic_init()
{
    poke8(BASE+REG_RX_FIFO_PIRQ,0x0F);  // max RX FIFO depth
    CR(CR_TXRST);                       // TX FIFO reset
    CR(CR_EN);                          // enable
}

// start read/write access with 8 bit subaddress
void axi_iic_sa8(uint8_t a, uint8_t sa)
{
	while(SR() & SR_BB);                // wait until bus not busy
	while(!(SR() & SR_TXE));            // wait until TX FIFO empty
	while(!(SR() & SR_RXE))				// empty RX FIFO if needed
		RX();
	TX(TX_START | (a << 1) | 0);        // start + slave address | write
	TX(sa);                        		// subaddress
}

// start read/write access with 16 bit subaddress
void axi_iic_sa16(uint8_t a, uint16_t sa)
{
	while(SR() & SR_BB);                // wait until bus not busy
	while(!(SR() & SR_TXE));            // wait until TX FIFO empty
	while(!(SR() & SR_RXE))				// empty RX FIFO if needed
		RX();
	TX(TX_START | (a << 1) | 0);        // start + slave address | write
	TX(sa >> 8);                        // subaddress high byte
	TX(sa & 0xFF);                      // subaddress low byte
}

// multiple poke with 8 bit subaddress
void axi_iic_pokem_sa8(uint8_t a, uint8_t sa, uint8_t *d, uint8_t n)
{
	axi_iic_sa8(a,sa);
    while(n-- >= 1) {
        if (n == 1) {
            TX(TX_STOP | *d++);         // stop + last data
        }
        else {
            TX(*d++);                   // data
        }
    }
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(SR() & SR_BB);                // wait until bus not busy
}

// single poke with 8 bit subaddress
void axi_iic_poke_sa8(uint8_t a, uint8_t sa, uint8_t d)
{
	axi_iic_sa8(a,sa);
    TX(TX_STOP | d);                    // stop + data
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(SR() & SR_BB);                // wait until bus not busy
}

// multiple poke with 16 bit subaddress
void axi_iic_pokem_sa16(uint8_t a, uint16_t sa, uint8_t *d, uint8_t n)
{
	axi_iic_sa16(a,sa);
    while(n-- >= 1) {
        if (n == 1) {
            TX(TX_STOP | *d++);         // stop + last data
        }
        else {
            TX(*d++);                   // data
        }
    }
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(SR() & SR_BB);                // wait until bus not busy
}

// single poke with 16 bit subaddress
void axi_iic_poke_sa16(uint8_t a, uint16_t sa, uint8_t d)
{
	axi_iic_sa16(a,sa);
    TX(TX_STOP | d);                    // stop + data
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(SR() & SR_BB);                // wait until bus not busy
}

// multiple peek with 8 bit subaddress
void axi_iic_peekm_sa8(uint8_t a, uint8_t sa, uint8_t *d, uint8_t n)
{
	axi_iic_sa8(a,sa);
    TX(TX_START | (a << 1) | 1);        // (re)start + slave address | read
    TX(TX_STOP | n);                    // read n bytes
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(n-- >= 1) {
        while((SR() & SR_RXE));            	// wait until RX FIFO not empty
        *d++ = RX();
    }
    while(SR() & SR_BB);                // wait until bus not busy
}

// single peek with 8 bit subaddress
uint8_t axi_iic_peek_sa8(uint8_t a, uint8_t sa)
{
    uint8_t r;

	axi_iic_sa8(a,sa);
    TX(TX_START | (a << 1) | 1);        // (re)start + slave address | read
    TX(TX_STOP | 1);                    // read single byte
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while((SR() & SR_RXE));            	// wait until RX FIFO not empty
    r = RX();
    while(SR() & SR_BB);                // wait until bus not busy
    return r;
}

// multiple peek with 16 bit subaddress
void axi_iic_peekm_sa16(uint8_t a, uint16_t sa, uint8_t *d, uint8_t n)
{
	axi_iic_sa16(a,sa);
    TX(TX_START | (a << 1) | 1);        // (re)start + slave address | read
    TX(TX_STOP | n);                    // read n bytes
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while(n-- >= 1) {
        while((SR() & SR_RXE));            	// wait until RX FIFO not empty
        *d++ = RX();
    }
    while(SR() & SR_BB);                // wait until bus not busy
}

// single peek with 16 bit subaddress
uint8_t axi_iic_peek_sa16(uint8_t a, uint16_t sa)
{
    uint8_t r;

	axi_iic_sa16(a,sa);
    TX(TX_START | (a << 1) | 1);        // (re)start + slave address | read
    TX(TX_STOP | 1);                    // read single byte
    while(!(SR() & SR_TXE));            // wait until TX FIFO empty
    while((SR() & SR_RXE));            	// wait until RX FIFO not empty
    r = RX();
    while(SR() & SR_BB);                // wait until bus not busy
    return r;
}

// set GPOs
void axi_iic_gpo(uint8_t d)
{
    poke32(BASE+REG_GPO,d);
}
