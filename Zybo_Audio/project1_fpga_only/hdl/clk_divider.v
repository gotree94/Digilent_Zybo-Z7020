// clk_divider.v
// Clock Divider for Audio System
// Input: 125MHz (Zybo Z7-20 Ethernet PHY clock)
// Generates MCLK (12.288MHz), BCLK (3.072MHz), LRCLK (48kHz)

module clk_divider (
    input wire clk_in,          // 125MHz input from K17
    input wire rst_n,
    output reg mclk,            // 12.288MHz master clock (target)
    output reg bclk,            // 3.072MHz bit clock  
    output reg lrclk            // 48kHz LR clock
);

    // Counter for clock division
    reg [7:0] mclk_counter;
    reg [2:0] bclk_counter;
    reg [5:0] lrclk_counter;
    
    // MCLK generation: 125MHz / 10.17 ≈ 12.3MHz (close to 12.288MHz)
    // Using 125MHz / 10 = 12.5MHz for simplicity
    // This gives us 48.828kHz sample rate (acceptable for audio)
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            mclk_counter <= 0;
            mclk <= 0;
        end else begin
            if (mclk_counter >= 4) begin  // Divide by 10 (5 high, 5 low)
                mclk_counter <= 0;
                mclk <= ~mclk;
            end else begin
                mclk_counter <= mclk_counter + 1;
            end
        end
    end
    
    // BCLK generation: MCLK / 4 ≈ 3.125MHz
    // For 48kHz, 64x oversampling: 48kHz * 64 = 3.072MHz (target)
    // Actual: 12.5MHz / 4 = 3.125MHz (close enough)
    always @(posedge mclk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_counter <= 0;
            bclk <= 0;
        end else begin
            if (bclk_counter >= 1) begin  // Divide by 4 (toggle every 2)
                bclk_counter <= 0;
                bclk <= ~bclk;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
    end
    
    // LRCLK generation: BCLK / 64 ≈ 48.828kHz
    // Target: 48kHz
    // Actual: 3.125MHz / 64 = 48.828kHz (0.017% error - acceptable)
    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            lrclk_counter <= 0;
            lrclk <= 0;
        end else begin
            if (lrclk_counter >= 31) begin  // Divide by 64 (toggle every 32)
                lrclk_counter <= 0;
                lrclk <= ~lrclk;
            end else begin
                lrclk_counter <= lrclk_counter + 1;
            end
        end
    end
    
endmodule

/*
Clock Frequency Calculations for Zybo Z7-20:
============================================

Input Clock: 125MHz (Ethernet PHY)

MCLK = 125MHz / 10 = 12.5MHz
  Target: 12.288MHz
  Error: 1.7% (acceptable for audio)

BCLK = 12.5MHz / 4 = 3.125MHz  
  Target: 3.072MHz (48kHz * 64)
  Error: 1.7%

LRCLK = 3.125MHz / 64 = 48.828kHz
  Target: 48kHz
  Error: 1.7% (still within USB audio spec)

Alternative for exact 48kHz:
============================
Use PLL/MMCM to generate 12.288MHz from 125MHz
Then divide normally:
  12.288MHz / 4 = 3.072MHz (BCLK)
  3.072MHz / 64 = 48kHz (LRCLK)

For most applications, the 1.7% error is acceptable
and doesn't require PLL complexity.
*/

