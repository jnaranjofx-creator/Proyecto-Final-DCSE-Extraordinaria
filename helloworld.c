/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "sleep.h"
#include "DAC_controller.h"
#include "ADC_controller.h"

// Definiciones de direcciones
#define DAC_BASEADDR XPAR_DAC_CONTROLLER_0_S00_AXI_BASEADDR
#define ADC_BASEADDR XPAR_ADC_CONTROLLER_0_S00_AXI_BASEADDR

// Offsets de registros (Según tu diseño)
#define ADC_REG_DATA    0x04  // Registro 1
#define ADC_REG_MAX     0x10  // Registro 4
#define ADC_REG_FREQ    0x14  // Registro 5
#define ADC_REG_MIN     0x18  // Registro 6
// --- Parámetros de Calibración del ADC ---
#define ADC_BITS            12              // N = Número de bits del ADC
#define ADC_MAX_VAL         4095 // 2^12 - 1 = 4095
#define V_REF               3300            // Tensión de Referencia del ADC (¡CONFIRMA ESTE VALOR!)

int main() {
    init_platform();

    // --- 1. CARGA DE LUT DAC (Simplificada) ---
    xil_printf("Configurando DAC...\r\n");
    DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 0, 0); // wren off
    DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 12, 0); // start off

    for(int i = 0; i < 16384; i++) {
    	int j=i%4096;
        DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 4, j); // Datos (Rampa)
        DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 8, i); // Dirección
        DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 0, 1); // wren on
        DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 0, 0); // wren off
    }

    DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 12, 1); // Start DAC
    //DAC_CONTROLLER_mWriteReg(DAC_BASEADDR, 12, 0);
    xil_printf("DAC en marcha. Iniciando ADC...\r\n");

    // Variables de trabajo


                int acquisition_count = 0;
    		// Variables para las nuevas lecturas
    			u32 frequency_val;
    			u32 max_val;
    			u32 min_val;
    			int mean_val; // Usaremos un float para el promedio
    			// Nueva variable para la tensión
    			int voltage_val;
    			int data_adc;

    while(1) {

    	// A. DISPARO DEL ADC
    	        ADC_CONTROLLER_mWriteReg(ADC_BASEADDR, 0, 1);
    	        ADC_CONTROLLER_mWriteReg(ADC_BASEADDR, 0, 0);
    	        usleep(10);
    	 // A. Iniciar y Leer una Muestra (Mantenemos la adquisición individual)
    	                    //acquired_sample = read_single_sample();
    	        			data_adc = ADC_CONTROLLER_mReadReg(ADC_BASEADDR, ADC_REG_DATA) & 0x0FFF;

    	        			 // La frecuencia se lee del registro 5 (offset 0x14)
    	        			frequency_val = ADC_CONTROLLER_mReadReg(ADC_BASEADDR, ADC_REG_FREQ);

    	                    // El máximo se lee del registro 4 (offset 0x10)
    	                    max_val = ADC_CONTROLLER_mReadReg(ADC_BASEADDR, ADC_REG_MAX) & 0x0FFF; // 12 bits

    	                    // El mínimo se lee del registro 6 (offset 0x18)
    	                    min_val = ADC_CONTROLLER_mReadReg(ADC_BASEADDR, ADC_REG_MIN) & 0x0FFF; // 12 bits

    	                    // B. Lectura de los Registros de la IP (Frecuencia, Máximo y Mínimo)
    	                    voltage_val = (int)(((long long)data_adc * V_REF) / ADC_MAX_VAL);// tensión de la señal

    	                    // C. Cálculo del Valor Medio
    	                    // Aseguramos que la operación se realice con flotantes para obtener precisión
    	                    mean_val = (max_val + min_val) / 2.0;

    	                    // D. Imprimir el resultado (Información detallada)
    	                    xil_printf("--- Muestra #%d ---\r\n", acquisition_count++);

    	                    xil_printf("Dato Actual: %d  -> Tension: %d.%03d V\r\n",
    	                    					data_adc,
    	                                        voltage_val / 1000,
												voltage_val % 1000); // <-- LÍNEA MODIFICADA
    	                        xil_printf("Frecuencia (Hz): %u\r\n", frequency_val);
    	                        xil_printf("Valor Máximo: %u\r\n", max_val);
    	                        xil_printf("Valor Mínimo: %u\r\n", min_val);
    	                        xil_printf("Valor Medio (calc.): %.2d\r\n", mean_val);
    	                        xil_printf("-------------------\r\n");

        // E. RETARDO DE VISUALIZACIÓN
        // Si no pones esto, el Termite se colapsa. 1 segundo es ideal.
    	sleep(1);
    }

    cleanup_platform();
    return 0;
}
