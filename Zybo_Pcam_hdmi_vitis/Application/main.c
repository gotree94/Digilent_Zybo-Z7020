/**
 * @file main.c
 * @brief PCAM5C HDMI Output Application for Zynq Z7-20
 *
 * This application demonstrates camera video streaming from OV5640
 * sensor to HDMI output via MIPI CSI-2 interface.
 *
 * Hardware Requirements:
 * - Digilent Zybo Z7-20 board
 * - Digilent PCAM5C camera module
 * - HDMI display (1080p capable)
 *
 * Build Requirements:
 * - Xilinx Vitis 2022.x or later
 * - Hardware design with MIPI D-PHY, CSI-2, VDMA, and RGB2DVI IPs
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "xiicps.h"
#include "xaxivdma.h"
#include "xscugic.h"
#include "sleep.h"

#include "ov5640.h"
#include "video_display.h"

/*===========================================================================*/
/* Hardware Definitions (from xparameters.h)                                 */
/*===========================================================================*/

/* Adjust these based on your actual xparameters.h */
#ifndef XPAR_AXI_GPIO_0_BASEADDR
#define XPAR_AXI_GPIO_0_BASEADDR    0x41200000
#endif

#ifndef XPAR_PS7_I2C_0_DEVICE_ID
#define XPAR_PS7_I2C_0_DEVICE_ID    XPAR_XIICPS_0_DEVICE_ID
#endif

#ifndef XPAR_AXI_VDMA_0_DEVICE_ID
#define XPAR_AXI_VDMA_0_DEVICE_ID   0
#endif

#ifndef XPAR_AXI_VDMA_1_DEVICE_ID
#define XPAR_AXI_VDMA_1_DEVICE_ID   1
#endif

/* MIPI D-PHY and CSI-2 Base Addresses */
#define MIPI_D_PHY_BASEADDR         0x43C00000
#define MIPI_CSI2_BASEADDR          0x43C10000

/* Demosaic and Gamma LUT Base Addresses */
#define V_DEMOSAIC_BASEADDR         0x43C10000
#define V_GAMMA_LUT_BASEADDR        0x43C20000

/*===========================================================================*/
/* Application Configuration                                                 */
/*===========================================================================*/

#define VIDEO_WIDTH                 1920
#define VIDEO_HEIGHT                1080
#define VIDEO_BPP                   4       /* Bytes per pixel (RGBA) */

#define I2C_SCLK_RATE               100000  /* 100 KHz I2C clock */

/* Camera GPIO Control */
#define CAM_GPIO_CHANNEL            1
#define CAM_GPIO_POWER_EN           0x01

/*===========================================================================*/
/* Global Variables                                                          */
/*===========================================================================*/

static XGpio Gpio;
static XIicPs IicPs;
static XAxiVdma VdmaWrite;
static XAxiVdma VdmaRead;
static XScuGic Intc;

static OV5640_Config CameraConfig;
static VideoDisplay_Config DisplayConfig;

/*===========================================================================*/
/* MIPI/CSI-2 Register Access                                                */
/*===========================================================================*/

#define MIPI_DPHY_CR_OFFSET         0x00
#define MIPI_DPHY_SR_OFFSET         0x04
#define MIPI_CSI2_CR_OFFSET         0x00
#define MIPI_CSI2_SR_OFFSET         0x04

#define CR_ENABLE_MASK              0x01
#define CR_RESET_MASK               0x02

static void MIPI_WriteReg(u32 BaseAddr, u32 Offset, u32 Value)
{
    Xil_Out32(BaseAddr + Offset, Value);
}

static u32 MIPI_ReadReg(u32 BaseAddr, u32 Offset)
{
    return Xil_In32(BaseAddr + Offset);
}

/*===========================================================================*/
/* Initialization Functions                                                  */
/*===========================================================================*/

static int InitGpio(void)
{
    int Status;
    XGpio_Config *GpioConfig;

    /* Initialize GPIO for camera power control */
    GpioConfig = XGpio_LookupConfig(XPAR_AXI_GPIO_0_DEVICE_ID);
    if (GpioConfig == NULL) {
        xil_printf("GPIO: Config lookup failed\r\n");
        return XST_FAILURE;
    }

    Status = XGpio_CfgInitialize(&Gpio, GpioConfig, GpioConfig->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("GPIO: Initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Set GPIO direction (output) */
    XGpio_SetDataDirection(&Gpio, CAM_GPIO_CHANNEL, 0x00);

    xil_printf("GPIO: Initialized\r\n");
    return XST_SUCCESS;
}

static int InitI2C(void)
{
    int Status;
    XIicPs_Config *IicConfig;

    /* Initialize I2C for camera control */
    IicConfig = XIicPs_LookupConfig(XPAR_PS7_I2C_0_DEVICE_ID);
    if (IicConfig == NULL) {
        xil_printf("I2C: Config lookup failed\r\n");
        return XST_FAILURE;
    }

    Status = XIicPs_CfgInitialize(&IicPs, IicConfig, IicConfig->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C: Initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Self test */
    Status = XIicPs_SelfTest(&IicPs);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C: Self test failed\r\n");
        return XST_FAILURE;
    }

    /* Set I2C clock rate */
    Status = XIicPs_SetSClk(&IicPs, I2C_SCLK_RATE);
    if (Status != XST_SUCCESS) {
        xil_printf("I2C: Set clock rate failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("I2C: Initialized at %d Hz\r\n", I2C_SCLK_RATE);
    return XST_SUCCESS;
}

static int InitVDMA(void)
{
    int Status;
    XAxiVdma_Config *VdmaConfig;

    /* Initialize Write VDMA (Camera -> DDR) */
    VdmaConfig = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_0_DEVICE_ID);
    if (VdmaConfig == NULL) {
        xil_printf("VDMA Write: Config lookup failed\r\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_CfgInitialize(&VdmaWrite, VdmaConfig, VdmaConfig->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA Write: Initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Initialize Read VDMA (DDR -> Display) */
    VdmaConfig = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_1_DEVICE_ID);
    if (VdmaConfig == NULL) {
        xil_printf("VDMA Read: Config lookup failed\r\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_CfgInitialize(&VdmaRead, VdmaConfig, VdmaConfig->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA Read: Initialization failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("VDMA: Initialized\r\n");
    return XST_SUCCESS;
}

static void CameraPowerOn(void)
{
    /* Enable camera power */
    XGpio_DiscreteWrite(&Gpio, CAM_GPIO_CHANNEL, CAM_GPIO_POWER_EN);
    usleep(100000);  /* Wait 100ms for power stabilization */
    xil_printf("Camera: Power ON\r\n");
}

static void CameraPowerOff(void)
{
    /* Disable camera power */
    XGpio_DiscreteWrite(&Gpio, CAM_GPIO_CHANNEL, 0x00);
    xil_printf("Camera: Power OFF\r\n");
}

static int InitMIPI(void)
{
    /* Reset MIPI D-PHY and CSI-2 */
    MIPI_WriteReg(MIPI_D_PHY_BASEADDR, MIPI_DPHY_CR_OFFSET,
                  CR_RESET_MASK & ~CR_ENABLE_MASK);
    MIPI_WriteReg(MIPI_CSI2_BASEADDR, MIPI_CSI2_CR_OFFSET,
                  CR_RESET_MASK & ~CR_ENABLE_MASK);

    usleep(1000);

    /* Enable MIPI D-PHY */
    MIPI_WriteReg(MIPI_D_PHY_BASEADDR, MIPI_DPHY_CR_OFFSET, CR_ENABLE_MASK);
    usleep(1000);

    /* Enable CSI-2 */
    MIPI_WriteReg(MIPI_CSI2_BASEADDR, MIPI_CSI2_CR_OFFSET, CR_ENABLE_MASK);
    usleep(1000);

    xil_printf("MIPI: D-PHY and CSI-2 enabled\r\n");
    return XST_SUCCESS;
}

static void ConfigureVideoProcessing(void)
{
    /* Configure Demosaic */
    Xil_Out32(V_DEMOSAIC_BASEADDR + 0x10, VIDEO_WIDTH);   /* Width */
    Xil_Out32(V_DEMOSAIC_BASEADDR + 0x18, VIDEO_HEIGHT);  /* Height */
    Xil_Out32(V_DEMOSAIC_BASEADDR + 0x00, 0x81);          /* Enable, auto-restart */

    /* Configure Gamma LUT (gamma = 1/1.8 for typical display) */
    Xil_Out32(V_GAMMA_LUT_BASEADDR + 0x10, VIDEO_WIDTH);
    Xil_Out32(V_GAMMA_LUT_BASEADDR + 0x18, VIDEO_HEIGHT);
    Xil_Out32(V_GAMMA_LUT_BASEADDR + 0x20, 3);            /* Gamma factor select */
    Xil_Out32(V_GAMMA_LUT_BASEADDR + 0x00, 0x81);

    xil_printf("Video Processing: Demosaic and Gamma configured\r\n");
}

/*===========================================================================*/
/* Menu Interface                                                            */
/*===========================================================================*/

static void PrintMenu(void)
{
    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf("  PCAM5C HDMI Output - Zybo Z7-20\r\n");
    xil_printf("========================================\r\n");
    xil_printf("  1. Start video streaming\r\n");
    xil_printf("  2. Stop video streaming\r\n");
    xil_printf("  3. Switch to 720p @ 60fps\r\n");
    xil_printf("  4. Switch to 1080p @ 30fps\r\n");
    xil_printf("  5. Enable test pattern\r\n");
    xil_printf("  6. Disable test pattern\r\n");
    xil_printf("  7. Display test pattern (SW)\r\n");
    xil_printf("  8. Print status\r\n");
    xil_printf("  9. Reset camera\r\n");
    xil_printf("  0. Exit\r\n");
    xil_printf("========================================\r\n");
    xil_printf("Select option: ");
}

static void ProcessCommand(char Cmd)
{
    int Status;

    switch (Cmd) {
        case '1':  /* Start streaming */
            xil_printf("\r\nStarting video streaming...\r\n");
            Status = VideoDisplay_Configure(&DisplayConfig);
            if (Status == XST_SUCCESS) {
                VideoDisplay_Start(&DisplayConfig);
                OV5640_StreamOn(&CameraConfig);
            }
            break;

        case '2':  /* Stop streaming */
            xil_printf("\r\nStopping video streaming...\r\n");
            OV5640_StreamOff(&CameraConfig);
            VideoDisplay_Stop(&DisplayConfig);
            break;

        case '3':  /* 720p60 */
            xil_printf("\r\nSwitching to 720p @ 60fps...\r\n");
            OV5640_StreamOff(&CameraConfig);
            VideoDisplay_Stop(&DisplayConfig);
            OV5640_SetMode(&CameraConfig, OV5640_MODE_720P_60FPS);
            VideoDisplay_SetResolution(&DisplayConfig, 1280, 720);
            break;

        case '4':  /* 1080p30 */
            xil_printf("\r\nSwitching to 1080p @ 30fps...\r\n");
            OV5640_StreamOff(&CameraConfig);
            VideoDisplay_Stop(&DisplayConfig);
            OV5640_SetMode(&CameraConfig, OV5640_MODE_1080P_30FPS);
            VideoDisplay_SetResolution(&DisplayConfig, 1920, 1080);
            break;

        case '5':  /* Enable test pattern */
            xil_printf("\r\nEnabling camera test pattern...\r\n");
            OV5640_SetTestPattern(&CameraConfig, OV5640_TEST_PATTERN_COLOR_BAR);
            break;

        case '6':  /* Disable test pattern */
            xil_printf("\r\nDisabling camera test pattern...\r\n");
            OV5640_SetTestPattern(&CameraConfig, OV5640_TEST_PATTERN_OFF);
            break;

        case '7':  /* Software test pattern */
            xil_printf("\r\nDrawing software test pattern...\r\n");
            VideoDisplay_DrawTestPattern(&DisplayConfig, 0);
            break;

        case '8':  /* Print status */
            OV5640_PrintInfo(&CameraConfig);
            VideoDisplay_PrintStatus(&DisplayConfig);

            /* MIPI status */
            xil_printf("MIPI D-PHY Status: 0x%08X\r\n",
                       MIPI_ReadReg(MIPI_D_PHY_BASEADDR, MIPI_DPHY_SR_OFFSET));
            xil_printf("MIPI CSI-2 Status: 0x%08X\r\n",
                       MIPI_ReadReg(MIPI_CSI2_BASEADDR, MIPI_CSI2_SR_OFFSET));
            break;

        case '9':  /* Reset camera */
            xil_printf("\r\nResetting camera...\r\n");
            OV5640_Reset(&CameraConfig);
            usleep(100000);
            OV5640_SetMode(&CameraConfig, OV5640_MODE_1080P_30FPS);
            OV5640_SetFormat(&CameraConfig, OV5640_FORMAT_RAW10);
            break;

        case '0':  /* Exit */
            xil_printf("\r\nExiting...\r\n");
            OV5640_StreamOff(&CameraConfig);
            VideoDisplay_Stop(&DisplayConfig);
            CameraPowerOff();
            break;

        default:
            xil_printf("\r\nInvalid option\r\n");
            break;
    }
}

/*===========================================================================*/
/* Main Function                                                             */
/*===========================================================================*/

int main(void)
{
    int Status;
    char Cmd;

    /* Initialize cache */
    Xil_ICacheEnable();
    Xil_DCacheEnable();

    xil_printf("\r\n\r\n");
    xil_printf("========================================\r\n");
    xil_printf("  PCAM5C HDMI Output Application\r\n");
    xil_printf("  Zybo Z7-20 + OV5640\r\n");
    xil_printf("========================================\r\n\r\n");

    /* Initialize GPIO */
    Status = InitGpio();
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Power on camera */
    CameraPowerOn();

    /* Initialize I2C */
    Status = InitI2C();
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: I2C initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Initialize VDMA */
    Status = InitVDMA();
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: VDMA initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Initialize video display */
    Status = VideoDisplay_Init(&DisplayConfig, &VdmaWrite, &VdmaRead,
                               VIDEO_WIDTH, VIDEO_HEIGHT, VIDEO_BPP);
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: Video display initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Initialize OV5640 camera */
    Status = OV5640_Init(&CameraConfig, &IicPs);
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: Camera initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Initialize MIPI interface */
    Status = InitMIPI();
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: MIPI initialization failed\r\n");
        return XST_FAILURE;
    }

    /* Configure video processing pipeline */
    ConfigureVideoProcessing();

    /* Draw initial test pattern */
    VideoDisplay_DrawTestPattern(&DisplayConfig, 0);

    xil_printf("\r\nSystem initialization complete!\r\n");
    xil_printf("Connect HDMI display and press any key to continue...\r\n\r\n");

    /* Main loop */
    while (1) {
        PrintMenu();

        /* Wait for user input */
        Cmd = inbyte();
        xil_printf("%c\r\n", Cmd);

        if (Cmd == '0') {
            break;
        }

        ProcessCommand(Cmd);
    }

    xil_printf("\r\nApplication terminated.\r\n");

    /* Disable cache */
    Xil_DCacheDisable();
    Xil_ICacheDisable();

    return XST_SUCCESS;
}
