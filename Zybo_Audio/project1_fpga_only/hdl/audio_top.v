// audio_top.v
// Top module for FPGA-only audio loopback system
// Zybo Z7-20 SSM2603 Audio Codec

module audio_top (
    input wire clk_100mhz,      // 100MHz system clock
    input wire rst_n,            // Active-low reset
    
    // I2C for codec configuration
    inout wire i2c_sda,
    output wire i2c_scl,
    
    // I2S audio interface
    output wire ac_mclk,         // Master clock (12MHz)
    output wire ac_bclk,         // Bit clock (3.072MHz for 48kHz)
    input wire ac_recdat,        // Record data from ADC
    output wire ac_reclrc,       // Record LR clock
    output wire ac_pbdat,        // Playback data to DAC
    output wire ac_pblrc,        // Playback LR clock
    
    // Status LEDs
    output wire [3:0] led
);

    // Clock generation
    wire mclk;           // 12MHz master clock
    wire bclk;           // 3.072MHz bit clock
    wire lrclk;          // 48kHz LR clock
    
    clk_divider clk_div_inst (
        .clk_in(clk_100mhz),
        .rst_n(rst_n),
        .mclk(mclk),
        .bclk(bclk),
        .lrclk(lrclk)
    );
    
    assign ac_mclk = mclk;
    assign ac_bclk = bclk;
    assign ac_reclrc = lrclk;
    assign ac_pblrc = lrclk;
    
    // I2C configuration
    wire config_done;
    
    i2c_config i2c_cfg_inst (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl),
        .config_done(config_done)
    );
    
    // Audio data path
    wire [23:0] audio_left;
    wire [23:0] audio_right;
    wire audio_valid;
    
    // I2S Receiver
    i2s_rx i2s_rx_inst (
        .bclk(bclk),
        .lrclk(lrclk),
        .rst_n(rst_n),
        .sdata(ac_recdat),
        .left_data(audio_left),
        .right_data(audio_right),
        .data_valid(audio_valid)
    );
    
    // I2S Transmitter (loopback)
    i2s_tx i2s_tx_inst (
        .bclk(bclk),
        .lrclk(lrclk),
        .rst_n(rst_n),
        .left_data(audio_left),
        .right_data(audio_right),
        .data_valid(audio_valid),
        .sdata(ac_pbdat)
    );
    
    // Status indicators
    assign led[0] = config_done;
    assign led[1] = audio_valid;
    assign led[2] = lrclk;
    assign led[3] = |audio_left[23:16];  // Audio activity
    
endmodule
