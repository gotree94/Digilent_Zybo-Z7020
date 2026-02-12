// main.c
// Vitis audio processing application
// Zybo Z7-20 with SSM2603

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiicps.h"

int main()
{
    init_platform();
    
    xil_printf("\r\n=== Zybo Z7-20 Audio Demo ===\r\n");
    xil_printf("Initializing audio codec...\r\n");
    
    // Audio processing loop
    while (1) {
        // Process audio with effects
    }
    
    cleanup_platform();
    return 0;
}
