
-----------------------------------------------------------------------------
-- NoCem -- Network on Chip Emulation Tool for System on Chip Research 
-- and Implementations
-- 
-- Copyright (C) 2006  Graham Schelle, Dirk Grunwald
-- 
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
-- 02110-1301, USA.
-- 
-- The authors can be contacted by email: <schelleg,grunwald>@cs.colorado.edu 
-- 
-- or by mail: Campus Box 430, Department of Computer Science,
-- University of Colorado at Boulder, Boulder, Colorado 80309
-------------------------------------------------------------------------------- 


-- 
-- Filename: vc_buffer.vhd
-- 
-- Description: vc FIFO buffer with extra signalling
-- 



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.pkg_nocem.all;

entity vc_buffer is
    Port ( 
	 
	 		  vc_mux_wr : in std_logic_vector(NOCEM_NUM_VC-1 downto 0);
	 		  vc_mux_rd : in std_logic_vector(NOCEM_NUM_VC-1 downto 0);

           wr_pkt_cntrl : in std_logic_vector(NOCEM_PKT_CNTRL_WIDTH-1 downto 0);
           wr_pkt_data  : in std_logic_vector(NOCEM_DW-1 downto 0);

           rd_pkt_cntrl : out std_logic_vector(NOCEM_PKT_CNTRL_WIDTH-1 downto 0);
           rd_pkt_data  : out std_logic_vector(NOCEM_DW-1 downto 0);

           WE : in std_logic;
           RE : in std_logic;

           vc_credit : out std_logic_vector(NOCEM_NUM_VC-1 downto 0);
           vc_credit_valid : out std_logic;

           clk : in std_logic;			  
	 		  rst : in std_logic			  
			  );
end vc_buffer;

architecture Behavioral of vc_buffer is

   signal fifo_wr_en  		: std_logic_vector(NOCEM_NUM_VC-1 downto 0);
   signal fifo_rd_en   		: std_logic_vector(NOCEM_NUM_VC-1 downto 0);
   signal datain_pad,dataout_pad : std_logic_vector(255 downto 0);

   type array256 is array(natural range <>) of std_logic_vector(255 downto 0);
   signal fifo_rd_data : array256(NOCEM_NUM_VC-1 downto 0);

begin

      --FIFO data format: (255) pad,pkt_cntrl,pkt_data (0)
     	datain_pad(255 downto NOCEM_DW+NOCEM_PKT_CNTRL_WIDTH) <= (others => '0');
		datain_pad(NOCEM_DW+NOCEM_PKT_CNTRL_WIDTH-1 downto NOCEM_DW) <= wr_pkt_cntrl;
      datain_pad(NOCEM_DW-1 downto 0) <= wr_pkt_data;





read_sel : process (vc_mux_rd,fifo_rd_data,rst,RE, vc_mux_wr, WE, dataout_pad)
begin

	rd_pkt_data  <= (others => '0');
   rd_pkt_cntrl <= (others => '0');
   vc_credit <= (others => '0');
   vc_credit_valid <= '0';

	if rst = '1' then
      null;
	else

      -- do correct crediting
      if RE='1' then
         vc_credit <= vc_mux_rd;
         vc_credit_valid <= '1';
      end if;

      -- push dataout from the correct fifo
		l1: for I in NOCEM_NUM_VC-1 downto 0 loop

   	   fifo_wr_en(I) <= vc_mux_wr(I) and WE;
   	   fifo_rd_en(I) <= vc_mux_rd(I) and RE;

			if vc_mux_rd(I) = '1' then
				dataout_pad  <= fifo_rd_data(I);						
			end if;         	
		end loop;

      -- breakout the padded dataout lines
      rd_pkt_cntrl <=	dataout_pad(NOCEM_DW+NOCEM_PKT_CNTRL_WIDTH-1 downto NOCEM_DW);
		rd_pkt_data  <=	dataout_pad(NOCEM_DW-1 downto 0);

	end if;

end process;




   g1: for I in NOCEM_NUM_VC-1 downto 0 generate





   	I_vc : fifo_allvhdl PORT MAP(
   		din => datain_pad,
   		clk => clk,
   		rd_en => fifo_rd_en(I),
   		rst => rst,
   		wr_en => fifo_wr_en(I),
   		dout => fifo_rd_data(I),
   		empty => open,
   		full => 	open
   	);



  end generate;

end Behavioral;
