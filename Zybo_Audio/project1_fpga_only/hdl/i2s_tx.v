// i2s_tx.v
// I2S Transmitter Module
// Transmits 24-bit stereo audio data

module i2s_tx (
    input wire bclk,
    input wire lrclk,
    input wire rst_n,
    input wire [23:0] left_data,
    input wire [23:0] right_data,
    input wire data_valid,
    output reg sdata
);

    reg lrclk_prev;
    reg [4:0] bit_count;
    reg [23:0] tx_shift_reg;
    reg [23:0] left_buffer;
    reg [23:0] right_buffer;
    
    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            sdata <= 0;
            bit_count <= 0;
            lrclk_prev <= 0;
            tx_shift_reg <= 24'h0;
            left_buffer <= 24'h0;
            right_buffer <= 24'h0;
        end else begin
            lrclk_prev <= lrclk;
            
            // Buffer incoming data
            if (data_valid) begin
                left_buffer <= left_data;
                right_buffer <= right_data;
            end
            
            // Detect LR clock edge
            if (lrclk != lrclk_prev) begin
                if (lrclk == 0) begin      // Start left channel
                    tx_shift_reg <= left_buffer;
                end else begin             // Start right channel
                    tx_shift_reg <= right_buffer;
                end
                bit_count <= 0;
            end else begin
                // Shift out data (MSB first)
                if (bit_count < 24) begin
                    sdata <= tx_shift_reg[23];
                    tx_shift_reg <= {tx_shift_reg[22:0], 1'b0};
                    bit_count <= bit_count + 1;
                end else begin
                    sdata <= 0;
                end
            end
        end
    end
    
endmodule
