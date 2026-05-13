library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DAC_controller_v1_0 is
	generic (
		-- Users to add parameters here
        ADDR_WIDTH : integer := 14;
        DATA_WIDTH : integer := 12;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
        nSync : out std_logic;
        D1 : out std_logic;
        clk_out : out std_logic;
        
--        debug_loaddata: out std_logic;
--        debug_shiftcounter : out STD_LOGIC_VECTOR(3 downto 0);
--        debug_state        : out STD_LOGIC_VECTOR(1 downto 0);
--        debug_start_int    : out STD_LOGIC;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end DAC_controller_v1_0;

architecture arch_imp of DAC_controller_v1_0 is

	-- component declaration
	component DAC_controller_v1_0_S00_AXI is
		generic (
		ADDR_WIDTH : integer := 14;
        DATA_WIDTH : integer := 12; 
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		reg_start : out std_logic;
        wr_en : out STD_LOGIC;
        data_in : out STD_LOGIC_VECTOR (data_width-1 downto 0);
        addr_wr : out STD_LOGIC_VECTOR (addr_width-1 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component DAC_controller_v1_0_S00_AXI;
component Sin_Axi is
generic (
        ADDR_WIDTH : integer := 14;
        DATA_WIDTH : integer := 12
    );
    Port ( clk50 : in STD_LOGIC;
           nRST : in STD_LOGIC;
           reg_start : in std_logic;
           D1 : out STD_LOGIC;
           nSync : out STD_LOGIC;
           clk_out : out STD_LOGIC;
           wr_en : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
           addr_wr : in STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
           debug_loaddata: out std_logic;
           debug_shiftcounter : out STD_LOGIC_VECTOR(3 downto 0);
           debug_state        : out STD_LOGIC_VECTOR(1 downto 0); 
           debug_start_int    : out STD_LOGIC);
end component Sin_Axi;
         
         signal reg_start_sg : std_logic;
         signal wr_en_sg : STD_LOGIC;
         signal data_in_sg : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
         signal addr_wr_sg : STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
         signal rst_internal : std_logic;
begin

-- Instantiation of Axi Bus Interface S00_AXI
DAC_controller_v1_0_S00_AXI_inst : DAC_controller_v1_0_S00_AXI
	generic map (
		ADDR_WIDTH => ADDR_WIDTH,
	    DATA_WIDTH => DATA_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		reg_start => reg_start_sg,
	    wr_en => wr_en_sg,
	    data_in => data_in_sg,
	    addr_wr => addr_wr_sg,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
rst_internal <= s00_axi_aresetn;
	-- Add user logic here
    I_Sin_Axi : entity work.Sin_Axi
    generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
    )
     port map(
        reg_start => reg_start_sg,
        wr_en => wr_en_sg,
        data_in => data_in_sg,
        addr_wr => addr_wr_sg,
        D1 => D1,
        nSync => nSync,
        clk_out => clk_out,
        clk50 => s00_axi_aclk,
        nrst => rst_internal
        
--        debug_loaddata => debug_loaddata,
--        debug_shiftcounter => debug_shiftcounter,
--        debug_state        => debug_state,
--         debug_start_int    => debug_start_int
        );
	-- User logic ends

end arch_imp;
