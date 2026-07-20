##############################################################################
## Zybo Z7-20 PL 주변장치 종합 테스트
## 대상: Zybo Z7-20 (XC7Z020CLG400-1)
## Vivado 2022.2 호환
## 사용법: vivado -mode batch -source zybo_z7_pl_test.tcl
##############################################################################

# ======================================================================
# 설정
# ======================================================================
set proj_name   "zybo_z7_pl_test"
set proj_dir    [file dirname [file normalize [info script]]]
set part        "xc7z020clg400-1"

# HDL 소스 디렉토리
set src_dir [file join $proj_dir "src"]
file mkdir $src_dir

# ======================================================================
# HDL 소스 파일 생성
# ======================================================================

# ----- button_debouncer.v ----------------------------------------------
set fp [open [file join $src_dir "button_debouncer.v"] w]
puts $fp {`timescale 1ns / 1ps
module button_debouncer #(
    parameter DEBOUNCE_CNT = 1_250_000
)(
    input  wire clk,
    input  wire btn_in,
    output reg  btn_out
);
    reg [20:0] cnt;
    reg        btn_sync0, btn_sync1;

    always @(posedge clk) begin
        btn_sync0 <= btn_in;
        btn_sync1 <= btn_sync0;
    end

    always @(posedge clk) begin
        if (btn_sync1 != btn_out) begin
            if (cnt == DEBOUNCE_CNT[20:0]) begin
                btn_out <= btn_sync1;
                cnt     <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end else begin
            cnt <= 0;
        end
    end
endmodule}
close $fp

# ----- led_controller.v ------------------------------------------------
set fp [open [file join $src_dir "led_controller.v"] w]
puts $fp {`timescale 1ns / 1ps
module led_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  sw,
    input  wire [3:0]  btn_clean,
    output reg  [3:0]  led,
    output reg         led5_r,
    output reg         led5_g,
    output reg         led5_b,
    output reg         led6_r,
    output reg         led6_g,
    output reg         led6_b
);
    reg [31:0] counter;
    reg [3:0]  prev_btn;

    always @(posedge clk or posedge rst) begin
        if (rst)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_btn <= 0;
            led      <= 0;
            led5_r   <= 0; led5_g <= 0; led5_b <= 0;
            led6_r   <= 0; led6_g <= 0; led6_b <= 0;
        end else begin
            prev_btn <= btn_clean;

            case (sw[1:0])
                2'b00: led <= btn_clean;
                2'b01: led <= sw;
                2'b10: led <= counter[27:24];
                2'b11: led <= {counter[24], btn_clean[3], sw[3], counter[25]};
            endcase

            led5_r <= btn_clean[0] | counter[26];
            led5_g <= btn_clean[1] | counter[25];
            led5_b <= btn_clean[2] | counter[24];

            led6_r <= counter[23];
            led6_g <= counter[22];
            led6_b <= counter[21];
        end
    end
endmodule}
close $fp

# ----- pmod_gpio.v -----------------------------------------------------
set fp [open [file join $src_dir "pmod_gpio.v"] w]
puts $fp {`timescale 1ns / 1ps
module pmod_gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  mode,
    inout  wire [7:0]  ja,
    inout  wire [7:0]  jb,
    inout  wire [7:0]  jc,
    inout  wire [7:0]  jd,
    inout  wire [7:0]  je
);
    reg [7:0] ja_oe, jb_oe, jc_oe, jd_oe, je_oe;
    reg [7:0] ja_out, jb_out, jc_out, jd_out, je_out;

    assign ja = ja_oe[0] ? ja_out[0] : 1'bz;
    assign ja = ja_oe[1] ? ja_out[1] : 1'bz;
    assign ja = ja_oe[2] ? ja_out[2] : 1'bz;
    assign ja = ja_oe[3] ? ja_out[3] : 1'bz;
    assign ja = ja_oe[4] ? ja_out[4] : 1'bz;
    assign ja = ja_oe[5] ? ja_out[5] : 1'bz;
    assign ja = ja_oe[6] ? ja_out[6] : 1'bz;
    assign ja = ja_oe[7] ? ja_out[7] : 1'bz;

    assign jb = jb_oe[0] ? jb_out[0] : 1'bz;
    assign jb = jb_oe[1] ? jb_out[1] : 1'bz;
    assign jb = jb_oe[2] ? jb_out[2] : 1'bz;
    assign jb = jb_oe[3] ? jb_out[3] : 1'bz;
    assign jb = jb_oe[4] ? jb_out[4] : 1'bz;
    assign jb = jb_oe[5] ? jb_out[5] : 1'bz;
    assign jb = jb_oe[6] ? jb_out[6] : 1'bz;
    assign jb = jb_oe[7] ? jb_out[7] : 1'bz;

    assign jc = jc_oe[0] ? jc_out[0] : 1'bz;
    assign jc = jc_oe[1] ? jc_out[1] : 1'bz;
    assign jc = jc_oe[2] ? jc_out[2] : 1'bz;
    assign jc = jc_oe[3] ? jc_out[3] : 1'bz;
    assign jc = jc_oe[4] ? jc_out[4] : 1'bz;
    assign jc = jc_oe[5] ? jc_out[5] : 1'bz;
    assign jc = jc_oe[6] ? jc_out[6] : 1'bz;
    assign jc = jc_oe[7] ? jc_out[7] : 1'bz;

    assign jd = jd_oe[0] ? jd_out[0] : 1'bz;
    assign jd = jd_oe[1] ? jd_out[1] : 1'bz;
    assign jd = jd_oe[2] ? jd_out[2] : 1'bz;
    assign jd = jd_oe[3] ? jd_out[3] : 1'bz;
    assign jd = jd_oe[4] ? jd_out[4] : 1'bz;
    assign jd = jd_oe[5] ? jd_out[5] : 1'bz;
    assign jd = jd_oe[6] ? jd_out[6] : 1'bz;
    assign jd = jd_oe[7] ? jd_out[7] : 1'bz;

    assign je = je_oe[0] ? je_out[0] : 1'bz;
    assign je = je_oe[1] ? je_out[1] : 1'bz;
    assign je = je_oe[2] ? je_out[2] : 1'bz;
    assign je = je_oe[3] ? je_out[3] : 1'bz;
    assign je = je_oe[4] ? je_out[4] : 1'bz;
    assign je = je_oe[5] ? je_out[5] : 1'bz;
    assign je = je_oe[6] ? je_out[6] : 1'bz;
    assign je = je_oe[7] ? je_out[7] : 1'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ja_oe <= 0; ja_out <= 0;
            jb_oe <= 0; jb_out <= 0;
            jc_oe <= 0; jc_out <= 0;
            jd_oe <= 0; jd_out <= 0;
            je_oe <= 0; je_out <= 0;
        end else begin
            case (mode)
                2'b00: begin
                    ja_oe <= 8'hFF; ja_out <= 8'h55;
                    jb_oe <= 8'hFF; jb_out <= 8'hAA;
                    jc_oe <= 8'hFF; jc_out <= 8'h0F;
                    jd_oe <= 8'hFF; jd_out <= 8'hF0;
                    je_oe <= 8'hFF; je_out <= 8'hFF;
                end
                2'b01: begin
                    ja_oe <= 8'h00; jb_oe <= 8'h00;
                    jc_oe <= 8'h00; jd_oe <= 8'h00;
                    je_oe <= 8'h00;
                end
                default: begin
                    ja_oe <= 8'h00; jb_oe <= 8'h00;
                    jc_oe <= 8'h00; jd_oe <= 8'h00;
                    je_oe <= 8'h00;
                end
            endcase
        end
    end
endmodule}
close $fp

# ----- zybo_z7_pl_top.v ------------------------------------------------
set fp [open [file join $src_dir "zybo_z7_pl_top.v"] w]
puts $fp {`timescale 1ns / 1ps
module zybo_z7_pl_top (
    input  wire        sysclk,
    input  wire [3:0]  sw,
    input  wire [3:0]  btn,
    output wire [3:0]  led,
    output wire        led5_r,
    output wire        led5_g,
    output wire        led5_b,
    output wire        led6_r,
    output wire        led6_g,
    output wire        led6_b,
    output wire        fan_fb_pu,
    inout  wire [7:0]  ja,
    inout  wire [7:0]  jb,
    inout  wire [7:0]  jc,
    inout  wire [7:0]  jd,
    inout  wire [7:0]  je,
    output wire        hdmi_tx_hpd,
    input  wire        otg_oc,
    input  wire        eth_int_pu_b,
    output wire        eth_rst_b,
    output wire        cam_gpio,
    output wire        ac_muten
);
    wire rst;
    assign rst = btn[3];

    wire [3:0] btn_clean;
    wire [1:0] pmod_mode;

    button_debouncer db0 (.clk(sysclk), .btn_in(btn[0]), .btn_out(btn_clean[0]));
    button_debouncer db1 (.clk(sysclk), .btn_in(btn[1]), .btn_out(btn_clean[1]));
    button_debouncer db2 (.clk(sysclk), .btn_in(btn[2]), .btn_out(btn_clean[2]));
    button_debouncer db3 (.clk(sysclk), .btn_in(btn[3]), .btn_out(btn_clean[3]));

    assign pmod_mode = sw[3:2];

    led_controller u_led (
        .clk       (sysclk),
        .rst       (rst),
        .sw        (sw),
        .btn_clean (btn_clean),
        .led       (led),
        .led5_r    (led5_r), .led5_g (led5_g), .led5_b (led5_b),
        .led6_r    (led6_r), .led6_g (led6_g), .led6_b (led6_b)
    );

    pmod_gpio u_pmod (
        .clk  (sysclk),
        .rst  (rst),
        .mode (pmod_mode),
        .ja   (ja), .jb (jb), .jc (jc), .jd (jd), .je (je)
    );

    assign fan_fb_pu = 1'bz;
    assign hdmi_tx_hpd = 1'b0;
    assign eth_rst_b = 1'b1;
    assign cam_gpio = 1'b0;
    assign ac_muten = 1'b0;
endmodule}
close $fp

puts "INFO: HDL 소스 파일 생성 완료 ($src_dir)"

# ======================================================================
# XDC 컨스트레인트 파일 생성
# ======================================================================
set fp [open [file join $proj_dir "zybo_z7_pl_test.xdc"] w]
puts $fp {## ==========================================================================
## Zybo Z7-20 PL 주변장치 테스트용 컨스트레인트
## Vivado 2022.2 호환
## ==========================================================================

## Clock (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }]

## Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]

## Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]

## LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## RGB LED 5 (Zybo Z7-20 only)
set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { led5_r }]
set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { led5_g }]
set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { led5_b }]

## RGB LED 6
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led6_r }]
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { led6_g }]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { led6_b }]

## Fan (Zybo Z7-20 only)
set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { fan_fb_pu }]

## Additional Ethernet signals
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { eth_int_pu_b }]
set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { eth_rst_b }]

## USB-OTG over-current detect pin
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { otg_oc }]

## Pmod Header JA (XADC)
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]
set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]
set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]
set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]

## Pmod Header JB (Zybo Z7-20 only)
set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]
set_property -dict { PACKAGE_PIN W8    IOSTANDARD LVCMOS33 } [get_ports { jb[1] }]
set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { jb[2] }]
set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { jb[3] }]
set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { jb[4] }]
set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { jb[5] }]
set_property -dict { PACKAGE_PIN V6    IOSTANDARD LVCMOS33 } [get_ports { jb[6] }]
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { jb[7] }]

## Pmod Header JC
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jc[0] }]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { jc[1] }]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jc[2] }]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { jc[3] }]
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { jc[4] }]
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { jc[5] }]
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { jc[6] }]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { jc[7] }]

## Pmod Header JD
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { jd[0] }]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { jd[1] }]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { jd[2] }]
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { jd[3] }]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { jd[4] }]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { jd[5] }]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { jd[6] }]
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { jd[7] }]

## Pmod Header JE
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { je[0] }]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { je[1] }]
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { je[2] }]
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { je[3] }]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { je[4] }]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { je[5] }]
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { je[6] }]
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { je[7] }]

## HDMI TX
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_hpd }]

## Pcam MIPI CSI-2 - Camera GPIO
set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { cam_gpio }]

## Audio Codec
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { ac_muten }]
}
close $fp

puts "INFO: XDC 컨스트레인트 파일 생성 완료"

# ======================================================================
# Vivado 프로젝트 생성 및 빌드
# ======================================================================
puts "=============================================="
puts " Vivado 프로젝트 생성 시작"
puts "=============================================="

create_project $proj_name $proj_dir -part $part -force

# 소스 파일 추가
add_files -norecurse [glob $src_dir/*.v]
add_files -fileset constrs_1 -norecurse [file join $proj_dir "zybo_z7_pl_test.xdc"]

# 탑 모듈 설정
set_property top zybo_z7_pl_top [current_fileset]

puts "INFO: 프로젝트 생성 완료 - [file join $proj_dir ${proj_name}.xpr]"

# ======================================================================
# 종합 (Synthesis)
# ======================================================================
puts "=============================================="
puts " 종합 (Synthesis) 시작"
puts "=============================================="

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "INFO: 종합 상태 - $synth_status"

if {[string match "*ERROR*" $synth_status]} {
    puts "ERROR: 종합 실패! 로그를 확인하세요."
    open_run synth_1
    exit 1
}

# ======================================================================
# 구현 (Implementation)
# ======================================================================
puts "=============================================="
puts " 구현 (Implementation) 시작"
puts "=============================================="

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "INFO: 구현 상태 - $impl_status"

if {[string match "*ERROR*" $impl_status]} {
    puts "ERROR: 구현 실패! 로그를 확인하세요."
    exit 1
}

# ======================================================================
# 결과 확인
# ======================================================================
puts "=============================================="
puts " 빌드 완료!"
puts "=============================================="
puts ""
puts " 프로젝트: [file join $proj_dir ${proj_name}.xpr]"
puts " 비트스트림: [file join $proj_dir ${proj_name}.runs impl_1 zybo_z7_pl_top.bit]"
puts ""
puts "=============================================="
puts " 테스트 모드 (sw[3:0] 조합)"
puts "=============================================="
puts " sw[3:2] = Pmod GPIO 모드"
puts "   00 : 출력 테스트 패턴"
puts "   01 : 입력 모드 (tristate)"
puts "   10-11 : 기본값"
puts ""
puts " sw[1:0] = LED 모드"
puts "   00 : 버튼 -> LED 직접 연결"
puts "   01 : 스위치 -> LED"
puts "   10 : 카운터 -> LED (점멸)"
puts "   11 : 혼합 모드"
puts ""
puts " btn[3] = 리셋"
puts " btn[0:2] = RGB LED 5 제어"
puts ""
puts "=============================================="
puts " 실행 방법"
puts "=============================================="
puts " vivado -mode batch -source zybo_z7_pl_test.tcl"
puts ""
puts " 프로젝트 열기:"
puts " vivado [file join $proj_dir ${proj_name}.xpr]"
puts "=============================================="

# xsa 파일 생성 (PS 통합용)
write_hw_platform -fixed -include_bit -force -file [file join $proj_dir "${proj_name}.xsa"]
puts "INFO: HW 플랫폼 생성 - [file join $proj_dir ${proj_name}.xsa]"
