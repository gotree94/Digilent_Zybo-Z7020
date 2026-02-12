// clk_divider.v
// Clock Divider for Audio System
// Generates MCLK (12MHz), BCLK (3.072MHz), LRCLK (48kHz)

module clk_divider (
    input wire clk_in,          // 100MHz input
    input wire rst_n,
    output reg mclk,            // 12MHz master clock
    output reg bclk,            // 3.072MHz bit clock  
    output reg lrclk            // 48kHz LR clock
);

    // Counter for clock division
    reg [15:0] mclk_counter;
    reg [7:0] bclk_counter;
    reg [5:0] lrclk_counter;
    
    // MCLK generation: 100MHz / 8.33 ≈ 12MHz
    // Using 100MHz / 8 = 12.5MHz for simplicity
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            mclk_counter <= 0;
            mclk <= 0;
        end else begin
            if (mclk_counter >= 3) begin  // Divide by 8
                mclk_counter <= 0;
                mclk <= ~mclk;
            end else begin
                mclk_counter <= mclk_counter + 1;
            end
        end
    end
    
    // BCLK generation: MCLK / 4 = 3.072MHz
    // For 48kHz, 16-bit stereo: 48k * 2 * 16 = 1.536MHz
    // Using MCLK/4 for 64x oversampling
    always @(posedge mclk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_counter <= 0;
            bclk <= 0;
        end else begin
            if (bclk_counter >= 1) begin  // Divide by 4
                bclk_counter <= 0;
                bclk <= ~bclk;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
    end
    
    // LRCLK generation: BCLK / 64 = 48kHz
    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            lrclk_counter <= 0;
            lrclk <= 0;
        end else begin
            if (lrclk_counter >= 31) begin  // Divide by 64
                lrclk_counter <= 0;
                lrclk <= ~lrclk;
            end else begin
                lrclk_counter <= lrclk_counter + 1;
            end
        end
    end
    
endmodule
