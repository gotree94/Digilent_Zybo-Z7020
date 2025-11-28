/*
 * ov5640.c
 * OV5640 Camera Driver Implementation
 */

#include "ov5640.h"
#include "ov5640_init.h"
#include "../platform/platform_config.h"
#include "sleep.h"

/* ============================================================================
 * Private Definitions
 * ============================================================================ */

#define OV5640_EXPECTED_CHIP_ID     0x5640
#define OV5640_I2C_TIMEOUT          1000
#define OV5640_DELAY_MARKER         0x0000

/* Mode configuration table */
static const struct {
    u16 width;
    u16 height;
    u8  fps;
    const ov5640_reg_t *regs;
    u32 reg_count;
} ov5640_mode_table[] = {
    [OV5640_MODE_1080P_30FPS] = {
        .width = 1920,
        .height = 1080,
        .fps = 30,
        .regs = ov5640_1080p30_seq,
        .reg_count = OV5640_1080P30_SEQ_SIZE
    },
    [OV5640_MODE_720P_60FPS] = {
        .width = 1280,
        .height = 720,
        .fps = 60,
        .regs = ov5640_720p60_seq,
        .reg_count = OV5640_720P60_SEQ_SIZE
    },
};

/* ============================================================================
 * Low-level I2C Functions
 * ============================================================================ */

ov5640_status_t ov5640_write_reg(ov5640_inst_t *inst, u16 reg_addr, u8 value)
{
    u8 buf[3];
    int status;
    
    buf[0] = (reg_addr >> 8) & 0xFF;
    buf[1] = reg_addr & 0xFF;
    buf[2] = value;
    
    status = XIicPs_MasterSendPolled(inst->iic_inst, buf, 3, inst->i2c_addr);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("I2C write failed: reg=0x%04X, val=0x%02X\r\n", reg_addr, value);
        return OV5640_STATUS_ERROR_I2C;
    }
    
    /* Wait for I2C bus to be ready */
    while (XIicPs_BusIsBusy(inst->iic_inst));
    
    return OV5640_STATUS_OK;
}

ov5640_status_t ov5640_read_reg(ov5640_inst_t *inst, u16 reg_addr, u8 *value)
{
    u8 buf[2];
    int status;
    
    buf[0] = (reg_addr >> 8) & 0xFF;
    buf[1] = reg_addr & 0xFF;
    
    /* Send register address */
    status = XIicPs_MasterSendPolled(inst->iic_inst, buf, 2, inst->i2c_addr);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("I2C write (addr) failed: reg=0x%04X\r\n", reg_addr);
        return OV5640_STATUS_ERROR_I2C;
    }
    while (XIicPs_BusIsBusy(inst->iic_inst));
    
    /* Read register value */
    status = XIicPs_MasterRecvPolled(inst->iic_inst, value, 1, inst->i2c_addr);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("I2C read failed: reg=0x%04X\r\n", reg_addr);
        return OV5640_STATUS_ERROR_I2C;
    }
    while (XIicPs_BusIsBusy(inst->iic_inst));
    
    return OV5640_STATUS_OK;
}

ov5640_status_t ov5640_write_regs(ov5640_inst_t *inst, 
                                   const void *regs, 
                                   u32 count)
{
    const ov5640_reg_t *reg_array = (const ov5640_reg_t *)regs;
    ov5640_status_t status;
    u32 i;
    
    for (i = 0; i < count; i++) {
        /* Check for delay marker */
        if (reg_array[i].addr == OV5640_DELAY_MARKER) {
            usleep(reg_array[i].val * 1000);
            continue;
        }
        
        status = ov5640_write_reg(inst, reg_array[i].addr, reg_array[i].val);
        if (status != OV5640_STATUS_OK) {
            DEBUG_ERROR("Failed to write reg[%lu]: 0x%04X = 0x%02X\r\n",
                       i, reg_array[i].addr, reg_array[i].val);
            return status;
        }
    }
    
    return OV5640_STATUS_OK;
}

/* ============================================================================
 * Public Functions
 * ============================================================================ */

ov5640_status_t ov5640_init(ov5640_inst_t *inst, XIicPs *iic_inst, u8 i2c_addr)
{
    ov5640_status_t status;
    u16 chip_id;
    
    DEBUG_INFO("Initializing OV5640 camera...\r\n");
    
    /* Initialize instance */
    inst->iic_inst = iic_inst;
    inst->i2c_addr = i2c_addr;
    inst->is_streaming = 0;
    inst->current_mode = OV5640_MODE_1080P_30FPS;
    
    /* Software reset */
    DEBUG_INFO("  Performing software reset...\r\n");
    status = ov5640_write_regs(inst, ov5640_reset_seq, OV5640_RESET_SEQ_SIZE);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("  Reset sequence failed\r\n");
        return status;
    }
    usleep(100000);  /* Wait 100ms after reset */
    
    /* Verify chip ID */
    status = ov5640_get_chip_id(inst, &chip_id);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("  Failed to read chip ID\r\n");
        return status;
    }
    
    if (chip_id != OV5640_EXPECTED_CHIP_ID) {
        DEBUG_ERROR("  Invalid chip ID: 0x%04X (expected 0x%04X)\r\n", 
                   chip_id, OV5640_EXPECTED_CHIP_ID);
        return OV5640_STATUS_ERROR_ID;
    }
    DEBUG_INFO("  Chip ID: 0x%04X\r\n", chip_id);
    
    /* Write initial settings */
    DEBUG_INFO("  Writing initial settings...\r\n");
    status = ov5640_write_regs(inst, ov5640_init_seq, OV5640_INIT_SEQ_SIZE);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("  Initial settings failed\r\n");
        return status;
    }
    
    /* Set default mode (1080p30) */
    DEBUG_INFO("  Setting default mode (1080p30)...\r\n");
    status = ov5640_set_mode(inst, OV5640_MODE_1080P_30FPS);
    if (status != OV5640_STATUS_OK) {
        DEBUG_ERROR("  Mode setting failed\r\n");
        return status;
    }
    
    DEBUG_INFO("  OV5640 initialization complete\r\n");
    return OV5640_STATUS_OK;
}

ov5640_status_t ov5640_get_chip_id(ov5640_inst_t *inst, u16 *chip_id)
{
    ov5640_status_t status;
    u8 id_high, id_low;
    
    status = ov5640_read_reg(inst, OV5640_REG_CHIP_ID_HIGH, &id_high);
    if (status != OV5640_STATUS_OK) {
        return status;
    }
    
    status = ov5640_read_reg(inst, OV5640_REG_CHIP_ID_LOW, &id_low);
    if (status != OV5640_STATUS_OK) {
        return status;
    }
    
    *chip_id = ((u16)id_high << 8) | id_low;
    return OV5640_STATUS_OK;
}

ov5640_status_t ov5640_set_mode(ov5640_inst_t *inst, ov5640_mode_t mode)
{
    ov5640_status_t status;
    u8 was_streaming;
    
    if (mode >= OV5640_MODE_COUNT) {
        DEBUG_ERROR("Invalid mode: %d\r\n", mode);
        return OV5640_STATUS_ERROR_MODE;
    }
    
    /* Stop streaming if active */
    was_streaming = inst->is_streaming;
    if (was_streaming) {
        status = ov5640_stream_stop(inst);
        if (status != OV5640_STATUS_OK) {
            return status;
        }
    }
    
    /* Write mode registers */
    status = ov5640_write_regs(inst, 
                               ov5640_mode_table[mode].regs,
                               ov5640_mode_table[mode].reg_count);
    if (status != OV5640_STATUS_OK) {
        return status;
    }
    
    /* Update instance */
    inst->current_mode = mode;
    inst->config.width = ov5640_mode_table[mode].width;
    inst->config.height = ov5640_mode_table[mode].height;
    inst->config.fps = ov5640_mode_table[mode].fps;
    inst->config.mipi_lanes = 2;
    
    DEBUG_INFO("Mode set: %dx%d @ %dfps\r\n",
              inst->config.width, inst->config.height, inst->config.fps);
    
    /* Restart streaming if it was active */
    if (was_streaming) {
        status = ov5640_stream_start(inst);
    }
    
    return status;
}

ov5640_status_t ov5640_get_config(ov5640_inst_t *inst, ov5640_config_t *config)
{
    *config = inst->config;
    return OV5640_STATUS_OK;
}

ov5640_status_t ov5640_stream_start(ov5640_inst_t *inst)
{
    ov5640_status_t status;
    
    if (inst->is_streaming) {
        DEBUG_WARN("Already streaming\r\n");
        return OV5640_STATUS_OK;
    }
    
    status = ov5640_write_regs(inst, ov5640_stream_on, OV5640_STREAM_ON_SIZE);
    if (status == OV5640_STATUS_OK) {
        inst->is_streaming = 1;
        DEBUG_INFO("Streaming started\r\n");
    }
    
    return status;
}

ov5640_status_t ov5640_stream_stop(ov5640_inst_t *inst)
{
    ov5640_status_t status;
    
    if (!inst->is_streaming) {
        DEBUG_WARN("Not streaming\r\n");
        return OV5640_STATUS_OK;
    }
    
    status = ov5640_write_regs(inst, ov5640_stream_off, OV5640_STREAM_OFF_SIZE);
    if (status == OV5640_STATUS_OK) {
        inst->is_streaming = 0;
        DEBUG_INFO("Streaming stopped\r\n");
    }
    
    return status;
}

ov5640_status_t ov5640_set_brightness(ov5640_inst_t *inst, u8 brightness)
{
    ov5640_status_t status;
    s8 signed_val = (s8)(brightness - 128);
    
    /* SDE control enable */
    status = ov5640_write_reg(inst, 0x5580, 0x04);
    if (status != OV5640_STATUS_OK) return status;
    
    /* Brightness sign */
    status = ov5640_write_reg(inst, 0x5587, (signed_val >= 0) ? 0x00 : 0x08);
    if (status != OV5640_STATUS_OK) return status;
    
    /* Brightness value */
    status = ov5640_write_reg(inst, 0x5588, (signed_val >= 0) ? signed_val : -signed_val);
    
    return status;
}

ov5640_status_t ov5640_set_contrast(ov5640_inst_t *inst, u8 contrast)
{
    ov5640_status_t status;
    
    /* SDE control enable */
    status = ov5640_write_reg(inst, 0x5580, 0x04);
    if (status != OV5640_STATUS_OK) return status;
    
    /* Contrast value */
    status = ov5640_write_reg(inst, 0x5586, contrast);
    
    return status;
}

ov5640_status_t ov5640_set_saturation(ov5640_inst_t *inst, u8 saturation)
{
    ov5640_status_t status;
    
    /* SDE control enable */
    status = ov5640_write_reg(inst, 0x5580, 0x02);
    if (status != OV5640_STATUS_OK) return status;
    
    /* Saturation U */
    status = ov5640_write_reg(inst, 0x5583, saturation);
    if (status != OV5640_STATUS_OK) return status;
    
    /* Saturation V */
    status = ov5640_write_reg(inst, 0x5584, saturation);
    
    return status;
}

ov5640_status_t ov5640_set_hmirror(ov5640_inst_t *inst, u8 enable)
{
    u8 reg_val;
    ov5640_status_t status;
    
    status = ov5640_read_reg(inst, 0x3821, &reg_val);
    if (status != OV5640_STATUS_OK) return status;
    
    if (enable) {
        reg_val |= 0x06;
    } else {
        reg_val &= ~0x06;
    }
    
    return ov5640_write_reg(inst, 0x3821, reg_val);
}

ov5640_status_t ov5640_set_vflip(ov5640_inst_t *inst, u8 enable)
{
    u8 reg_val;
    ov5640_status_t status;
    
    status = ov5640_read_reg(inst, 0x3820, &reg_val);
    if (status != OV5640_STATUS_OK) return status;
    
    if (enable) {
        reg_val |= 0x06;
    } else {
        reg_val &= ~0x06;
    }
    
    return ov5640_write_reg(inst, 0x3820, reg_val);
}

ov5640_status_t ov5640_set_auto_exposure(ov5640_inst_t *inst, u8 enable)
{
    u8 reg_val;
    ov5640_status_t status;
    
    status = ov5640_read_reg(inst, 0x3503, &reg_val);
    if (status != OV5640_STATUS_OK) return status;
    
    if (enable) {
        reg_val &= ~0x01;  /* Enable AEC */
    } else {
        reg_val |= 0x01;   /* Disable AEC */
    }
    
    return ov5640_write_reg(inst, 0x3503, reg_val);
}

ov5640_status_t ov5640_set_auto_wb(ov5640_inst_t *inst, u8 enable)
{
    u8 reg_val;
    ov5640_status_t status;
    
    status = ov5640_read_reg(inst, 0x3406, &reg_val);
    if (status != OV5640_STATUS_OK) return status;
    
    if (enable) {
        reg_val &= ~0x01;  /* Enable AWB */
    } else {
        reg_val |= 0x01;   /* Disable AWB */
    }
    
    return ov5640_write_reg(inst, 0x3406, reg_val);
}

ov5640_status_t ov5640_reset(ov5640_inst_t *inst)
{
    return ov5640_write_regs(inst, ov5640_reset_seq, OV5640_RESET_SEQ_SIZE);
}
