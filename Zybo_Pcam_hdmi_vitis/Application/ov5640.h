/**
 * @file ov5640.h
 * @brief OV5640 Camera Sensor Driver for Zynq Z7-20 PCAM5C
 *
 * This driver provides initialization and control functions for the
 * OmniVision OV5640 5MP image sensor via I2C (SCCB) interface.
 */

#ifndef OV5640_H_
#define OV5640_H_

#include "xil_types.h"
#include "xiicps.h"

/*===========================================================================*/
/* I2C Configuration                                                         */
/*===========================================================================*/

#define OV5640_I2C_ADDR         0x3C    /* 7-bit I2C address (0x78 >> 1) */
#define OV5640_CHIP_ID_HIGH     0x300A
#define OV5640_CHIP_ID_LOW      0x300B
#define OV5640_CHIP_ID          0x5640

/*===========================================================================*/
/* Register Addresses                                                        */
/*===========================================================================*/

/* System Control */
#define OV5640_REG_SYS_RESET00      0x3000
#define OV5640_REG_SYS_RESET01      0x3001
#define OV5640_REG_SYS_RESET02      0x3002
#define OV5640_REG_SYS_RESET03      0x3003
#define OV5640_REG_SYS_CLK_EN00     0x3004
#define OV5640_REG_SYS_CLK_EN01     0x3005
#define OV5640_REG_SYS_CLK_EN02     0x3006
#define OV5640_REG_SYS_CLK_EN03     0x3007
#define OV5640_REG_SYS_CTRL0        0x3008
#define OV5640_REG_PAD_OUTPUT_EN00  0x3016
#define OV5640_REG_PAD_OUTPUT_EN01  0x3017
#define OV5640_REG_PAD_OUTPUT_EN02  0x3018
#define OV5640_REG_SC_PLL_CTRL0     0x3034
#define OV5640_REG_SC_PLL_CTRL1     0x3035
#define OV5640_REG_SC_PLL_CTRL2     0x3036
#define OV5640_REG_SC_PLL_CTRL3     0x3037

/* Timing Control */
#define OV5640_REG_TIMING_HS_H      0x3800
#define OV5640_REG_TIMING_HS_L      0x3801
#define OV5640_REG_TIMING_VS_H      0x3802
#define OV5640_REG_TIMING_VS_L      0x3803
#define OV5640_REG_TIMING_HW_H      0x3804
#define OV5640_REG_TIMING_HW_L      0x3805
#define OV5640_REG_TIMING_VH_H      0x3806
#define OV5640_REG_TIMING_VH_L      0x3807
#define OV5640_REG_TIMING_DVPHO_H   0x3808
#define OV5640_REG_TIMING_DVPHO_L   0x3809
#define OV5640_REG_TIMING_DVPVO_H   0x380A
#define OV5640_REG_TIMING_DVPVO_L   0x380B
#define OV5640_REG_TIMING_HTS_H     0x380C
#define OV5640_REG_TIMING_HTS_L     0x380D
#define OV5640_REG_TIMING_VTS_H     0x380E
#define OV5640_REG_TIMING_VTS_L     0x380F
#define OV5640_REG_TIMING_HOFFSET_H 0x3810
#define OV5640_REG_TIMING_HOFFSET_L 0x3811
#define OV5640_REG_TIMING_VOFFSET_H 0x3812
#define OV5640_REG_TIMING_VOFFSET_L 0x3813
#define OV5640_REG_TIMING_X_INC     0x3814
#define OV5640_REG_TIMING_Y_INC     0x3815
#define OV5640_REG_TIMING_TC_REG20  0x3820
#define OV5640_REG_TIMING_TC_REG21  0x3821

/* AEC/AGC Control */
#define OV5640_REG_AEC_CTRL00       0x3A00
#define OV5640_REG_AEC_CTRL0D       0x3A0D
#define OV5640_REG_AEC_CTRL0E       0x3A0E
#define OV5640_REG_AEC_CTRL0F       0x3A0F
#define OV5640_REG_AEC_CTRL10       0x3A10
#define OV5640_REG_AEC_CTRL11       0x3A11
#define OV5640_REG_AEC_CTRL1B       0x3A1B
#define OV5640_REG_AEC_CTRL1E       0x3A1E
#define OV5640_REG_AEC_CTRL1F       0x3A1F
#define OV5640_REG_AEC_MAX_EXPO_H   0x3A02
#define OV5640_REG_AEC_MAX_EXPO_L   0x3A03

/* AWB Control */
#define OV5640_REG_AWB_CTRL00       0x5180
#define OV5640_REG_AWB_CTRL01       0x5181

/* ISP Control */
#define OV5640_REG_ISP_CTRL00       0x5000
#define OV5640_REG_ISP_CTRL01       0x5001
#define OV5640_REG_ISP_CTRL37       0x5025

/* Format Control */
#define OV5640_REG_FORMAT_CTRL00    0x4300
#define OV5640_REG_FORMAT_MUX_CTRL  0x501F

/* MIPI Control */
#define OV5640_REG_MIPI_CTRL00      0x300E
#define OV5640_REG_MIPI_CTRL01      0x4800
#define OV5640_REG_MIPI_CTRL05      0x4805

/* Test Pattern */
#define OV5640_REG_PRE_ISP_TEST     0x503D

/*===========================================================================*/
/* Video Modes                                                               */
/*===========================================================================*/

typedef enum {
    OV5640_MODE_720P_60FPS = 0,     /* 1280x720 @ 60fps */
    OV5640_MODE_1080P_30FPS,        /* 1920x1080 @ 30fps */
    OV5640_MODE_1080P_15FPS,        /* 1920x1080 @ 15fps */
    OV5640_MODE_VGA_60FPS,          /* 640x480 @ 60fps */
    OV5640_MODE_QVGA_120FPS,        /* 320x240 @ 120fps */
    OV5640_MODE_5MP_15FPS,          /* 2592x1944 @ 15fps */
    OV5640_MODE_COUNT
} OV5640_Mode;

typedef enum {
    OV5640_FORMAT_RAW8 = 0,         /* RAW8 Bayer */
    OV5640_FORMAT_RAW10,            /* RAW10 Bayer */
    OV5640_FORMAT_RGB565,           /* RGB565 */
    OV5640_FORMAT_YUV422,           /* YUV422 */
} OV5640_Format;

typedef enum {
    OV5640_TEST_PATTERN_OFF = 0,
    OV5640_TEST_PATTERN_COLOR_BAR,
    OV5640_TEST_PATTERN_COLOR_SQUARE,
    OV5640_TEST_PATTERN_RANDOM,
} OV5640_TestPattern;

/*===========================================================================*/
/* Resolution Structure                                                      */
/*===========================================================================*/

typedef struct {
    u16 width;
    u16 height;
    u16 fps;
    u32 pixel_clock;    /* Pixel clock in Hz */
    u16 hts;            /* Horizontal total size */
    u16 vts;            /* Vertical total size */
} OV5640_Resolution;

/*===========================================================================*/
/* Driver Context                                                            */
/*===========================================================================*/

typedef struct {
    XIicPs *IicInstance;
    u8 I2cAddr;
    OV5640_Mode CurrentMode;
    OV5640_Format CurrentFormat;
    u16 Width;
    u16 Height;
    u8 Initialized;
} OV5640_Config;

/*===========================================================================*/
/* Function Prototypes                                                       */
/*===========================================================================*/

/**
 * @brief Initialize OV5640 driver
 * @param Config Pointer to driver configuration
 * @param IicInstance Pointer to initialized I2C instance
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_Init(OV5640_Config *Config, XIicPs *IicInstance);

/**
 * @brief Check if OV5640 sensor is present
 * @param Config Pointer to driver configuration
 * @return XST_SUCCESS if sensor detected, XST_FAILURE otherwise
 */
int OV5640_Detect(OV5640_Config *Config);

/**
 * @brief Configure sensor for specified video mode
 * @param Config Pointer to driver configuration
 * @param Mode Desired video mode
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetMode(OV5640_Config *Config, OV5640_Mode Mode);

/**
 * @brief Set output format
 * @param Config Pointer to driver configuration
 * @param Format Desired output format
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetFormat(OV5640_Config *Config, OV5640_Format Format);

/**
 * @brief Start video streaming
 * @param Config Pointer to driver configuration
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_StreamOn(OV5640_Config *Config);

/**
 * @brief Stop video streaming
 * @param Config Pointer to driver configuration
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_StreamOff(OV5640_Config *Config);

/**
 * @brief Software reset of sensor
 * @param Config Pointer to driver configuration
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_Reset(OV5640_Config *Config);

/**
 * @brief Set test pattern
 * @param Config Pointer to driver configuration
 * @param Pattern Test pattern to enable
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetTestPattern(OV5640_Config *Config, OV5640_TestPattern Pattern);

/**
 * @brief Set horizontal mirror
 * @param Config Pointer to driver configuration
 * @param Enable 1 to enable mirror, 0 to disable
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetMirror(OV5640_Config *Config, u8 Enable);

/**
 * @brief Set vertical flip
 * @param Config Pointer to driver configuration
 * @param Enable 1 to enable flip, 0 to disable
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetFlip(OV5640_Config *Config, u8 Enable);

/**
 * @brief Set auto exposure
 * @param Config Pointer to driver configuration
 * @param Enable 1 to enable AEC, 0 to disable
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetAutoExposure(OV5640_Config *Config, u8 Enable);

/**
 * @brief Set auto white balance
 * @param Config Pointer to driver configuration
 * @param Enable 1 to enable AWB, 0 to disable
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_SetAutoWhiteBalance(OV5640_Config *Config, u8 Enable);

/**
 * @brief Read register value
 * @param Config Pointer to driver configuration
 * @param RegAddr 16-bit register address
 * @param Value Pointer to store read value
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_ReadReg(OV5640_Config *Config, u16 RegAddr, u8 *Value);

/**
 * @brief Write register value
 * @param Config Pointer to driver configuration
 * @param RegAddr 16-bit register address
 * @param Value Value to write
 * @return XST_SUCCESS on success, XST_FAILURE on error
 */
int OV5640_WriteReg(OV5640_Config *Config, u16 RegAddr, u8 Value);

/**
 * @brief Get current resolution
 * @param Config Pointer to driver configuration
 * @param Width Pointer to store width
 * @param Height Pointer to store height
 */
void OV5640_GetResolution(OV5640_Config *Config, u16 *Width, u16 *Height);

/**
 * @brief Print sensor information
 * @param Config Pointer to driver configuration
 */
void OV5640_PrintInfo(OV5640_Config *Config);

#endif /* OV5640_H_ */
