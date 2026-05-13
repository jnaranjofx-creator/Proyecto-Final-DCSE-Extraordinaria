----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.12.2025 19:47:27
-- Design Name: 
-- Module Name: Freq_estimator - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Asumimos 12 bits para el ADC (0 a 4095)
entity Freq_Estimator is
    Port (
        -- Entradas de Reloj y Reset
        CLK_ADC       : in  STD_LOGIC;  -- Reloj de muestreo (ej. 20 MHz)
        RESET         : in  STD_LOGIC;
        
        -- Entrada de Dato
        ADC_SAMPLE_IN : in  STD_LOGIC_VECTOR(11 downto 0); -- Dato ADC (12 bits)
        
        -- Salida AXI (Resultado: Periodo T)
        PERIOD_OUT    : out STD_LOGIC_VECTOR(31 downto 0); -- Periodo en ciclos de CLK_ADC
        PERIOD_VLD    : out STD_LOGIC                      -- Dato de Periodo Válido (para AXI)
    );
end Freq_Estimator;

architecture Behavioral of Freq_Estimator is
    
    -- Constantes
    constant ZERO_LEVEL : natural := 2048; -- Punto central para un ADC de 12 bits
    
    -- Registros y Señales de Estado
    signal s_cnt_period : unsigned(31 downto 0) := (others => '0'); -- Contador de Periodo (T)
    signal s_period_reg : unsigned(31 downto 0) := (others => '0'); -- Registro final del Periodo
    
    -- Detección de Cruce por Cero (ZCD)
    -- s_sample_above: '1' si la muestra actual es >= 2048
    -- s_last_above: '1' si la muestra ANTERIOR era >= 2048
    signal s_sample_above : std_logic;
    signal s_last_above   : std_logic := '0';
    signal s_zero_cross   : std_logic := '0';

begin
    
    -- Asignación de Nivel Actual (Combinacional)
    -- Si la muestra actual está por encima o igual al nivel cero (2048)
    s_sample_above <= '1' when unsigned(ADC_SAMPLE_IN) >= ZERO_LEVEL else '0';
    
    -- Lógica Síncrona (Sensible al reloj ADC)
    process(CLK_ADC, RESET)
    begin
        if RESET = '0' then
            s_cnt_period <= (others => '0');
            s_period_reg <= (others => '0');
            s_last_above <= '0';
            PERIOD_VLD <= '0';
            
        elsif rising_edge(CLK_ADC) then
            
            -- Latch de la muestra anterior
            s_last_above <= s_sample_above;
            
            -- 1. DETECTOR DE CRUCE POR CERO (De Negativo a Positivo)
            -- Detecta la transición de estar ABAJO (s_last_above='0') a estar ARRIBA (s_sample_above='1')
            if s_last_above = '0' and s_sample_above = '1' then
                s_zero_cross <= '1';
            else
                s_zero_cross <= '0';
            end if;
            
            -- 2. LÓGICA DEL CONTADOR
            if s_zero_cross = '1' then
                -- Si detectamos un cruce, el periodo T ha terminado:
                s_period_reg <= s_cnt_period; -- Guardamos el valor medido
                s_cnt_period <= (others => '0'); -- Reseteamos el contador para empezar el siguiente ciclo
                PERIOD_VLD <= '1'; -- Marcamos que hay un nuevo Periodo Válido
            else
                -- Si no hay cruce, seguimos contando el tiempo
                s_cnt_period <= s_cnt_period + 1;
                PERIOD_VLD <= '0'; -- El dato anterior ya no es nuevo
            end if;

        end if;
    end process;

    -- Conexión de Salida
    PERIOD_OUT <= std_logic_vector(s_period_reg);

end Behavioral;
