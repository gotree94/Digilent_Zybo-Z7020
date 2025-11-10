// zybo_z720_stepper_top.v
module zybo_z720_stepper_top #(
    parameter integer CLK_HZ        = 125_000_000,
    parameter integer STEPS_PER_SEC = 600
)(
    input  wire clk,
    input  wire [3:0] in_signal,
    output wire [3:0] coils
);

    wire rst_n     = in_signal[0];  // Active-Low Reset
    wire sw_run    = in_signal[1];
    wire sw_dir    = in_signal[2];
    wire half_full = in_signal[3];

    // µð¹Ù¿î½º
    wire run_clean, dir_clean;
    debounce #(.CLK_HZ(CLK_HZ), .MS(10)) u_db_run (
        .clk(clk), .rst_n(rst_n), .din(sw_run), .dout(run_clean)
    );
    debounce #(.CLK_HZ(CLK_HZ), .MS(10)) u_db_dir (
        .clk(clk), .rst_n(rst_n), .din(sw_dir), .dout(dir_clean)
    );

    // ½ºÅÜ Å¸ÀÌ¸Ó
    localparam integer TICKS_PER_STEP = (CLK_HZ / STEPS_PER_SEC);
    reg [31:0] tick_cnt;
    wire step_pulse = (tick_cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tick_cnt <= TICKS_PER_STEP - 1;
        else if (run_clean)
            tick_cnt <= (tick_cnt == 0) ? (TICKS_PER_STEP - 1) : (tick_cnt - 1);
        else
            tick_cnt <= TICKS_PER_STEP - 1;
    end

    // ½ºÅÜ ÀÎµ¦½º
    reg [2:0] step_idx;
    reg [2:0] max_idx;
    always @(*) max_idx = (half_full) ? 3'd7 : 3'd3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            step_idx <= 0;
        else if (run_clean && step_pulse) begin
            if (dir_clean) begin
                if (step_idx == max_idx) step_idx <= 0;
                else                     step_idx <= step_idx + 1'b1;
            end else begin
                if (step_idx == 0) step_idx <= max_idx;
                else               step_idx <= step_idx - 1'b1;
            end
        end
    end

    // ½ÃÄö½º ROM
    reg [3:0] patt;
    always @(*) begin
        if (half_full) begin
            case (step_idx)
                3'd0: patt = 4'b1000;
                3'd1: patt = 4'b1100;
                3'd2: patt = 4'b0100;
                3'd3: patt = 4'b0110;
                3'd4: patt = 4'b0010;
                3'd5: patt = 4'b0011;
                3'd6: patt = 4'b0001;
                3'd7: patt = 4'b1001;
                default: patt = 4'b0000;
            endcase
        end else begin
            case (step_idx[1:0])
                2'd0: patt = 4'b1100;
                2'd1: patt = 4'b0110;
                2'd2: patt = 4'b0011;
                2'd3: patt = 4'b1001;
                default: patt = 4'b0000;
            endcase
        end
    end

    assign coils = run_clean ? patt : 4'b0000;

endmodule

// ---------------------- debounce ----------------------
module debounce #(
    parameter integer CLK_HZ = 125_000_000,
    parameter integer MS     = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);
    localparam integer CNT_MAX = (CLK_HZ/1250)*MS;
    reg din_q1, din_q2;
    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_q1 <= 1'b0;
            din_q2 <= 1'b0;
        end else begin
            din_q1 <= din;
            din_q2 <= din_q1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 0;
            dout <= 0;
        end else if (din_q2 == dout) begin
            cnt <= 0;
        end else begin
            if (cnt >= CNT_MAX) begin
                dout <= din_q2;
                cnt  <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
