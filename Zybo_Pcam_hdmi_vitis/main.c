/*
 * main.c
 * Zynq Z7-20 PCAM5C HDMI Output Demo
 * 
 * This application captures video from PCAM5C camera and outputs to HDMI.
 */

#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "xiicps.h"
#include "xscugic.h"
#include "sleep.h"

#include "platform/platform_config.h"
#include "camera/ov5640.h"
#include "video/video_capture.h"
#include "video/video_display.h"

/* ============================================================================
 * Global Instances
 * ============================================================================ */

static XIicPs iic_inst;
static XGpio gpio_inst;
static XScuGic intc_inst;

static ov5640_inst_t camera;
static video_capture_inst_t capture;
static video_display_inst_t display;

/* ============================================================================
 * Function Prototypes
 * ============================================================================ */

static int init_platform(void);
static int init_iic(void);
static int init_gpio(void);
static int init_interrupts(void);
static int init_camera(void);
static int init_video_pipeline(void);
static void camera_power_on(void);
static void camera_power_off(void);
static void run_demo(void);
static void cleanup(void);

/* ============================================================================
 * Main Function
 * ============================================================================ */

int main(void)
{
    int status;
    
    xil_printf("\r\n");
    xil_printf("==============================================\r\n");
    xil_printf("  Zynq Z7-20 PCAM5C HDMI Output Demo\r\n");
    xil_printf("==============================================\r\n");
    xil_printf("\r\n");
    
    /* Initialize platform */
    status = init_platform();
    if (status != XST_SUCCESS) {
        xil_printf("Platform initialization failed!\r\n");
        return XST_FAILURE;
    }
    
    /* Initialize camera */
    status = init_camera();
    if (status != XST_SUCCESS) {
        xil_printf("Camera initialization failed!\r\n");
        cleanup();
        return XST_FAILURE;
    }
    
    /* Initialize video pipeline */
    status = init_video_pipeline();
    if (status != XST_SUCCESS) {
        xil_printf("Video pipeline initialization failed!\r\n");
        cleanup();
        return XST_FAILURE;
    }
    
    /* Run demo */
    run_demo();
    
    /* Cleanup */
    cleanup();
    
    xil_printf("Demo complete.\r\n");
    return XST_SUCCESS;
}

/* ============================================================================
 * Platform Initialization
 * ============================================================================ */

static int init_platform(void)
{
    int status;
    
    DEBUG_INFO("Initializing platform...\r\n");
    
    /* Initialize cache */
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    
    /* Initialize I2C */
    status = init_iic();
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("I2C initialization failed\r\n");
        return status;
    }
    
    /* Initialize GPIO */
    status = init_gpio();
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("GPIO initialization failed\r\n");
        return status;
    }
    
    /* Initialize interrupts */
    status = init_interrupts();
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("Interrupt initialization failed\r\n");
        return status;
    }
    
    DEBUG_INFO("Platform initialization complete\r\n");
    return XST_SUCCESS;
}

static int init_iic(void)
{
    XIicPs_Config *config;
    int status;
    
    config = XIicPs_LookupConfig(IIC_DEVICE_ID);
    if (!config) {
        return XST_FAILURE;
    }
    
    status = XIicPs_CfgInitialize(&iic_inst, config, config->BaseAddress);
    if (status != XST_SUCCESS) {
        return status;
    }
    
    /* Set I2C clock rate to 100kHz */
    status = XIicPs_SetSClk(&iic_inst, 100000);
    if (status != XST_SUCCESS) {
        return status;
    }
    
    DEBUG_INFO("  I2C initialized (100kHz)\r\n");
    return XST_SUCCESS;
}

static int init_gpio(void)
{
    int status;
    
    status = XGpio_Initialize(&gpio_inst, XPAR_AXI_GPIO_0_DEVICE_ID);
    if (status != XST_SUCCESS) {
        return status;
    }
    
    /* Set GPIO direction (output for camera power) */
    XGpio_SetDataDirection(&gpio_inst, CAM_PWR_GPIO_CHANNEL, 0x00);
    
    DEBUG_INFO("  GPIO initialized\r\n");
    return XST_SUCCESS;
}

static int init_interrupts(void)
{
    XScuGic_Config *config;
    int status;
    
    config = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (!config) {
        return XST_FAILURE;
    }
    
    status = XScuGic_CfgInitialize(&intc_inst, config, config->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        return status;
    }
    
    /* Enable interrupts in processor */
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XScuGic_InterruptHandler,
                                 &intc_inst);
    Xil_ExceptionEnable();
    
    DEBUG_INFO("  Interrupts initialized\r\n");
    return XST_SUCCESS;
}

/* ============================================================================
 * Camera Functions
 * ============================================================================ */

static void camera_power_on(void)
{
    DEBUG_INFO("Powering on camera...\r\n");
    
    /* Set camera power enable high */
    XGpio_DiscreteWrite(&gpio_inst, CAM_PWR_GPIO_CHANNEL, 0x01);
    
    /* Wait for power to stabilize */
    usleep(100000);  /* 100ms */
    
    DEBUG_INFO("  Camera power on\r\n");
}

static void camera_power_off(void)
{
    DEBUG_INFO("Powering off camera...\r\n");
    
    /* Set camera power enable low */
    XGpio_DiscreteWrite(&gpio_inst, CAM_PWR_GPIO_CHANNEL, 0x00);
    
    DEBUG_INFO("  Camera power off\r\n");
}

static int init_camera(void)
{
    ov5640_status_t status;
    ov5640_config_t config;
    
    DEBUG_INFO("Initializing camera...\r\n");
    
    /* Power on camera */
    camera_power_on();
    
    /* Initialize OV5640 */
    status = ov5640_init(&camera, &iic_inst, OV5640_I2C_ADDR);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("OV5640 initialization failed: %d\r\n", status);
        return XST_FAILURE;
    }
    
    /* Set 1080p30 mode */
    status = ov5640_set_mode(&camera, OV5640_MODE_1080P_30FPS);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("Failed to set camera mode\r\n");
        return XST_FAILURE;
    }
    
    /* Get configuration */
    ov5640_get_config(&camera, &config);
    xil_printf("  Camera configured: %dx%d @ %dfps\r\n",
              config.width, config.height, config.fps);
    
    return XST_SUCCESS;
}

/* ============================================================================
 * Video Pipeline Functions
 * ============================================================================ */

static int init_video_pipeline(void)
{
    video_capture_status_t cap_status;
    video_display_status_t disp_status;
    
    DEBUG_INFO("Initializing video pipeline...\r\n");
    
    /* Initialize video capture (camera input) */
    cap_status = video_capture_init(&capture,
                                    VDMA_WRITE_DEVICE_ID,
                                    VTC_DETECT_DEVICE_ID,
                                    FRAME_BUFFER_BASE);
    if (cap_status != VIDEO_CAPTURE_OK) {
        DEBUG_ERROR("Video capture initialization failed\r\n");
        return XST_FAILURE;
    }
    
    /* Configure capture for 1080p */
    cap_status = video_capture_configure(&capture,
                                         FRAME_WIDTH_1080P,
                                         FRAME_HEIGHT_1080P,
                                         BYTES_PER_PIXEL);
    if (cap_status != VIDEO_CAPTURE_OK) {
        DEBUG_ERROR("Video capture configuration failed\r\n");
        return XST_FAILURE;
    }
    
    /* Initialize video display (HDMI output) */
    /* Use different frame buffer region for display */
    u32 display_buffer_base = FRAME_BUFFER_BASE + 
                              (NUM_FRAME_BUFFERS * FRAME_BUFFER_SIZE);
    
    disp_status = video_display_init(&display,
                                     VDMA_READ_DEVICE_ID,
                                     VTC_GEN_DEVICE_ID,
                                     display_buffer_base);
    if (disp_status != VIDEO_DISPLAY_OK) {
        DEBUG_ERROR("Video display initialization failed\r\n");
        return XST_FAILURE;
    }
    
    /* Configure display for 1080p60 */
    disp_status = video_display_set_resolution(&display, VIDEO_DISPLAY_RES_1080P);
    if (disp_status != VIDEO_DISPLAY_OK) {
        DEBUG_ERROR("Video display configuration failed\r\n");
        return XST_FAILURE;
    }
    
    DEBUG_INFO("Video pipeline initialization complete\r\n");
    return XST_SUCCESS;
}

/* ============================================================================
 * Demo Application
 * ============================================================================ */

static void run_demo(void)
{
    ov5640_status_t cam_status;
    video_capture_status_t cap_status;
    video_display_status_t disp_status;
    u32 frame_count = 0;
    u32 last_count = 0;
    u32 fps_timer = 0;
    
    xil_printf("\r\n");
    xil_printf("Starting video streaming...\r\n");
    xil_printf("Press 'q' to quit, 'm' to change mode, 'h/v' for mirror/flip\r\n");
    xil_printf("\r\n");
    
    /* Start camera streaming */
    cam_status = ov5640_stream_start(&camera);
    if (cam_status != OV5640_STATUS_OK) {
        DEBUG_ERROR("Failed to start camera streaming\r\n");
        return;
    }
    
    /* Start video capture */
    cap_status = video_capture_start(&capture);
    if (cap_status != VIDEO_CAPTURE_OK) {
        DEBUG_ERROR("Failed to start video capture\r\n");
        ov5640_stream_stop(&camera);
        return;
    }
    
    /* Start video display */
    disp_status = video_display_start(&display);
    if (disp_status != VIDEO_DISPLAY_OK) {
        DEBUG_ERROR("Failed to start video display\r\n");
        video_capture_stop(&capture);
        ov5640_stream_stop(&camera);
        return;
    }
    
    xil_printf("System running. Press 'q' to exit.\r\n\r\n");
    
    /* Main loop */
    while (1) {
        /* Update display with latest captured frame */
        u32 frame_addr = video_capture_get_frame_addr(&capture);
        video_display_set_frame(&display, frame_addr);
        
        /* Calculate and display FPS every second */
        fps_timer++;
        if (fps_timer >= 30) {  /* Approximately 1 second at 30fps */
            frame_count = video_capture_get_frame_count(&capture);
            u32 fps = frame_count - last_count;
            last_count = frame_count;
            fps_timer = 0;
            
            xil_printf("\rFrames: %lu, FPS: ~%lu    ", frame_count, fps);
        }
        
        /* Check for user input (non-blocking) */
        if (XUartPs_IsReceiveData(STDIN_BASEADDRESS)) {
            char cmd = XUartPs_ReadReg(STDIN_BASEADDRESS, XUARTPS_FIFO_OFFSET);
            
            switch (cmd) {
                case 'q':
                case 'Q':
                    xil_printf("\r\nExiting...\r\n");
                    goto exit_loop;
                    
                case 'm':
                case 'M':
                    /* Toggle between 1080p and 720p */
                    if (camera.current_mode == OV5640_MODE_1080P_30FPS) {
                        xil_printf("\r\nSwitching to 720p60...\r\n");
                        ov5640_set_mode(&camera, OV5640_MODE_720P_60FPS);
                        video_capture_configure(&capture, 1280, 720, BYTES_PER_PIXEL);
                        video_display_set_resolution(&display, VIDEO_DISPLAY_RES_720P);
                    } else {
                        xil_printf("\r\nSwitching to 1080p30...\r\n");
                        ov5640_set_mode(&camera, OV5640_MODE_1080P_30FPS);
                        video_capture_configure(&capture, 1920, 1080, BYTES_PER_PIXEL);
                        video_display_set_resolution(&display, VIDEO_DISPLAY_RES_1080P);
                    }
                    break;
                    
                case 'h':
                case 'H':
                    xil_printf("\r\nToggling horizontal mirror...\r\n");
                    {
                        static u8 hmirror = 0;
                        hmirror = !hmirror;
                        ov5640_set_hmirror(&camera, hmirror);
                    }
                    break;
                    
                case 'v':
                case 'V':
                    xil_printf("\r\nToggling vertical flip...\r\n");
                    {
                        static u8 vflip = 0;
                        vflip = !vflip;
                        ov5640_set_vflip(&camera, vflip);
                    }
                    break;
                    
                case '+':
                    xil_printf("\r\nIncreasing brightness...\r\n");
                    {
                        static u8 brightness = 128;
                        if (brightness < 240) brightness += 16;
                        ov5640_set_brightness(&camera, brightness);
                    }
                    break;
                    
                case '-':
                    xil_printf("\r\nDecreasing brightness...\r\n");
                    {
                        static u8 brightness = 128;
                        if (brightness > 16) brightness -= 16;
                        ov5640_set_brightness(&camera, brightness);
                    }
                    break;
                    
                default:
                    break;
            }
        }
        
        /* Small delay */
        usleep(33333);  /* ~30fps */
    }
    
exit_loop:
    /* Stop video pipeline */
    video_display_stop(&display);
    video_capture_stop(&capture);
    ov5640_stream_stop(&camera);
    
    xil_printf("Video streaming stopped.\r\n");
}

/* ============================================================================
 * Cleanup
 * ============================================================================ */

static void cleanup(void)
{
    DEBUG_INFO("Cleaning up...\r\n");
    
    /* Power off camera */
    camera_power_off();
    
    /* Disable interrupts */
    Xil_ExceptionDisable();
    
    /* Disable cache */
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    
    DEBUG_INFO("Cleanup complete\r\n");
}
