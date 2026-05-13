----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.11.2025 17:20:29
-- Design Name: 
-- Module Name: tb_ADC_controller - Behavioral
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ADC_Controller is
end tb_ADC_Controller;

architecture Behavioral of tb_ADC_Controller is

    -- 1. Declaramos tu diseño (El que acabamos de hacer)
    component ADC_Controller
    Port (
        clk_100      : in STD_LOGIC;
        RESET    : in STD_LOGIC;
        MISO     : in STD_LOGIC;
        Start    : in STD_LOGIC;
        CS       : out STD_LOGIC;
        SCLK     : out STD_LOGIC;
        DRDY     : out STD_LOGIC;
        Data_Out : out STD_LOGIC_VECTOR(11 downto 0)
    );
    end component;

    -- 2. Cables para conectar
    signal clk_100 , reset, start, miso : std_logic := '0';
    signal cs, sclk, drdy : std_logic;
    signal data_out : std_logic_vector(11 downto 0);

begin

    -- 3. Conectamos los cables a tu diseño
    uut: ADC_Controller Port map (
        clk_100  => clk_100 , RESET => reset, MISO => miso, Start => start,
        CS => cs, SCLK => sclk, DRDY => drdy, Data_Out => data_out
    );

    -- 4. Generador de Reloj (100 MHz -> 10 ns)
    process begin
        clk_100  <= '0'; wait for 5 ns;
        clk_100 <= '1'; wait for 5 ns;
    end process;

    -- 5. SIMULADOR DE ADC "INTELIGENTE" (Generador de Rampa Triangular)
    process
        variable v_dato_rampa : integer range 0 to 4095 := 0;
        variable v_subiendo   : boolean := true;
        variable v_vector_16  : std_logic_vector(15 downto 0);
    begin
        -- Esperamos a que CS baje (el controlador pide datos)
        wait until falling_edge(cs); 
        
        -- Preparamos el dato de 12 bits en un vector de 16 (rellenando ceros/ceros)
        -- Ajusta según cómo lea tu protocolo (si los 12 bits son los primeros o últimos)
        v_vector_16 := "0000" & std_logic_vector(to_unsigned(v_dato_rampa, 12));

        -- Enviamos los 16 bits serializados por MISO
        for i in 15 downto 0 loop
            miso <= v_vector_16(i);
            wait until falling_edge(sclk); 
        end loop;
        
        miso <= '0'; 

        -- Lógica de la rampa: calculamos el valor para la PRÓXIMA vez que baje CS
        if v_subiendo then
            v_dato_rampa := v_dato_rampa + 100; -- Incremento grande para ver cambios rápido
            if v_dato_rampa >= 4000 then v_subiendo := false; end if;
        else
            v_dato_rampa := v_dato_rampa - 100;
            if v_dato_rampa <= 500 then v_subiendo := true; end if;
        end if;
    end process;

    -- 6. EL GUIÓN DE LA PRUEBA (Múltiples capturas para probar Max/Min/Frec)
    process
    begin
        -- Reset inicial
        reset <= '0';
        start <= '0';
        wait for 100 ns;
        reset <= '1';
        wait for 100 ns;

        -- Hacemos 20 capturas automáticas
        for j in 1 to 20 loop
            start <= '1';
            wait for 20 ns;
            start <= '0';
            
            -- Esperamos a que el controlador termine esta muestra
            wait until drdy = '1';
            wait for 200 ns; -- Pausa entre muestras
        end loop;

        wait; -- Fin de la simulación
    end process;
end Behavioral;

