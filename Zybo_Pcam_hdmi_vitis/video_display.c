/*
 * video_display.c
 * Video Display (HDMI Output) Module Implementation
 */

#include "video_display.h"
#include "../platform/platform_config.h"
#include "sleep.h"
#include "xil_cache.h"

/* ============================================================================
 * Standard Timing Tables
 * ============================================================================ */

static const video_timing_t standard_timings[] = {
    /* 1080p60 */
    [VIDEO_DISPLAY_RES_1080P] = {
        .width = 1920,
        .height = 1080,
        .h_front_porch = 88,
        .h_sync_width = 44,
        .h_back_porch = 148,
        .v_front_porch = 4,
        .v_sync_width = 5,
        .v_back_porch = 36,
        .pixel_clock = 148500000
    },
    /* 720p60 */
    [VIDEO_DISPLAY_RES_720P] = {
        .width = 1280,
        .height = 720,
        .h_front_porch = 110,
        .h_sync_width = 40,
        .h_back_porch = 220,
        .v_front_porch = 5,
        .v_sync_width = 5,
        .v_back_porch = 20,
        .pixel_clock = 74250000
    },
    /* VGA 60Hz */
    [VIDEO_DISPLAY_RES_VGA] = {
        .width = 640,
        .height = 480,
        .h_front_porch = 16,
        .h_sync_width = 96,
        .h_back_porch = 48,
        .v_front_porch = 10,
        .v_sync_width = 2,
        .v_back_porch = 33,
        .pixel_clock = 25175000
    }
};

/* ============================================================================
 * Private Functions
 * ============================================================================ */

static int setup_vdma_read_channel(video_display_inst_t *inst)
{
    XAxiVdma_DmaSetup read_cfg;
    int status;
    int i;
    
    /* Configure read channel */
    read_cfg.VertSizeInput = inst->config.height;
    read_cfg.HoriSizeInput = inst->config.stride;
    read_cfg.Stride = inst->config.stride;
    read_cfg.FrameDelay = 0;
    read_cfg.EnableCircularBuf = 1;
    read_cfg.EnableSync = 1;
    read_cfg.PointNum = 0;
    read_cfg.EnableFrameCounter = 1;
    read_cfg.FixedFrameStoreAddr = 0;
    read_cfg.GenLockRepeat = 1;  /* Slave mode - repeat frame if needed */
    
    status = XAxiVdma_DmaConfig(&inst->vdma, XAXIVDMA_READ, &read_cfg);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("VDMA read config failed: %d\r\n", status);
        return status;
    }
    
    /* Set frame buffer addresses */
    for (i = 0; i < inst->config.num_frames; i++) {
        status = XAxiVdma_DmaSetBufferAddr(&inst->vdma, XAXIVDMA_READ,
                                           inst->frame_buffer_addr);
        if (status != XST_SUCCESS) {
            DEBUG_ERROR("VDMA set buffer addr failed: %d\r\n", status);
            return status;
        }
    }
    
    return XST_SUCCESS;
}

static void setup_vtc_generator(video_display_inst_t *inst)
{
    XVtc_Timing timing;
    XVtc_Signal signal_cfg;
    XVtc_SourceSelect src_select;
    XVtc_Polarity polarity;
    
    /* Configure timing generator */
    timing.HActiveVideo = inst->timing.width;
    timing.HFrontPorch = inst->timing.h_front_porch;
    timing.HSyncWidth = inst->timing.h_sync_width;
    timing.HBackPorch = inst->timing.h_back_porch;
    timing.VActiveVideo = inst->timing.height;
    timing.VFrontPorch = inst->timing.v_front_porch;
    timing.VSyncWidth = inst->timing.v_sync_width;
    timing.VBackPorch = inst->timing.v_back_porch;
    timing.Interlaced = 0;
    
    /* Signal configuration */
    memset(&signal_cfg, 0, sizeof(signal_cfg));
    signal_cfg.OriginMode = 1;
    signal_cfg.HTotal = inst->timing.width + inst->timing.h_front_porch +
                        inst->timing.h_sync_width + inst->timing.h_back_porch;
    signal_cfg.VTotal = inst->timing.height + inst->timing.v_front_porch +
                        inst->timing.v_sync_width + inst->timing.v_back_porch;
    signal_cfg.HActiveStart = inst->timing.h_sync_width + inst->timing.h_back_porch;
    signal_cfg.HFrontPorchStart = signal_cfg.HActiveStart + inst->timing.width;
    signal_cfg.HSyncStart = 0;
    signal_cfg.VActiveStart = inst->timing.v_sync_width + inst->timing.v_back_porch;
    signal_cfg.VFrontPorchStart = signal_cfg.VActiveStart + inst->timing.height;
    signal_cfg.VSyncStart = 0;
    
    /* Polarity - all active high for HDMI */
    memset(&polarity, 0, sizeof(polarity));
    polarity.ActiveChromaPol = 1;
    polarity.ActiveVideoPol = 1;
    polarity.HSyncPol = 1;
    polarity.VSyncPol = 1;
    polarity.HBlankPol = 1;
    polarity.VBlankPol = 1;
    
    /* Source select - all from register */
    memset(&src_select, 0, sizeof(src_select));
    src_select.VBlankPolSrc = 0;
    src_select.VSyncPolSrc = 0;
    src_select.HBlankPolSrc = 0;
    src_select.HSyncPolSrc = 0;
    src_select.ActiveVideoPolSrc = 0;
    src_select.ActiveChromaPolSrc = 0;
    
    XVtc_SetPolarity(&inst->vtc, &polarity);
    XVtc_SetSource(&inst->vtc, &src_select);
    XVtc_SetGeneratorTiming(&inst->vtc, &timing);
    
    /* Enable generator */
    XVtc_EnableGenerator(&inst->vtc);
}

/* ============================================================================
 * Public Functions
 * ============================================================================ */

video_display_status_t video_display_init(video_display_inst_t *inst,
                                          u16 vdma_id,
                                          u16 vtc_id,
                                          u32 frame_base)
{
    XAxiVdma_Config *vdma_cfg;
    XVtc_Config *vtc_cfg;
    int status;
    int i;
    
    DEBUG_INFO("Initializing video display...\r\n");
    
    /* Initialize instance */
    memset(inst, 0, sizeof(video_display_inst_t));
    
    /* Default configuration (1080p) */
    inst->config.width = FRAME_WIDTH_1080P;
    inst->config.height = FRAME_HEIGHT_1080P;
    inst->config.bytes_per_pixel = BYTES_PER_PIXEL;
    inst->config.stride = inst->config.width * inst->config.bytes_per_pixel;
    inst->config.frame_size = inst->config.stride * inst->config.height;
    inst->config.num_frames = NUM_FRAME_BUFFERS;
    
    /* Default timing (1080p60) */
    inst->timing = standard_timings[VIDEO_DISPLAY_RES_1080P];
    
    /* Setup frame buffer addresses */
    for (i = 0; i < NUM_FRAME_BUFFERS; i++) {
        inst->frame_buffer_addr[i] = frame_base + (i * inst->config.frame_size);
        DEBUG_INFO("  Display buffer %d: 0x%08lX\r\n", i, inst->frame_buffer_addr[i]);
    }
    
    /* Initialize VDMA */
    vdma_cfg = XAxiVdma_LookupConfig(vdma_id);
    if (!vdma_cfg) {
        DEBUG_ERROR("VDMA config lookup failed\r\n");
        return VIDEO_DISPLAY_ERROR_INIT;
    }
    
    status = XAxiVdma_CfgInitialize(&inst->vdma, vdma_cfg, vdma_cfg->BaseAddress);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("VDMA init failed: %d\r\n", status);
        return VIDEO_DISPLAY_ERROR_INIT;
    }
    
    /* Initialize VTC */
    vtc_cfg = XVtc_LookupConfig(vtc_id);
    if (!vtc_cfg) {
        DEBUG_ERROR("VTC config lookup failed\r\n");
        return VIDEO_DISPLAY_ERROR_INIT;
    }
    
    status = XVtc_CfgInitialize(&inst->vtc, vtc_cfg, vtc_cfg->BaseAddress);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("VTC init failed: %d\r\n", status);
        return VIDEO_DISPLAY_ERROR_INIT;
    }
    
    DEBUG_INFO("  Video display initialization complete\r\n");
    return VIDEO_DISPLAY_OK;
}

video_display_status_t video_display_set_resolution(video_display_inst_t *inst,
                                                    video_display_resolution_t resolution)
{
    if (resolution > VIDEO_DISPLAY_RES_VGA) {
        DEBUG_ERROR("Invalid resolution: %d\r\n", resolution);
        return VIDEO_DISPLAY_ERROR_CONFIG;
    }
    
    return video_display_set_timing(inst, &standard_timings[resolution]);
}

video_display_status_t video_display_set_timing(video_display_inst_t *inst,
                                                const video_timing_t *timing)
{
    int i;
    u8 was_running;
    
    DEBUG_INFO("Setting video timing: %dx%d\r\n", timing->width, timing->height);
    
    /* Stop display if running */
    was_running = inst->is_running;
    if (was_running) {
        video_display_stop(inst);
    }
    
    /* Update timing */
    inst->timing = *timing;
    
    /* Update configuration */
    inst->config.width = timing->width;
    inst->config.height = timing->height;
    inst->config.stride = timing->width * inst->config.bytes_per_pixel;
    inst->config.frame_size = inst->config.stride * timing->height;
    
    /* Recalculate frame buffer addresses */
    u32 frame_base = inst->frame_buffer_addr[0];
    for (i = 0; i < NUM_FRAME_BUFFERS; i++) {
        inst->frame_buffer_addr[i] = frame_base + (i * inst->config.frame_size);
    }
    
    /* Restart if was running */
    if (was_running) {
        video_display_start(inst);
    }
    
    return VIDEO_DISPLAY_OK;
}

video_display_status_t video_display_start(video_display_inst_t *inst)
{
    int status;
    
    if (inst->is_running) {
        DEBUG_WARN("Video display already running\r\n");
        return VIDEO_DISPLAY_OK;
    }
    
    DEBUG_INFO("Starting video display...\r\n");
    
    /* Configure VDMA read channel */
    status = setup_vdma_read_channel(inst);
    if (status != XST_SUCCESS) {
        return VIDEO_DISPLAY_ERROR_CONFIG;
    }
    
    /* Configure VTC generator */
    setup_vtc_generator(inst);
    
    /* Start VDMA */
    status = XAxiVdma_DmaStart(&inst->vdma, XAXIVDMA_READ);
    if (status != XST_SUCCESS) {
        DEBUG_ERROR("VDMA start failed: %d\r\n", status);
        return VIDEO_DISPLAY_ERROR_START;
    }
    
    inst->is_running = 1;
    inst->frame_count = 0;
    inst->current_frame = 0;
    
    DEBUG_INFO("  Video display started\r\n");
    return VIDEO_DISPLAY_OK;
}

video_display_status_t video_display_stop(video_display_inst_t *inst)
{
    if (!inst->is_running) {
        DEBUG_WARN("Video display not running\r\n");
        return VIDEO_DISPLAY_OK;
    }
    
    DEBUG_INFO("Stopping video display...\r\n");
    
    /* Stop VDMA */
    XAxiVdma_DmaStop(&inst->vdma, XAXIVDMA_READ);
    
    /* Disable VTC generator */
    XVtc_DisableGenerator(&inst->vtc);
    
    inst->is_running = 0;
    
    DEBUG_INFO("  Video display stopped\r\n");
    return VIDEO_DISPLAY_OK;
}

video_display_status_t video_display_set_frame(video_display_inst_t *inst,
                                               u32 frame_addr)
{
    /* Update all frame buffer pointers to the same address */
    /* This causes the VDMA to continuously read from the same buffer */
    u32 addrs[NUM_FRAME_BUFFERS];
    int i;
    
    for (i = 0; i < NUM_FRAME_BUFFERS; i++) {
        addrs[i] = frame_addr;
    }
    
    XAxiVdma_DmaSetBufferAddr(&inst->vdma, XAXIVDMA_READ, addrs);
    
    return VIDEO_DISPLAY_OK;
}

u32 video_display_get_frame_count(video_display_inst_t *inst)
{
    return inst->frame_count;
}

void video_display_frame_done_handler(video_display_inst_t *inst)
{
    inst->frame_count++;
    inst->current_frame = (inst->current_frame + 1) % NUM_FRAME_BUFFERS;
}

video_display_status_t video_display_get_standard_timing(
    video_display_resolution_t resolution,
    video_timing_t *timing)
{
    if (resolution > VIDEO_DISPLAY_RES_VGA) {
        return VIDEO_DISPLAY_ERROR_CONFIG;
    }
    
    *timing = standard_timings[resolution];
    return VIDEO_DISPLAY_OK;
}
