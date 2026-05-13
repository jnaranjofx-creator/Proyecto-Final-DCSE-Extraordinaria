library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC_controller_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here
        MISO            : in  std_logic;
        clk_100         : in std_logic;
        CS              : out std_logic;
        SCLK            : out std_logic;
--        DRDY            : out STD_LOGIC;
        
--        debug_cnt       : out std_logic_vector(31 downto 0);
--        debug_clk_100   : out std_logic;
--        debug_clk_20    : out std_logic;
--        Data_Out  : out STD_LOGIC_VECTOR(11 downto 0);
--        debug_cntData : out std_logic_vector(31 downto 0);
--        debug_state : out STD_LOGIC_VECTOR(1 downto 0);
--        debug_start_s: out STD_LOGIC;
        
--        max : out std_logic_vector(31 downto 0); -- máximo
--        frec : out std_logic_vector(31 downto 0); -- frecuencia
--        min : out std_logic_vector(31 downto 0); -- minimo
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
end ADC_controller_v1_0;

architecture arch_imp of ADC_controller_v1_0 is

	-- component declaration
	component ADC_controller_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
        START     : out std_logic;
        
        data_out    : in  std_logic_vector(11 downto 0);            -- Dato Pararlelo del ADC
		max : in std_logic_vector(31 downto 0); -- máximo
        frec : in std_logic_vector(31 downto 0); -- frecuencia
        min : in std_logic_vector(31 downto 0); -- minimo
        
        
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
	end component ADC_controller_v1_0_S00_AXI;
component ADC_controller is
Port (
        CLK_100      : in  STD_LOGIC; -- Reloj 100MHz
        RESET    : in  STD_LOGIC;
        MISO     : in  STD_LOGIC; -- Entrada de datos del ADC
        
        -- Variables EXACTAS del dibujo (Entradas/Salidas)
        Start    : in  STD_LOGIC;
        CS       : out STD_LOGIC;
        SCLK     : out STD_LOGIC;
        DRDY     : out STD_LOGIC;
        cnt      : out std_logic_vector(31 downto 0);
        
        
        clk_20  : out std_logic;
        
        max : out std_logic_vector(31 downto 0); -- máximo
        frec : out std_logic_vector(31 downto 0); -- frecuencia
        min : out std_logic_vector(31 downto 0); -- minimo
        
        Data_Out : out STD_LOGIC_VECTOR(11 downto 0);
        debug_cntData : out std_logic_vector(31 downto 0);
        debug_cnt   : out std_logic_vector(31 downto 0);
        debug_state : out STD_LOGIC_VECTOR(1 downto 0);
        debug_start_s: out STD_LOGIC
    );
    end component ADC_Controller;

        signal start_s : std_logic;
        
        --signal addr_rd_s : std_logic_vector(13 downto 0);
        signal data_out_s : std_logic_vector(11 downto 0);
        
        signal max_s : std_logic_vector(31 downto 0);
        signal frec_s : std_logic_vector(31 downto 0);
        signal min_s : std_logic_vector(31 downto 0);
begin

-- Instantiation of Axi Bus Interface S00_AXI
ADC_controller_v1_0_S00_AXI_inst : ADC_controller_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    START => start_s,
        data_out => data_out_s,
        max => max_s,
        frec => frec_s,
        min => min_s,
	
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
I_ADC_Controller : entity work.ADC_Controller
        port map(
        CLK_100  => clk_100,
        RESET    => s00_axi_aresetn,
        MISO     => MISO,
        Start    => start_s,
        CS       => CS,
        SCLK     => SCLK,
--        DRDY     => DRDY,
        
--        -- CONEXIONES DE DEBUG (Asegúrate de conectarlas todas)
--        cnt      => debug_cnt,      -- Conecta al nuevo puerto de salida
----        clk_100  => debug_clk_100,  -- Conecta al nuevo puerto de salida
--        clk_20   => debug_clk_20,   -- Conecta al nuevo puerto de salida
        Data_Out => data_out_s,     -- Esta ya la tienes
        
        -- Cálculos
        max      => max_s,
        frec     => frec_s,
        min      => min_S
--        debug_cntData => debug_cntData,
--        debug_state        => debug_state,
--        debug_start_s    => debug_start_s
        );
	-- User logic ends
--    Data_Out <= data_out_s;
--    max  <= max_s;
--    frec <= frec_s;
--    min  <= min_s;
end arch_imp;
