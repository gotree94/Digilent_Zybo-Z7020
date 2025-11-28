/**
 * @file ov5640.c
 * @brief OV5640 Camera Sensor Driver Implementation
 */

#include "ov5640.h"
#include "xil_printf.h"
#include "sleep.h"

/*===========================================================================*/
/* Register Configuration Tables                                             */
/*===========================================================================*/

typedef struct {
    u16 addr;
    u8 value;
} RegSetting;

/* Initial configuration for OV5640 */
static const RegSetting OV5640_InitSettings[] = {
    /* System Control */
    {0x3103, 0x11},  /* System clock from PLL */
    {0x3008, 0x82},  /* Software reset */
    /* Delay handled in code */

    /* Clock Configuration for MIPI */
    {0x3008, 0x42},  /* Software power down */
    {0x3103, 0x03},  /* System clock from PLL */
    {0x3017, 0x00},  /* FREX, Vsync, HREF, PCLK output disable */
    {0x3018, 0x00},

    /* PLL Configuration: Input clock 24MHz */
    {0x3034, 0x18},  /* MIPI 8-bit mode */
    {0x3035, 0x11},  /* PLL */
    {0x3036, 0x54},  /* PLL multiplier */
    {0x3037, 0x13},  /* PLL root divider, PLL pre-divider */
    {0x3108, 0x01},  /* PCLK root divider */
    {0x3630, 0x36},
    {0x3631, 0x0E},
    {0x3632, 0xE2},
    {0x3633, 0x12},
    {0x3621, 0xE0},
    {0x3704, 0xA0},
    {0x3703, 0x5A},
    {0x3715, 0x78},
    {0x3717, 0x01},
    {0x370B, 0x60},
    {0x3705, 0x1A},
    {0x3905, 0x02},
    {0x3906, 0x10},
    {0x3901, 0x0A},
    {0x3731, 0x12},
    {0x3600, 0x08},
    {0x3601, 0x33},
    {0x302D, 0x60},
    {0x3620, 0x52},
    {0x371B, 0x20},
    {0x471C, 0x50},
    {0x3A13, 0x43},
    {0x3A18, 0x00},
    {0x3A19, 0xF8},
    {0x3635, 0x13},
    {0x3636, 0x03},
    {0x3634, 0x40},
    {0x3622, 0x01},
    {0x3C01, 0x34},
    {0x3C04, 0x28},
    {0x3C05, 0x98},
    {0x3C06, 0x00},
    {0x3C07, 0x08},
    {0x3C08, 0x00},
    {0x3C09, 0x1C},
    {0x3C0A, 0x9C},
    {0x3C0B, 0x40},

    /* Timing Control */
    {0x3814, 0x11},  /* X increment */
    {0x3815, 0x11},  /* Y increment */
    {0x3800, 0x00},  /* HS */
    {0x3801, 0x00},
    {0x3802, 0x00},  /* VS */
    {0x3803, 0x00},
    {0x3804, 0x0A},  /* HE */
    {0x3805, 0x3F},
    {0x3806, 0x07},  /* VE */
    {0x3807, 0x9F},
    {0x3810, 0x00},  /* H offset */
    {0x3811, 0x10},
    {0x3812, 0x00},  /* V offset */
    {0x3813, 0x04},

    /* ISP Control */
    {0x5000, 0xA7},  /* ISP control: LENC on, raw gamma on, BPC on, WPC on, CIP on */
    {0x5001, 0xA3},  /* ISP control: SDE on, scale on, UV average off, color matrix on, AWB on */
    {0x5180, 0xFF},  /* AWB control */
    {0x5181, 0xF2},
    {0x5182, 0x00},
    {0x5183, 0x14},
    {0x5184, 0x25},
    {0x5185, 0x24},
    {0x5186, 0x09},
    {0x5187, 0x09},
    {0x5188, 0x09},
    {0x5189, 0x75},
    {0x518A, 0x54},
    {0x518B, 0xE0},
    {0x518C, 0xB2},
    {0x518D, 0x42},
    {0x518E, 0x3D},
    {0x518F, 0x56},
    {0x5190, 0x46},
    {0x5191, 0xF8},
    {0x5192, 0x04},
    {0x5193, 0x70},
    {0x5194, 0xF0},
    {0x5195, 0xF0},
    {0x5196, 0x03},
    {0x5197, 0x01},
    {0x5198, 0x04},
    {0x5199, 0x12},
    {0x519A, 0x04},
    {0x519B, 0x00},
    {0x519C, 0x06},
    {0x519D, 0x82},
    {0x519E, 0x38},

    /* Color Matrix */
    {0x5381, 0x1E},
    {0x5382, 0x5B},
    {0x5383, 0x08},
    {0x5384, 0x0A},
    {0x5385, 0x7E},
    {0x5386, 0x88},
    {0x5387, 0x7C},
    {0x5388, 0x6C},
    {0x5389, 0x10},
    {0x538A, 0x01},
    {0x538B, 0x98},

    /* Gamma Curve */
    {0x5480, 0x01},
    {0x5481, 0x08},
    {0x5482, 0x14},
    {0x5483, 0x28},
    {0x5484, 0x51},
    {0x5485, 0x65},
    {0x5486, 0x71},
    {0x5487, 0x7D},
    {0x5488, 0x87},
    {0x5489, 0x91},
    {0x548A, 0x9A},
    {0x548B, 0xAA},
    {0x548C, 0xB8},
    {0x548D, 0xCD},
    {0x548E, 0xDD},
    {0x548F, 0xEA},
    {0x5490, 0x1D},

    /* SDE (Special Digital Effects) */
    {0x5580, 0x02},  /* SDE control: saturation enable */
    {0x5583, 0x40},
    {0x5584, 0x10},
    {0x5589, 0x10},
    {0x558A, 0x00},
    {0x558B, 0xF8},

    /* LENC (Lens Correction) */
    {0x5800, 0x23},
    {0x5801, 0x14},
    {0x5802, 0x0F},
    {0x5803, 0x0F},
    {0x5804, 0x12},
    {0x5805, 0x26},
    {0x5806, 0x0C},
    {0x5807, 0x08},
    {0x5808, 0x05},
    {0x5809, 0x05},
    {0x580A, 0x08},
    {0x580B, 0x0D},
    {0x580C, 0x08},
    {0x580D, 0x03},
    {0x580E, 0x00},
    {0x580F, 0x00},
    {0x5810, 0x03},
    {0x5811, 0x09},
    {0x5812, 0x07},
    {0x5813, 0x03},
    {0x5814, 0x00},
    {0x5815, 0x01},
    {0x5816, 0x03},
    {0x5817, 0x08},
    {0x5818, 0x0D},
    {0x5819, 0x08},
    {0x581A, 0x05},
    {0x581B, 0x06},
    {0x581C, 0x08},
    {0x581D, 0x0E},
    {0x581E, 0x29},
    {0x581F, 0x17},
    {0x5820, 0x11},
    {0x5821, 0x11},
    {0x5822, 0x15},
    {0x5823, 0x28},
    {0x5824, 0x46},
    {0x5825, 0x26},
    {0x5826, 0x08},
    {0x5827, 0x26},
    {0x5828, 0x64},
    {0x5829, 0x26},
    {0x582A, 0x24},
    {0x582B, 0x22},
    {0x582C, 0x24},
    {0x582D, 0x24},
    {0x582E, 0x06},
    {0x582F, 0x22},
    {0x5830, 0x40},
    {0x5831, 0x42},
    {0x5832, 0x24},
    {0x5833, 0x26},
    {0x5834, 0x24},
    {0x5835, 0x22},
    {0x5836, 0x22},
    {0x5837, 0x26},
    {0x5838, 0x44},
    {0x5839, 0x24},
    {0x583A, 0x26},
    {0x583B, 0x28},
    {0x583C, 0x42},
    {0x583D, 0xCE},

    /* AEC/AGC */
    {0x3A0F, 0x30},  /* AEC target */
    {0x3A10, 0x28},
    {0x3A11, 0x60},
    {0x3A1B, 0x30},
    {0x3A1E, 0x26},
    {0x3A1F, 0x14},

    /* End marker */
    {0x0000, 0x00}
};

/* 1080p @ 30fps MIPI 2-lane configuration */
static const RegSetting OV5640_1080p30[] = {
    /* PLL settings for 1080p */
    {0x3034, 0x18},  /* MIPI 8-bit */
    {0x3035, 0x21},  /* PLL charge pump, sys clk div */
    {0x3036, 0x54},  /* PLL multiplier */
    {0x3037, 0x13},  /* PLL root div, pre-div */
    {0x3108, 0x01},  /* PCLK div */
    {0x3824, 0x01},

    /* Timing */
    {0x3808, 0x07},  /* DVP H output: 1920 */
    {0x3809, 0x80},
    {0x380A, 0x04},  /* DVP V output: 1080 */
    {0x380B, 0x38},
    {0x380C, 0x09},  /* HTS: 2500 */
    {0x380D, 0xC4},
    {0x380E, 0x04},  /* VTS: 1120 */
    {0x380F, 0x60},

    /* Window */
    {0x3800, 0x01},  /* HS */
    {0x3801, 0x5C},
    {0x3802, 0x01},  /* VS */
    {0x3803, 0xB2},
    {0x3804, 0x08},  /* HE */
    {0x3805, 0xE3},
    {0x3806, 0x05},  /* VE */
    {0x3807, 0xF1},

    {0x3810, 0x00},  /* H offset */
    {0x3811, 0x04},
    {0x3812, 0x00},  /* V offset */
    {0x3813, 0x02},

    {0x3814, 0x11},  /* X inc */
    {0x3815, 0x11},  /* Y inc */

    {0x3820, 0x40},  /* Flip off, binning off */
    {0x3821, 0x06},  /* Mirror off, binning off */

    /* MIPI */
    {0x4837, 0x10},  /* PCLK period */
    {0x4800, 0x24},  /* MIPI control */
    {0x300E, 0x45},  /* MIPI 2-lane */

    /* End marker */
    {0x0000, 0x00}
};

/* 720p @ 60fps MIPI 2-lane configuration */
static const RegSetting OV5640_720p60[] = {
    /* PLL settings for 720p60 */
    {0x3034, 0x18},
    {0x3035, 0x11},
    {0x3036, 0x54},
    {0x3037, 0x13},
    {0x3108, 0x01},
    {0x3824, 0x01},

    /* Timing */
    {0x3808, 0x05},  /* DVP H output: 1280 */
    {0x3809, 0x00},
    {0x380A, 0x02},  /* DVP V output: 720 */
    {0x380B, 0xD0},
    {0x380C, 0x07},  /* HTS: 1896 */
    {0x380D, 0x68},
    {0x380E, 0x03},  /* VTS: 984 */
    {0x380F, 0xD8},

    /* Window with 2x2 subsample */
    {0x3800, 0x00},
    {0x3801, 0x00},
    {0x3802, 0x00},
    {0x3803, 0xFA},
    {0x3804, 0x0A},
    {0x3805, 0x3F},
    {0x3806, 0x06},
    {0x3807, 0xA9},

    {0x3810, 0x00},
    {0x3811, 0x10},
    {0x3812, 0x00},
    {0x3813, 0x04},

    {0x3814, 0x31},  /* X inc (subsample) */
    {0x3815, 0x31},  /* Y inc (subsample) */

    {0x3820, 0x41},  /* Flip off, V binning on */
    {0x3821, 0x07},  /* Mirror off, H binning on */

    /* MIPI */
    {0x4837, 0x10},
    {0x4800, 0x24},
    {0x300E, 0x45},

    /* End marker */
    {0x0000, 0x00}
};

/* MIPI RAW10 output format */
static const RegSetting OV5640_FormatRAW10[] = {
    {0x4300, 0x00},  /* Format control: RAW */
    {0x501F, 0x03},  /* Format MUX: ISP RAW */
    {0x3034, 0x1A},  /* MIPI 10-bit */
    {0x0000, 0x00}
};

/* MIPI RAW8 output format */
static const RegSetting OV5640_FormatRAW8[] = {
    {0x4300, 0x00},  /* Format control: RAW */
    {0x501F, 0x03},  /* Format MUX: ISP RAW */
    {0x3034, 0x18},  /* MIPI 8-bit */
    {0x0000, 0x00}
};

/*===========================================================================*/
/* Static Functions                                                          */
/*===========================================================================*/

static int WriteRegTable(OV5640_Config *Config, const RegSetting *Table)
{
    int Status;
    const RegSetting *Setting = Table;

    while (Setting->addr != 0x0000) {
        Status = OV5640_WriteReg(Config, Setting->addr, Setting->value);
        if (Status != XST_SUCCESS) {
            return XST_FAILURE;
        }
        Setting++;
    }

    return XST_SUCCESS;
}

/*===========================================================================*/
/* Public Functions                                                          */
/*===========================================================================*/

int OV5640_Init(OV5640_Config *Config, XIicPs *IicInstance)
{
    int Status;

    if (Config == NULL || IicInstance == NULL) {
        return XST_FAILURE;
    }

    Config->IicInstance = IicInstance;
    Config->I2cAddr = OV5640_I2C_ADDR;
    Config->Initialized = 0;

    /* Detect sensor */
    Status = OV5640_Detect(Config);
    if (Status != XST_SUCCESS) {
        xil_printf("OV5640: Sensor not detected\r\n");
        return XST_FAILURE;
    }

    /* Software reset */
    Status = OV5640_Reset(Config);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for reset to complete */
    usleep(10000);

    /* Write initial configuration */
    Status = WriteRegTable(Config, OV5640_InitSettings);
    if (Status != XST_SUCCESS) {
        xil_printf("OV5640: Initial configuration failed\r\n");
        return XST_FAILURE;
    }

    /* Set default mode: 1080p @ 30fps */
    Status = OV5640_SetMode(Config, OV5640_MODE_1080P_30FPS);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Set default format: RAW10 */
    Status = OV5640_SetFormat(Config, OV5640_FORMAT_RAW10);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Config->Initialized = 1;
    xil_printf("OV5640: Initialized successfully\r\n");

    return XST_SUCCESS;
}

int OV5640_Detect(OV5640_Config *Config)
{
    u8 IdHigh, IdLow;
    u16 ChipId;
    int Status;

    Status = OV5640_ReadReg(Config, OV5640_CHIP_ID_HIGH, &IdHigh);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Status = OV5640_ReadReg(Config, OV5640_CHIP_ID_LOW, &IdLow);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    ChipId = ((u16)IdHigh << 8) | IdLow;

    if (ChipId != OV5640_CHIP_ID) {
        xil_printf("OV5640: Invalid chip ID 0x%04X (expected 0x%04X)\r\n",
                   ChipId, OV5640_CHIP_ID);
        return XST_FAILURE;
    }

    xil_printf("OV5640: Chip ID 0x%04X detected\r\n", ChipId);
    return XST_SUCCESS;
}

int OV5640_SetMode(OV5640_Config *Config, OV5640_Mode Mode)
{
    int Status;
    const RegSetting *ModeSettings;

    switch (Mode) {
        case OV5640_MODE_1080P_30FPS:
            ModeSettings = OV5640_1080p30;
            Config->Width = 1920;
            Config->Height = 1080;
            break;

        case OV5640_MODE_720P_60FPS:
            ModeSettings = OV5640_720p60;
            Config->Width = 1280;
            Config->Height = 720;
            break;

        default:
            xil_printf("OV5640: Unsupported mode %d\r\n", Mode);
            return XST_FAILURE;
    }

    Status = WriteRegTable(Config, ModeSettings);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Config->CurrentMode = Mode;
    xil_printf("OV5640: Mode set to %dx%d\r\n", Config->Width, Config->Height);

    return XST_SUCCESS;
}

int OV5640_SetFormat(OV5640_Config *Config, OV5640_Format Format)
{
    int Status;
    const RegSetting *FormatSettings;

    switch (Format) {
        case OV5640_FORMAT_RAW10:
            FormatSettings = OV5640_FormatRAW10;
            break;

        case OV5640_FORMAT_RAW8:
            FormatSettings = OV5640_FormatRAW8;
            break;

        default:
            xil_printf("OV5640: Unsupported format %d\r\n", Format);
            return XST_FAILURE;
    }

    Status = WriteRegTable(Config, FormatSettings);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Config->CurrentFormat = Format;
    return XST_SUCCESS;
}

int OV5640_StreamOn(OV5640_Config *Config)
{
    int Status;

    /* Release software standby */
    Status = OV5640_WriteReg(Config, OV5640_REG_SYS_CTRL0, 0x02);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for stream to start */
    usleep(30000);

    xil_printf("OV5640: Streaming started\r\n");
    return XST_SUCCESS;
}

int OV5640_StreamOff(OV5640_Config *Config)
{
    int Status;

    /* Enter software standby */
    Status = OV5640_WriteReg(Config, OV5640_REG_SYS_CTRL0, 0x42);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    xil_printf("OV5640: Streaming stopped\r\n");
    return XST_SUCCESS;
}

int OV5640_Reset(OV5640_Config *Config)
{
    int Status;

    /* Software reset */
    Status = OV5640_WriteReg(Config, OV5640_REG_SYS_CTRL0, 0x82);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for reset */
    usleep(5000);

    return XST_SUCCESS;
}

int OV5640_SetTestPattern(OV5640_Config *Config, OV5640_TestPattern Pattern)
{
    u8 Value;

    switch (Pattern) {
        case OV5640_TEST_PATTERN_OFF:
            Value = 0x00;
            break;
        case OV5640_TEST_PATTERN_COLOR_BAR:
            Value = 0x80;
            break;
        case OV5640_TEST_PATTERN_COLOR_SQUARE:
            Value = 0x82;
            break;
        case OV5640_TEST_PATTERN_RANDOM:
            Value = 0x81;
            break;
        default:
            return XST_FAILURE;
    }

    return OV5640_WriteReg(Config, OV5640_REG_PRE_ISP_TEST, Value);
}

int OV5640_SetMirror(OV5640_Config *Config, u8 Enable)
{
    u8 Value;
    int Status;

    Status = OV5640_ReadReg(Config, OV5640_REG_TIMING_TC_REG21, &Value);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (Enable) {
        Value |= 0x06;
    } else {
        Value &= ~0x06;
    }

    return OV5640_WriteReg(Config, OV5640_REG_TIMING_TC_REG21, Value);
}

int OV5640_SetFlip(OV5640_Config *Config, u8 Enable)
{
    u8 Value;
    int Status;

    Status = OV5640_ReadReg(Config, OV5640_REG_TIMING_TC_REG20, &Value);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (Enable) {
        Value |= 0x06;
    } else {
        Value &= ~0x06;
    }

    return OV5640_WriteReg(Config, OV5640_REG_TIMING_TC_REG20, Value);
}

int OV5640_SetAutoExposure(OV5640_Config *Config, u8 Enable)
{
    u8 Value;
    int Status;

    Status = OV5640_ReadReg(Config, OV5640_REG_AEC_CTRL00, &Value);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (Enable) {
        Value |= 0x01;
    } else {
        Value &= ~0x01;
    }

    return OV5640_WriteReg(Config, OV5640_REG_AEC_CTRL00, Value);
}

int OV5640_SetAutoWhiteBalance(OV5640_Config *Config, u8 Enable)
{
    u8 Value;
    int Status;

    Status = OV5640_ReadReg(Config, OV5640_REG_AWB_CTRL00, &Value);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    if (Enable) {
        Value |= 0xFF;
    } else {
        Value &= ~0xFF;
    }

    return OV5640_WriteReg(Config, OV5640_REG_AWB_CTRL00, Value);
}

int OV5640_ReadReg(OV5640_Config *Config, u16 RegAddr, u8 *Value)
{
    u8 TxBuffer[2];
    u8 RxBuffer[1];
    int Status;

    TxBuffer[0] = (RegAddr >> 8) & 0xFF;
    TxBuffer[1] = RegAddr & 0xFF;

    /* Send register address */
    Status = XIicPs_MasterSendPolled(Config->IicInstance, TxBuffer, 2, Config->I2cAddr);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for bus idle */
    while (XIicPs_BusIsBusy(Config->IicInstance));

    /* Receive data */
    Status = XIicPs_MasterRecvPolled(Config->IicInstance, RxBuffer, 1, Config->I2cAddr);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for bus idle */
    while (XIicPs_BusIsBusy(Config->IicInstance));

    *Value = RxBuffer[0];
    return XST_SUCCESS;
}

int OV5640_WriteReg(OV5640_Config *Config, u16 RegAddr, u8 Value)
{
    u8 TxBuffer[3];
    int Status;

    TxBuffer[0] = (RegAddr >> 8) & 0xFF;
    TxBuffer[1] = RegAddr & 0xFF;
    TxBuffer[2] = Value;

    Status = XIicPs_MasterSendPolled(Config->IicInstance, TxBuffer, 3, Config->I2cAddr);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* Wait for bus idle */
    while (XIicPs_BusIsBusy(Config->IicInstance));

    return XST_SUCCESS;
}

void OV5640_GetResolution(OV5640_Config *Config, u16 *Width, u16 *Height)
{
    if (Width) *Width = Config->Width;
    if (Height) *Height = Config->Height;
}

void OV5640_PrintInfo(OV5640_Config *Config)
{
    xil_printf("\r\n=== OV5640 Sensor Info ===\r\n");
    xil_printf("Resolution: %dx%d\r\n", Config->Width, Config->Height);
    xil_printf("Mode: %d\r\n", Config->CurrentMode);
    xil_printf("Format: %d\r\n", Config->CurrentFormat);
    xil_printf("Initialized: %s\r\n", Config->Initialized ? "Yes" : "No");
    xil_printf("==========================\r\n\r\n");
}
