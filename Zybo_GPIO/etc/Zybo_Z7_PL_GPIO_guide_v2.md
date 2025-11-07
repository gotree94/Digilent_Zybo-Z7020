# Zybo Z7-20 PL GPIO 제어 완전 가이드
## Vivado 2022.2 (Windows) + PetaLinux (Ubuntu 22.04.5)

---

## 📋 목차
1. [개요 및 환경 구성](#1-개요-및-환경-구성)
2. [Part 1: Windows에서 Vivado 하드웨어 설계](#part-1-windows에서-vivado-하드웨어-설계)
3. [Part 2: Ubuntu에서 PetaLinux 프로젝트 생성](#part-2-ubuntu에서-petalinux-프로젝트-생성)
4. [Part 3: C 언어로 GPIO 제어 프로그램 작성](#part-3-c-언어로-gpio-제어-프로그램-작성)
5. [Part 4: Shell Script로 GPIO 제어](#part-4-shell-script로-gpio-제어)
6. [Part 5: SD 카드 부팅 및 테스트](#part-5-sd-카드-부팅-및-테스트)
7. [문제 해결 가이드](#문제-해결-가이드)

---

## 1. 개요 및 환경 구성

### 1.1 프로젝트 개요

**목표:** Zybo Z7-20의 PL 영역에 AXI GPIO를 구현하여 LED 4개를 제어

**시스템 구성:**
```
┌─────────────────────────────────────┐
│  Zybo Z7-20 (Zynq-7000 SoC)        │
│  ┌─────────────┐  ┌──────────────┐ │
│  │     PS      │  │      PL      │ │
│  │  (ARM CPU)  │◄─┤  AXI GPIO    │ │
│  │  PetaLinux  │  │   (4-bit)    │ │
│  │             │  │      ↓       │ │
│  │  C Program  │  │  LD0~LD3     │ │
│  │  Shell Script│ │   (LEDs)     │ │
│  └─────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

### 1.2 작업 환경

#### Windows PC (Vivado 작업용)
- **OS:** Windows 10/11
- **소프트웨어:** Vivado Design Suite 2022.2
- **필요 공간:** 약 100GB
- **RAM:** 최소 8GB (16GB 권장)

#### Ubuntu PC (PetaLinux 작업용)
- **OS:** Ubuntu 22.04.5 LTS
- **소프트웨어:** PetaLinux Tools 2022.2
- **필요 공간:** 약 100GB 이상
- **RAM:** 최소 8GB (16GB 이상 강력 권장)

#### 하드웨어
- Digilent Zybo Z7-20 보드
- Micro-USB 케이블 (JTAG/UART용)
- SD 카드 (8GB 이상, Class 10 권장)
- 이더넷 케이블 (선택사항)

### 1.3 Ubuntu 22.04.5에서 PetaLinux 사전 준비

Ubuntu 시스템에 필요한 패키지를 먼저 설치합니다:

```bash
# 시스템 업데이트
sudo apt update
sudo apt upgrade -y

# PetaLinux 2022.2에 필요한 필수 패키지 설치
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    git \
    make \
    net-tools \
    libncurses5-dev \
    tftpd \
    zlib1g-dev \
    libssl-dev \
    flex \
    bison \
    libselinux1 \
    gnupg \
    wget \
    diffstat \
    chrpath \
    socat \
    xterm \
    autoconf \
    libtool \
    tar \
    unzip \
    texinfo \
    zlib1g-dev \
    gcc-multilib \
    automake \
    zlib1g:i386 \
    screen \
    pax \
    gawk \
    python3 \
    python3-pexpect \
    python3-pip \
    python3-git \
    python3-jinja2 \
    xz-utils \
    debianutils \
    iputils-ping \
    libegl1-mesa \
    libsdl1.2-dev \
    pylint3 \
    cpio \
    iproute2 \
    gzip \
    bc

# Ubuntu 22.04용 추가 설정
sudo dpkg-reconfigure dash  # "No" 선택하여 bash를 기본 쉘로 설정

# 사용자 추가 설정 (필요시)
# PetaLinux는 root로 실행하면 안됩니다!
```

**중요 참고사항:**
- PetaLinux는 반드시 일반 사용자 계정으로 실행해야 합니다
- `/bin/sh`가 `bash`를 가리켜야 합니다 (위의 dpkg-reconfigure 명령으로 설정)
- 충분한 디스크 공간 확보 필요 (최소 100GB 여유 공간)

---

## Part 1: Windows에서 Vivado 하드웨어 설계

### 1.1 Vivado 프로젝트 생성

#### Step 1: Vivado 실행
1. 시작 메뉴에서 **Vivado 2022.2** 실행
2. 시작 화면에서 **Create Project** 클릭

#### Step 2: 프로젝트 설정
```
Project Name: zybo_gpio_led
Project Location: C:\Vivado_Projects\zybo_gpio_led
```
- ✅ **Create project subdirectory** 체크
- **Next** 클릭

#### Step 3: 프로젝트 타입 선택
- **RTL Project** 선택
- ✅ **Do not specify sources at this time** 체크
- **Next** 클릭

#### Step 4: 보드 선택
- **Boards** 탭 선택
- 검색창에 `zybo z7-20` 입력
- **Zybo Z7-20** 선택

**⚠️ 보드가 목록에 없는 경우:**

```
1. Digilent 보드 파일 다운로드:
   https://github.com/Digilent/vivado-boards/archive/master.zip

2. 압축 해제 후 다음 폴더로 복사:
   C:\Xilinx\Vivado\2022.2\data\boards\board_files\

3. Vivado 재시작
```

- **Next** → **Finish** 클릭

### 1.2 Block Design 생성

#### Step 1: Block Design 생성
1. 좌측 **Flow Navigator**에서
   - **IP INTEGRATOR** → **Create Block Design** 클릭
2. Design name: `system` (기본값 사용)
3. **OK** 클릭

#### Step 2: ZYNQ7 Processing System 추가
1. Diagram 영역에서 **+ (Add IP)** 버튼 클릭
2. 검색창에 `zynq` 입력
3. **ZYNQ7 Processing System** 더블클릭하여 추가
4. 상단에 나타나는 **Run Block Automation** 링크 클릭
5. 기본 설정 그대로 **OK** 클릭

이제 Diagram에 ZYNQ 블록이 나타납니다.

#### Step 3: AXI GPIO IP 추가
1. 다시 **+ (Add IP)** 버튼 클릭
2. 검색창에 `axi gpio` 입력
3. **AXI GPIO** 더블클릭하여 추가

### 1.3 AXI GPIO 상세 설정

#### Step 1: GPIO 설정
1. **AXI GPIO** 블록을 더블클릭
2. **IP Configuration** 탭에서:
   ```
   GPIO:
   - All Outputs 선택
   - GPIO Width: 4
   ```
3. **OK** 클릭

#### Step 2: Board Interface 연결
1. **AXI GPIO** 블록에서 **GPIO** 포트를 찾습니다
2. GPIO 포트를 우클릭 → **Make External** 클릭
3. 외부 포트 이름이 `gpio_rtl_0`로 생성됩니다
4. 이 포트를 우클릭 → **Edit Interface**
   ```
   Name: leds_4bits
   ```
5. **OK** 클릭

**또는 Board 탭에서 직접 연결:**
1. AXI GPIO 더블클릭
2. **Board** 탭 선택
3. **GPIO** 인터페이스를 **leds 4bits**에 연결
4. **OK** 클릭

### 1.4 AXI 인터커넥트 연결

#### Step 1: Connection Automation 실행
1. 상단에 **Run Connection Automation** 링크가 나타나면 클릭
2. 다음 항목들 체크:
   ```
   ✅ S_AXI
   ✅ axi_gpio_0
   ```
3. **OK** 클릭

자동으로 다음이 생성됩니다:
- AXI Interconnect
- Processor System Reset
- 클럭 및 리셋 연결

#### Step 2: 연결 상태 확인
최종적으로 다음과 같이 연결되어야 합니다:
```
ZYNQ7 Processing System
├─ M_AXI_GP0 → AXI Interconnect → AXI GPIO (S_AXI)
├─ FCLK_CLK0 → AXI Interconnect, AXI GPIO (s_axi_aclk)
└─ FCLK_RESET0_N → Processor System Reset → AXI GPIO (s_axi_aresetn)

AXI GPIO
└─ GPIO → leds_4bits (외부 포트)
```

### 1.5 주소 맵 확인 및 설정

#### Step 1: Address Editor 열기
1. 상단 탭에서 **Address Editor** 클릭
2. 또는 **Window** → **Address Editor**

#### Step 2: AXI GPIO 주소 확인
```
Peripheral: axi_gpio_0
Base Address: 0x41200000  (기본값)
Range: 64K
```

**⚠️ 이 주소를 메모장에 기록하세요!**
```
AXI GPIO Base Address: 0x41200000
```
이 주소는 나중에 C 프로그램과 디바이스 트리에서 사용됩니다.

필요시 주소 변경:
- 주소를 클릭하여 수정 가능
- 일반적으로 기본값 사용 권장

### 1.6 디자인 검증

#### Step 1: Validate Design
1. Diagram 영역 상단의 **Validate Design (✓)** 버튼 클릭
2. 또는 **Tools** → **Validate Design (F6)**
3. 성공 메시지 확인:
   ```
   Validation successful. There are no errors or critical warnings in this design.
   ```

### 1.7 HDL Wrapper 생성

#### Step 1: Wrapper 생성
1. **Sources** 탭 (좌측 하단)에서
2. **Design Sources** 확장
3. `system.bd` 파일을 우클릭
4. **Create HDL Wrapper...** 선택
5. **Let Vivado manage wrapper and auto-update** 선택 (권장)
6. **OK** 클릭

생성된 파일: `system_wrapper.v`

### 1.8 Constraints 파일 추가 (선택사항)

LED 핀을 명시적으로 지정하려면:

#### Step 1: XDC 파일 생성
1. **File** → **Add Sources** 클릭
2. **Add or create constraints** 선택 → **Next**
3. **Create File** 클릭
   ```
   File name: zybo_z7_constraints
   File type: XDC
   ```
4. **OK** → **Finish**

#### Step 2: Constraints 내용 작성
생성된 `zybo_z7_constraints.xdc` 파일을 열고 다음 내용 입력:

```tcl
# LED 핀 할당 (Zybo Z7-20)
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[3]}]
```

**참고:** Zybo Z7 보드 파일을 사용했다면 이 과정은 선택사항입니다.

### 1.9 Synthesis 및 Implementation

#### Step 1: Synthesis 실행
1. **Flow Navigator**에서
2. **SYNTHESIS** → **Run Synthesis** 클릭
3. 설정:
   ```
   Number of jobs: 4 (CPU 코어 수에 맞게 조정)
   ```
4. **OK** 클릭
5. 완료까지 대기 (약 3-5분)

완료 후 대화상자:
- **Run Implementation** 선택
- **OK** 클릭

#### Step 2: Implementation 실행
1. Implementation이 자동 시작됩니다
2. 완료까지 대기 (약 5-10분)

완료 후 대화상자:
- **Generate Bitstream** 선택
- **OK** 클릭

#### Step 3: Bitstream 생성
1. Bitstream 생성 시작
2. 완료까지 대기 (약 2-5분)

완료 후:
- **Cancel** 클릭 (Open Implemented Design은 불필요)

**생성된 파일 위치:**
```
C:\Vivado_Projects\zybo_gpio_led\zybo_gpio_led.runs\impl_1\system_wrapper.bit
```

### 1.10 하드웨어 Export (.XSA 파일 생성)

#### Step 1: Hardware Export
1. 메뉴에서 **File** → **Export** → **Export Hardware...** 클릭
2. Export Hardware Platform 대화상자:
   ```
   Output: Select Platform Location
   ✅ Include bitstream
   
   XSA file name: system_wrapper.xsa
   Export to: C:\Vivado_Projects\zybo_gpio_led\system_wrapper.xsa
   ```
3. **Next** → **Finish** 클릭

**생성된 파일:**
```
C:\Vivado_Projects\zybo_gpio_led\system_wrapper.xsa
```

**⚠️ 중요: 이 파일을 Ubuntu PC로 전송해야 합니다!**

### 1.11 XSA 파일을 Ubuntu로 전송

다음 방법 중 하나를 선택:

#### 방법 1: USB 드라이브 사용
```
1. USB 메모리에 system_wrapper.xsa 복사
2. Ubuntu PC에 연결
3. 다음 위치에 복사:
   ~/petalinux_projects/zybo_gpio/
```

#### 방법 2: 네트워크 공유 (추천)
```bash
# Ubuntu에서 실행
mkdir -p ~/petalinux_projects/zybo_gpio
cd ~/petalinux_projects/zybo_gpio

# Windows에서 네트워크 공유 설정 후
# 또는 scp, FileZilla 등 사용
```

#### 방법 3: 클라우드 스토리지
```
1. Google Drive, Dropbox 등에 업로드
2. Ubuntu에서 다운로드
```

---

## Part 2: Ubuntu에서 PetaLinux 프로젝트 생성

### 2.1 PetaLinux 설치 확인

#### Step 1: PetaLinux 환경 확인
```bash
# PetaLinux 설치 디렉토리로 이동 (예시)
cd /opt/Xilinx/PetaLinux/2022.2

# 또는 사용자 홈 디렉토리에 설치한 경우
cd ~/petalinux/2022.2

# 환경 설정 스크립트 확인
ls settings.sh
```

**⚠️ PetaLinux가 설치되지 않은 경우:**

PetaLinux 2022.2 설치 가이드:
```bash
# Xilinx 웹사이트에서 다운로드 필요
# https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html

# 다운로드 파일: petalinux-v2022.2-final-installer.run

# 설치 디렉토리 생성
mkdir -p ~/petalinux/2022.2

# 설치 스크립트 실행
chmod +x petalinux-v2022.2-final-installer.run
./petalinux-v2022.2-final-installer.run ~/petalinux/2022.2

# 설치 완료까지 대기 (약 30분~1시간)
```

### 2.2 PetaLinux 환경 설정

#### Step 1: 작업 디렉토리 생성
```bash
# 프로젝트 디렉토리 생성
mkdir -p ~/petalinux_projects
cd ~/petalinux_projects
```

#### Step 2: PetaLinux 환경 활성화
```bash
# PetaLinux 환경 설정 (매번 새 터미널마다 실행 필요)
source ~/petalinux/2022.2/settings.sh

# 또는 PetaLinux가 다른 위치에 있다면
source /opt/Xilinx/PetaLinux/2022.2/settings.sh
```

**환경 설정 확인:**
```bash
echo $PETALINUX
# 출력: /home/username/petalinux/2022.2 (설치 경로)

petalinux-util --version
# 출력: PetaLinux Tools version 2022.2 ...
```

**⚠️ 자주 하는 실수:**
- 매번 새 터미널을 열 때마다 `source` 명령을 실행해야 합니다
- root 사용자로 PetaLinux를 실행하면 안 됩니다

### 2.3 PetaLinux 프로젝트 생성

#### Step 1: 프로젝트 생성
```bash
cd ~/petalinux_projects

# Zynq 기반 프로젝트 생성
petalinux-create --type project --template zynq --name zybo_gpio

# 완료 메시지 확인:
# INFO: New project successfully created in zybo_gpio
```

생성된 디렉토리 구조:
```
zybo_gpio/
├── project-spec/
│   ├── configs/
│   ├── hw-description/
│   └── meta-user/
├── components/
└── build/
```

#### Step 2: 프로젝트 디렉토리로 이동
```bash
cd zybo_gpio
```

### 2.4 하드웨어 Description 가져오기

#### Step 1: XSA 파일 배치 확인
```bash
# XSA 파일을 프로젝트 디렉토리로 복사 (아직 안했다면)
cp /path/to/system_wrapper.xsa ~/petalinux_projects/zybo_gpio/

# 예: USB에서 복사하는 경우
cp /media/username/USB_DRIVE/system_wrapper.xsa ~/petalinux_projects/zybo_gpio/
```

#### Step 2: 하드웨어 Description 설정
```bash
cd ~/petalinux_projects/zybo_gpio

# XSA 파일로 하드웨어 구성
petalinux-config --get-hw-description=./

# 또는 XSA 파일 경로를 직접 지정
petalinux-config --get-hw-description=/path/to/system_wrapper.xsa
```

**설정 화면이 나타납니다 (menuconfig 스타일).**

### 2.5 PetaLinux 프로젝트 설정

menuconfig 화면에서 다음 설정을 확인/변경합니다:

#### Step 1: DTG (Device Tree Generator) 설정
```
메뉴 네비게이션:
- 화살표 키로 이동
- Enter키로 선택
- Space키로 체크
- ESC ESC로 뒤로 가기
- / 키로 검색
```

**설정 경로:**
```
DTG Settings --->
    Kernel Bootargs --->
        [*] generate boot args automatically
        (console=ttyPS0,115200 earlycon) User Set Kernel Bootargs
```

#### Step 2: 루트 파일시스템 설정
```
Image Packaging Configuration --->
    Root filesystem type --->
        [*] EXT4 (SD/eMMC/SATA/USB) 선택
```

#### Step 3: SD 카드 부팅 설정
```
Subsystem AUTO Hardware Settings --->
    Advanced bootable images storage Settings --->
        boot image settings --->
            image storage media (primary sd) 선택
        
        kernel image settings --->
            image storage media (primary sd) 선택
        
        dtb image settings --->
            image storage media (primary sd) 선택
```

#### Step 4: 저장 및 종료
```
- Tab 키를 눌러 <Save> 선택
- Enter 키로 저장
- Tab 키를 눌러 <Exit> 선택
- Enter 키로 종료
- 여러 번 ESC ESC 눌러서 최종 종료
- 변경사항을 저장하겠냐는 질문에 Yes 선택
```

### 2.6 디바이스 트리 수정 (중요!)

GPIO를 리눅스에서 사용하려면 디바이스 트리를 수정해야 합니다.

#### Step 1: 디바이스 트리 파일 찾기
```bash
cd ~/petalinux_projects/zybo_gpio

# 시스템 사용자 디바이스 트리 파일 열기
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

#### Step 2: GPIO 노드 추가
파일에 다음 내용을 추가합니다:

```dts
/include/ "system-conf.dtsi"
/ {
};

/* AXI GPIO 추가 */
&axi_gpio_0 {
    compatible = "xlnx,xps-gpio-1.00.a";
    #gpio-cells = <2>;
    gpio-controller;
    xlnx,gpio-width = <0x4>;
    xlnx,all-outputs = <0x1>;
    status = "okay";
};
```

**설명:**
- `&axi_gpio_0`: Vivado에서 생성한 AXI GPIO 인스턴스 이름
- `compatible`: 드라이버 매칭에 사용
- `gpio-controller`: 이 노드가 GPIO 컨트롤러임을 표시
- `xlnx,gpio-width = <0x4>`: 4비트 폭 (LED 4개)
- `status = "okay"`: 디바이스 활성화

**Ctrl+O로 저장, Ctrl+X로 종료**

#### Step 3: GPIO 이름 지정 (선택사항, 편의성 향상)

더 쉬운 접근을 위해 별칭을 추가할 수 있습니다:

```bash
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

다음 내용으로 수정:

```dts
/include/ "system-conf.dtsi"
/ {
    aliases {
        gpio-leds = "/amba_pl@0/gpio@41200000";
    };
    
    leds {
        compatible = "gpio-leds";
        led0 {
            label = "led0";
            gpios = <&axi_gpio_0 0 0>;
            default-state = "off";
        };
        led1 {
            label = "led1";
            gpios = <&axi_gpio_0 1 0>;
            default-state = "off";
        };
        led2 {
            label = "led2";
            gpios = <&axi_gpio_0 2 0>;
            default-state = "off";
        };
        led3 {
            label = "led3";
            gpios = <&axi_gpio_0 3 0>;
            default-state = "off";
        };
    };
};

&axi_gpio_0 {
    compatible = "xlnx,xps-gpio-1.00.a";
    #gpio-cells = <2>;
    gpio-controller;
    xlnx,gpio-width = <0x4>;
    xlnx,all-outputs = <0x1>;
    status = "okay";
};
```

### 2.7 커널 설정 (GPIO 드라이버 활성화)

#### Step 1: 커널 설정 열기
```bash
cd ~/petalinux_projects/zybo_gpio

# 커널 menuconfig 실행
petalinux-config -c kernel
```

#### Step 2: GPIO 드라이버 활성화
menuconfig에서 다음 항목들을 찾아 활성화 (스페이스바로 <*> 표시):

```
Device Drivers --->
    GPIO Support --->
        <*> /sys/class/gpio/... (sysfs interface)
        <*> Memory mapped GPIO drivers --->
            <*> Xilinx GPIO support
            <*> Xilinx Zynq GPIO support
    
    [*] LED Support --->
        <*> LED Class Support
        <*> LED Support for GPIO connected LEDs
```

**검색 단축키:** `/` 키를 누르고 `XILINX_GPIO` 입력하여 빠르게 찾기

#### Step 3: 설정 저장 및 종료
- Tab 키로 <Save> 선택 → Enter
- ESC ESC로 나가기 → Yes 선택

### 2.8 Root파일시스템 설정

#### Step 1: Rootfs 설정 열기
```bash
petalinux-config -c rootfs
```

#### Step 2: 유용한 패키지 추가
```
Filesystem Packages --->
    base --->
        [*] gpio-demo (선택사항)
    
    console --->
        utils --->
            [*] gpio-utils (선택사항, gpiod 관련)
    
    misc --->
        [*] python3
        [*] python3-periphery (GPIO 제어용, 선택사항)
    
    devel --->
        [*] gcc
        [*] g++
        [*] make
```

#### Step 3: 저장 및 종료
- Tab 키로 <Save> → Enter
- ESC ESC로 종료

---

## Part 3: C 언어로 GPIO 제어 프로그램 작성

### 3.1 UIO 방식 (사용자 공간에서 직접 메모리 액세스)

#### Step 1: UIO 드라이버 활성화

```bash
cd ~/petalinux_projects/zybo_gpio

# 커널 설정 다시 열기
petalinux-config -c kernel
```

menuconfig에서:
```
Device Drivers --->
    <*> Userspace I/O drivers --->
        <*> Userspace I/O platform driver with generic IRQ handling
        <*> Xilinx AXI Performance Monitor
```

저장 후 종료.

#### Step 2: 디바이스 트리에 UIO 추가

```bash
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

내용을 다음과 같이 수정:

```dts
/include/ "system-conf.dtsi"
/ {
};

&axi_gpio_0 {
    compatible = "generic-uio";
    status = "okay";
};
```

**설명:**
- `compatible = "generic-uio"`로 변경하면 UIO 드라이버가 바인딩됩니다
- 이렇게 하면 `/dev/uio0` 디바이스가 생성됩니다

#### Step 3: C 프로그램 작성

PetaLinux 사용자 애플리케이션을 생성합니다:

```bash
cd ~/petalinux_projects/zybo_gpio

# 애플리케이션 생성
petalinux-create -t apps --template install --name gpio-led-control --enable

# 애플리케이션 디렉토리로 이동
cd project-spec/meta-user/recipes-apps/gpio-led-control
```

#### Step 4: 소스 파일 작성

```bash
# files 디렉토리로 이동
cd files

# 기존 파일 삭제 또는 백업
mv gpio-led-control gpio-led-control.bak 2>/dev/null

# 새 C 프로그램 작성
nano gpio_led_control.c
```

다음 코드를 입력합니다:

```c
/*
 * Zybo Z7-20 PL GPIO LED Control (UIO 방식)
 * 
 * 컴파일: arm-linux-gnueabihf-gcc -o gpio_led_control gpio_led_control.c
 * 사용법: ./gpio_led_control <led_pattern>
 *        led_pattern: 0-15 (4bit binary)
 * 예: ./gpio_led_control 5  -> LED0=ON, LED2=ON (0b0101)
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

/* AXI GPIO 레지스터 오프셋 */
#define GPIO_DATA_OFFSET    0x0000  /* GPIO 데이터 레지스터 */
#define GPIO_TRI_OFFSET     0x0004  /* GPIO 3-state 제어 레지스터 */
#define GPIO2_DATA_OFFSET   0x0008  /* GPIO2 데이터 레지스터 (사용 안함) */
#define GPIO2_TRI_OFFSET    0x000C  /* GPIO2 3-state 제어 레지스터 (사용 안함) */

/* UIO 디바이스 경로 */
#define UIO_DEVICE "/dev/uio0"

/* GPIO 기본 주소 (디바이스 트리에서 가져옴, 일반적으로 자동) */
#define GPIO_SIZE 0x10000

int main(int argc, char *argv[]) {
    int fd;
    void *gpio_base;
    uint32_t led_value;
    volatile uint32_t *gpio_data_reg;
    volatile uint32_t *gpio_tri_reg;
    
    printf("=== Zybo Z7-20 PL GPIO LED Control ===\n");
    
    /* 인자 확인 */
    if (argc != 2) {
        printf("사용법: %s <led_pattern>\n", argv[0]);
        printf("  led_pattern: 0-15 (4-bit binary값)\n");
        printf("  예: %s 5  -> LED0=ON, LED2=ON (binary: 0101)\n", argv[0]);
        printf("  예: %s 15 -> 모든 LED ON (binary: 1111)\n", argv[0]);
        return -1;
    }
    
    led_value = atoi(argv[1]);
    
    /* 값 범위 확인 */
    if (led_value > 15) {
        printf("에러: LED 값은 0-15 사이여야 합니다.\n");
        return -1;
    }
    
    printf("설정할 LED 패턴: %d (binary: ", led_value);
    for (int i = 3; i >= 0; i--) {
        printf("%d", (led_value >> i) & 1);
    }
    printf(")\n");
    
    /* UIO 디바이스 열기 */
    fd = open(UIO_DEVICE, O_RDWR);
    if (fd < 0) {
        perror("UIO 디바이스 열기 실패");
        printf("힌트: UIO 디바이스가 존재하는지 확인하세요.\n");
        printf("  $ ls -l /dev/uio*\n");
        return -1;
    }
    
    /* 메모리 매핑 */
    gpio_base = mmap(NULL, GPIO_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (gpio_base == MAP_FAILED) {
        perror("메모리 매핑 실패");
        close(fd);
        return -1;
    }
    
    printf("UIO 디바이스 매핑 성공: %s\n", UIO_DEVICE);
    
    /* GPIO 레지스터 포인터 설정 */
    gpio_data_reg = (volatile uint32_t *)(gpio_base + GPIO_DATA_OFFSET);
    gpio_tri_reg = (volatile uint32_t *)(gpio_base + GPIO_TRI_OFFSET);
    
    /* GPIO를 출력으로 설정 (TRI 레지스터를 0으로) */
    *gpio_tri_reg = 0x00000000;
    printf("GPIO 방향 설정: 출력 모드\n");
    
    /* LED 값 쓰기 */
    *gpio_data_reg = led_value;
    printf("LED 값 0x%02X 쓰기 완료\n", led_value);
    
    /* 각 LED 상태 출력 */
    printf("\nLED 상태:\n");
    for (int i = 0; i < 4; i++) {
        printf("  LED%d: %s\n", i, (led_value & (1 << i)) ? "ON" : "OFF");
    }
    
    /* 정리 */
    munmap(gpio_base, GPIO_SIZE);
    close(fd);
    
    printf("\n프로그램 종료\n");
    
    return 0;
}
```

저장 후 종료 (Ctrl+O, Ctrl+X).

#### Step 5: Makefile 수정

```bash
cd ~/petalinux_projects/zybo_gpio/project-spec/meta-user/recipes-apps/gpio-led-control/files

# Makefile 생성
nano Makefile
```

다음 내용 입력:

```makefile
APP = gpio_led_control

# Add any other object files to this list below
APP_OBJS = gpio_led_control.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.o
```

저장 후 종료.

#### Step 6: Recipe 파일 확인

```bash
cd ~/petalinux_projects/zybo_gpio/project-spec/meta-user/recipes-apps/gpio-led-control

nano gpio-led-control.bb
```

내용이 다음과 유사한지 확인:

```
SUMMARY = "Simple gpio-led-control application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gpio_led_control.c \
           file://Makefile \
          "

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/gpio_led_control ${D}${bindir}
}
```

필요시 수정 후 저장.

### 3.2 sysfs 방식 (GPIO sysfs 인터페이스 사용)

sysfs 방식은 더 간단하지만, 커널 5.x 이상에서는 deprecated되고 있습니다.
대신 libgpiod를 사용하는 것이 권장됩니다.

#### 간단한 sysfs 방식 C 프로그램:

```bash
cd ~/petalinux_projects/zybo_gpio/project-spec/meta-user/recipes-apps/gpio-led-control/files

nano gpio_led_sysfs.c
```

```c
/*
 * GPIO LED Control using sysfs
 * 주의: 이 방법은 deprecated되고 있습니다
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define GPIO_BASE 1024  /* 실제 GPIO 번호는 부팅 후 확인 필요 */

int gpio_export(int gpio) {
    int fd;
    char buf[64];
    
    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("gpio export 열기 실패");
        return -1;
    }
    
    snprintf(buf, sizeof(buf), "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
    
    return 0;
}

int gpio_set_direction(int gpio, const char *direction) {
    int fd;
    char path[64];
    
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/direction", gpio);
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("gpio direction 열기 실패");
        return -1;
    }
    
    write(fd, direction, strlen(direction));
    close(fd);
    
    return 0;
}

int gpio_set_value(int gpio, int value) {
    int fd;
    char path[64];
    char buf[2];
    
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/value", gpio);
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("gpio value 열기 실패");
        return -1;
    }
    
    snprintf(buf, sizeof(buf), "%d", value ? 1 : 0);
    write(fd, buf, 1);
    close(fd);
    
    return 0;
}

int main(int argc, char *argv[]) {
    int led_pattern;
    int gpio_nums[4] = {GPIO_BASE, GPIO_BASE+1, GPIO_BASE+2, GPIO_BASE+3};
    
    if (argc != 2) {
        printf("사용법: %s <led_pattern>\n", argv[0]);
        return -1;
    }
    
    led_pattern = atoi(argv[1]);
    
    printf("LED 패턴: %d\n", led_pattern);
    
    /* GPIO export 및 설정 */
    for (int i = 0; i < 4; i++) {
        gpio_export(gpio_nums[i]);
        usleep(100000);  /* 100ms 대기 */
        gpio_set_direction(gpio_nums[i], "out");
    }
    
    /* LED 값 설정 */
    for (int i = 0; i < 4; i++) {
        int value = (led_pattern >> i) & 1;
        gpio_set_value(gpio_nums[i], value);
        printf("LED%d: %s\n", i, value ? "ON" : "OFF");
    }
    
    return 0;
}
```

**참고:** 실제 GPIO 번호는 부팅 후 확인해야 합니다.

---

## Part 4: Shell Script로 GPIO 제어

Shell script는 빠른 테스트와 간단한 제어에 유용합니다.

### 4.1 UIO 방식 Shell Script

```bash
cd ~/petalinux_projects/zybo_gpio/project-spec/meta-user/recipes-apps/gpio-led-control/files

nano gpio_led_control.sh
```

다음 내용 입력:

```bash
#!/bin/bash
#
# Zybo Z7-20 PL GPIO LED Control Script (UIO 방식)
# 사용법: ./gpio_led_control.sh <led_pattern>
#

UIO_DEVICE="/dev/uio0"
GPIO_DATA_OFFSET=0

# 사용법 출력
if [ $# -ne 1 ]; then
    echo "사용법: $0 <led_pattern>"
    echo "  led_pattern: 0-15 (4-bit binary값)"
    echo "  예: $0 5  -> LED0=ON, LED2=ON"
    echo "  예: $0 15 -> 모든 LED ON"
    exit 1
fi

LED_VALUE=$1

# 값 범위 확인
if [ $LED_VALUE -lt 0 ] || [ $LED_VALUE -gt 15 ]; then
    echo "에러: LED 값은 0-15 사이여야 합니다."
    exit 1
fi

# UIO 디바이스 존재 확인
if [ ! -c "$UIO_DEVICE" ]; then
    echo "에러: $UIO_DEVICE가 존재하지 않습니다."
    echo "UIO 드라이버가 로드되었는지 확인하세요."
    exit 1
fi

echo "=== Zybo Z7-20 GPIO LED Control ==="
echo "LED 패턴: $LED_VALUE"

# devmem을 사용하여 GPIO 레지스터에 값 쓰기
# 먼저 UIO 디바이스의 기본 주소 찾기
UIO_BASE=$(cat /sys/class/uio/uio0/maps/map0/addr)
echo "UIO Base Address: $UIO_BASE"

# TRI 레지스터를 0으로 설정 (출력 모드)
TRI_ADDR=$(printf "0x%X" $((UIO_BASE + 0x4)))
devmem $TRI_ADDR 32 0x0
echo "GPIO 방향: 출력 모드 설정 완료"

# DATA 레지스터에 LED 값 쓰기
DATA_ADDR=$(printf "0x%X" $((UIO_BASE + 0x0)))
devmem $DATA_ADDR 32 $LED_VALUE
echo "LED 값 $LED_VALUE 쓰기 완료"

# 각 LED 상태 출력
echo ""
echo "LED 상태:"
for i in 0 1 2 3; do
    BIT=$((($LED_VALUE >> $i) & 1))
    if [ $BIT -eq 1 ]; then
        echo "  LED$i: ON"
    else
        echo "  LED$i: OFF"
    fi
done

echo ""
echo "완료!"
```

실행 권한 부여:
```bash
chmod +x gpio_led_control.sh
```

### 4.2 sysfs 방식 Shell Script

```bash
nano gpio_led_sysfs.sh
```

```bash
#!/bin/bash
#
# GPIO LED Control using sysfs
# 주의: GPIO 번호는 실제 시스템에서 확인 필요
#

GPIO_BASE=1024  # 실제 GPIO 번호로 변경 필요

# 사용법
if [ $# -ne 1 ]; then
    echo "사용법: $0 <led_pattern>"
    exit 1
fi

LED_VALUE=$1

echo "LED 패턴: $LED_VALUE"

# GPIO export 및 방향 설정
for i in 0 1 2 3; do
    GPIO=$((GPIO_BASE + i))
    
    # Export
    if [ ! -d "/sys/class/gpio/gpio$GPIO" ]; then
        echo $GPIO > /sys/class/gpio/export
        sleep 0.1
    fi
    
    # 방향 설정
    echo "out" > /sys/class/gpio/gpio$GPIO/direction
done

# LED 값 설정
for i in 0 1 2 3; do
    GPIO=$((GPIO_BASE + i))
    BIT=$((($LED_VALUE >> $i) & 1))
    
    echo $BIT > /sys/class/gpio/gpio$GPIO/value
    
    if [ $BIT -eq 1 ]; then
        echo "LED$i: ON"
    else
        echo "LED$i: OFF"
    fi
done

echo "완료!"
```

실행 권한:
```bash
chmod +x gpio_led_sysfs.sh
```

### 4.3 Script를 rootfs에 포함시키기

#### 방법 1: 애플리케이션 recipe에 추가

```bash
cd ~/petalinux_projects/zybo_gpio/project-spec/meta-user/recipes-apps/gpio-led-control

nano gpio-led-control.bb
```

`SRC_URI`에 script 파일 추가:

```
SRC_URI = "file://gpio_led_control.c \
           file://gpio_led_control.sh \
           file://gpio_led_sysfs.sh \
           file://Makefile \
          "
```

`do_install` 함수 수정:

```
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/gpio_led_control ${D}${bindir}
    install -m 0755 ${S}/gpio_led_control.sh ${D}${bindir}
    install -m 0755 ${S}/gpio_led_sysfs.sh ${D}${bindir}
}
```

---

## Part 5: PetaLinux 빌드 및 SD 카드 부팅

### 5.1 PetaLinux 빌드

이제 모든 설정이 완료되었으므로 빌드를 시작합니다.

#### Step 1: 빌드 시작
```bash
cd ~/petalinux_projects/zybo_gpio

# 환경 설정 확인 (매 터미널마다 필요)
source ~/petalinux/2022.2/settings.sh

# 빌드 시작
petalinux-build
```

**빌드 시간: 약 1-3시간 (첫 빌드), 이후 빌드는 훨씬 빠름**

#### Step 2: 빌드 진행 상황 모니터링
```bash
# 다른 터미널에서 로그 확인 (선택사항)
tail -f build/tmp/log/cooker/zybo_gpio/console-latest.log
```

#### Step 3: 빌드 완료 확인
성공 메시지:
```
INFO: Build completed successfully
```

생성된 이미지 파일:
```
~/petalinux_projects/zybo_gpio/images/linux/
├── BOOT.BIN          # 부트 이미지 (FSBL + Bitstream + U-Boot)
├── boot.scr          # U-Boot 스크립트
├── image.ub          # Kernel + Device Tree
└── rootfs.ext4       # 루트 파일시스템
```

### 5.2 부트 이미지 패키징

#### Step 1: BOOT.BIN 생성
```bash
cd ~/petalinux_projects/zybo_gpio

# BOOT.BIN 생성
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
                          --fpga images/linux/system.bit \
                          --u-boot images/linux/u-boot.elf \
                          --force
```

**생성 확인:**
```bash
ls -lh images/linux/BOOT.BIN
# 출력: -rw-rw-r-- 1 user user 4.2M ... BOOT.BIN
```

### 5.3 SD 카드 준비

#### Step 1: SD 카드 파티션 생성

**⚠️ 주의: 모든 데이터가 삭제됩니다!**

SD 카드를 Ubuntu PC에 삽입합니다.

```bash
# SD 카드 디바이스 확인
lsblk

# 예상 출력:
# sdb      8:16   1   7.4G  0 disk
# ├─sdb1   8:17   1   512M  0 part
# └─sdb2   8:18   1   6.9G  0 part

# SD 카드 디바이스 이름 확인 (예: /dev/sdb)
SD_DEV=/dev/sdb  # 실제 장치명으로 변경!

# 기존 파티션 삭제 및 새 파티션 생성
sudo fdisk $SD_DEV
```

fdisk 명령어:
```
Command (m for help): o      # 새 파티션 테이블 생성
Command (m for help): n      # 새 파티션 생성
Partition type: p            # Primary
Partition number: 1
First sector: (기본값)
Last sector: +512M           # 512MB 부트 파티션

Command (m for help): t      # 파티션 타입 변경
Partition type: c            # W95 FAT32 (LBA)

Command (m for help): n      # 두 번째 파티션 생성
Partition type: p
Partition number: 2
First sector: (기본값)
Last sector: (기본값, 나머지 전체)

Command (m for help): w      # 저장 및 종료
```

#### Step 2: 파일시스템 생성

```bash
SD_DEV=/dev/sdb  # 실제 장치명으로 변경!

# 파티션 변수 설정
BOOT_PART=${SD_DEV}1
ROOT_PART=${SD_DEV}2

# 부트 파티션 포맷 (FAT32)
sudo mkfs.vfat -F 32 -n BOOT $BOOT_PART

# 루트 파티션 포맷 (EXT4)
sudo mkfs.ext4 -L ROOT $ROOT_PART
```

### 5.4 이미지 파일 복사

#### Step 1: 파티션 마운트

```bash
# 마운트 포인트 생성
mkdir -p /tmp/sd_boot
mkdir -p /tmp/sd_root

# 파티션 마운트
sudo mount $BOOT_PART /tmp/sd_boot
sudo mount $ROOT_PART /tmp/sd_root
```

#### Step 2: 부트 파일 복사

```bash
cd ~/petalinux_projects/zybo_gpio/images/linux

# BOOT 파티션에 파일 복사
sudo cp BOOT.BIN /tmp/sd_boot/
sudo cp boot.scr /tmp/sd_boot/
sudo cp image.ub /tmp/sd_boot/

# 복사 확인
ls -lh /tmp/sd_boot/
```

#### Step 3: 루트 파일시스템 복사

```bash
# rootfs.ext4 압축 해제 및 복사
sudo tar -xzf rootfs.tar.gz -C /tmp/sd_root/

# 또는 ext4 이미지 직접 쓰기 (대안)
# sudo dd if=rootfs.ext4 of=$ROOT_PART bs=4M status=progress

# 복사 확인
ls -lh /tmp/sd_root/
```

#### Step 4: 동기화 및 언마운트

```bash
# 버퍼 플러시
sudo sync

# 언마운트
sudo umount /tmp/sd_boot
sudo umount /tmp/sd_root

# SD 카드 제거 안전 확인
sudo eject $SD_DEV
```

이제 SD 카드를 안전하게 제거할 수 있습니다!

### 5.5 Zybo Z7-20 부팅

#### Step 1: 하드웨어 연결
1. SD 카드를 Zybo Z7-20 보드의 SD 슬롯에 삽입
2. Micro-USB 케이블로 보드와 PC 연결 (UART 포트)
3. 점퍼 설정 확인:
   ```
   JP5: SD 부팅 모드 설정
   - SD 부팅: 점퍼를 SD 쪽에 연결
   ```

#### Step 2: 시리얼 터미널 연결

Windows에서:
```
- PuTTY, Tera Term 등 사용
- COM 포트 확인 (장치 관리자에서)
- 설정:
  - Baud rate: 115200
  - Data bits: 8
  - Stop bits: 1
  - Parity: None
  - Flow control: None
```

Ubuntu에서:
```bash
# 시리얼 포트 확인
ls /dev/ttyUSB*

# minicom 사용
sudo minicom -D /dev/ttyUSB1 -b 115200

# 또는 screen 사용
sudo screen /dev/ttyUSB1 115200
```

#### Step 3: 보드 전원 켜기
1. 전원 스위치 ON
2. 시리얼 터미널에서 부팅 로그 확인:

```
Xilinx Zynq MP First Stage Boot Loader
...
U-Boot 2022.01
...
Starting kernel ...
...
[    0.000000] Booting Linux on physical CPU 0x0
...
PetaLinux 2022.2 zybo-gpio /dev/ttyPS0

zybo-gpio login:
```

#### Step 4: 로그인
```
Username: root
Password: root
```

### 5.6 GPIO 테스트

#### Step 1: UIO 디바이스 확인
```bash
# 로그인 후
ls -l /dev/uio*

# 예상 출력:
# crw------- 1 root root 241, 0 Jan  1 00:00 /dev/uio0

# UIO 정보 확인
cat /sys/class/uio/uio0/name
# 출력: axi_gpio_0 또는 generic-uio

# 기본 주소 확인
cat /sys/class/uio/uio0/maps/map0/addr
# 출력: 0x41200000
```

#### Step 2: C 프로그램 테스트
```bash
# 프로그램 위치 확인
which gpio_led_control
# 출력: /usr/bin/gpio_led_control

# LED 테스트
gpio_led_control 0   # 모든 LED OFF
gpio_led_control 15  # 모든 LED ON (0b1111)
gpio_led_control 5   # LED0, LED2 ON (0b0101)
gpio_led_control 10  # LED1, LED3 ON (0b1010)

# 순차 테스트
for i in 0 1 2 4 8 15; do
    gpio_led_control $i
    sleep 1
done
```

#### Step 3: Shell Script 테스트
```bash
# Script 위치 확인
which gpio_led_control.sh

# Script 실행
gpio_led_control.sh 7   # LED0, LED1, LED2 ON

# 깜빡임 효과
while true; do
    gpio_led_control.sh 15
    sleep 0.5
    gpio_led_control.sh 0
    sleep 0.5
done
# Ctrl+C로 종료
```

#### Step 4: devmem으로 직접 테스트
```bash
# GPIO 기본 주소 (Address Editor에서 확인한 주소)
GPIO_BASE=0x41200000

# TRI 레지스터 설정 (출력 모드)
devmem $((GPIO_BASE + 0x4)) 32 0x0

# LED 켜기
devmem $GPIO_BASE 32 0xF    # 모든 LED ON
devmem $GPIO_BASE 32 0x0    # 모든 LED OFF
devmem $GPIO_BASE 32 0x5    # LED0, LED2 ON
```

---

## Part 6: 고급 기능 및 최적화

### 6.1 자동 시작 스크립트 추가

부팅 시 자동으로 LED를 제어하고 싶다면:

```bash
# 보드에서
nano /etc/init.d/led_init.sh
```

```bash
#!/bin/sh

### BEGIN INIT INFO
# Provides:          led_init
# Required-Start:    $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize LEDs at boot
### END INIT INFO

case "$1" in
    start)
        echo "Initializing LEDs..."
        /usr/bin/gpio_led_control 15
        sleep 1
        /usr/bin/gpio_led_control 0
        ;;
    stop)
        /usr/bin/gpio_led_control 0
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
```

실행 권한 및 등록:
```bash
chmod +x /etc/init.d/led_init.sh
update-rc.d led_init.sh defaults
```

### 6.2 Python으로 GPIO 제어

Python을 사용하면 더 복잡한 제어 로직을 쉽게 구현할 수 있습니다.

#### Step 1: Python 스크립트 작성

```bash
nano /home/root/gpio_led.py
```

```python
#!/usr/bin/env python3
"""
Zybo Z7-20 PL GPIO LED Control (Python)
"""

import mmap
import struct
import time
import sys

# AXI GPIO 레지스터 오프셋
GPIO_DATA_OFFSET = 0x0000
GPIO_TRI_OFFSET = 0x0004

# UIO 디바이스
UIO_DEVICE = "/dev/uio0"
GPIO_SIZE = 0x10000

class AXIGPIO:
    def __init__(self, uio_device=UIO_DEVICE):
        self.uio_fd = open(uio_device, 'r+b', buffering=0)
        self.gpio_mem = mmap.mmap(self.uio_fd.fileno(), GPIO_SIZE)
        
        # GPIO를 출력으로 설정
        self.write_reg(GPIO_TRI_OFFSET, 0x00000000)
    
    def write_reg(self, offset, value):
        """레지스터에 값 쓰기"""
        self.gpio_mem.seek(offset)
        self.gpio_mem.write(struct.pack('I', value))
    
    def read_reg(self, offset):
        """레지스터에서 값 읽기"""
        self.gpio_mem.seek(offset)
        return struct.unpack('I', self.gpio_mem.read(4))[0]
    
    def set_leds(self, value):
        """LED 값 설정 (0-15)"""
        self.write_reg(GPIO_DATA_OFFSET, value & 0xF)
    
    def close(self):
        """리소스 정리"""
        self.gpio_mem.close()
        self.uio_fd.close()

def main():
    if len(sys.argv) != 2:
        print(f"사용법: {sys.argv[0]} <led_pattern>")
        print("  led_pattern: 0-15")
        return
    
    led_value = int(sys.argv[1])
    
    if led_value < 0 or led_value > 15:
        print("에러: LED 값은 0-15 사이여야 합니다.")
        return
    
    print("=== Python GPIO LED Control ===")
    print(f"LED 패턴: {led_value} (binary: {bin(led_value)})")
    
    # GPIO 초기화
    gpio = AXIGPIO()
    
    # LED 설정
    gpio.set_leds(led_value)
    
    # 상태 출력
    print("\nLED 상태:")
    for i in range(4):
        state = "ON" if (led_value & (1 << i)) else "OFF"
        print(f"  LED{i}: {state}")
    
    # 정리
    gpio.close()
    print("\n완료!")

if __name__ == "__main__":
    main()
```

실행 권한:
```bash
chmod +x /home/root/gpio_led.py
```

#### Step 2: LED 애니메이션 예제

```bash
nano /home/root/led_animation.py
```

```python
#!/usr/bin/env python3
"""
LED 애니메이션 예제
"""

import mmap
import struct
import time

UIO_DEVICE = "/dev/uio0"
GPIO_SIZE = 0x10000
GPIO_DATA_OFFSET = 0x0000
GPIO_TRI_OFFSET = 0x0004

class AXIGPIO:
    def __init__(self):
        self.uio_fd = open(UIO_DEVICE, 'r+b', buffering=0)
        self.gpio_mem = mmap.mmap(self.uio_fd.fileno(), GPIO_SIZE)
        self.write_reg(GPIO_TRI_OFFSET, 0x00000000)
    
    def write_reg(self, offset, value):
        self.gpio_mem.seek(offset)
        self.gpio_mem.write(struct.pack('I', value))
    
    def set_leds(self, value):
        self.write_reg(GPIO_DATA_OFFSET, value & 0xF)
    
    def close(self):
        self.gpio_mem.close()
        self.uio_fd.close()

def knight_rider(gpio, cycles=5):
    """나이트 라이더 효과"""
    print("Knight Rider 효과...")
    for _ in range(cycles):
        # 왼쪽에서 오른쪽으로
        for i in range(4):
            gpio.set_leds(1 << i)
            time.sleep(0.1)
        # 오른쪽에서 왼쪽으로
        for i in range(3, -1, -1):
            gpio.set_leds(1 << i)
            time.sleep(0.1)

def blink_all(gpio, cycles=5):
    """모든 LED 깜빡임"""
    print("전체 깜빡임...")
    for _ in range(cycles):
        gpio.set_leds(0xF)
        time.sleep(0.5)
        gpio.set_leds(0x0)
        time.sleep(0.5)

def binary_counter(gpio, max_count=16):
    """이진 카운터"""
    print("이진 카운터...")
    for i in range(max_count):
        gpio.set_leds(i)
        print(f"Count: {i:2d} = {bin(i)}")
        time.sleep(0.5)

def main():
    print("=== LED 애니메이션 데모 ===\n")
    
    gpio = AXIGPIO()
    
    try:
        knight_rider(gpio)
        time.sleep(1)
        
        blink_all(gpio)
        time.sleep(1)
        
        binary_counter(gpio)
        
    except KeyboardInterrupt:
        print("\n\n중단됨")
    finally:
        gpio.set_leds(0)  # 모든 LED OFF
        gpio.close()
        print("완료!")

if __name__ == "__main__":
    main()
```

실행:
```bash
python3 /home/root/led_animation.py
```

---

## 문제 해결 가이드

### 문제 1: /dev/uio0가 존재하지 않음

**증상:**
```bash
ls /dev/uio*
# ls: cannot access '/dev/uio*': No such file or directory
```

**해결 방법:**

1. **디바이스 트리 확인:**
```bash
# 부팅 로그 확인
dmesg | grep uio

# 디바이스 트리 덤프 확인
dtc -I fs /sys/firmware/devicetree/base > /tmp/devicetree.dts
cat /tmp/devicetree.dts | grep -A 10 "gpio@41200000"
```

2. **Compatible 문자열 확인:**
   - 디바이스 트리의 `compatible`이 "generic-uio"인지 확인
   - PetaLinux 재빌드 시 디바이스 트리 변경사항 반영됐는지 확인

3. **커널 모듈 확인:**
```bash
lsmod | grep uio
# 출력이 없으면:
modprobe uio_pdrv_genirq
```

### 문제 2: LED가 켜지지 않음

**원인 및 해결:**

1. **GPIO 주소 확인:**
```bash
cat /sys/class/uio/uio0/maps/map0/addr
# Vivado Address Editor의 주소와 일치하는지 확인
```

2. **TRI 레지스터 설정 확인:**
```bash
# TRI 레지스터가 0인지 확인 (출력 모드)
GPIO_BASE=$(cat /sys/class/uio/uio0/maps/map0/addr)
devmem $((GPIO_BASE + 0x4))
# 출력: 0x00000000이어야 함
```

3. **하드웨어 연결 확인:**
   - Vivado에서 GPIO가 올바른 LED 핀에 연결되었는지 확인
   - Bitstream이 올바르게 로드되었는지 확인

### 문제 3: PetaLinux 빌드 실패

**일반적인 원인:**

1. **디스크 공간 부족:**
```bash
df -h
# 최소 100GB 여유 공간 필요
```

2. **필수 패키지 누락:**
```bash
# Ubuntu 22.04에서 다시 설치
sudo apt update
sudo apt install -y build-essential libncurses5-dev libssl-dev
```

3. **인터넷 연결 문제:**
```bash
# 패키지 다운로드 실패 시
petalinux-build -c <패키지 이름> -x cleanall
petalinux-build
```

### 문제 4: SD 카드 부팅 안됨

**체크리스트:**

1. **점퍼 설정:**
   - JP5가 SD 부팅 모드인지 확인

2. **파일 존재 확인:**
```bash
# BOOT 파티션에 다음 파일 있어야 함:
# - BOOT.BIN
# - boot.scr
# - image.ub
```

3. **파티션 테이블:**
```bash
# 첫 번째 파티션: FAT32, 부트 플래그
# 두 번째 파티션: EXT4
sudo fdisk -l /dev/sdb
```

### 문제 5: 시리얼 터미널 연결 안됨

**Windows:**
- 장치 관리자에서 Digilent USB Device 드라이버 설치 확인
- COM 포트 번호 확인

**Linux:**
```bash
# 사용자를 dialout 그룹에 추가
sudo usermod -aG dialout $USER
# 로그아웃 후 재로그인 필요

# 포트 권한 확인
ls -l /dev/ttyUSB*
```

### 문제 6: devmem 명령어 없음

```bash
# busybox devmem 설치
# PetaLinux rootfs config에서:
petalinux-config -c rootfs

# 메뉴:
# Filesystem Packages --->
#   base --->
#     busybox --->
#       [*] devmem

# 재빌드
petalinux-build
```

---

## 추가 리소스 및 참고자료

### 공식 문서
- [Xilinx PetaLinux Tools Documentation](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2022_2/ug1144-petalinux-tools-reference-guide.pdf)
- [Zynq-7000 Technical Reference Manual](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf)
- [Digilent Zybo Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)

### 유용한 명령어 요약

```bash
# PetaLinux 환경 설정
source /path/to/petalinux/settings.sh

# 프로젝트 생성
petalinux-create --type project --template zynq --name <project_name>

# 하드웨어 구성
petalinux-config --get-hw-description=<path_to_xsa>

# 커널 설정
petalinux-config -c kernel

# Rootfs 설정
petalinux-config -c rootfs

# 빌드
petalinux-build

# BOOT.BIN 생성
petalinux-package --boot --fsbl <fsbl.elf> --fpga <bitstream.bit> --u-boot <u-boot.elf>

# 클린 빌드
petalinux-build -x mrproper
```

### GPIO 제어 명령어 요약

```bash
# UIO 디바이스 확인
ls -l /dev/uio*
cat /sys/class/uio/uio0/name
cat /sys/class/uio/uio0/maps/map0/addr

# devmem으로 GPIO 제어
GPIO_BASE=0x41200000
devmem $((GPIO_BASE + 0x4)) 32 0x0    # TRI 레지스터 (출력 모드)
devmem $GPIO_BASE 32 <value>          # DATA 레지스터 (LED 값)

# C 프로그램
gpio_led_control <0-15>

# Shell script
gpio_led_control.sh <0-15>

# Python
python3 gpio_led.py <0-15>
```

---

## 마무리

이 가이드를 따라했다면 다음을 성공적으로 완료한 것입니다:

✅ Vivado에서 PL GPIO 하드웨어 설계<br>
✅ PetaLinux 프로젝트 생성 및 구성<br>
✅ 디바이스 트리 수정<br>
✅ C 프로그램으로 GPIO 제어<br>
✅ Shell script로 GPIO 제어<br>
✅ Python으로 GPIO 제어<br>
✅ SD 카드 부팅 및 테스트<br>

**다음 단계:**
- 인터럽트 기반 GPIO 제어
- AXI DMA를 활용한 고속 데이터 전송
- 센서 및 액추에이터 연결
- 네트워크 기반 원격 제어

궁금한 점이나 문제가 있으면 언제든지 질문하세요!

**행운을 빕니다! 🎉**
