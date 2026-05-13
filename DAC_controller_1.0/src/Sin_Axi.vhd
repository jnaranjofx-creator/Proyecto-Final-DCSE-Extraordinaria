----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.11.2025 13:26:06
-- Design Name: 
-- Module Name: Sin_Axi - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Sin_Axi is
generic (
        ADDR_WIDTH : integer := 14;
        DATA_WIDTH : integer := 12
    );
    Port ( clk50    : in STD_LOGIC;
           nRST     : in STD_LOGIC;
           reg_start: in std_logic;
           D1       : out STD_LOGIC;
           nSync    : out STD_LOGIC;
           clk_out  : out STD_LOGIC;
           wr_en    : in STD_LOGIC;
           data_in  : in STD_LOGIC_VECTOR (data_width-1 downto 0);
           addr_wr  : in STD_LOGIC_VECTOR (addr_width-1 downto 0);
           
           debug_loaddata: out std_logic;
           debug_shiftcounter : out STD_LOGIC_VECTOR(3 downto 0);
           debug_state        : out STD_LOGIC_VECTOR(1 downto 0); 
           debug_start_int    : out STD_LOGIC);
end Sin_Axi;

architecture Behavioral of Sin_Axi is

    -- Señales internas
    signal START_sig   : std_logic;
    signal DONE_sig    : std_logic;
    signal addr_rd_sig : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal data_sig    : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    ------------------------------------------------------------------
    -- Instancia de AddrCtrl
    ------------------------------------------------------------------
    U_AddrCrtl : entity work.Addr_Ctrl
        generic map (ADDR_WIDTH => ADDR_WIDTH)
        port map (
            clk50   => clk50,
            nRST    => nRST,
            DONE    => DONE_sig,
            addr_rd => addr_rd_sig,
            START   => START_sig
        );

    ------------------------------------------------------------------
    -- Instancia de RAM
    ------------------------------------------------------------------
    U_RAM : entity work.RAM
        generic map (
            d_width   => DATA_WIDTH,
            addr_width => ADDR_WIDTH
        )
        port map (
            clk50  => clk50,
            wr_en   => wr_en,          -- lectura continua
            data_in => data_in,
            addr_wr => addr_wr,
            addr_rd => addr_rd_sig,
            data_out=> data_sig
        );

    ------------------------------------------------------------------
    -- Instancia del DAC Controller
    ------------------------------------------------------------------
    U_DAC : entity work.DAC_controller
        port map (
            Data1  => data_sig,
            start  => START_sig,
            reg_start => reg_start,
            nRST   => nRST,
            clk50  => clk50,
            D1     => D1,          -- salida al DAC (puede dejarse open)
            nSync  => nSync,
            Done   => DONE_sig,
            clk_out=> clk_out,
            debug_loaddata => debug_loaddata,
            debug_shiftcounter => debug_shiftcounter,
            debug_state => debug_state,
            debug_start_int => debug_start_int
        );

end architecture;
