// i2c_config.v
// I2C Master for SSM2603 Configuration
// Automatically configures the audio codec on startup

module i2c_config (
    input wire clk,              // 100MHz
    input wire rst_n,
    inout wire i2c_sda,
    output wire i2c_scl,
    output reg config_done
);

    // I2C parameters
    localparam DEVICE_ADDR = 7'h1A;  // SSM2603 I2C address
    localparam CLK_DIV = 250;        // 100MHz / 250 = 400kHz I2C
    
    // Configuration registers (address : data)
    localparam NUM_REGS = 11;
    reg [15:0] config_data [0:NUM_REGS-1];
    
    initial begin
        // Reset and power down
        config_data[0]  = 16'h0C00;  // R6: Power Down - all on
        
        // Analog audio path
        config_data[1]  = 16'h0815;  // R4: Analog path - DAC sel, bypass off
        
        // Digital audio path  
        config_data[2]  = 16'h0A00;  // R5: Digital path - disable mute
        
        // Power control
        config_data[3]  = 16'h0C00;  // R6: Power - all devices on
        
        // Digital interface format
        config_data[4]  = 16'h0E02;  // R7: I2S format, 16-bit, slave mode
        
        // Sample rate (48kHz with 12MHz MCLK)
        config_data[5]  = 16'h1000;  // R8: Normal mode, 48kHz
        
        // Active control
        config_data[6]  = 16'h1201;  // R9: Active
        
        // Left line in
        config_data[7]  = 16'h0017;  // R0: Left line in volume 0dB
        
        // Right line in
        config_data[8]  = 16'h0217;  // R1: Right line in volume 0dB
        
        // Left headphone out
        config_data[9]  = 16'h0479;  // R2: Left HP volume 0dB
        
        // Right headphone out
        config_data[10] = 16'h0679;  // R3: Right HP volume 0dB
    end
    
    // State machine
    localparam IDLE = 0, START = 1, ADDR = 2, WRITE = 3, 
               ACK = 4, STOP = 5, DONE = 6;
    
    reg [3:0] state;
    reg [7:0] reg_index;
    reg [7:0] bit_index;
    reg [15:0] tx_data;
    reg sda_out, sda_oe;
    reg scl_out;
    reg [15:0] clk_count;
    
    assign i2c_sda = sda_oe ? sda_out : 1'bz;
    assign i2c_scl = scl_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            config_done <= 0;
            reg_index <= 0;
            scl_out <= 1;
            sda_out <= 1;
            sda_oe <= 0;
            clk_count <= 0;
        end else begin
            // I2C clock divider
            if (clk_count < CLK_DIV - 1) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 0;
                
                case (state)
                    IDLE: begin
                        if (reg_index < NUM_REGS) begin
                            tx_data <= config_data[reg_index];
                            state <= START;
                            bit_index <= 0;
                        end else begin
                            state <= DONE;
                        end
                    end
                    
                    START: begin
                        sda_oe <= 1;
                        sda_out <= 0;  // Start condition
                        state <= ADDR;
                        bit_index <= 7;
                    end
                    
                    ADDR: begin
                        scl_out <= ~scl_out;
                        if (scl_out) begin  // Falling edge
                            if (bit_index == 0) begin
                                sda_out <= 0;  // Write bit
                                state <= ACK;
                            end else begin
                                sda_out <= DEVICE_ADDR[bit_index-1];
                                bit_index <= bit_index - 1;
                            end
                        end
                    end
                    
                    WRITE: begin
                        scl_out <= ~scl_out;
                        if (scl_out) begin
                            if (bit_index == 0) begin
                                state <= ACK;
                            end else begin
                                sda_out <= tx_data[bit_index-1];
                                bit_index <= bit_index - 1;
                            end
                        end
                    end
                    
                    ACK: begin
                        scl_out <= ~scl_out;
                        if (scl_out) begin
                            sda_oe <= 0;  // Release SDA for ACK
                        end else begin
                            if (bit_index == 16) begin
                                state <= STOP;
                            end else begin
                                bit_index <= 15;
                                state <= WRITE;
                                sda_oe <= 1;
                            end
                        end
                    end
                    
                    STOP: begin
                        sda_oe <= 1;
                        scl_out <= 1;
                        sda_out <= 1;  // Stop condition
                        reg_index <= reg_index + 1;
                        state <= IDLE;
                    end
                    
                    DONE: begin
                        config_done <= 1;
                    end
                endcase
            end
        end
    end
    
endmodule
