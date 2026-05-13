----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2025 19:43:36
-- Design Name: 
-- Module Name: ADC_Controller - Behavioral
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

entity ADC_Controller is
generic (
        DIVISOR: integer := 5
);
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
end ADC_Controller;

architecture Behavioral of ADC_Controller is

    -- 1. ESTADOS DEL DIBUJO
    type state_type is (HOLD, FPORCH, SHIFTING, BPORCH);
    signal e_act, e_sig : state_type;
    
    signal sg_start : std_logic := '0';
    signal data_ready : std_logic;
    
    signal cuenta_5ticks: unsigned(2 downto 0);
    signal stop5 : std_logic;
    signal VAL_FCUENTA_5tick: integer := 4;   -- 100MHz / 5 = 20MHz
    -- 2. VARIABLES DEL DIBUJO (Contadores)
    -- "cnt": Usado en FPORCH (<3) y BPORCH (<1)
    signal cnt_sg : unsigned (31 downto 0);
    signal en_cnt : std_logic; 
    signal en_shift : std_logic; 
    
    -- "cntData": Usado en SHIFTING (<16)
    signal cntData : unsigned (31 downto 0);


    signal shift_reg : std_logic_vector(15 downto 0); -- Para guardar lo que entra
    signal sclk_int  : std_logic; -- Copia interna de SCLK

    -- Prescaler: Necesario para que "SCLK Activo" vaya a velocidad humana (10 MHz)
    -- 100MHz / 10MHz = 10 ciclos (5 arriba, 5 abajo)
    
    signal s_clk_100: std_logic;
    signal s_clk_25: std_logic;
    signal s_clk_20: std_logic;
    
    signal count_div_8   : unsigned (6 downto 0);
    signal count_div_10   : unsigned (8 downto 0);
   
    signal fcntData      : std_logic := '0'; -- Permiso para mover SCLK
    signal data_out_sg : STD_LOGIC_VECTOR(11 downto 0);
    signal data_out_uns: unsigned(11 downto 0); 
    
    signal data_ADC_anterior: unsigned(11 downto 0):= (others => '0'); 
    signal conta_periodo: unsigned(15 downto 0) := (others => '0');
    signal registro_periodo: unsigned(15 downto 0) := (others => '0');
    
    signal max_reg_current: unsigned(11 downto 0) := (others => '0'); -- Registro del máximo actual
    signal min_reg_current: unsigned(11 downto 0) := (others => '0');
    constant CRUCE_THRESHOLD: unsigned(11 downto 0) := to_unsigned( 2047, 12);

    

begin
    -- vatiables de control del ILA
    debug_start_s <= sg_start;
    debug_state <= "00" when e_act = HOLD else
                   "01" when e_act = FPORCH else
                   "10" when e_act =  SHIFTING else
                   "11" when e_act = BPORCH;


    -- Conectar señal interna a salida física
    DRDY <= data_ready;
    Data_Out <= data_out_sg;
    -- Asignar las señales internas a los puertos de salida

    clk_20  <= s_clk_20;
    -- Prescaler
    P_conta_5: process(clk_100, reset)
begin
    if reset = '0' then               
       cuenta_5ticks <= (others => '0');
       s_clk_20 <= '0';
    elsif rising_edge(clk_100) then 
        -- Contador del 0 al 4 (5 estados total = 50ns)
        if cuenta_5ticks = 4 then                        
            cuenta_5ticks <= (others => '0');
            s_clk_20 <= '1'; -- Pulso de subida al reiniciar
        else                                 
            cuenta_5ticks <= cuenta_5ticks + 1;
            
            -- Para que sea lo más parecido a una onda cuadrada:
            -- 2 ticks en alto (20ns), 3 ticks en bajo (30ns) = 50ns total
            if cuenta_5ticks = 1 then 
                s_clk_20 <= '0';
            end if;
        end if; 
    end if;
end process;

clk_20 <= s_clk_20;

    -- MÁQUINA DE ESTADOS 
   FSM_P: process(clk_100, RESET)
    begin
    
        if RESET = '0' then
            e_act    <= HOLD;
        elsif rising_edge(clk_100) then
            e_act <= e_sig;                  
        end if;
        end process;
   
        
    cnt_proces: process(clk_100,reset)
    begin
    if reset = '0' then 
        cnt_sg <= (others => '0');
        elsif rising_edge(clk_100)then
            if en_cnt = '1'then
--                cnt_sg <= (others => '0');
             if cnt_sg < 9 then
                cnt_sg <= cnt_sg + 1;
             end if;
             else 
                cnt_sg <= (others => '0');           
         end if;
    end if;
    end process;    
        
 cnt <= std_logic_vector(cnt_sg);   

--    shift_register2 : process (clk_100,reset,s_clk_20)
--    begin
--        if rising_edge(s_clk_20) then
--            if en_shift = '1' then
--                shift_reg <= shift_reg(14 downto 0) & MISO;                    
--                cntData   <= cntData + 1;  
--            else 
--                shift_reg(15 downto 12) <= (others => '0');
--                cntData <= (others => '0'); 
--            end if; 
--        end if;
--        if rising_edge(clk_100) then
--                if en_shift = '0' then
--                    shift_reg(15 downto 12) <= (others => '0');
--                    cntData <= (others => '0');
--                end if;         
--  end if;
--    end process;
--       fcntData <= '1' when cntData =16 else '0';
--       SCLK <= s_clk_20 when en_shift = '1' else '1';
     shift_register : process (s_clk_20,reset,clk_100)
    begin
    if reset = '0' then
        shift_reg <= (others => '0');
        cntData <= (others => '0');
        sclk_int <= '1';       
       elsif rising_edge(s_clk_20) then 
            if en_shift = '1' then    
             shift_reg <= shift_reg(14 downto 0) & MISO;
             cntData   <= cntData + 1; -- Incrementamos cntData
                if fcntData = '1' then
                    cntData <= (others => '0');
                else
                sclk_int <= not sclk_int; -- Genera la onda cuadrada
                    
                    -- Leer dato en flanco de subida (cuando sclk pasa de 0 a 1)
                    end if;
              else   
                cntData <= (others => '0');
            end if;
       end if;      
       end process;   
       
       fcntData <= '1' when cntData =16 else '0';
       --SCLK <= sclk_int;
       SCLK <= s_clk_20 when en_shift = '1';      
       debug_cntData <= std_logic_vector(cntData);
           START_bucle: process(reset, CLK_100)
        begin
            if reset = '0' then 
                sg_START <= '0';
            elsif rising_edge(CLK_100) then
                if Start = '1' or data_ready = '1' then
                    sg_START <= '1';
                else
                    sg_START <= '0';
                end if;
            end if;
    end process;
       
        FSM: process(e_act,e_sig,cnt_sg,sg_start,cntData)
        begin
        
         e_Sig <= e_act;
        case e_act is
                
                -- ---------------------------------------------------
                -- BURBUJA 1: HOLD
                -- Salidas: CS='1', DRDY='0', SCLK=Desh
                -- ---------------------------------------------------
                when HOLD =>
                    CS       <= '1';
--                    sclk_int <= '1'; -- Deshabilitado (Alto)
--                    cnt_sg   <= (others => '0');   -- Preparamos contadores a 0
--                    cntData  <= (others => '0');
                    en_cnt <= '0';
                    en_shift <= '0';
                    Data_ready <= '0';
                    
                    -- Transición: Start = '1' --> FPORCH
                    if sg_Start = '1' then
                        e_sig <= FPORCH;
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 2: FPORCH
                -- Salidas: CS='0', DRDY='0', SCLK=Desh
                -- ---------------------------------------------------
                when FPORCH =>
                    CS <= '0';
                    en_cnt <= '1';
                    en_shift <= '0';
                    Data_ready <= '0';
                    -- Condición: cnt < 3 T100MHz
                    if cnt_sg = "10" then
                        -- Transición: cnt = 3 --> SHIFTING
                        e_sig <= SHIFTING;                       
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 3: SHIFTING
                -- Salidas: CS='0', DRDY='0', SCLK=Activo
                -- ---------------------------------------------------
                when SHIFTING =>
                    CS <= '0';
                    en_cnt <= '0';
                    en_shift <= '1';                   
                    Data_ready <= '0';
                    -- Lógica de "SCLK Activo" (usando el tick del prescaler)


                    -- Condición de Salida del dibujo: cntData = 16 --> BPORCH
                    if cntData = 16 then
                        e_sig <= BPORCH;                        
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 4: BPORCH
                -- Salidas: CS='0', DRDY='1', SCLK=Desh
                -- ---------------------------------------------------
                when BPORCH =>
                    CS       <= '0';
--                    sclk_int <= '1'; -- Deshabilitado
                    en_cnt <= '1';
                    en_shift <= '0';
                    Data_ready     <= '1'; -- ¡Salida activa según tabla!
                    -- Condición: cnt < 1 T100MHz
                    if cnt_sg = "00" then
                        -- Transición: cnt = 1 --> HOLD
                        e_sig    <= HOLD;
                        data_out_sg <= shift_reg(11 downto 0);
                    end if;

            end case;
           
    end process;
data_out_uns <= unsigned(data_out_sg);

 MAXIMO: process(CLK_100, reset)
        begin
            if reset = '0' then                
                max_reg_current <= (others => '0');                
            elsif rising_edge(CLK_100) then
                if data_ready = '1' and data_out_uns > max_reg_current then 
                    max_reg_current <= data_out_uns;     -- MÁXIMO
                end if;                
            end if;
    end process;
    
    max(11 downto 0) <= std_logic_vector(max_reg_current);
    max(31 downto 12) <= (others =>'0'); 

FREQUENCIA: process(CLK_100, reset)
        begin
            if reset = '0' then                
                data_ADC_anterior <= (others => '0');
                conta_periodo <= (others => '0');
                registro_periodo <= (others => '0');
            elsif rising_edge(CLK_100) then 
                conta_periodo <= conta_periodo + 1;
                if data_ready = '1' then                                                   
                    if data_out_uns >= CRUCE_THRESHOLD and data_ADC_anterior < CRUCE_THRESHOLD then
                        registro_periodo <= conta_periodo;
                        conta_periodo <= (others => '0');
                    end if;
                    data_ADC_anterior <= data_out_uns;
                end if;
            end if;
    end process;
    frec(15 downto 0) <= std_logic_vector(registro_periodo);
    frec(31 downto 16) <= (others =>'0');
    MINIMO: process(CLK_100, reset)
        begin
            if reset = '0' then                
                min_reg_current <= (others => '1'); -- Como siempre será > 0 la onda, se inicializa en vez de a 0 al valor máximo                 
            elsif rising_edge(CLK_100) then
                if data_ready = '1' and data_out_uns < min_reg_current then 
                    min_reg_current <= data_out_uns;     -- MÍNIMO
                end if;                
            end if;
    end process;

    min(11 downto 0) <= std_logic_vector(min_reg_current);
    min(31 downto 12) <= (others =>'0');
     
end Behavioral;
     
