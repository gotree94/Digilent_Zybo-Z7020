/**
 * @file video_display.c
 * @brief Video Display Driver for HDMI Output
 *
 * This module handles VDMA configuration and video output pipeline
 * for displaying camera frames on HDMI.
 */

#include "video_display.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "sleep.h"

/*===========================================================================*/
/* Defines                                                                   */
/*===========================================================================*/

#define DISPLAY_DEBUG   0

#if DISPLAY_DEBUG
#define DPRINTF(fmt, ...) xil_printf(fmt, ##__VA_ARGS__)
#else
#define DPRINTF(fmt, ...)
#endif

/*===========================================================================*/
/* Static Variables                                                          */
/*===========================================================================*/

static VideoDisplay_Config DisplayConfig;

/*===========================================================================*/
/* Frame Buffer Configuration                                                */
/*===========================================================================*/

/* Frame buffer addresses in DDR */
#define FRAME_BUFFER_BASE   0x10000000
#define FRAME_BUFFER_SIZE   (1920 * 1080 * 4)  /* Max resolution, 32bpp */

static u32 FrameBufferAddr[DISPLAY_NUM_FRAMES];

/*===========================================================================*/
/* Static Functions                                                          */
/*===========================================================================*/

static void InitFrameBuffers(VideoDisplay_Config *Config)
{
    int i;
    u32 BaseAddr = FRAME_BUFFER_BASE;

    for (i = 0; i < DISPLAY_NUM_FRAMES; i++) {
        FrameBufferAddr[i] = BaseAddr + (i * FRAME_BUFFER_SIZE);
        Config->FrameBuffer[i] = FrameBufferAddr[i];

        DPRINTF("Frame buffer %d: 0x%08X\r\n", i, FrameBufferAddr[i]);
    }

    Config->CurrentWriteFrame = 0;
    Config->CurrentReadFrame = 0;
}

static int ConfigureWriteVDMA(VideoDisplay_Config *Config)
{
    int Status;
    XAxiVdma_DmaSetup WriteCfg;
    int i;

    /* Configure Write channel (S2MM - from camera) */
    WriteCfg.VertSizeInput = Config->Height;
    WriteCfg.HoriSizeInput = Config->Width * Config->BytesPerPixel;
    WriteCfg.Stride = Config->Width * Config->BytesPerPixel;
    WriteCfg.FrameDelay = 0;
    WriteCfg.EnableCircularBuf = 1;
    WriteCfg.EnableSync = 1;
    WriteCfg.PointNum = 0;
    WriteCfg.EnableFrameCounter = 0;
    WriteCfg.FixedFrameStoreAddr = 0;

    Status = XAxiVdma_DmaConfig(Config->VdmaWrite, XAXIVDMA_WRITE, &WriteCfg);
    if (Status != XST_SUCCESS) {
        xil_printf("VideoDisplay: Write VDMA config failed\r\n");
        return XST_FAILURE;
    }

    /* Set frame buffer addresses */
    for (i = 0; i < DISPLAY_NUM_FRAMES; i++) {
        Status = XAxiVdma_DmaSetBufferAddr(Config->VdmaWrite, XAXIVDMA_WRITE,
                                           Config->FrameBuffer);
        if (Status != XST_SUCCESS) {
            xil_printf("VideoDisplay: Write buffer address set failed\r\n");
            return XST_FAILURE;
        }
    }

    return XST_SUCCESS;
}

static int ConfigureReadVDMA(VideoDisplay_Config *Config)
{
    int Status;
    XAxiVdma_DmaSetup ReadCfg;
    int i;

    /* Configure Read channel (MM2S - to display) */
    ReadCfg.VertSizeInput = Config->Height;
    ReadCfg.HoriSizeInput = Config->Width * Config->BytesPerPixel;
    ReadCfg.Stride = Config->Width * Config->BytesPerPixel;
    ReadCfg.FrameDelay = 0;
    ReadCfg.EnableCircularBuf = 1;
    ReadCfg.EnableSync = 1;
    ReadCfg.PointNum = 0;
    ReadCfg.EnableFrameCounter = 0;
    ReadCfg.FixedFrameStoreAddr = 0;

    Status = XAxiVdma_DmaConfig(Config->VdmaRead, XAXIVDMA_READ, &ReadCfg);
    if (Status != XST_SUCCESS) {
        xil_printf("VideoDisplay: Read VDMA config failed\r\n");
        return XST_FAILURE;
    }

    /* Set frame buffer addresses */
    for (i = 0; i < DISPLAY_NUM_FRAMES; i++) {
        Status = XAxiVdma_DmaSetBufferAddr(Config->VdmaRead, XAXIVDMA_READ,
                                           Config->FrameBuffer);
        if (Status != XST_SUCCESS) {
            xil_printf("VideoDisplay: Read buffer address set failed\r\n");
            return XST_FAILURE;
        }
    }

    return XST_SUCCESS;
}

/*===========================================================================*/
/* Public Functions                                                          */
/*===========================================================================*/

int VideoDisplay_Init(VideoDisplay_Config *Config,
                      XAxiVdma *VdmaWrite,
                      XAxiVdma *VdmaRead,
                      u32 Width,
                      u32 Height,
                      u32 BytesPerPixel)
{
    if (Config == NULL || VdmaWrite == NULL || VdmaRead == NULL) {
        return XST_FAILURE;
    }

    Config->VdmaWrite = VdmaWrite;
    Config->VdmaRead = VdmaRead;
    Config->Width = Width;
    Config->Height = Height;
    Config->BytesPerPixel = BytesPerPixel;
    Config->Initialized = 0;
    Config->Running = 0;

    /* Initialize frame buffers */
    InitFrameBuffers(Config);

    /* Clear frame buffers */
    VideoDisplay_ClearFrameBuffers(Config, 0x00000000);

    xil_printf("VideoDisplay: Initialized %dx%d, %d bpp\r\n",
               Width, Height, BytesPerPixel * 8);

    Config->Initialized = 1;
    return XST_SUCCESS;
}

int VideoDisplay_Configure(VideoDisplay_Config *Config)
{
    int Status;

    if (!Config->Initialized) {
        return XST_FAILURE;
    }

    /* Configure Write VDMA (Camera -> DDR) */
    Status = ConfigureWriteVDMA(Config);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Configure Read VDMA (DDR -> Display) */
    Status = ConfigureReadVDMA(Config);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    xil_printf("VideoDisplay: VDMA configured\r\n");
    return XST_SUCCESS;
}

int VideoDisplay_Start(VideoDisplay_Config *Config)
{
    int Status;

    if (!Config->Initialized) {
        return XST_FAILURE;
    }

    /* Start Write channel */
    Status = XAxiVdma_DmaStart(Config->VdmaWrite, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS) {
        xil_printf("VideoDisplay: Write VDMA start failed\r\n");
        return XST_FAILURE;
    }

    /* Start Read channel */
    Status = XAxiVdma_DmaStart(Config->VdmaRead, XAXIVDMA_READ);
    if (Status != XST_SUCCESS) {
        xil_printf("VideoDisplay: Read VDMA start failed\r\n");
        return XST_FAILURE;
    }

    Config->Running = 1;
    xil_printf("VideoDisplay: Started\r\n");

    return XST_SUCCESS;
}

int VideoDisplay_Stop(VideoDisplay_Config *Config)
{
    if (!Config->Initialized) {
        return XST_FAILURE;
    }

    /* Stop Write channel */
    XAxiVdma_DmaStop(Config->VdmaWrite, XAXIVDMA_WRITE);

    /* Stop Read channel */
    XAxiVdma_DmaStop(Config->VdmaRead, XAXIVDMA_READ);

    Config->Running = 0;
    xil_printf("VideoDisplay: Stopped\r\n");

    return XST_SUCCESS;
}

void VideoDisplay_ClearFrameBuffers(VideoDisplay_Config *Config, u32 Color)
{
    int i;
    u32 *Ptr;
    u32 Size;

    if (!Config->Initialized && Config->FrameBuffer[0] == 0) {
        return;
    }

    Size = Config->Width * Config->Height;

    for (i = 0; i < DISPLAY_NUM_FRAMES; i++) {
        Ptr = (u32 *)Config->FrameBuffer[i];
        memset(Ptr, 0, Size * Config->BytesPerPixel);
    }

    /* Flush cache */
    Xil_DCacheFlush();

    DPRINTF("VideoDisplay: Frame buffers cleared\r\n");
}

int VideoDisplay_SetResolution(VideoDisplay_Config *Config,
                               u32 Width,
                               u32 Height)
{
    if (!Config->Initialized) {
        return XST_FAILURE;
    }

    if (Config->Running) {
        VideoDisplay_Stop(Config);
    }

    Config->Width = Width;
    Config->Height = Height;

    /* Reconfigure VDMA */
    return VideoDisplay_Configure(Config);
}

u32 VideoDisplay_GetFrameBufferAddr(VideoDisplay_Config *Config, int Index)
{
    if (Index < 0 || Index >= DISPLAY_NUM_FRAMES) {
        return 0;
    }

    return Config->FrameBuffer[Index];
}

void VideoDisplay_SwitchFrame(VideoDisplay_Config *Config)
{
    /* Switch to next frame in circular buffer */
    Config->CurrentReadFrame = (Config->CurrentReadFrame + 1) % DISPLAY_NUM_FRAMES;
    Config->CurrentWriteFrame = (Config->CurrentWriteFrame + 1) % DISPLAY_NUM_FRAMES;
}

int VideoDisplay_IsRunning(VideoDisplay_Config *Config)
{
    return Config->Running;
}

void VideoDisplay_DrawTestPattern(VideoDisplay_Config *Config, int Pattern)
{
    u32 *Ptr;
    u32 x, y;
    u32 Color;
    u32 Width = Config->Width;
    u32 Height = Config->Height;

    if (!Config->Initialized) {
        return;
    }

    Ptr = (u32 *)Config->FrameBuffer[0];

    switch (Pattern) {
        case 0:  /* Color bars */
            for (y = 0; y < Height; y++) {
                for (x = 0; x < Width; x++) {
                    int Bar = (x * 8) / Width;
                    switch (Bar) {
                        case 0: Color = 0xFFFFFFFF; break;  /* White */
                        case 1: Color = 0xFFFFFF00; break;  /* Yellow */
                        case 2: Color = 0xFF00FFFF; break;  /* Cyan */
                        case 3: Color = 0xFF00FF00; break;  /* Green */
                        case 4: Color = 0xFFFF00FF; break;  /* Magenta */
                        case 5: Color = 0xFFFF0000; break;  /* Red */
                        case 6: Color = 0xFF0000FF; break;  /* Blue */
                        case 7: Color = 0xFF000000; break;  /* Black */
                        default: Color = 0xFF000000; break;
                    }
                    Ptr[y * Width + x] = Color;
                }
            }
            break;

        case 1:  /* Gradient */
            for (y = 0; y < Height; y++) {
                for (x = 0; x < Width; x++) {
                    u8 R = (x * 255) / Width;
                    u8 G = (y * 255) / Height;
                    u8 B = 128;
                    Color = 0xFF000000 | (R << 16) | (G << 8) | B;
                    Ptr[y * Width + x] = Color;
                }
            }
            break;

        case 2:  /* Checkerboard */
            for (y = 0; y < Height; y++) {
                for (x = 0; x < Width; x++) {
                    int CheckX = x / 64;
                    int CheckY = y / 64;
                    if ((CheckX + CheckY) % 2 == 0) {
                        Color = 0xFFFFFFFF;
                    } else {
                        Color = 0xFF000000;
                    }
                    Ptr[y * Width + x] = Color;
                }
            }
            break;

        default:
            /* Solid black */
            memset(Ptr, 0, Width * Height * sizeof(u32));
            break;
    }

    /* Copy to other frame buffers */
    for (int i = 1; i < DISPLAY_NUM_FRAMES; i++) {
        memcpy((void *)Config->FrameBuffer[i],
               (void *)Config->FrameBuffer[0],
               Width * Height * sizeof(u32));
    }

    /* Flush cache */
    Xil_DCacheFlush();

    xil_printf("VideoDisplay: Test pattern %d drawn\r\n", Pattern);
}

void VideoDisplay_PrintStatus(VideoDisplay_Config *Config)
{
    u32 WriteStatus, ReadStatus;

    if (!Config->Initialized) {
        xil_printf("VideoDisplay: Not initialized\r\n");
        return;
    }

    WriteStatus = XAxiVdma_GetDmaChannelStatus(Config->VdmaWrite, XAXIVDMA_WRITE);
    ReadStatus = XAxiVdma_GetDmaChannelStatus(Config->VdmaRead, XAXIVDMA_READ);

    xil_printf("\r\n=== Video Display Status ===\r\n");
    xil_printf("Resolution: %dx%d\r\n", Config->Width, Config->Height);
    xil_printf("Bytes/Pixel: %d\r\n", Config->BytesPerPixel);
    xil_printf("Running: %s\r\n", Config->Running ? "Yes" : "No");
    xil_printf("Write VDMA Status: 0x%08X\r\n", WriteStatus);
    xil_printf("Read VDMA Status: 0x%08X\r\n", ReadStatus);
    xil_printf("Current Write Frame: %d\r\n", Config->CurrentWriteFrame);
    xil_printf("Current Read Frame: %d\r\n", Config->CurrentReadFrame);

    for (int i = 0; i < DISPLAY_NUM_FRAMES; i++) {
        xil_printf("Frame Buffer %d: 0x%08X\r\n", i, Config->FrameBuffer[i]);
    }
    xil_printf("=============================\r\n\r\n");
}
