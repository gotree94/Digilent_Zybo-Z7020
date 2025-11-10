# Zybo_StepMotor

## Standalone Step Motor Controller : StepMotor(28BYJ-48) 5V - ULN2003

### ⚙️ 1.회로

<img width="357" height="241" alt="002" src="https://github.com/user-attachments/assets/e3528fc4-6645-4929-b022-2307864cf76e" />
<br>
<img width="608" height="186" alt="003" src="https://github.com/user-attachments/assets/e3575f39-af0e-401a-8ddc-dfcf0dacb800" />
<br>

---
https://cookierobotics.com/042/

<img width="284" height="185" alt="001" src="https://github.com/user-attachments/assets/a0466c38-e394-4f88-85ea-c284e5b2f055" />
<img width="384" height="185" alt="002" src="https://github.com/user-attachments/assets/1b102543-878c-488b-a975-708d9e810989" />
<br>
<img width="296" height="134" alt="003" src="https://github.com/user-attachments/assets/c6bcccd2-034f-4bcf-b247-cc0b3bcb0c4e" />
<img width="292" height="201" alt="004" src="https://github.com/user-attachments/assets/471f5e82-0914-4f7d-a2f8-f7d2527c72af" />
<br>

---

### ⚙️ 2. Full-Step (풀스텝) 구동

한 번에 두 코일씩(예: A + B, B + C, C + D, D + A) 에 전류를 흘립니다.

|스텝 순서	|코일 상태	|출력 비트 (A,B,C,D)|
|:----:|:----:|:----:|
|1	|A+B	|1100|
|2	|B+C	|0110|
|3	|C+D	|0011|
|4	|D+A	|1001|

* 특징
  * ✅ 장점
     * 두 코일이 동시에 자력을 내므로 토크가 크다.
     * 단순한 제어(4패턴).
   * ⚠️ 단점
     * 스텝 각도가 큼 → 해상도 낮음.
     * 진동이 커서 소음이 날 수 있음.

* 28BYJ-48의 풀스텝 모터 기준 기계적 스텝각 ≈ 11.25°,
* 기어비(64:1) 적용 시 출력축 1스텝 ≈ 0.1758°

### ⚙️ 3. Half-Step (하프스텝) 구동

* 한 코일만 켜는 스텝과 두 코일을 동시에 켜는 스텝을 교대로 실행합니다.

|스텝 순서	|코일 상태	|출력 비트 (A,B,C,D)|
|:----:|:----:|:----:|
|1	|A	|1000|
|2	|A+B	|1100|
|3	|B	|0100|
|4	|B+C	|0110|
|5	|C	|0010|
|6	|C+D	|0011|
|7	|D	|0001|
|8	|D+A	|1001|

* 특징
   * ✅ 장점
      * 스텝 해상도 2배 증가 (Full-Step의 절반 각도).
      * 움직임이 부드럽고 진동 적음.
    * ⚠️ 단점
      * 단일 코일 구간에서는 토크가 조금 떨어짐.
      * 제어가 약간 복잡(8패턴).

* 28BYJ-48의 하프스텝 스텝각 ≈ 5.625°,
* 기어비(64:1) 적용 시 출력축 1스텝 ≈ 0.0879°

### 🧩 디바운스

* 1)카운트 기준 계산 → 2)입력 신호 동기화 (메타스테이블 방지) → 3)안정 상태 판정 로직

* 🔍 동작 예시 (파형으로 이해)

| 시간	|din (입력)	|din_q2 (동기화)|	cnt	|dout (출력)	|설명|
|:---:|:---:|:---:|:---:|:---:|:---:| 
| t0	|0	|0	|0	|0	|초기 상태|
| t1	|1	|1	|↑	|0	|입력이 변해서 카운트 시작|
| t2~t3	|1	|1	|→ CNT_MAX 도달|	0→1|	10ms 이상 유지 → 출력 반영|
| t4	|1→0 (노이즈)	|0	|리셋	|1	|노이즈 순간은 무시됨|
| t5	|0	|0	|↑	|1	|10ms 이상 유지 시 다음 반전 허용|

### ⚙️ 4. 타이밍 설정 팁
| 목표	| 설정 예시| 
|:---:|:---:| 
| 버튼	| 10~20ms| 
| 토글 스위치	| 5~10ms| 
| 리셋 신호	| 1ms 이하 (빠르게 반응)| 

```verilog
// zybo_z720_stepper_top.v
module zybo_z720_stepper_top #(
    parameter integer CLK_HZ        = 125_000_000, 
    parameter integer STEPS_PER_SEC = 600,         // 초당 스텝 수(half-step 기준). 28BYJ-48은 200~600 정도 무난
    parameter         HALF_STEP     = 1            // 1: half-step(8패턴), 0: full-step(4패턴)
)(
    input  wire clk,         // 보드 클럭
    input  wire rst_n,       // Active-Low Reset
    input  wire sw_run,      // RUN/STOP 스위치 (1=RUN, 0=STOP)
    input  wire sw_dir,      // 1=Forward, 0=Backward
    output wire [3:0] coils  // ULN2003 IN1..IN4 로 연결 (논리 '1'이면 해당 코일 ON)
);

    // -------- 스위치 동기화/디바운스 --------
    wire run_clean, dir_clean;

    debounce #(
        .CLK_HZ(CLK_HZ),
        .MS(10)             // 10ms 디바운스
    ) u_db_run (
        .clk(clk), .rst_n(rst_n),
        .din(sw_run),
        .dout(run_clean)
    );

    debounce #(
        .CLK_HZ(CLK_HZ),
        .MS(10)
    ) u_db_dir (
        .clk(clk), .rst_n(rst_n),
        .din(sw_dir),
        .dout(dir_clean)
    );

    // -------- 스텝 타이머 --------
    localparam integer TICKS_PER_STEP = (CLK_HZ / STEPS_PER_SEC);
    reg [31:0] tick_cnt;
    wire step_pulse = (tick_cnt == 0);

    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            tick_cnt <= TICKS_PER_STEP - 1;
        end else if (run_clean) begin
            tick_cnt <= (tick_cnt == 0) ? (TICKS_PER_STEP - 1) : (tick_cnt - 1);
        end else begin
            tick_cnt <= TICKS_PER_STEP - 1; // STOP 상태에선 주기 카운터 정지/유지
        end
    end

    // -------- 스텝 인덱스 (0..7 half-step) --------
    localparam integer MAX_IDX = (HALF_STEP ? 7 : 3);
    reg [2:0] step_idx; // 충분한 비트 폭

    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            step_idx <= 0;
        end else if (run_clean && step_pulse) begin
            if (dir_clean) begin
                // Forward
                if (step_idx == MAX_IDX) step_idx <= 0;
                else                     step_idx <= step_idx + 1'b1;
            end else begin
                // Backward
                if (step_idx == 0)       step_idx <= MAX_IDX[2:0];
                else                     step_idx <= step_idx - 1'b1;
            end
        end
    end

    // -------- 시퀀스 ROM: 28BYJ-48 권장 패턴 --------
    // 코일 순서: [A,B,C,D] = [3,2,1,0] 비트로 가정. ULN2003 IN1=A, IN2=B, IN3=C, IN4=D 에 맞춰 배선하세요.
    reg [3:0] patt;

    always @(*) begin
        if (HALF_STEP) begin
            // Half-step (8-step) : A, A+B, B, B+C, C, C+D, D, D+A
            case (step_idx)
                3'd0: patt = 4'b1000; // A
                3'd1: patt = 4'b1100; // A+B
                3'd2: patt = 4'b0100; // B
                3'd3: patt = 4'b0110; // B+C
                3'd4: patt = 4'b0010; // C
                3'd5: patt = 4'b0011; // C+D
                3'd6: patt = 4'b0001; // D
                3'd7: patt = 4'b1001; // D+A
                default: patt = 4'b0000;
            endcase
        end else begin
            // Full-step (4-step) : A+B, B+C, C+D, D+A
            case (step_idx[1:0])
                2'd0: patt = 4'b1100; // A+B
                2'd1: patt = 4'b0110; // B+C
                2'd2: patt = 4'b0011; // C+D
                2'd3: patt = 4'b1001; // D+A
                default: patt = 4'b0000;
            endcase
        end
    end

    assign coils = run_clean ? patt : 4'b0000; // STOP 시 모든 코일 OFF

endmodule

// ---------------------- 디바운스 모듈 ----------------------
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

    // 2FF 동기화
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            din_q1 <= 1'b0;
            din_q2 <= 1'b0;
        end else begin
            din_q1 <= din;
            din_q2 <= din_q1;
        end
    end

    // 안정 시간 카운트
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            cnt  <= 0;
            dout <= 0;
        end else if (din_q2 == dout) begin
            cnt <= 0; // 상태 유지
        end else begin
            if (cnt >= CNT_MAX) begin
                dout <= din_q2; // 충분히 유지되면 상태 갱신
                cnt  <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
```

```xdc
## This file is a general .xdc for the Zybo Z7 Rev. B
## It is compatible with the Zybo Z7-20 and Zybo Z7-10
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

##Clock signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

##Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw_run }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw_dir }]; #IO_L24P_T3_34 Sch=sw[1]
#set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; #IO_L9P_T1_DQS_34 Sch=sw[3]
                                                                                                                                 
##Pmod Header JE                                                                                                                  
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { coils[0] }]; #IO_L4P_T0_34 Sch=je[1]						 
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { coils[1] }]; #IO_L18N_T2_34 Sch=je[2]                     
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { coils[2] }]; #IO_25_35 Sch=je[3]                          
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { coils[3] }]; #IO_L19P_T3_35 Sch=je[4]                     
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { je[4] }]; #IO_L3N_T0_DQS_34 Sch=je[7]                  
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { je[5] }]; #IO_L9N_T1_DQS_34 Sch=je[8]                  
#set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { je[6] }]; #IO_L20P_T3_34 Sch=je[9]                     
#set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { je[7] }]; #IO_L7N_T1_34 Sch=je[10]                    

```

---

#  AXI 인터페이스

* 1) 스텝 코어 (AXI 외부용, 런타임 제어 핀 방식)
   * 아래는 기존 코드를 런타임 제어 신호로 간소화한 코어입니다.
   * half_step_i, run_i, dir_i, ticks_per_step_i 입력으로 동작
   * 디바운스 제거(리눅스에서 제어하므로 불필요)
   * Active-Low reset (rst_n)
* Tools -> Create and Package New IP
   * Vivado에서는 이 파일들을 Create and Package IP 로 묶어 AXI4-Lite Slave Peripheral 로 등록한 뒤,
   * Zynq PS와 AXI SmartConnect/Interconnect에 연결.
   * coils[3:0]는 기존 XDC(ULN2003) 핀에 매핑합니다.
   * s_axi_aclk 는 PS의 FCLK_CLK0(예: 100MHz 또는 125MHz) 를 사용.

```
// stepper_core.v : runtime-controllable stepper engine (no AXI here)
module stepper_core #(
    parameter integer CLK_HZ = 125_000_000
)(
    input  wire        clk,
    input  wire        rst_n,             // Active-Low Reset
    input  wire        run_i,             // 1=RUN, 0=STOP
    input  wire        dir_i,             // 1=Forward, 0=Backward
    input  wire        half_step_i,       // 1=half-step(8), 0=full-step(4)
    input  wire [31:0] ticks_per_step_i,  // reload value: clk_hz / steps_per_sec
    output wire [3:0]  coils,             // ULN2003 IN1..IN4
    output wire        step_pulse_o,      // 디버깅용(한 스텝 경계 펄스)
    output wire [2:0]  step_idx_o         // 현재 스텝 인덱스
);

    // -------- 타이머 --------
    reg [31:0] tick_cnt;
    wire step_pulse = (tick_cnt == 0);
    assign step_pulse_o = step_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_cnt <= (ticks_per_step_i>0) ? (ticks_per_step_i-1) : 32'd0;
        end else if (run_i) begin
            tick_cnt <= (tick_cnt==0)
                ? ((ticks_per_step_i>0)?(ticks_per_step_i-1):32'd0)
                : (tick_cnt-1);
        end else begin
            tick_cnt <= (ticks_per_step_i>0) ? (ticks_per_step_i-1) : 32'd0;
        end
    end

    // -------- 스텝 인덱스 --------
    wire [2:0] max_idx = half_step_i ? 3'd7 : 3'd3;
    reg  [2:0] step_idx;
    assign step_idx_o = step_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_idx <= 3'd0;
        end else if (run_i && step_pulse) begin
            if (dir_i) begin
                step_idx <= (step_idx == max_idx) ? 3'd0 : (step_idx + 1'b1);
            end else begin
                step_idx <= (step_idx == 3'd0) ? max_idx : (step_idx - 1'b1);
            end
        end
    end

    // -------- 패턴 ROM --------
    reg [3:0] patt;
    always @(*) begin
        if (half_step_i) begin
            case (step_idx)
                3'd0: patt = 4'b1000; // A
                3'd1: patt = 4'b1100; // A+B
                3'd2: patt = 4'b0100; // B
                3'd3: patt = 4'b0110; // B+C
                3'd4: patt = 4'b0010; // C
                3'd5: patt = 4'b0011; // C+D
                3'd6: patt = 4'b0001; // D
                3'd7: patt = 4'b1001; // D+A
                default: patt = 4'b0000;
            endcase
        end else begin
            case (step_idx[1:0])
                2'd0: patt = 4'b1100; // A+B
                2'd1: patt = 4'b0110; // B+C
                2'd2: patt = 4'b0011; // C+D
                2'd3: patt = 4'b1001; // D+A
                default: patt = 4'b0000;
            endcase
        end
    end

    assign coils = run_i ? patt : 4'b0000;

endmodule
```

---

=================================================
## 해결안 1
=================================================

<img width="995" height="484" alt="002" src="https://github.com/user-attachments/assets/a9de87aa-6fda-4716-ac66-10f6feb62b9b" />
<br>
<img width="1461" height="500" alt="001" src="https://github.com/user-attachments/assets/280f59ff-1195-457e-b728-81e9364a7c7e" />
<br>

```verilog
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

    // 디바운스
    wire run_clean, dir_clean;
    debounce #(.CLK_HZ(CLK_HZ), .MS(10)) u_db_run (
        .clk(clk), .rst_n(rst_n), .din(sw_run), .dout(run_clean)
    );
    debounce #(.CLK_HZ(CLK_HZ), .MS(10)) u_db_dir (
        .clk(clk), .rst_n(rst_n), .din(sw_dir), .dout(dir_clean)
    );

    // 스텝 타이머
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

    // 스텝 인덱스
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

    // 시퀀스 ROM
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

```


```xdc
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { coils[0] }]; #IO_L4P_T0_34 Sch=je[1]						 
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { coils[1] }]; #IO_L18N_T2_34 Sch=je[2]                     
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { coils[2] }]; #IO_25_35 Sch=je[3]                          
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { coils[3] }]; #IO_L19P_T3_35 Sch=je[4]
```


```shc
# GPIO export (LED0 = GPIO 1020 가정)
echo 1020 > /sys/class/gpio/export
echo 1021 > /sys/class/gpio/export
echo 1022 > /sys/class/gpio/export
echo 1023 > /sys/class/gpio/export

# 출력 모드 설정
echo out > /sys/class/gpio/gpio1020/direction
echo out > /sys/class/gpio/gpio1021/direction
echo out > /sys/class/gpio/gpio1022/direction
echo out > /sys/class/gpio/gpio1023/direction


# LED 켜기
echo 1 > /sys/class/gpio/gpio1020/value
echo 1 > /sys/class/gpio/gpio1021/value
echo 1 > /sys/class/gpio/gpio1022/value
echo 1 > /sys/class/gpio/gpio1023/value

# LED 끄기
echo 0 > /sys/class/gpio/gpio1020/value
echo 0 > /sys/class/gpio/gpio1021/value
echo 0 > /sys/class/gpio/gpio1022/value
echo 0 > /sys/class/gpio/gpio1023/value

# GPIO unexport
echo 1020 > /sys/class/gpio/unexport


1020 - reset (0 : reset, 1 : unreset)
1021 - run (0 : stop, 1: run)
1022 - dir (0:frw, 1:back)
1023 - half_full (0:half, 1: full)
```

### stepctl.c (ARM Compile)

```
arm-linux-gnueabihf-gcc -o stepctl stepctl.c
```

```c
// stepctl.c — Zybo Z7-20 + PetaLinux에서 sysfs GPIO(1020~1023)로 스텝모터 제어
// 사용법: 보드의 UART 콘솔(ttyPS0)에서 ./stepctl 실행 후 명령 입력
// 명령 예시: show / set run 1 / toggle dir / pulse reset 100 / watch 500 / quit

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>

typedef struct {
    const char *name; // 논리명
    int gpio;         // sysfs 번호
    const char *desc; // 설명
} gpio_map_t;

static gpio_map_t gmap[] = {
    {"reset",     1020, "0: reset(assert), 1: unreset(deassert)"},
    {"run",       1021, "0: stop, 1: run"},
    {"dir",       1022, "0: forward, 1: backward"},
    {"half_full", 1023, "0: half-step, 1: full-step"},
};
static const int GMAP_N = sizeof(gmap)/sizeof(gmap[0]);

static volatile sig_atomic_t g_stop = 0;
static void on_sigint(int sig){ (void)sig; g_stop = 1; }

static int write_str(const char *path, const char *s){
    int fd = open(path, O_WRONLY);
    if (fd < 0) return -errno;
    ssize_t n = write(fd, s, strlen(s));
    int rc = (n < 0) ? -errno : 0;
    close(fd);
    return rc;
}
static int read_str(const char *path, char *buf, size_t cap){
    int fd = open(path, O_RDONLY);
    if (fd < 0) return -errno;
    ssize_t n = read(fd, buf, cap-1);
    if (n < 0){ int e = -errno; close(fd); return e; }
    buf[n] = '\0';
    close(fd);
    return 0;
}
static int path_exists(const char *path){
    struct stat st;
    return stat(path, &st) == 0;
}

static int gpio_export_if_needed(int gpio){
    char dirpath[128];
    snprintf(dirpath, sizeof(dirpath), "/sys/class/gpio/gpio%d", gpio);
    if (path_exists(dirpath)) return 0;
    char num[16]; snprintf(num, sizeof(num), "%d", gpio);
    int rc = write_str("/sys/class/gpio/export", num);
    if (rc < 0 && rc != -EBUSY) return rc;
    // sysfs가 생성될 때까지 잠깐 대기
    for (int i=0; i<50; ++i){
        if (path_exists(dirpath)) return 0;
        usleep(20000);
    }
    return -ETIMEDOUT;
}
static int gpio_set_dir_out(int gpio){
    char path[128];
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/direction", gpio);
    return write_str(path, "out");
}
static int gpio_set_value(int gpio, int value){
    char path[128], v[4];
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/value", gpio);
    snprintf(v, sizeof(v), "%d", value ? 1 : 0);
    return write_str(path, v);
}
static int gpio_get_value(int gpio, int *value){
    char path[128], buf[16];
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/value", gpio);
    int rc = read_str(path, buf, sizeof(buf));
    if (rc < 0) return rc;
    *value = (buf[0] == '1') ? 1 : 0;
    return 0;
}

static gpio_map_t* find_gpio(const char *name){
    for (int i=0;i<GMAP_N;i++)
        if (strcmp(gmap[i].name, name)==0) return &gmap[i];
    return NULL;
}

static void msleep(unsigned ms){
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (long)(ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}

static void print_header(void){
    printf("\n=== Step Motor GPIO Control (sysfs) ===\n");
    for (int i=0;i<GMAP_N;i++)
        printf(" - %-9s : gpio%d  (%s)\n", gmap[i].name, gmap[i].gpio, gmap[i].desc);
    printf("\n명령:\n");
    printf("  show                      : 현재 상태 출력\n");
    printf("  set <name> <0|1>          : 값 설정 (예: set run 1)\n");
    printf("  toggle <name>             : 0/1 토글\n");
    printf("  pulse <name> <ms> [level] : <level>(기본 1)로 <ms>ms 펄스\n");
    printf("  watch <ms>                : <ms>주기로 상태 갱신 (Ctrl+C 종료)\n");
    printf("  help                      : 도움말\n");
    printf("  quit/exit                 : 종료\n\n");
}

static void cmd_show(void){
    printf("\n[GPIO 상태]\n");
    for (int i=0;i<GMAP_N;i++){
        int v=-1;
        int rc = gpio_get_value(gmap[i].gpio, &v);
        if (rc==0) printf("  %-9s(gpio%-4d) = %d\n", gmap[i].name, gmap[i].gpio, v);
        else printf("  %-9s(gpio%-4d) = <error %d>\n", gmap[i].name, gmap[i].gpio, rc);
    }
    printf("\n");
}

static int ensure_all_ready(void){
    for (int i=0;i<GMAP_N;i++){
        int rc = gpio_export_if_needed(gmap[i].gpio);
        if (rc<0) {
            fprintf(stderr, "gpio%d export 실패: %s\n", gmap[i].gpio, strerror(-rc));
            return rc;
        }
        rc = gpio_set_dir_out(gmap[i].gpio);
        if (rc<0) {
            fprintf(stderr, "gpio%d direction=out 실패: %s\n", gmap[i].gpio, strerror(-rc));
            return rc;
        }
    }
    return 0;
}

int main(void){
    signal(SIGINT, on_sigint);
    signal(SIGTERM, on_sigint);

    if (ensure_all_ready() < 0){
        fprintf(stderr, "초기화 실패. root 권한 또는 디바이스 트리/퍼미션 확인 필요.\n");
        return 1;
    }

    print_header();
    cmd_show();

    char line[256];
    while (1){
        printf("stepctl> ");
        fflush(stdout);
        if (!fgets(line, sizeof(line), stdin)) break;

        // 공백/개행 정리
        char *p = line;
        while (*p==' '||*p=='\t') p++;
        size_t L = strlen(p);
        while (L>0 && (p[L-1]=='\n'||p[L-1]=='\r'||p[L-1]==' '||p[L-1]=='\t')) p[--L]=0;
        if (L==0) continue;

        if (!strcmp(p,"quit") || !strcmp(p,"exit")) break;
        if (!strcmp(p,"help")) { print_header(); continue; }
        if (!strcmp(p,"show")) { cmd_show(); continue; }

        if (!strncmp(p,"set ",4)){
            char name[32]; int val; 
            if (sscanf(p+4, "%31s %d", name, &val)==2){
                gpio_map_t *gm = find_gpio(name);
                if (!gm){ printf("알 수 없는 name: %s\n", name); continue; }
                if (val!=0 && val!=1){ printf("값은 0 또는 1\n"); continue; }
                int rc = gpio_set_value(gm->gpio, val);
                if (rc<0) printf("설정 실패: %s\n", strerror(-rc));
                else cmd_show();
            } else {
                printf("형식: set <name> <0|1>\n");
            }
            continue;
        }

        if (!strncmp(p,"toggle ",7)){
            char name[32];
            if (sscanf(p+7, "%31s", name)==1){
                gpio_map_t *gm = find_gpio(name);
                if (!gm){ printf("알 수 없는 name: %s\n", name); continue; }
                int v=0; int rc = gpio_get_value(gm->gpio, &v);
                if (rc<0){ printf("읽기 실패: %s\n", strerror(-rc)); continue; }
                rc = gpio_set_value(gm->gpio, !v);
                if (rc<0) printf("설정 실패: %s\n", strerror(-rc));
                else cmd_show();
            } else {
                printf("형식: toggle <name>\n");
            }
            continue;
        }

        if (!strncmp(p,"pulse ",6)){
            char name[32]; int ms=0; int level=1;
            int n = sscanf(p+6, "%31s %d %d", name, &ms, &level);
            if (n>=2){
                gpio_map_t *gm = find_gpio(name);
                if (!gm){ printf("알 수 없는 name: %s\n", name); continue; }
                if (ms<=0){ printf("ms는 양수여야 합니다\n"); continue; }
                if (level!=0 && level!=1) level = 1;
                int v_backup=0; 
                if (gpio_get_value(gm->gpio, &v_backup)<0) v_backup=0;
                if (gpio_set_value(gm->gpio, level)<0){ printf("설정 실패\n"); continue; }
                msleep((unsigned)ms);
                gpio_set_value(gm->gpio, v_backup);
                cmd_show();
            } else {
                printf("형식: pulse <name> <ms> [level]\n");
            }
            continue;
        }

        if (!strncmp(p,"watch ",6)){
            int period_ms = 0;
            if (sscanf(p+6, "%d", &period_ms)==1 && period_ms>=50){
                printf("watch 시작 — %d ms 주기 (Ctrl+C 종료)\n", period_ms);
                g_stop = 0;
                while (!g_stop){
                    cmd_show();
                    msleep((unsigned)period_ms);
                }
                printf("watch 종료\n");
            } else {
                printf("형식: watch <ms>  (권장: >= 100)\n");
            }
            continue;
        }

        printf("알 수 없는 명령입니다. help 를 입력해 보세요.\n");
    }

    printf("종료합니다.\n");
    return 0;
}

```

```
root@myproject:~# ./stepctl

=== Step Motor GPIO Control (sysfs) ===
 - reset     : gpio1020  (0: reset(assert), 1: unreset(deassert))
 - run       : gpio1021  (0: stop, 1: run)
 - dir       : gpio1022  (0: forward, 1: backward)
 - half_full : gpio1023  (0: half-step, 1: full-step)

명령:
  show                      : 현재 상태 출력
  set <name> <0|1>          : 값 설정 (예: set run 1)
  toggle <name>             : 0/1 토글
  pulse <name> <ms> [level] : <level>(기본 1)로 <ms>ms 펄스
  watch <ms>                : <ms>주기로 상태 갱신 (Ctrl+C 종료)
  help                      : 도움말
  quit/exit                 : 종료


[GPIO 상태]
  reset    (gpio1020) = 0
  run      (gpio1021) = 0
  dir      (gpio1022) = 0
  half_full(gpio1023) = 0
```

---

=============================================================
# AXI4 Peripheral IP 생성 과정
=============================================================

<img width="1154" height="452" alt="006" src="https://github.com/user-attachments/assets/40d6decf-b090-468d-95ad-401d186e5da3" />

### 1. Create and Package New IP 시작
Vivado에서:
```
Tools → Create and Package New IP...
→ Create a new AXI4 peripheral 선택
→ Next
```

### 2. Peripheral Details 설정
```
Name: stepper_motor_ctrl (또는 원하는 이름)
Version: 1.0
Display name: Stepper Motor Controller
Description: ULN2003 Stepper Motor Controller with AXI4-Lite interface
```

### 3. Add Interfaces
```
Interface Type: AXI4-Lite
Interface Mode: Slave
Data Width: 32
Number of Registers: 4 (최소한 필요)
```

추천 레지스터 맵:
* Offset 0x00: Control Register (run, dir, half_full, enable)
* Offset 0x04: Status Register (현재 step_idx, coils 상태)
* Offset 0x08: Speed Register (STEPS_PER_SEC 설정)
* Offset 0x0C: Reserved

### 4. IP 구조 제안
IP를 생성하면 <ip_name>_v1_0_S00_AXI.v 파일이 생성됩니다. 이 파일을 수정해야 합니다:

```verilog
// stepper_motor_ctrl_v1_0_S00_AXI.v 수정 예시

module stepper_motor_ctrl_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4,
    parameter integer CLK_HZ = 125_000_000
)(
    // AXI ports...
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // ... (standard AXI signals)
    
    // User ports - Stepper Motor Interface
    output wire [3:0] coils_out
);

    // AXI4-Lite signals (기존 생성된 코드 유지)
    // ...

    // User registers
    reg [31:0] control_reg;  // slv_reg0
    reg [31:0] status_reg;   // slv_reg1  
    reg [31:0] speed_reg;    // slv_reg2
    
    // Control signals extraction
    wire motor_enable = control_reg[0];
    wire motor_run    = control_reg[1];
    wire motor_dir    = control_reg[2];
    wire half_full    = control_reg[3];
    
    // Speed parameter
    wire [15:0] steps_per_sec = speed_reg[15:0];
    
    // Instantiate your stepper controller
    wire [3:0] in_signal = {half_full, motor_dir, motor_run, S_AXI_ARESETN};
    
    zybo_z720_stepper_top #(
        .CLK_HZ(CLK_HZ),
        .STEPS_PER_SEC(600)  // or use speed_reg value
    ) stepper_inst (
        .clk(S_AXI_ACLK),
        .in_signal(in_signal),
        .coils(coils_out)
    );
    
    // Update status register
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            status_reg <= 0;
        else
            status_reg <= {28'h0, coils_out};
    end

    // AXI write/read logic (기존 템플릿 코드 활용)
    // slv_reg0 → control_reg
    // slv_reg1 → status_reg (read-only)
    // slv_reg2 → speed_reg
    
endmodule
```

### 5. Top-level Wrapper 수정
stepper_motor_ctrl_v1_0.v 파일에 외부 포트 추가:
```verilog
module stepper_motor_ctrl_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
)(
    // AXI ports
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    // ... (standard AXI ports)
    
    // User ports - add this!
    output wire [3:0] coils
);

    stepper_motor_ctrl_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) stepper_motor_ctrl_v1_0_S00_AXI_inst (
        // AXI connections...
        .coils_out(coils)  // Connect user port
    );

endmodule
```

### 6. Constraints 파일 준비
IP 패키징 후 Block Design에서 사용할 때 외부 포트로 연결:

```tcl
# coils[0-3] → Pmod JE 등에 연결
set_property PACKAGE_PIN V12 [get_ports {coils[0]}]
set_property PACKAGE_PIN W16 [get_ports {coils[1]}]
set_property PACKAGE_PIN J15 [get_ports {coils[2]}]
set_property PACKAGE_PIN H15 [get_ports {coils[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {coils[*]}]
```

### 7. IP Packaging 완료

```
Review and Package → Re-Package IP
```

### 8. Block Design에서 사용

* IP Catalog에서 생성한 IP 추가
* ZYNQ PS의 M_AXI_GP0와 연결 (Run Connection Automation)
* coils 포트를 "Make External"로 외부 포트 생성
* Address Editor에서 적절한 주소 할당 (예: 0x43C0_0000)

### 9. Software에서 제어 (PetaLinux/Bare-metal)

```c
#define STEPPER_BASE_ADDR 0x43C00000
#define CTRL_REG   (*(volatile uint32_t *)(STEPPER_BASE_ADDR + 0x00))
#define STATUS_REG (*(volatile uint32_t *)(STEPPER_BASE_ADDR + 0x04))
#define SPEED_REG  (*(volatile uint32_t *)(STEPPER_BASE_ADDR + 0x08))

// Motor control
void stepper_start(void) {
    CTRL_REG |= 0x02;  // Set run bit
}

void stepper_stop(void) {
    CTRL_REG &= ~0x02; // Clear run bit
}

void stepper_set_direction(int cw) {
    if (cw)
        CTRL_REG |= 0x04;
    else
        CTRL_REG &= ~0x04;
}
```
















