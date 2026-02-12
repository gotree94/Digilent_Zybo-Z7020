// i2s_rx.v
// I2S Receiver Module
// Receives 24-bit stereo audio data

module i2s_rx (
    input wire bclk,
    input wire lrclk,
    input wire rst_n,
    input wire sdata,
    output reg [23:0] left_data,
    output reg [23:0] right_data,
    output reg data_valid
);

    reg lrclk_prev;
    reg [4:0] bit_count;
    reg [23:0] shift_reg;
    
    always @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            left_data <= 24'h0;
            right_data <= 24'h0;
            data_valid <= 0;
            bit_count <= 0;
            lrclk_prev <= 0;
            shift_reg <= 24'h0;
        end else begin
            lrclk_prev <= lrclk;
            data_valid <= 0;
            
            // Detect LR clock edge
            if (lrclk != lrclk_prev) begin
                if (lrclk_prev == 0) begin  // Left channel complete
                    left_data <= shift_reg;
                    data_valid <= 1;
                end else begin              // Right channel complete
                    right_data <= shift_reg;
                end
                bit_count <= 0;
                shift_reg <= 24'h0;
            end else begin
                // Shift in data (MSB first)
                if (bit_count < 24) begin
                    shift_reg <= {shift_reg[22:0], sdata};
                    bit_count <= bit_count + 1;
                end
            end
        end
    end
    
endmodule
