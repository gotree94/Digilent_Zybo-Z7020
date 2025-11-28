/*
 * ov5640.h
 * OV5640 Camera Driver Header
 */

#ifndef OV5640_H
#define OV5640_H

#include "xil_types.h"
#include "xiicps.h"

/* ============================================================================
 * Type Definitions
 * ============================================================================ */

/* Camera resolution modes */
typedef enum {
    OV5640_MODE_1080P_30FPS = 0,
    OV5640_MODE_720P_60FPS,
    OV5640_MODE_VGA_90FPS,
    OV5640_MODE_COUNT
} ov5640_mode_t;

/* Camera status */
typedef enum {
    OV5640_STATUS_OK = 0,
    OV5640_STATUS_ERROR_I2C,
    OV5640_STATUS_ERROR_ID,
    OV5640_STATUS_ERROR_INIT,
    OV5640_STATUS_ERROR_MODE,
    OV5640_STATUS_ERROR_TIMEOUT
} ov5640_status_t;

/* Camera configuration structure */
typedef struct {
    u16 width;
    u16 height;
    u8  fps;
    u8  mipi_lanes;
} ov5640_config_t;

/* Camera instance structure */
typedef struct {
    XIicPs *iic_inst;
    u8 i2c_addr;
    ov5640_mode_t current_mode;
    ov5640_config_t config;
    u8 is_streaming;
} ov5640_inst_t;

/* ============================================================================
 * Function Prototypes
 * ============================================================================ */

/**
 * Initialize OV5640 camera
 * @param inst      Pointer to camera instance
 * @param iic_inst  Pointer to initialized I2C instance
 * @param i2c_addr  I2C address of camera (default 0x3C)
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_init(ov5640_inst_t *inst, XIicPs *iic_inst, u8 i2c_addr);

/**
 * Read camera chip ID
 * @param inst      Pointer to camera instance
 * @param chip_id   Pointer to store chip ID
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_get_chip_id(ov5640_inst_t *inst, u16 *chip_id);

/**
 * Set camera resolution mode
 * @param inst      Pointer to camera instance
 * @param mode      Resolution mode
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_mode(ov5640_inst_t *inst, ov5640_mode_t mode);

/**
 * Get current camera configuration
 * @param inst      Pointer to camera instance
 * @param config    Pointer to store configuration
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_get_config(ov5640_inst_t *inst, ov5640_config_t *config);

/**
 * Start video streaming
 * @param inst      Pointer to camera instance
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_stream_start(ov5640_inst_t *inst);

/**
 * Stop video streaming
 * @param inst      Pointer to camera instance
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_stream_stop(ov5640_inst_t *inst);

/**
 * Set camera brightness
 * @param inst      Pointer to camera instance
 * @param brightness Brightness value (0-255)
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_brightness(ov5640_inst_t *inst, u8 brightness);

/**
 * Set camera contrast
 * @param inst      Pointer to camera instance
 * @param contrast  Contrast value (0-255)
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_contrast(ov5640_inst_t *inst, u8 contrast);

/**
 * Set camera saturation
 * @param inst      Pointer to camera instance
 * @param saturation Saturation value (0-255)
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_saturation(ov5640_inst_t *inst, u8 saturation);

/**
 * Set camera horizontal mirror
 * @param inst      Pointer to camera instance
 * @param enable    1 to enable, 0 to disable
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_hmirror(ov5640_inst_t *inst, u8 enable);

/**
 * Set camera vertical flip
 * @param inst      Pointer to camera instance
 * @param enable    1 to enable, 0 to disable
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_vflip(ov5640_inst_t *inst, u8 enable);

/**
 * Set auto exposure enable
 * @param inst      Pointer to camera instance
 * @param enable    1 to enable, 0 to disable
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_auto_exposure(ov5640_inst_t *inst, u8 enable);

/**
 * Set auto white balance enable
 * @param inst      Pointer to camera instance
 * @param enable    1 to enable, 0 to disable
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_set_auto_wb(ov5640_inst_t *inst, u8 enable);

/**
 * Perform software reset
 * @param inst      Pointer to camera instance
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_reset(ov5640_inst_t *inst);

/* ============================================================================
 * Low-level Register Access
 * ============================================================================ */

/**
 * Write single register
 * @param inst      Pointer to camera instance
 * @param reg_addr  16-bit register address
 * @param value     8-bit value to write
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_write_reg(ov5640_inst_t *inst, u16 reg_addr, u8 value);

/**
 * Read single register
 * @param inst      Pointer to camera instance
 * @param reg_addr  16-bit register address
 * @param value     Pointer to store 8-bit value
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_read_reg(ov5640_inst_t *inst, u16 reg_addr, u8 *value);

/**
 * Write register array
 * @param inst      Pointer to camera instance
 * @param regs      Pointer to register array
 * @param count     Number of registers
 * @return          OV5640_STATUS_OK on success
 */
ov5640_status_t ov5640_write_regs(ov5640_inst_t *inst, 
                                   const void *regs, 
                                   u32 count);

#endif /* OV5640_H */
