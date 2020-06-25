################################################################################
## hdmi_bch_ecc.py                                                            ##
## HDMI BCH ECC logic calculator for 1-8 clocks.                              ##
################################################################################
## (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of The Tyto Project. The Tyto Project is free software:  ##
## you can redistribute it and/or modify it under the terms of the GNU Lesser ##
## General Public License as published by the Free Software Foundation,       ##
## either version 3 of the License, or (at your option) any later version.    ##
## The Tyto Project is distributed in the hope that it will be useful, but    ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Tyto Project. If not, see     ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

# initial states
reg_q = []
reg_d = []
for i in range (0,8):
    reg_q.append(["q"+str(i)])
    reg_d.append([])

# 8 cycles through lfsr (see fig 5-5)
for i in range(0,8):
    # advance lfsr
    fb = reg_q[0]+["d"+str(i)]
    reg_d[0] = reg_q[1]+fb
    reg_d[1] = reg_q[2]+fb
    reg_d[2:7] = reg_q[3:8]
    reg_d[7] = fb
    reg_q = reg_d
    # remove all duplicate pairs
    for j in range(0,8):
        for k in range(0,8):
            while reg_q[j].count("q"+str(k)) > 1:
                reg_q[j].remove("q"+str(k))
                reg_q[j].remove("q"+str(k))
            while reg_q[j].count("d"+str(k)) > 1:
                reg_q[j].remove("d"+str(k))
                reg_q[j].remove("d"+str(k))    
    # result
    print("after %d clocks:" % (i+1))
    for i in range(0,8):
        reg_q[i].sort()
        print("q%d <= xor( " % i, end="")
        for s in reg_q[i]:
            print(s+" ",end="")
        print(")")
    print("")
