--------------------------------------------------------------------------------
-- sim_video_out_pkg.vhd                                                      --
-- Types and procedures for simulating video output designs.                  --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;

package sim_video_out_pkg is

 	subtype uint8_t is integer range 0 to 255;
	type pixel_t is array(0 to 2) of uint8_t;
	type bmp_t is array(natural range <>,natural range <>) of pixel_t;

	procedure write_bmp(
       name : in string;
	   img : in bmp_t;
	   count : in integer;
	   width : in integer;
	   hieght : in integer;
       interlaced : in boolean
	);

end package sim_video_out_pkg;

-------------------------------------------------------------------------------

package body sim_video_out_pkg is

	procedure write_bmp(
       name : in string;
	   img : in bmp_t;
	   count : in integer;
	   width : in integer;
	   hieght : in integer;
       interlaced : in boolean
	) is
		type char_file_t is file of character;
		file f : char_file_t;
		type bmp_hdr_t is array (0 to 53) of unsigned(7 downto 0);
		variable bmp_filesize : unsigned(31 downto 0) := unsigned(to_unsigned(bmp_hdr_t'length+(3*width*hieght),32));
		variable bmp_size_x : unsigned(31 downto 0) := unsigned(to_unsigned(width,32));
		variable bmp_size_y : unsigned(31 downto 0) := unsigned(to_unsigned(hieght,32));
		variable bmp_imgsize : unsigned(31 downto 0) := unsigned(to_unsigned(3*width*hieght,32));
		variable bmp_header : bmp_hdr_t := (
			x"42",x"4D",
			bmp_filesize(7 downto 0),bmp_filesize(15 downto 8),bmp_filesize(23 downto 16),bmp_filesize(31 downto 24),
			x"00",x"00",x"00",x"00",x"36",x"00",x"00",x"00",x"28",x"00",x"00",x"00",
			bmp_size_x(7 downto 0),bmp_size_x(15 downto 8),bmp_size_x(23 downto 16),bmp_size_x(31 downto 24),
			bmp_size_y(7 downto 0),bmp_size_y(15 downto 8),bmp_size_y(23 downto 16),bmp_size_y(31 downto 24),
			x"01",x"00",x"18",x"00",x"00",x"00",x"00",x"00",
			bmp_imgsize(7 downto 0),bmp_imgsize(15 downto 8),bmp_imgsize(23 downto 16),bmp_imgsize(31 downto 24),
			x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
		);
        variable y : integer;
	begin
		file_open(f, name&"_"&integer'image(count)&".bmp",WRITE_MODE);
		for i in 0 to bmp_header'length-1 loop
			write(f, character'val(to_integer(bmp_header(i))));
		end loop;
        for y_raw in hieght-1 downto 0 loop -- BMP origin is bottom left
            if interlaced then
                y := (y_raw/2);
                if y_raw mod 2 = 1 then
                    y := y+(hieght/2);
                end if;
            else
                y := y_raw;
            end if;
            for x in 0 to width-1 loop
                write(f, character'val(img(x,y)(2)));
                write(f, character'val(img(x,y)(1)));
                write(f, character'val(img(x,y)(0)));
            end loop;
        end loop;
	end procedure write_bmp;

    -------------------------------------------------------------------------------

end package body sim_video_out_pkg;

-------------------------------------------------------------------------------
-- end of file