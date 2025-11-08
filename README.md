# Digilent Zybo Z7-20 PetaLinux 가이드

# Xilinx/AMD 임베디드 플랫폼 비교

## Zybo Z7-20, PYNQ-Z2, Kria KV260 상세 비교

| 구분 | 항목 | Zybo Z7-20 (보드) | PYNQ-Z2 (보드) | Kria KV260 (키트) |
|------|------|-------------------|----------------|-------------------|
| **제품 유형** | - | 개발 보드 | 개발 보드 | 비전 AI 스타터 키트 |
| **제조사** | - | Digilent | TUL Corporation | AMD/Xilinx |
| **SoC** | 칩셋 | Zynq-7020 | Zynq-7020 | Zynq UltraScale+ MPSoC (K26 SOM) |
| **Processing System** | CPU | Dual ARM Cortex-A9 @ 667MHz | 동일 | Quad ARM Cortex-A53 @ 1.5GHz |
| | GPU | - | - | ARM Mali-400 MP2 |
| | 실시간 프로세서 | - | - | Dual ARM Cortex-R5F |
| **Programmable Logic** | 로직 셀 | 85K | 85K | 256K 시스템 로직 셀 |
| | 블록 RAM | 4.9Mb | 4.9Mb | 11.4Mb UltraRAM |
| | DSP 슬라이스 | 220 | 220 | 1,248 |
| **메모리** | DDR | 1GB DDR3 | 512MB DDR3 | 4GB DDR4 |
| | 플래시 | 16MB Quad-SPI | 16MB Quad-SPI | 16GB eMMC, QSPI |
| **비디오** | 디스플레이 출력 | HDMI 출력 | HDMI 입출력 | DisplayPort |
| | 카메라 입력 | PCAM 5C 지원 (옵션) | - | MIPI CSI-2 (x2) |
| **오디오** | 오디오 | SSM2603 codec (Line in/out, Headphone) | Audio codec | - |
| **네트워크** | Ethernet | 1x GbE | 1x GbE | 1x GbE |
| **USB** | USB | 1x USB 2.0 OTG | 1x USB 2.0 | USB 3.0 (x1) |
| **스토리지** | SD 카드 | microSD | microSD | microSD |
| **확장** | PCIe | - | - | - |
| | 확장 포트 | 6x Pmod, Arduino shield | Arduino, RPi, 2x Pmod | FMC, Pmod |
| **AI/ML** | AI 가속 | - | - | DPU 포함 |
| **보안** | 보안 기능 | 기본 | 기본 | 하드웨어 보안, Secure Boot |
| **전원** | 소비전력 | USB 또는 외부 7-15V | USB 또는 12V | 12V/2A |
| **온도 범위** | 동작 온도 | 상업용 (0~70°C) | 상업용 | 상업용 (0~50°C) |
| **사용자 I/O** | 버튼/스위치/LED | 4 버튼, 2 슬라이드 스위치, 5 LED | 4 버튼, 2 슬라이드 스위치, 4 LED | - |
| **소프트웨어** | OS 지원 | Linux, FreeRTOS | PYNQ (Python/Jupyter) | Ubuntu 22.04 |
| | 개발 환경 | Vivado, Vitis | PYNQ Framework | Vitis AI, 비전 앱 |
| **주요 용도** | 타겟 시장 | 교육/임베디드 시스템 | 교육/연구 (Python 중심) | 비전 AI 애플리케이션 |
| **가격대** | 대략적 가격 | $200-250 | $150-200 | $199-299 |
| **출시 시기** | 세대 | 2017 | 2018 | 2021 |

 * C = Commercial (Tj = 0°C to +85°C)
 * E = Extended (Tj = 0°C to +100°C)
 * I = Industrial (Tj = –40°C to +100°C)

<img width="1354" height="864" alt="024" src="https://github.com/user-attachments/assets/67a63815-aec8-4000-92d1-bdb633852e73" />



---

## 주요 차이점 요약

### 세대 및 성능
- **Zybo Z7-20 / PYNQ-Z2**: Zynq-7000 시리즈 기반, 듀얼코어, 교육/프로토타입용
- **Kria KV260**: Zynq UltraScale+ 기반, 쿼드코어 + GPU, 산업용 AI/ML 특화

### 메모리 및 스토리지
- **Zybo Z7-20**: 1GB DDR3 (가장 많음)
- **PYNQ-Z2**: 512MB DDR3
- **Kria KV260**: 4GB DDR4 + 16GB eMMC (압도적)

### 타겟 사용자
- **Zybo Z7-20**: 임베디드 시스템 개발자, 전통적 FPGA 개발자
- **PYNQ-Z2**: 학생, 연구자, Python 기반 FPGA 입문자
- **Kria KV260**: 비전 AI 개발자, 산업용 애플리케이션

### AI/ML 성능
- **Zybo Z7-20 / PYNQ-Z2**: 수동 가속기 구현 필요, 교육용 ML 프로젝트에 적합
- **Kria KV260**: DPU(Deep Learning Processing Unit) 내장으로 즉시 사용 가능

### 개발 환경
- **Zybo Z7-20**: Vivado/Vitis 기반 전통적 개발
- **PYNQ-Z2**: Python/Jupyter Notebook 기반 쉬운 진입
- **Kria KV260**: Vitis AI, 사전 빌드된 비전 애플리케이션

### 확장성
- **Zybo Z7-20**: 6x Pmod + Arduino shield (최다 확장)
- **PYNQ-Z2**: Arduino + RPi + 2x Pmod (호환성 중시)
- **Kria KV260**: FMC + Pmod (산업용 고속 인터페이스)
---

## 제품별 추천 사용 사례

### Zybo Z7-20
- 임베디드 리눅스 개발
- 디지털 신호처리 (DSP) 프로젝트
- FPGA 설계 교육
- 오디오/비디오 처리 프로젝트
- 다양한 주변장치 연결이 필요한 프로젝트

### PYNQ-Z2
- FPGA 학습 및 교육 (Python 선호)
- 대학 연구 프로젝트
- 머신러닝/딥러닝 입문
- 빠른 프로토타이핑
- Jupyter Notebook 기반 개발

### Kria KV260
- 스마트 카메라 시스템
- 공장 자동화 비전 검사
- 의료 영상 처리
- 얼굴 인식 및 객체 탐지
- 실시간 AI 추론 애플리케이션

---

## 참고 자료
- [Digilent Zybo Z7 제품 페이지](https://digilent.com/shop/zybo-z7-zynq-7000-arm-fpga-soc-development-board/)
- [PYNQ 공식 웹사이트](http://www.pynq.io/)
- [AMD Kria KV260 제품 페이지](https://www.xilinx.com/products/som/kria/kv260-vision-starter-kit.html)

---

## 빌드 성공 및 Warning 해결 포함

---

## 목차
1. [VirtualBox Ubuntu 22.04.5 설치](#1-virtualbox-ubuntu-22045-설치)
2. [Ubuntu 시스템 준비](#2-ubuntu-시스템-준비)
3. [PetaLinux 2022.2 설치](#3-petalinux-20222-설치)
4. [Zybo Z7-20 프로젝트 생성](#4-zybo-z7-20-프로젝트-생성)
5. [PetaLinux 빌드](#5-petalinux-빌드)
6. [빌드 Warning 해결](#6-빌드-warning-해결)
7. [SD 카드 이미지 생성](#7-sd-카드-이미지-생성)
8. [Windows에서 SD 카드 굽기](#8-windows에서-sd-카드-굽기)
9. [Zybo Z7-20 부팅](#9-zybo-z7-20-부팅)
10. [트러블슈팅](#10-트러블슈팅)

---
## 0. Zybo - PS 설정 및 XSA 만들기

```
create_zybo_petalinux_project.tcl
```
   *  프로젝트 이름 및 디렉토리, 디자인 탑의 경로를 상황에 맞게 수정합니다.
```
# Set project variables
set project_name "zybo_7020_peta"
set project_dir "C:/Users/Administrator/${project_name}"
set bd_name "design_top"
set part_name "xc7z020clg400-1"
set board_part "digilentinc.com:zybo-z7-20:part0:1.1"
```
* Tools > Run Tcl Script.. > create_zybo_petalinux_project.tcl 선택 후 실행

* File > Export > Xsa 생성(include bit stream 선택)

## 준비할 파일
   * petalinux-v2022.2-10141622-installer.run
   * ubuntu-22.04.5-desktop-amd64.iso
   * VirtualBox-7.2.4-170995-Win.exe
   * balenaEtcher-2.1.2.Setup.exe

## 1. VirtualBox Ubuntu 22.04.5 설치

### 1.1 VirtualBox 가상머신 생성

**시스템 사양 (권장)**

```
lsb_release -a
```

```
이름: Zybo-PetaLinux
타입: Linux
버전: Ubuntu (64-bit)

메모리: 16384 MB (16GB) - 최소 8GB
프로세서: 8 CPU - 최소 4 CPU
디스크: 200 GB (VDI, 동적 할당) - 최소 150GB
```

**고급 설정**
- 설정 → 시스템 → 프로세서
  - ✅ PAE/NX 사용
  - ✅ 하드웨어 가상화 (VT-x/AMD-V) 활성화
  
- 설정 → 디스플레이
  - 비디오 메모리: 128 MB
  - ✅ 3D 가속 사용

- 설정 → 공유 폴더
  - 새 공유 폴더 추가
  - 이름: `SharedFolder`
  - 경로: `C:\SharedFolder` (Windows에 먼저 생성)
  - ✅ 자동 마운트
  - ✅ 영구적으로 만들기

### 1.2 Ubuntu 22.04.5 설치

1. **ISO 마운트 및 부팅**
   - `ubuntu-22.04.5-desktop-amd64.iso` 선택
   - 가상머신 시작

2. **설치 옵션**
   - Install Ubuntu
   - 언어: English
   - 키보드: English (US)
   - Normal installation
   - ✅ Download updates while installing Ubuntu
   - ✅ Install third-party software

3. **디스크 설정**
   - Erase disk and install Ubuntu
   - Install Now

4. **사용자 계정**
   ```
   Your name: Zybo User
   Computer name: zybo-petalinux
   Username: zybo (또는 원하는 이름)
   Password: [원하는 비밀번호]
   ```

5. **설치 완료 후 재부팅**
 
### 5.1 공유 폴더 권한 설정

```bash
# 사용자를 vboxsf 그룹에 추가
sudo usermod -aG vboxsf gotree94

# 재부팅
sudo reboot

# 재로그인 후 확인
groups

# 공유 폴더 확인
ls -la /mnt/share
```

---

## 2. Ubuntu 시스템 준비

### 2.1 시스템 업데이트

```bash
sudo apt update
sudo apt upgrade -y
```

### 2.2 32비트 라이브러리 지원 추가

```bash
sudo dpkg --add-architecture i386
sudo apt update
```

### 2.3 필수 패키지 설치

```bash
sudo apt install -y \
    build-essential \
    gcc-multilib \
    g++-multilib \
    gawk \
    wget \
    git \
    diffstat \
    unzip \
    texinfo \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    libegl1-mesa \
    libsdl1.2-dev \
    pylint \
    xterm \
    rsync \
    curl \
    libncurses5-dev \
    libncursesw5-dev \
    libssl-dev \
    flex \
    bison \
    libselinux1 \
    gnupg \
    zlib1g-dev \
    libtool \
    autoconf \
    automake \
    net-tools \
    screen \
    pax \
    gzip \
    vim \
    iproute2 \
    locales \
    libncurses5 \
    libtinfo5
```

### 2.4 32비트 라이브러리 설치

```bash
sudo apt install -y \
    libncurses5:i386 \
    libc6:i386 \
    libstdc++6:i386 \
    lib32z1 \
    zlib1g:i386
```

### 2.5 Locale 설정

```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

### 2.6 Dash를 Bash로 변경

```bash
sudo dpkg-reconfigure dash
```
- 메뉴가 나타나면 **"No"** 선택

### 2.7 TFTP 서버 설치

```bash
# TFTP 서버 설치
sudo apt install -y tftpd-hpa

# TFTP 디렉토리 생성 및 권한 설정
sudo mkdir -p /tftpboot
sudo chmod 777 /tftpboot
sudo chown nobody:nogroup /tftpboot

# TFTP 설정 편집
sudo vi /etc/default/tftpd-hpa
```

**TFTP 설정 내용:**
```
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

```bash
# TFTP 서비스 재시작
sudo systemctl restart tftpd-hpa
sudo systemctl enable tftpd-hpa

# 상태 확인
sudo systemctl status tftpd-hpa
```

---

## 3. PetaLinux 2022.2 설치

### 3.1 작업 디렉토리 생성

```bash
mkdir -p ~/petalinux_work
cd ~/petalinux_work
```

### 3.2 인스톨러 준비

Windows에서 Ubuntu로 파일 복사:
```bash
# petalinux-v2022.2-10141622-installer.run을 
# C:\SharedFolder에 복사한 후

# Ubuntu에서:
cp /mnt/share/petalinux-v2022.2-10141622-installer.run ~/petalinux_work/
chmod +x ~/petalinux_work/petalinux-v2022.2-10141622-installer.run
```

### 3.3 PetaLinux 설치

```bash
# 설치 디렉토리 생성
mkdir -p ~/petalinux/2022.2

# 인스톨러 실행
cd ~/petalinux_work
./petalinux-v2022.2-10141622-installer.run -d ~/petalinux/2022.2
```

**설치 진행:**
- 라이센스 동의: `y` 입력하고 Enter
- 설치 시간: 약 10-30분 소요
- 디스크 사용량: 약 8GB

### 3.4 PetaLinux 환경 설정

```bash
# PetaLinux 환경 활성화
source ~/petalinux/2022.2/settings.sh

# 확인
echo $PETALINUX
# 출력: /home/사용자명/petalinux/2022.2
```

**영구 설정 (선택사항):**
```bash
echo "source ~/petalinux/2022.2/settings.sh" >> ~/.bashrc
```

---

## 4. Zybo Z7-20 프로젝트 생성

### 4.1 프로젝트 디렉토리 생성

```bash
mkdir -p ~/projects
cd ~/projects
```

### 4.2 XSA 파일 준비

```bash
# design_top_wrapper.xsa를 Windows의 SharedFolder로 복사한 후
cp /mnt/share/design_top_wrapper.xsa ~/projects/

# XSA 파일 내용 확인
unzip -l design_top_wrapper.xsa
```

**예상 출력:**
```
Archive:  design_top_wrapper.xsa
  Length      Date    Time    Name
---------  ---------- -----   ----
      306  2025-09-22 21:05   aie_primitive.json
     3168  2025-09-22 21:05   design_1.bda
   155208  2025-09-22 21:05   design_1.hwh
   618914  2025-09-22 21:05   design_top_wrapper.bit
   542756  2025-09-22 21:05   ps7_init.c
     3794  2025-09-22 21:05   ps7_init.h
  2951774  2025-09-22 21:05   ps7_init.html
    35774  2025-09-22 21:05   ps7_init.tcl
   543373  2025-09-22 21:05   ps7_init_gpl.c
     4412  2025-09-22 21:05   ps7_init_gpl.h
     1441  2025-09-22 21:05   sysdef.xml
     2432  2025-09-22 21:05   xsa.json
     1221  2025-09-22 21:05   xsa.xml
```

### 4.3 Zynq-7000 프로젝트 생성

```bash
cd ~/projects

# PetaLinux 환경이 활성화되어 있는지 확인
source ~/petalinux/2022.2/settings.sh

# Zybo Z7-20용 프로젝트 생성
petalinux-create --type project --template zynq --name myproject

# 프로젝트 디렉토리로 이동
cd myproject
```

### 4.4 하드웨어 설정 가져오기

```bash
# XSA 파일로 하드웨어 설정
petalinux-config --get-hw-description=~/projects/
```

**초기화 방법(확인중)**

#### 결과물만 지우

```bash
# 1. PetaLinux 환경 설정
source ~/petalinux/2022.2/settings.sh

# 2. 프로젝트 디렉토리로 이동
cd ~/projects/myproject

# 3. 설정 초기화/클린 작업
petalinux-build -x mrproper           # 전체 클린
# 또는
petalinux-build -c kernel -x cleansstate    # 커널만 클린
petalinux-build -c rootfs -x cleansstate    # rootfs만
petalinux-build -c bootloader -x cleansstate # u-boot만

# 4. 다시 설정
petalinux-config                       # 프로젝트 설정
petalinux-config -c kernel            # 커널 설정  
petalinux-config -c rootfs            # 루트파일시스템 설정

# 5. 하드웨어 다시 임포트
petalinux-config --get-hw-description=~/projects/
```

#### 설정지우기(확인중)
```

```

**설정 메뉴가 나타남**

### 4.5 시스템 설정 (중요!)

#### **Image Packaging Configuration**
```
-*- ZYNQ Configuration
    Linux Components Selection  --->
    Auto Config Settings  --->
-*- Subsystem AUTO Hardware Settings  --->
    DTG Settings  --->
    FSBL Configuration  --->
    FPGA Manager  --->
    u-boot Configuration  --->
    Linux Configuration  --->
    Image Packaging Configuration  --->
    Firmware Version Configuration  --->
```

#### **Root filesystem type (EXT4 (SD/eMMC/SATA/USB))**
```
     Root filesystem type (EXT4 (SD/eMMC/SATA/USB))  --->
 (/dev/mmcblk0p2) Device node of SD device
 (image.ub) name for bootable kernel image
 (cpio cpio.gz cpio.gz.u-boot ext4 tar.gz jffs2) Root filesystem formats
 (0x1000) DTB padding size
 [*] Copy final images to tftpboot
 (/tftpboot) tftpboot directory
```

#### **EXT4 (SD/eMMC/SATA/USB)**
```
┌──────────────────── Root filesystem type ─────────────────────┐
│  Use the arrow keys to navigate this window or press the      │  
│  hotkey of the item you wish to select followed by the <SPACE │  
│  BAR>. Press <?> for additional information about this        │  
│ ┌───────────────────────────────────────────────────────────┐ │  
│ │                ( ) INITRAMFS                              │ │  
│ │                ( ) INITRD                                 │ │  
│ │                ( ) JFFS2                                  │ │  
│ │                ( ) UBI/UBIFS                              │ │  
│ │                ( ) NFS                                    │ │  
│ │                (X) EXT4 (SD/eMMC/SATA/USB)                │ │  
│ └────────────────────↓(+)───────────────────────────────────┘ │  
├───────────────────────────────────────────────────────────────┤  
│                    <Select>      < Help >      	            │
└───────────────────────────────────────────────────────────────┘
```

#### **Subsystem AUTO Hardware Settings**
```
Subsystem AUTO Hardware Settings  --->
    Serial Settings  --->
        Primary stdin/stdout (ps7_uart_1)  --->
            (X) ps7_uart_1
    
    Ethernet Settings  --->
        Primary Ethernet (ps7_ethernet_0)  --->
            (X) ps7_ethernet_0
    
    SD/SDIO Settings  --->
        Primary SD/SDIO (ps7_sd_0)  --->
            (X) ps7_sd_0
```
**설정 저장:**
- `Save` 선택
- 기본 파일명 `.config` 그대로 저장
- `Exit` 선택
  

---

### 4.6 Root Filesystem 설정

```bash
petalinux-config -c rootfs
```

**초기화 방법(확인중)**
```bash
# 1. PetaLinux 환경 설정
source ~/petalinux/2022.2/settings.sh

# 2. 프로젝트 디렉토리로 이동
cd ~/projects/myproject

# 3. 설정 초기화/클린 작업
petalinux-build -x mrproper           # 전체 클린
# 또는
petalinux-build -c kernel -x cleansstate    # 커널만 클린
petalinux-build -c rootfs -x cleansstate    # rootfs만
petalinux-build -c bootloader -x cleansstate # u-boot만

# 4. 다시 설정
petalinux-config                       # 프로젝트 설정
petalinux-config -c kernel            # 커널 설정  
petalinux-config -c rootfs            # 루트파일시스템 설정

# 5. rootfs 설정 파일 삭제
rm -f project-spec/configs/rootfs_config

# 6. rootfs 설정 다시 열기 (기본값으로 시작)
petalinux-config -c rootfs
```

**유용한 패키지:**
```
Filesystem Packages   --->
  Petalinux Package Groups  --->
  Image Features  --->
  user packages   --->
  PetaLinux RootFS Settings  --->
```

```
Filesystem Packages  --->
    admin  --->
        [*] sudo
    
    console/utils  --->
        [*] vim
        [*] nano
    
```
---
### 4.7 Image Features -> Root 로그인 설정 (중요!)

```
[*] ssh-server-dropbear
[ ] ssh-server-openssh
[*] hwcodecs
[ ] package-management
-*- debug-tweaks
[*] auto-login
    Init-manager (sysvinit)  --->  
```

**설정 저장:**
- `Save` → `Exit`

## 5. PetaLinux 빌드

### 5.1 전체 시스템 빌드

```bash
cd ~/projects/myproject

# PetaLinux 환경 확인
source ~/petalinux/2022.2/settings.sh

# 빌드 시작
petalinux-build
```

**빌드 시간:**
- 첫 빌드: 1-3시간 (시스템 사양에 따라)
- 이후 빌드: 10-30분

**빌드 성공 메시지:**
```
NOTE: Tasks Summary: Attempted 5162 tasks of which 1350 didn't need to be rerun and all succeeded.
Summary: There were 2 WARNING messages shown.
INFO: Failed to copy built images to tftp dir: /tftpboot
[INFO] Successfully built project
```

### 5.2 부트 이미지 생성 (BOOT.BIN)

**1단계: XSA 파일 구조 확인**

```bash
cd ~/projects/myproject

# XSA 파일 확인
ls -lh design_top_wrapper.xsa

# XSA 파일 구조 미리보기 (압축 해제 없이)
unzip -l design_top_wrapper.xsa | grep -E "\.(bit|bd|hwh)"
```

**2단계: 임시 디렉토리에 XSA 압축 해제**

```bash
# 임시 작업 디렉토리 생성
mkdir -p ~/xsa_extract
cd ~/xsa_extract

# XSA 파일 압축 해제
unzip -o ~/projects/design_top_wrapper.xsa

# 압축 해제된 파일 확인
ls -lh *.bit
```

**3단계: Bitstream 파일을 PetaLinux images 디렉토리로 복사**

```bash
# PetaLinux 프로젝트 디렉토리로 이동
cd ~/projects/myproject

# Bitstream 복사
cp ~/xsa_extract/design_top_wrapper.bit images/linux/

# 복사 확인
ls -lh images/linux/design_top_wrapper.bit
```

```bash
# PetaLinux 프로젝트 디렉토리로 이동
cd ~/projects/myproject

# Bitstream 복사
cp ~/xsa_extract/design_1_wrapper.bit images/linux/

# 복사 확인
ls -lh images/linux/design_1_wrapper.bit
```

```bash
cd ~/projects/myproject

petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force
```

```bash
cd ~/projects/myproject

petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_1_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force
```

**생성된 파일:**
```
images/linux/BOOT.BIN
```

### 5.3 WIC 이미지 생성 (권장)

```bash
cd ~/projects/myproject

# WIC 이미지 생성
petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
```

**생성된 파일:**
```
images/linux/petalinux-sdimage.wic
```

### 5.4 이미지 압축 (선택사항)

```bash
cd ~/projects/myproject/images/linux/

# gzip 압축
gzip -k petalinux-sdimage.wic

# 압축 파일 확인
ls -lh petalinux-sdimage.wic.gz
```

### 5.5 Windows로 파일 복사

```bash
# WIC 이미지 복사
cp petalinux-sdimage.wic /mnt/share/

# 또는 압축 파일
cp petalinux-sdimage.wic.gz /mnt/share/

# 개별 부트 파일도 백업
mkdir -p /mnt/share/zybo_boot_files/
cp BOOT.BIN image.ub boot.scr /mnt/share/zybo_boot_files/
cp rootfs.tar.gz /mnt/share/zybo_boot_files/
```

---

## 6. Windows에서 SD 카드 굽기

### 6.1 준비물

- **SD 카드**: 최소 4GB (8GB 이상 권장)
- **SD 카드 리더기**
- **balenaEtcher 2.1.2** (또는 최신 버전)

### 6.2 balenaEtcher로 SD 카드 굽기

#### Step 1: balenaEtcher 실행

Windows에서 `balenaEtcher-2.1.2.Setup.exe` 실행 및 설치

#### Step 2: 이미지 파일 선택

1. **Flash from file** 클릭
2. 파일 선택:
   - `C:\SharedFolder\petalinux-sdimage.wic` 또는
   - `petalinux-sdimage.wic.gz` (압축 파일, 자동 해제)

#### Step 3: SD 카드 선택

1. **Select target** 클릭
2. SD 카드 드라이브 선택
   - ⚠️ **주의**: 올바른 드라이브인지 확인!
   - 모든 데이터가 삭제됩니다

#### Step 4: 굽기 시작

1. **Flash!** 클릭
2. 진행 상황 표시 (약 5-10분)
3. "Flash Complete!" 메시지 확인

#### Step 5: 안전하게 제거

- Windows에서 "하드웨어 안전하게 제거"
- SD 카드 제거

### 6.3 SD 카드 파티션 확인

**디스크 관리 (diskmgmt.msc):**
```
파티션 1: ~500MB, FAT32, BOOT (활성)
파티션 2: ~나머지, EXT4, rootfs
```

---

## 7. Zybo Z7-20 부팅

### 7.1 하드웨어 준비

#### Zybo Z7-20 점퍼 설정

**JP5 (Boot Mode) 점퍼:**
```
SD 카드 부팅 모드:
JP5: [  ] [  ]
     [SD] [  ]
```

#### 연결

1. **SD 카드 삽입**
   - Zybo Z7-20의 SD 카드 슬롯에 삽입

2. **UART 연결**
   - USB-UART 케이블을 J14 포트에 연결
   - Windows PC와 연결

3. **이더넷 연결** (선택사항)
   - RJ45 케이블로 네트워크 연결

4. **전원**
   - USB 전원 또는 DC 12V 어댑터
   - 전원 스위치 OFF 상태

### 7.2 Windows에서 시리얼 콘솔 연결

#### FTDI 드라이버 설치

- [FTDI 드라이버 다운로드](https://ftdichip.com/drivers/vcp-drivers/)
- 설치 후 재부팅

#### 장치 관리자에서 COM 포트 확인

1. `Win + X` → 장치 관리자
2. "포트 (COM & LPT)" 확인
3. "USB Serial Port (COMx)" 찾기 (예: COM3)

#### PuTTY 설정

**설정:**
```
Connection type: Serial
Serial line: COM3
Speed: 115200

Category: Connection → Serial
  - Speed: 115200
  - Data bits: 8
  - Stop bits: 1
  - Parity: None
  - Flow control: None
```

### 7.3 부팅

1. **시리얼 콘솔 열기** (PuTTY 또는 Tera Term)
2. **전원 켜기** (SW0 스위치 ON)
3. **부팅 메시지 확인**

```
Xilinx Zynq First Stage Boot Loader
Release 2022.2

U-Boot 2022.01 (Sep 22 2025 - 21:05:30 +0000)

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 5.15.36-xilinx-v2022.2

PetaLinux 2022.2 myproject ttyPS0

myproject login:
```

### 7.4 로그인

**기본 계정:**
```
Username: root
Password: root
```

**처음 로그인 후:**
```bash
# 호스트명 확인
hostname

# 네트워크 확인
ifconfig eth0

# 커널 버전 확인
uname -a

# PetaLinux 버전 확인
cat /etc/os-release
```

### 7.5 네트워크 설정

#### DHCP (자동)
```bash
# DHCP 클라이언트 실행
udhcpc -i eth0

# IP 확인
ifconfig eth0
```

#### 고정 IP (수동)
```bash
# 임시 설정
ifconfig eth0 192.168.1.100 netmask 255.255.255.0
route add default gw 192.168.1.1

# ping 테스트
ping 192.168.1.1
```

---
---
---
---

# PetaLinux 설정 초기화 가이드

Digilent Zybo Z7-020에서 PetaLinux 설정을 초기화하는 방법을 정리한 문서입니다.

## 목차
- [개요](#개요)
- [사전 준비](#사전-준비)
- [1. System Configuration 초기화](#1-system-configuration-초기화)
- [2. Kernel Configuration 초기화](#2-kernel-configuration-초기화)
- [3. RootFS Configuration 초기화](#3-rootfs-configuration-초기화)
- [4. 모두 한번에 초기화](#4-모두-한번에-초기화)
- [5. 단계별 테스트 스크립트](#5-단계별-테스트-스크립트)
- [확인 방법](#확인-방법)
- [참고 사항](#참고-사항)

## 개요

PetaLinux는 Yocto 기반의 Xilinx(AMD) 임베디드 리눅스 개발 도구입니다. `petalinux-build -x mrproper`는 빌드 결과물만 삭제하고 설정 파일은 유지하므로, 설정을 초기화하려면 별도의 작업이 필요합니다.

## 사전 준비

모든 작업 전에 PetaLinux 환경을 설정해야 합니다:

```bash
source ~/petalinux/2022.2/settings.sh
cd ~/projects/myproject
```

## 1. System Configuration 초기화

System 설정만 초기화:

```bash
cd ~/projects/myproject
source ~/petalinux/2022.2/settings.sh

# 설정 파일 삭제
rm project-spec/configs/config

# 다시 설정 (기본값으로 시작)
petalinux-config --get-hw-description=~/projects/
```

**관련 파일:** `project-spec/configs/config`

## 2. Kernel Configuration 초기화

Kernel 설정만 초기화:

```bash
cd ~/projects/myproject
source ~/petalinux/2022.2/settings.sh

# 방법 1: defconfig 사용 (추천)
petalinux-config -c kernel --defconfig

# 방법 2: 설정 파일 직접 삭제
rm project-spec/configs/kernel.config
rm build/tmp/work/*/linux-xlnx/*/.config
petalinux-config -c kernel
```

**관련 파일:** `project-spec/configs/kernel.config`

## 3. RootFS Configuration 초기화

RootFS 설정만 초기화:

```bash
cd ~/projects/myproject
source ~/petalinux/2022.2/settings.sh

# 방법 1: defconfig 사용
petalinux-config -c rootfs --defconfig

# 방법 2: 설정 파일 직접 삭제
rm project-spec/configs/rootfs_config
petalinux-config -c rootfs
```

**관련 파일:** `project-spec/configs/rootfs_config`

## 4. 모두 한번에 초기화

### 방법 A: 설정 파일 모두 삭제

```bash
cd ~/projects/myproject
source ~/petalinux/2022.2/settings.sh

# 현재 설정 백업 (권장)
cp -r project-spec/configs project-spec/configs.backup

# 모든 설정 파일 삭제
rm project-spec/configs/config
rm project-spec/configs/kernel.config
rm project-spec/configs/rootfs_config
rm project-spec/configs/plnxbsp.conf

# 빌드 캐시도 정리
petalinux-build -x mrproper

# 처음부터 다시 설정
petalinux-config --get-hw-description=~/projects/
petalinux-config -c kernel
petalinux-config -c rootfs
```

### 방법 B: 프로젝트 완전 재생성 (가장 깨끗)

```bash
source ~/petalinux/2022.2/settings.sh
cd ~/projects/

# 백업
mv myproject myproject.backup

# 새로 생성
petalinux-create -t project --template zynq -n myproject
cd myproject

# 하드웨어 설정 적용
petalinux-config --get-hw-description=/path/to/your/design_1_wrapper.xsa

# 각 컴포넌트 설정
petalinux-config -c kernel
petalinux-config -c rootfs
```

## 5. 단계별 테스트 스크립트

각각 테스트해보시려면:

```bash
source ~/petalinux/2022.2/settings.sh
cd ~/projects/myproject

# 테스트 1: Kernel만 초기화
echo "=== Kernel 초기화 테스트 ==="
petalinux-config -c kernel --defconfig
petalinux-config -c kernel

# 테스트 2: RootFS만 초기화
echo "=== RootFS 초기화 테스트 ==="
petalinux-config -c rootfs --defconfig
petalinux-config -c rootfs

# 테스트 3: System만 초기화
echo "=== System 초기화 테스트 ==="
rm project-spec/configs/config
petalinux-config --get-hw-description=/path/to/your.xsa

# 테스트 4: 모두 초기화
echo "=== 전체 초기화 테스트 ==="
rm project-spec/configs/config
rm project-spec/configs/kernel.config
rm project-spec/configs/rootfs_config
petalinux-build -x mrproper
petalinux-config --get-hw-description=/path/to/your.xsa
petalinux-config -c kernel
petalinux-config -c rootfs
```

## 확인 방법

초기화가 잘 되었는지 확인:

```bash
# 설정 파일 날짜 확인
ls -lh project-spec/configs/

# 설정 내용 확인
cat project-spec/configs/config
cat project-spec/configs/kernel.config
cat project-spec/configs/rootfs_config
```

## 참고 사항

### 주요 PetaLinux 클린 명령어

| 명령어 | 설명 |
|--------|------|
| `petalinux-build -x clean` | 빌드 결과물만 삭제 (설정 유지) |
| `petalinux-build -x mrproper` | 빌드 결과물 삭제 (설정 유지) |
| `petalinux-build -x distclean` | 모든 빌드 결과물, 다운로드, 설정 삭제 |
| `petalinux-build -c kernel -x cleansstate` | 커널 컴포넌트만 클린 |

### 환경 설정

매번 `source` 명령을 실행하기 번거로우면 `.bashrc`에 추가:

```bash
echo "source ~/petalinux/2022.2/settings.sh" >> ~/.bashrc
```

### 주의사항

> ⚠️ **경고**: `distclean`이나 설정 파일 삭제는 되돌릴 수 없습니다. 반드시 백업을 먼저 수행하세요!

```bash
# 백업 예시
cp -r project-spec/configs project-spec/configs.backup.$(date +%Y%m%d_%H%M%S)
```

## 참고 자료

- [Xilinx PetaLinux Tools Documentation](https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide)
- [Digilent Zybo Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)

---

**작성일**: 2025-11-05  
**PetaLinux 버전**: 2022.2  
**타겟 보드**: Digilent Zybo Z7-020


---
---
---
---

## 6. 빌드 Warning 해결

빌드 중 발생한 2개의 Warning에 대한 분석과 해결 방법입니다.

### 6.1 Warning 1: Host Distribution 검증 안됨

**Warning 메시지:**
```
WARNING: Host distribution "ubuntu-22.04" has not been validated with this version of the build system; 
you may possibly experience unexpected failures. It is recommended that you use a tested distribution.
```

**원인:**
- PetaLinux 2022.2는 공식적으로 Ubuntu 20.04를 지원
- Ubuntu 22.04는 검증되지 않은 배포판

**영향:**
- ⚠️ 경고성 메시지이며, 실제로는 빌드가 정상적으로 완료됨
- 대부분의 경우 문제없이 작동

**해결 방법 (선택사항):**

#### 방법 1: 경고 무시 (권장)
```bash
# 빌드가 성공했다면 무시해도 됨
# 실제 문제가 발생할 때만 조치
```

#### 방법 2: 배포판 검증 우회
```bash
# 환경 변수로 검증 비활성화
export SKIP_DISTRO_CHECK=1

# 또는 .bashrc에 추가
echo "export SKIP_DISTRO_CHECK=1" >> ~/.bashrc
```

#### 방법 3: 공식 지원 배포판 사용
- Ubuntu 20.04 LTS 사용 (권장하지 않음 - 재설치 필요)

### 6.2 Warning 2: Uninative glibc 버전 불일치

**Warning 메시지:**
```
WARNING: Your host glibc version (2.35) is newer than that in uninative (2.34). 
Disabling uninative so that sstate is not corrupted.
```

**원인:**
- Ubuntu 22.04의 glibc 버전 (2.35)이 PetaLinux uninative (2.34)보다 최신
- Yocto는 자동으로 uninative를 비활성화하여 sstate 손상 방지

**영향:**
- ✅ 자동으로 처리되므로 문제없음
- 빌드 시간이 약간 증가할 수 있음 (sstate 캐시 미사용)

**해결 방법:**

#### 방법 1: 경고 무시 (권장)
```bash
# Yocto가 자동으로 처리하므로 조치 불필요
# 빌드는 정상적으로 완료됨
```

#### 방법 2: Uninative 비활성화 (명시적)
```bash
# project-spec/meta-user/conf/petalinuxbsp.conf 편집
vi ~/projects/myproject/project-spec/meta-user/conf/petalinuxbsp.conf

# 다음 줄 추가:
INHERIT_remove = "uninative"
```

### 6.3 Info: TFTP 복사 실패

**Info 메시지:**
```
INFO: Failed to copy built images to tftp dir: /tftpboot
```

**원인:**
- `/tftpboot` 디렉토리가 없거나 권한 부족
- TFTP 서버가 설치되지 않음

**영향:**
- ⚠️ SD 카드 부팅에는 영향 없음
- TFTP 네트워크 부팅을 사용하지 않는다면 무시 가능

**해결 방법:**

#### 방법 1: TFTP 복사 비활성화 (권장)
```bash
petalinux-config

# Image Packaging Configuration --->
#     [ ] Copy final images to tftpboot  (비활성화)
```

#### 방법 2: TFTP 디렉토리 생성
```bash
# TFTP 디렉토리 생성 및 권한 설정
sudo mkdir -p /tftpboot
sudo chmod 777 /tftpboot
sudo chown $USER:$USER /tftpboot

# 재빌드 (또는 이미지만 복사)
cp ~/projects/myproject/images/linux/BOOT.BIN /tftpboot/
cp ~/projects/myproject/images/linux/image.ub /tftpboot/
cp ~/projects/myproject/images/linux/boot.scr /tftpboot/
```

#### 방법 3: TFTP 서버 완전 설치 (네트워크 부팅용)
```bash
# TFTP 서버 설치
sudo apt install -y tftpd-hpa

# 설정
sudo vi /etc/default/tftpd-hpa
```

**TFTP 설정:**
```
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

```bash
# 권한 설정
sudo mkdir -p /tftpboot
sudo chmod 777 /tftpboot

# 서비스 재시작
sudo systemctl restart tftpd-hpa
sudo systemctl enable tftpd-hpa
```

### 6.4 Warning 요약

| Warning | 심각도 | 조치 필요 | 권장 사항 |
|---------|--------|-----------|-----------|
| Ubuntu 22.04 미검증 | 낮음 | 선택적 | 무시 가능 |
| glibc 버전 불일치 | 낮음 | 불필요 | 자동 처리됨 |
| TFTP 복사 실패 | 매우 낮음 | 선택적 | SD 카드 부팅 시 무시 |

**결론:**
- ✅ 빌드는 성공적으로 완료됨
- ✅ SD 카드 부팅에 문제 없음
- ⚠️ Warning은 참고용이며 필수 조치 아님

---

## 7. SD 카드 이미지 생성

### 7.1 생성된 이미지 파일 확인

```bash
cd ~/projects/myproject/images/linux/

ls -lh
```

**주요 파일:**
```
BOOT.BIN           - 부트 이미지 (FSBL + Bitstream + U-Boot)
image.ub           - 커널 + Device Tree (FIT 이미지)
boot.scr           - U-Boot 부팅 스크립트
rootfs.tar.gz      - 루트 파일시스템
rootfs.ext4        - EXT4 형식 루트 파일시스템
```



---

## 10. 트러블슈팅

### 10.1 빌드 관련 문제

#### 메모리 부족
```bash
# 스왑 파일 생성
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 영구 설정
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

#### 디스크 공간 부족
```bash
# 디스크 사용량 확인
df -h

# 빌드 캐시 정리
cd ~/projects/myproject
petalinux-build -x clean
```

### 10.2 부팅 문제

#### 부팅 멈춤
```bash
# Ubuntu에서 BOOT.BIN 재생성
cd ~/projects/myproject

petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

# SD 카드에 다시 복사
```

#### UART 출력 없음
```bash
# COM 포트 번호 확인
# Baud Rate 115200 확인
# FTDI 드라이버 재설치
```

#### SD 카드 인식 안됨
```bash
# 다른 SD 카드로 테스트
# Class 10 이상 사용
# 32GB 이하 권장
```

### 10.3 네트워크 문제

#### 이더넷 연결 안됨
```bash
# 링크 상태 확인
ethtool eth0

# DHCP 수동 실행
killall udhcpc
udhcpc -i eth0 -v

# 수동 IP 설정
ifconfig eth0 192.168.1.100 netmask 255.255.255.0 up
route add default gw 192.168.1.1
```

---

## 11. 체크리스트

### 11.1 설치 전 체크리스트

- [ ] VirtualBox 설치 완료
- [ ] Ubuntu 22.04.5 ISO 다운로드
- [ ] 충분한 디스크 공간 (200GB+)
- [ ] 충분한 RAM (16GB+)
- [ ] petalinux-v2022.2-10141622-installer.run 다운로드
- [ ] design_top_wrapper.xsa 준비
- [ ] 공유 폴더 설정 완료

### 11.2 빌드 전 체크리스트

- [ ] PetaLinux 환경 활성화 (`source settings.sh`)
- [ ] 모든 필수 패키지 설치 완료
- [ ] XSA 파일 복사 완료
- [ ] 충분한 빌드 시간 확보 (1-3시간)
- [ ] 안정적인 인터넷 연결

### 11.3 SD 카드 굽기 전 체크리스트

- [ ] WIC 이미지 생성 완료
- [ ] balenaEtcher 설치
- [ ] SD 카드 준비 (4GB+, Class 10+)
- [ ] SD 카드 리더기 연결
- [ ] 올바른 드라이브 선택 확인

### 11.4 부팅 전 체크리스트

- [ ] JP5 점퍼 SD 모드로 설정
- [ ] SD 카드 삽입
- [ ] UART 케이블 연결
- [ ] FTDI 드라이버 설치
- [ ] 시리얼 콘솔 설정 (115200 8N1)
- [ ] 전원 준비

---

## 12. 빌드 출력 분석

### 12.1 정상 빌드 출력

```
[INFO] Sourcing buildtools
[INFO] Building project
[INFO] Sourcing build environment
[INFO] Generating workspace directory
INFO: bitbake petalinux-image-minimal
NOTE: Started PRServer
WARNING: Host distribution "ubuntu-22.04" has not been validated
WARNING: Your host glibc version (2.35) is newer than that in uninative (2.34)
Loading cache: 100%
Parsing recipes: 100%
Parsing of 4461 .bb files complete
NOTE: Resolving any missing task queue dependencies
Initialising tasks: 100%
Checking sstate mirror object availability: 100%
Sstate summary: Wanted 1945 Local 0 Network 1328 Missed 617 Current 0
NOTE: Executing Tasks
NOTE: Tasks Summary: Attempted 5162 tasks of which 1350 didn't need to be rerun and all succeeded.
Summary: There were 2 WARNING messages shown.
INFO: Failed to copy built images to tftp dir: /tftpboot
[INFO] Successfully built project
```

### 12.2 빌드 통계

**Task 통계:**
- 총 시도: 5162 tasks
- 재실행 불필요: 1350 tasks
- 모두 성공: 5162 tasks

**Sstate 캐시:**
- 필요: 1945
- 로컬: 0
- 네트워크: 1328 (68% match)
- 누락: 617

**Warning:**
- Ubuntu 22.04 미검증 (무시 가능)
- glibc 버전 불일치 (자동 처리됨)

---

## 13. 고급 활용

### 13.1 커스텀 Device Tree 수정

```bash
cd ~/projects/myproject/project-spec/meta-user/

# Device Tree 파일 생성
mkdir -p recipes-bsp/device-tree/files
vi recipes-bsp/device-tree/files/system-user.dtsi
```

**예제 - GPIO LED 추가:**
```dts
/include/ "system-conf.dtsi"
/ {
    gpio-leds {
        compatible = "gpio-leds";
        led0 {
            label = "led0";
            gpios = <&gpio0 7 0>;
            default-state = "off";
        };
    };
};
```

**재빌드:**
```bash
petalinux-build -c device-tree -x cleansstate
petalinux-build
```

### 13.2 커스텀 애플리케이션 추가

```bash
cd ~/projects/myproject

# 애플리케이션 생성
petalinux-create -t apps --name myapp --enable

# 소스 편집
vi project-spec/meta-user/recipes-apps/myapp/files/myapp.c
```

**간단한 Hello World:**
```c
#include <stdio.h>

int main(void) {
    printf("Hello from Zybo Z7-20!\n");
    return 0;
}
```

**빌드:**
```bash
petalinux-build -c myapp
petalinux-build
```

### 13.3 성능 최적화

```bash
# ~/.bashrc에 추가
export BB_NUMBER_THREADS="8"
export PARALLEL_MAKE="-j 8"

# 또는 프로젝트별 설정
vi ~/projects/myproject/project-spec/meta-user/conf/petalinuxbsp.conf

# 추가:
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"
```

---

## 14. 백업 및 복구

### 14.1 프로젝트 백업

```bash
# 전체 프로젝트 백업
cd ~/projects
tar czf myproject_backup_$(date +%Y%m%d).tar.gz myproject/

# Windows로 복사
cp myproject_backup_*.tar.gz /media/sf_SharedFolder/
```

### 14.2 이미지 백업

```bash
cd ~/projects/myproject/images/linux/

# 부트 파일 백업
mkdir -p ~/backups/zybo_boot_$(date +%Y%m%d)
cp BOOT.BIN image.ub boot.scr rootfs.tar.gz \
    ~/backups/zybo_boot_$(date +%Y%m%d)/

# WIC 이미지 백업
cp petalinux-sdimage.wic ~/backups/
```

### 14.3 복구

```bash
# 프로젝트 복구
cd ~/projects
tar xzf myproject_backup_YYYYMMDD.tar.gz

# 환경 설정
cd myproject
source ~/petalinux/2022.2/settings.sh

# 필요시 재빌드
petalinux-build
```

---

## 15. 자주 사용하는 명령어

### 15.1 PetaLinux 명령어

```bash
# 환경 설정
source ~/petalinux/2022.2/settings.sh

# 프로젝트 생성
petalinux-create -t project -n <이름> --template zynq

# 하드웨어 가져오기
petalinux-config --get-hw-description=<XSA 경로>

# 설정
petalinux-config                  # 시스템 설정
petalinux-config -c kernel       # 커널 설정
petalinux-config -c rootfs       # rootfs 설정
petalinux-config -c u-boot       # U-Boot 설정

# 빌드
petalinux-build                   # 전체 빌드
petalinux-build -c <컴포넌트>    # 특정 컴포넌트
petalinux-build -x clean          # 클린
petalinux-build -x mrproper       # 완전 클린

# 패키징
petalinux-package --boot          # BOOT.BIN 생성
petalinux-package --wic           # WIC 이미지 생성

# 부팅
petalinux-boot --qemu --kernel    # QEMU 에뮬레이션
```

### 15.2 Zybo Z7-20 시스템 명령어

```bash
# 시스템 정보
uname -a
cat /etc/os-release
cat /proc/cpuinfo

# 네트워크
ifconfig
ip addr
route -n
ping <IP>

# GPIO 제어
echo <번호> > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio<번호>/direction
echo 1 > /sys/class/gpio/gpio<번호>/value

# 커널 모듈
lsmod
modprobe <모듈>
dmesg
```

---

## 16. 참고 자료

### 16.1 공식 문서

- **AMD/Xilinx PetaLinux**: https://docs.amd.com/
- **Zybo Z7 Reference**: https://digilent.com/reference/programmable-logic/zybo-z7/
- **Zynq-7000 TRM**: https://docs.amd.com/v/u/en-US/ug585-zynq-7000-trm

### 16.2 커뮤니티

- **Xilinx Forums**: https://support.xilinx.com/
- **Digilent Forums**: https://forum.digilent.com/
- **Stack Overflow**: Tag [petalinux], [zynq]

---

## 17. 최종 요약

### 전체 프로세스

```
1. VirtualBox + Ubuntu 22.04.5 설치
   ↓
2. 필수 패키지 설치
   ↓
3. PetaLinux 2022.2 설치
   ↓
4. Zybo Z7-20 프로젝트 생성
   ↓
5. XSA 하드웨어 설정
   ↓
6. 시스템/Rootfs 설정
   ↓
7. PetaLinux 빌드 (1-3시간)
   ↓
8. BOOT.BIN 생성
   ↓
9. WIC SD 이미지 생성
   ↓
10. balenaEtcher로 SD 카드 굽기
   ↓
11. Zybo Z7-20 부팅
   ↓
12. 로그인 (root/root)
```

### 핵심 명령어

```bash
# PetaLinux 환경
source ~/petalinux/2022.2/settings.sh

# 프로젝트 생성
petalinux-create -t project --template zynq -n myproject
cd myproject

# 하드웨어 설정
petalinux-config --get-hw-description=~/projects/

# 빌드
petalinux-build

# BOOT.BIN 생성
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf --force

# WIC 이미지 생성
petalinux-package --wic --bootfiles "BOOT.BIN image.ub boot.scr"

# Windows로 복사
cp images/linux/petalinux-sdimage.wic /media/sf_SharedFolder/
```

### 예상 소요 시간

| 작업 | 소요 시간 |
|------|-----------|
| VirtualBox + Ubuntu 설치 | 30-60분 |
| 패키지 설치 | 10-20분 |
| PetaLinux 설치 | 10-30분 |
| 프로젝트 생성 및 설정 | 10-20분 |
| 빌드 (첫 빌드) | 1-3시간 |
| 이미지 생성 및 SD 카드 | 10-20분 |
| **총 소요 시간** | **약 2-5시간** |

### Warning 요약

| Warning | 영향 | 조치 |
|---------|------|------|
| Ubuntu 22.04 미검증 | 없음 | 무시 |
| glibc 버전 불일치 | 없음 | 자동 처리 |
| TFTP 복사 실패 | 없음 | 선택적 |

---

## 18. 추가 리소스

### 18.1 유용한 링크

**PetaLinux 도구:**
- PetaLinux Tools Documentation: UG1144
- Embedded Design Tutorial: UG1165
- PetaLinux Command Line Reference: UG1157

**Zybo Z7-20 자료:**
- Schematic: Digilent 공식 사이트
- Constraint File (XDC): Digilent GitHub
- Example Projects: Digilent Reference

**Yocto/OpenEmbedded:**
- Yocto Project: https://www.yoctoproject.org/
- OpenEmbedded: https://www.openembedded.org/

### 18.2 지원 연락처

**Digilent 지원:**
- 이메일: support@digilentinc.com
- 포럼: https://forum.digilent.com/

**AMD/Xilinx 지원:**
- 지원 포털: https://support.amd.com/
- 커뮤니티: https://support.xilinx.com/

---

## 19. FAQ (자주 묻는 질문)

### Q1: 빌드에 얼마나 시간이 걸리나요?
**A:** 첫 빌드는 1-3시간, 이후 증분 빌드는 10-30분 소요됩니다.

### Q2: Warning 메시지가 나와도 괜찮나요?
**A:** 네, Ubuntu 22.04와 glibc 관련 Warning은 무시해도 됩니다. 빌드는 정상적으로 완료됩니다.

### Q3: TFTP 서버가 꼭 필요한가요?
**A:** 아니요, SD 카드 부팅만 사용한다면 필요 없습니다.

### Q4: SD 카드 크기는 얼마나 필요한가요?
**A:** 최소 4GB, 권장 8GB 이상입니다.

### Q5: 다른 Ubuntu 버전을 사용할 수 있나요?
**A:** 공식 지원은 Ubuntu 20.04지만, 22.04에서도 정상 작동합니다.

### Q6: 빌드 실패 시 어떻게 하나요?
**A:** 로그 확인 (`build/build.log`), 클린 빌드 시도 (`petalinux-build -x clean`), 디스크 공간 및 메모리 확인

### Q7: rootfs를 커스터마이징할 수 있나요?
**A:** 네, `petalinux-config -c rootfs`로 패키지 추가/제거 가능합니다.

### Q8: QEMU로 테스트할 수 있나요?
**A:** 네, `petalinux-boot --qemu --kernel` 명령어로 에뮬레이션 가능합니다.

---

## 20. 문서 정보

**작성일:** 2025년 9월 29일  
**버전:** 1.0  
**대상 하드웨어:** Digilent Zybo Z7-20 (Zynq-7020)  
**PetaLinux 버전:** 2022.2  
**호스트 OS:** Ubuntu 22.04.5 LTS (VirtualBox)  

**변경 이력:**
- v1.0 (2025-09-29): 초기 작성, Warning 해결 포함

---

## 부록 A: 전체 명령어 스크립트

### A.1 Ubuntu 준비 스크립트

```bash
#!/bin/bash
# Ubuntu 22.04 준비 스크립트

# 시스템 업데이트
sudo apt update
sudo apt upgrade -y

# 32비트 지원 추가
sudo dpkg --add-architecture i386
sudo apt update

# 필수 패키지 설치
sudo apt install -y \
    build-essential gcc-multilib g++-multilib gawk wget git \
    diffstat unzip texinfo chrpath socat cpio python3 \
    python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 libegl1-mesa \
    libsdl1.2-dev pylint xterm rsync curl libncurses5-dev \
    libncursesw5-dev libssl-dev flex bison libselinux1 \
    gnupg zlib1g-dev libtool autoconf automake net-tools \
    screen pax gzip vim iproute2 locales libncurses5 libtinfo5

# 32비트 라이브러리
sudo apt install -y \
    libncurses5:i386 libc6:i386 libstdc++6:i386 \
    lib32z1 zlib1g:i386

# Locale 설정
sudo locale-gen en_US.UTF-8

# Dash를 Bash로 변경
echo "dash dash/sh boolean false" | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive dash

echo "Ubuntu 준비 완료!"
```

### A.2 PetaLinux 빌드 스크립트

```bash
#!/bin/bash
# PetaLinux 빌드 자동화 스크립트

# 환경 설정
source ~/petalinux/2022.2/settings.sh

# 프로젝트 디렉토리
PROJECT_DIR=~/projects/myproject

cd $PROJECT_DIR

# 빌드
echo "빌드 시작..."
petalinux-build

# BOOT.BIN 생성
echo "BOOT.BIN 생성..."
petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

# WIC 이미지 생성
echo "WIC 이미지 생성..."
petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/

# 완료
echo "빌드 완료!"
echo "이미지 위치: $PROJECT_DIR/images/linux/petalinux-sdimage.wic"
```

---

이 가이드를 따라하시면 Digilent Zybo Z7-20 보드용 PetaLinux 시스템을 성공적으로 구축할 수 있습니다. 빌드 과정에서 발생하는 Warning은 정상적이며 무시해도 됩니다. 

문제가 발생하면 트러블슈팅 섹션을 참고하시고, 추가 도움이 필요하면 Digilent 또는 Xilinx 포럼을 이용하시기 바랍니다.

**성공적인 개발을 기원합니다! 🚀**


---

```
s=y
# CONFIG_allow-empty-password=y
# CONFIG_empty-root-password=y
# CONFIG_serial-autologin-root=y
```
---

1. GCC 컴파일러 찾기
검색 결과 gcc-sanitizers만 나왔다면, 실제 gcc 패키지는 다른 위치에 있거나 다른 이름일 수 있습니다.

다시 검색해보세요:
```
/packagegroup-core-buildessential
```
또는 직접 메뉴에서:
```
Filesystem Packages → 
  packagegroup → 
    packagegroup-core-buildessential
```   
이 패키지를 활성화하면 gcc, g++, make가 모두 포함됩니다.
```
Filesystem Packages → devel → 
  [*] packagegroup-core-buildessential
```

3. Image Features 옵션들이 안 보이는 이유
PetaLinux 버전에 따라 이런 옵션들이 다른 방식으로 관리됩니다.
해결 방법: 설정 파일 직접 수정
```bash
cd ~/projects/myproject
vi project-spec/configs/rootfs_config
```
다음 라인들을 추가:
```
CONFIG_debug-tweaks=y
CONFIG_empty-root-password=y
CONFIG_auto-login=y
```

그리고 project-spec/meta-user/conf/petalinuxbsp.conf 파일도 확인:

```bash
vi project-spec/meta-user/conf/petalinuxbsp.conf
```
다음 라인 추가:
```
EXTRA_IMAGE_FEATURES += "debug-tweaks empty-root-password allow-empty-password"
EXTRA_IMAGE_FEATURES += "serial-autologin-root"
```
또는 local.conf 수정:

```bash
vi project-spec/meta-user/conf/local.conf
```
추가:
```
EXTRA_IMAGE_FEATURES += "debug-tweaks"
EXTRA_IMAGE_FEATURES += "empty-root-password"
EXTRA_IMAGE_FEATURES += "allow-empty-password"
```

---


---
아래 부분 문제 있음.
### 4.7 Root 로그인 설정 (중요!)

**기본 상태의 문제:**
```
myproject login: root
Password: (무엇을 입력해도)
Login incorrect
```

**원인:**
- PetaLinux는 보안상 빈 패스워드 로그인 차단
- 하지만 root 패스워드가 설정되지 않음
- 결과: 로그인 불가능

#### 4.7.1 해결 방법 - Rootfs 설정 (필수!)

```bash
cd ~/projects/myproject
petalinux-config -c rootfs
```

**⭐ 반드시 다음 항목들을 활성화:**

```
Image Features --->
    [*] debug-tweaks                  ← 필수!
    [*] allow-empty-password          ← 필수!
    [*] allow-root-login              ← 필수!
    [*] empty-root-password           ← 필수!
    [*] serial-autologin-root         ← 권장 (자동 로그인)
```

**추가 패키지 (선택사항):**

```
Filesystem Packages --->
    admin --->
        [*] sudo
    console/utils --->
        [*] vim
        [*] nano
    network --->
        [*] openssh
        [*] openssh-sshd
```

저장: `Save` → `Exit`

#### 4.7.2 설정 확인

```bash
# 설정이 제대로 되었는지 확인
cat ~/projects/myproject/project-spec/configs/rootfs_config | grep -i "debug\|empty\|autologin"

# 다음 항목들이 있어야 함:
# CONFIG_debug-tweak
```

메뉴 이동

Root Filesystem Settings → Image Features 로 들어가서
package-management 체크 (패키지 설치 필요 시).

다시 Root Filesystem Settings → "Root Password" 항목 선택.

비밀번호 입력

원하는 root 비밀번호를 입력하고 저장합니다.

---

====================================================================================

# PetaLinux 2022.2로 생성된 SD 카드의 파티션 구조와 확장 방법

## 파티션 구조 분석
 * PetaLinux가 생성하는 기본 SD 카드 이미지는 다음과 같이 구성됩니다:

## 1. BOOT 파티션 (FAT32, ~2GB)
  * BOOT.BIN: FSBL + U-Boot + PMU firmware + bitstream
  * image.ub: Kernel + Device Tree + RootFS (FIT 이미지)
  * boot.scr: U-Boot 스크립트

## 2. rootfs 파티션 (ext4, ~4GB)
  * 실제 Linux 루트 파일시스템
  * 기본 크기는 PetaLinux 설정의 IMAGE_ROOTFS_EXTRA_SPACE에 의해 결정

## 3. 미할당 영역 (~23.72GB)
  * SD 카드의 나머지 공간은 기본적으로 할당되지 않음

  * 이 구조는 project-spec/meta-user/recipes-core/images/*.bb 파일과 WKS (Wic Kickstart) 파일에서 정의됩니다.

## 사용 가능한 영역 확장 방법
### 방법 1: PetaLinux 빌드 시 rootfs 크기 확장 (권장)
  * project-spec/meta-user/conf/petalinuxbsb.conf 파일에 추가:
```bash
# rootfs 파티션 크기를 28GB로 확장
IMAGE_ROOTFS_EXTRA_SPACE = "28000000"

# 또는 비율로 지정
IMAGE_ROOTFS_EXTRA_SPACE_append = " + 25000000"
```

   * 그 후 이미지 재빌드:
```bash
petalinux-build
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --force
petalinux-package --wic --images-dir images/linux/ --bootfiles "BOOT.BIN boot.scr image.ub"
```

### 방법 2: 부팅 후 수동으로 파티션 확장
   * SD 카드를 이미 만든 경우, ZyboZ7에서 부팅 후 실행:

```bash
# 1. 파티션 확장 (rootfs가 /dev/mmcblk0p2라고 가정)
sudo growpart /dev/mmcblk0 2

# 2. 파일시스템 리사이즈
sudo resize2fs /dev/mmcblk0p2

# 3. 확인
df -h
```

   * 필요한 패키지 추가 (PetaLinux 빌드 시):
```bash
petalinux-config -c rootfs
```
   → Filesystem Packages → base → cloud-utils 및 e2fsprogs-resize2fs 선택

### 방법 3: WKS 파일 수정 (고급)
   * project-spec/meta-user/wic/ 디렉토리에 커스텀 WKS 파일 생성:
```wks
# sdimage-custom.wks
part /boot --source bootimg-partition --ondisk mmcblk0 --fstype=vfat --label boot --active --align 4096 --size 200M
part / --source rootfs --ondisk mmcblk0 --fstype=ext4 --label root --align 4096 --size 28G
```
   * local.conf에 추가:
```bash
WKS_FILE = "sdimage-custom.wks"
```

### 방법 4: 추가 파티션 생성
   * 부팅 후 미할당 영역에 새 파티션 생성:
```bash
# fdisk로 새 파티션 생성
sudo fdisk /dev/mmcblk0
# n (새 파티션), p (primary), 3 (파티션 번호), 기본값, 기본값
# w (저장)

# 파일시스템 포맷
sudo mkfs.ext4 /dev/mmcblk0p3

# 마운트
sudo mkdir /data
sudo mount /dev/mmcblk0p3 /data

# 부팅 시 자동 마운트 (/etc/fstab에 추가)
echo "/dev/mmcblk0p3  /data  ext4  defaults  0  2" | sudo tee -a /etc/fstab
```

## 권장 접근법
   * 개발 단계: 방법 2 (부팅 후 수동 확장) - 빠르고 간단
   * 프로덕션: 방법 1 (PetaLinux 설정) - 재현 가능하고 자동화됨
   * 데이터 저장용 별도 공간이 필요하면 방법 4로 추가 파티션을 생성하는 것이 파일시스템 관리 측면에서 더 깔끔합니다.재시도Claude는 실수를 할 수 있습니다. 응답을 반드시 다시 확인해 주세요.

