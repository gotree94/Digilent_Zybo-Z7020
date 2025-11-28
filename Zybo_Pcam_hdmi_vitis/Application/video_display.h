/**
 * @file video_display.h
 * @brief Video Display Driver Header
 */

#ifndef VIDEO_DISPLAY_H_
#define VIDEO_DISPLAY_H_

#include "xil_types.h"
#include "xaxivdma.h"

/*===========================================================================*/
/* Defines                                                                   */
/*===========================================================================*/

#define DISPLAY_NUM_FRAMES      3       /* Triple buffering */
#define DISPLAY_MAX_WIDTH       1920
#define DISPLAY_MAX_HEIGHT      1080

/*===========================================================================*/
/* Data Structures                                                           */
/*===========================================================================*/

typedef struct {
    XAxiVdma *VdmaWrite;            /* VDMA for writing (camera -> DDR) */
    XAxiVdma *VdmaRead;             /* VDMA for reading (DDR -> display) */
    u32 Width;                      /* Frame width in pixels */
    u32 Height;                     /* Frame height in pixels */
    u32 BytesPerPixel;              /* Bytes per pixel (3 or 4) */
    u32 FrameBuffer[DISPLAY_NUM_FRAMES];  /* Frame buffer addresses */
    u32 CurrentWriteFrame;          /* Current write frame index */
    u32 CurrentReadFrame;           /* Current read frame index */
    u8 Initialized;                 /* Initialization flag */
    u8 Running;                     /* Running flag */
} VideoDisplay_Config;

/*===========================================================================*/
/* Function Prototypes                                                       */
/*===========================================================================*/

/**
 * @brief Initialize video display driver
 * @param Config Pointer to configuration structure
 * @param VdmaWrite VDMA instance for write channel
 * @param VdmaRead VDMA instance for read channel
 * @param Width Frame width
 * @param Height Frame height
 * @param BytesPerPixel Bytes per pixel
 * @return XST_SUCCESS or XST_FAILURE
 */
int VideoDisplay_Init(VideoDisplay_Config *Config,
                      XAxiVdma *VdmaWrite,
                      XAxiVdma *VdmaRead,
                      u32 Width,
                      u32 Height,
                      u32 BytesPerPixel);

/**
 * @brief Configure VDMA channels
 * @param Config Pointer to configuration structure
 * @return XST_SUCCESS or XST_FAILURE
 */
int VideoDisplay_Configure(VideoDisplay_Config *Config);

/**
 * @brief Start video streaming
 * @param Config Pointer to configuration structure
 * @return XST_SUCCESS or XST_FAILURE
 */
int VideoDisplay_Start(VideoDisplay_Config *Config);

/**
 * @brief Stop video streaming
 * @param Config Pointer to configuration structure
 * @return XST_SUCCESS or XST_FAILURE
 */
int VideoDisplay_Stop(VideoDisplay_Config *Config);

/**
 * @brief Clear all frame buffers
 * @param Config Pointer to configuration structure
 * @param Color Fill color (ARGB format)
 */
void VideoDisplay_ClearFrameBuffers(VideoDisplay_Config *Config, u32 Color);

/**
 * @brief Change display resolution
 * @param Config Pointer to configuration structure
 * @param Width New width
 * @param Height New height
 * @return XST_SUCCESS or XST_FAILURE
 */
int VideoDisplay_SetResolution(VideoDisplay_Config *Config,
                               u32 Width,
                               u32 Height);

/**
 * @brief Get frame buffer address
 * @param Config Pointer to configuration structure
 * @param Index Frame buffer index
 * @return Frame buffer address or 0 on error
 */
u32 VideoDisplay_GetFrameBufferAddr(VideoDisplay_Config *Config, int Index);

/**
 * @brief Switch to next frame
 * @param Config Pointer to configuration structure
 */
void VideoDisplay_SwitchFrame(VideoDisplay_Config *Config);

/**
 * @brief Check if display is running
 * @param Config Pointer to configuration structure
 * @return 1 if running, 0 if stopped
 */
int VideoDisplay_IsRunning(VideoDisplay_Config *Config);

/**
 * @brief Draw test pattern to frame buffer
 * @param Config Pointer to configuration structure
 * @param Pattern Pattern type (0=color bars, 1=gradient, 2=checkerboard)
 */
void VideoDisplay_DrawTestPattern(VideoDisplay_Config *Config, int Pattern);

/**
 * @brief Print display status
 * @param Config Pointer to configuration structure
 */
void VideoDisplay_PrintStatus(VideoDisplay_Config *Config);

#endif /* VIDEO_DISPLAY_H_ */
