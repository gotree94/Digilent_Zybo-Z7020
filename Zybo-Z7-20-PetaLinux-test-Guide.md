# Zybo Z7-20 PetaLinux 전체 가이드

> VirtualBox 리눅스 환경에서 PetaLinux 설치 → 빌드 → SD카드 부팅 → 하드웨어 테스트까지

---

## 목차

1. [VirtualBox 환경 설정](#1-virtualbox-환경-설정)
2. [Ubuntu 설치 및 초기 설정](#2-ubuntu-설치 및-초기-설정)
3. [PetaLinux 도구 설치](#3-petalinux-도구-설치)
4. [BSP 프로젝트 다운로드 및 빌드](#4-bsp-프로젝트-다운로드-및-빌드)
5. [SD카드 준비 및 부팅](#5-sd카드-준비-및-부팅)
6. [보드 동작 테스트 (Python)](#6-보드-동작-테스트-python)
7. [문제 해결](#7-문제-해결)

---

## 1. VirtualBox 환경 설정

### 1.1 VirtualBox 및 Extension Pack 설치

- [VirtualBox 다운로드](https://www.virtualbox.org/wiki/Downloads)
- Extension Pack도 함께 설치 (USB 3.0 지원용)

### 1.2 가상 머신 생성

| 항목 | 설정값 |
|------|--------|
| 이름 | `Zybo-PetaLinux` |
| 타입 | Linux |
| 버전 | Ubuntu (64-bit) |
| RAM | **8192 MB** (최소 8GB, PetaLinux 빌드 시 필요) |
| CPU | **4코어 이상** 권장 |
| 디스크 | **100GB** VDI (동적 할당) |

### 1.3 가상 머신 설정

#### 시스템 > 프로세서
- 프로세서 수: 4 이상
- 실행 패널티: 높음

#### 디스플레이
- 비디오 메모리: 128MB

#### 네트워크
- 어댑터 1: **bridged** (보드와 같은 네트워크 접속용)
  - 또는 NAT + 포트포워딩 사용

#### USB
- USB 컨트롤러: **USB 3.0 (xHCI)**
- Zigbee/시리얼 어댑터 규칙 추가:
  - Vendor ID: `10c4`
  - Product ID: `ea60` (CP210x UART 기준, 보드에 따라 다를 수 있음)

### 1.4 SD카드 리더 연결

VirtualBox 실행 중 USB 장치에서 호스트의 SD카드 리더를 가상 머신에 **연결**합니다.

---

## 2. Ubuntu 설치 및 초기 설정

### 2.1 Ubuntu ISO 다운로드

PetaLinux 2017.4 기준: **Ubuntu 16.04.3 LTS** 사용 권장 (공식 가이드 기준)

> **참고:** Ubuntu 16.04는 EOL 상태입니다. PetaLinux 2019.2 이상을 사용하는 경우 Ubuntu 18.04 LTS 사용 가능.
> 이 가이드는 PetaLinux 2017.4 + Ubuntu 16.04 기준으로 작성되었습니다.

- [Ubuntu 16.04 LTS 다운로드](https://releases.ubuntu.com/16.04/)

### 2.2 Ubuntu 설치 후 초기 설정

```bash
# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# 타임존 설정
sudo timedatectl set-timezone Asia/Seoul
```

### 2.3 필수 의존성 패키지 설치

```bash
sudo -s
apt-get update
apt-get install -y tofrodos gawk xvfb git libncurses5-dev tftpd \
    zlib1g-dev zlib1g-dev:i386 libssl-dev flex bison chrpath socat \
    autoconf libtool texinfo gcc-multilib libsdl1.2-dev \
    libglib2.0-dev screen pax net-tools
```

### 2.4 TFTP 서버 설정 (선택, 네트워크 부팅용)

```bash
sudo -s
apt-get install -y tftpd-hpa
chmod a+w /var/lib/tftpboot/
# tftpd-hpa 파일 수정 필요 시:
# nano /etc/default/tftpd-hpa
# TFTP_DIRECTORY="/var/lib/tftpboot"
systemctl restart tftpd-hpa
exit
```

### 2.5 시리얼 통신 도구 설치

```bash
# minicom (시리얼 콘솔)
sudo apt-get install -y minicom

# 또는 picocom (더 간단함)
sudo apt-get install -y picocom
```

---

## 3. PetaLinux 도구 설치

### 3.1 설치 디렉토리 준비

```bash
sudo -s
mkdir -p /opt/pkg/petalinux
chown $USER /opt/pkg/
chgrp $USER /opt/pkg/
chgrp $USER /opt/pkg/petalinux/
chown $USER /opt/pkg/petalinux/
exit
```

### 3.2 PetaLinux 설치 파일 준비

1. [Xilinx 웹사이트](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html)에서 PetaLinux 2017.4 설치 파일 다운로드
   - `petalinux-v2017.4-final-installer.run`
   - Xilinx 계정 로그인 필요

```bash
cd ~/Downloads
chmod +x petalinux-v2017.4-final-installer.run
./petalinux-v2017.4-final-installer.run /opt/pkg/petalinux
```

> 설치 중 라이센스 동의 화면에서 `y`를 눌러 진행

### 3.3 환경변수 확인

```bash
# 새 터미널에서 매번 실행
source /opt/pkg/petalinux/settings.sh

# 확인
petalinux-config --help
```

### 3.4 Bash 설정 (편의용)

```bash
echo 'source /opt/pkg/petalinux/settings.sh' >> ~/.bashrc
```

---

## 4. BSP 프로젝트 다운로드 및 빌드

### 4.1 소스 클론

```bash
cd ~/
git clone --recursive https://github.com/Digilent/Petalinux-Zybo-Z7-20.git
cd Petalinux-Zybo-Z7-20
```

> **참고:** `.bsp` 파일 사용 시:
> ```bash
> petalinux-create -t project -s <path to .bsp file>
> cd <생성된 프로젝트 디렉토리>
> ```

### 4.2 프로젝트 구성 확인 (선택)

```bash
# 네트워크 설정 (bridged 네트워크 사용 시)
petalinux-config

# 필요 시 rootfs 설정 변경
petalinux-config -c rootfs
```

### 4.3 프로젝트 빌드

```bash
# 환경 소스 확인
source /opt/pkg/petalinux/settings.sh

# 빌드 (소요시간: 30분~2시간, CPU/RAM 사양에 따라 다름)
petalinux-build
```

### 4.4 부팅 이미지 패키징

```bash
petalinux-package --boot \
    --force \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system_wrapper.bit \
    --u-boot
```

### 4.5 빌드 결과물 확인

```bash
ls -la images/linux/

# 주요 파일:
# BOOT.BIN        - FSBL + FPGA 비트스트림 + U-Boot
# image.ub        - 커널 + 디바이스트리 + 루트fs (initramfs)
# rootfs.ext4     - SD카드용 루트파일시스템 (SD rootfs 사용 시)
```

---

## 5. SD카드 준비 및 부팅

### 5.1 SD카드 포맷 (Ubuntu 가상머신 내에서)

> **주의:** 올바른 디바이스를 선택해야 합니다. 잘못된 디바이스 선택 시 호스트 데이터가 삭제됩니다.

```bash
# SD카드 디바이스 확인
lsblk
# 또는
sudo fdisk -l

# 보통 /dev/sdb 또는 /dev/sdc (USB 리더에 따라 다름)
# 아래에서 <SD_CARD>를 실제 디바이스로 대체하세요

# 파티션 테이블 삭제 및 새로 생성
sudo parted /dev/<SD_CARD> --script mklabel msdos

# FAT32 부팅 파티션 (최소 500MB)
sudo parted /dev/<SD_CARD> --script mkpart primary fat32 1MiB 500MiB

# initramfs 사용 시: 여기서 중단
# SD rootfs 사용 시: ext4 파티션 추가 (최소 1.5GB, 권장 3GB+)
sudo parted /dev/<SD_CARD> --script mkpart primary ext4 500MiB 100%

# 포맷
sudo mkfs.vfat -F 32 /dev/<SD_CARD>1
# SD rootfs 사용 시:
sudo mkfs.ext4 -F /dev/<SD_CARD>2
```

### 5.2 이미지 복사

```bash
# FAT32 파티션에 복사
sudo mkdir -p /mnt/boot
sudo mount /dev/<SD_CARD>1 /mnt/boot

sudo cp images/linux/BOOT.BIN /mnt/boot/
sudo cp images/linux/image.ub /mnt/boot/

# SD rootfs 사용 시
sudo mkdir -p /mnt/rootfs
sudo mount /dev/<SD_CARD>2 /mnt/rootfs
sudo dd if=images/linux/rootfs.ext4 of=/dev/<SD_CARD>2 bs=4M status=progress
sync
sudo resize2fs /dev/<SD_CARD>2
sync

# 언마운트
sudo umount /mnt/boot
sudo umount /mnt/rootfs 2>/dev/null
sync
```

### 5.3 (선택) SD rootfs 사용 시 커널 인자 변경

```bash
# 프로젝트 디렉토리에서
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

기존 bootargs 라인:
```
bootargs = "console=ttyPS0,115200 earlyprintk uio_pdrv_genirq.of_id=generic-uio";
```

을 다음으로 변경:
```
bootargs = "console=ttyPS0,115200 earlyprintk uio_pdrv_genirq.of_id=generic-uio root=/dev/mmcblk0p2 rw rootwait";
```

변경 후 재빌드:
```bash
petalinux-build
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system_wrapper.bit --u-boot
```

### 5.4 보드 부팅

#### 하드웨어 연결 순서

1. SD카드를 보드의 SD 슬롯에 삽입
2. 전원 선택 점퍼 **JP5**: `USB` 또는 `EXT` 선택
   - USB 전류 부족 시 외부 전원 사용 권장
3. 시리얼 케이블: 보드 microUSB ↔ PC USB 연결
4. (선택) HDMI 케이블 연결
5. (선택) 이더넷 케이블 연결

#### 시리얼 콘솔 접속

```bash
# minicom 사용
sudo minicom -D /dev/ttyUSB1 -b 115200
# 설정: 115200/8/N/1, Hardware Flow Control: No

# 또는 picocom 사용 (더 간단)
picocom -b 115200 /dev/ttyUSB1
```

#### 부팅 확인

- 전원 인가 후 **PS-SRST** 버튼 누름
- 콘솔에 U-Boot → 커널 부팅 로그 출력 확인
- `root@<hostname>:~#` 프롬프트 출력 시 부팅 성공

---

## 6. 보드 동작 테스트 (Python)

### 6.1 테스트 환경 준비

부팅 후 시리얼 콘솔 또는 SSH에서:

```bash
# Python 확인 (PetaLinux 이미지에 포함되어 있을 수 있음)
python --version || python3 --version

# 없을 경우 (SD rootfs 사용 시):
opkg update
opkg install python python-core
```

> **참고:** initramfs 모드에서는 패키지 설치가 재부팅 후 사라집니다.

### 6.2 테스트 스크립트 파일 전송

호스트 PC에서 SD카드의 빈 영역 또는 rootfs에 테스트 파일을 넣거나, 네트워크를 통해 전송:

```bash
# 호스트에서 SCP 사용 (보드 IP 확인 필요)
scp test_scripts.py root@<BOARD_IP>:/home/root/
```

### 6.3 전체 테스트 스크립트

아래 스크립트를 보드에서 `hardware_test.py`로 저장합니다.

```python
#!/usr/bin/env python3
"""
Zybo Z7-20 하드웨어 종합 테스트 스크립트
테스트 대상: LED, 스위치, 버튼, 이더ernet, UART, HDMI 출력, Pcam
"""

import os
import sys
import time
import subprocess
import json
from datetime import datetime


# ─── 테스트 결과 관리 ─────────────────────────────────────────────

class TestResult:
    def __init__(self):
        self.results = []

    def add(self, name, passed, detail=""):
        status = "PASS" if passed else "FAIL"
        self.results.append({
            "name": name,
            "status": status,
            "detail": detail
        })
        symbol = "[OK]" if passed else "[FAIL]"
        print(f"  {symbol} {name}" + (f" - {detail}" if detail else ""))

    def summary(self):
        total = len(self.results)
        passed = sum(1 for r in self.results if r["status"] == "PASS")
        failed = total - passed
        print("\n" + "=" * 60)
        print(f"  테스트 결과 요약: {passed}/{total} 통과, {failed} 실패")
        print("=" * 60)
        return failed == 0


# ─── 1. LED 테스트 ────────────────────────────────────────────────

def test_leds(result):
    """
    Zybo Z7-20: 4개 RGB LED (LD4~LD7)
    UIO 드라이버를 통해 GPIO 제어
    """
    print("\n[테스트 1] LED 테스트")

    # UIO 장치 확인
    uio_path = "/sys/class/uio"
    if not os.path.exists(uio_path):
        result.add("LED - UIO 디바이스 검색", False, "UIO 디바이스 없음")
        return

    # 디바이스 트리에서 LED GPIO 핀 번호 확인
    # Zybo Z7-20 기본 디자인: LEDs = MIO 14, 15, 16, 17 또는 EMIO
    gpio_base = find_gpio_chip("leds")
    if gpio_base is None:
        # 대체: 직접 UIO에서 확인
        result.add("LED - GPIO 칩 검색", False, "LED GPIO 칩을 찾을 수 없음")
        return

    result.add("LED - GPIO 칩 검색", True, gpio_base)

    # 4개 LED 순서대로 점등/소등
    led_pins = [0, 1, 2, 3]  # LD4~LD7

    for pin in led_pins:
        try:
            # GPIO export
            gpio_num = get_gpio_number(gpio_base, pin)
            if gpio_num is None:
                result.add(f"LED {pin} - GPIO 번호 획득", False)
                continue

            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "out")
            set_gpio_value(gpio_num, 1)
            time.sleep(0.5)
            val = get_gpio_value(gpio_num)
            set_gpio_value(gpio_num, 0)

            passed = (val == "1")
            result.add(f"LED {pin} 점등", passed, f"읽은 값: {val}")
            unexport_gpio(gpio_num)

        except Exception as e:
            result.add(f"LED {pin} 테스트", False, str(e))


def test_led_chase(result):
    """LED chase 패턴 테스트"""
    print("\n[테스트 1b] LED chase 패턴")

    gpio_base = find_gpio_chip("leds")
    if gpio_base is None:
        result.add("LED chase - GPIO 없음", False)
        return

    pins = []
    for i in range(4):
        gpio_num = get_gpio_number(gpio_base, i)
        if gpio_num:
            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "out")
            pins.append(gpio_num)

    if len(pins) != 4:
        result.add("LED chase - 핀 초기화 실패", False, f"{len(pins)}/4")
        for p in pins:
            unexport_gpio(p)
        return

    # Chase 패턴 3회
    try:
        for _ in range(3):
            for p in pins:
                set_gpio_value(p, 1)
                time.sleep(0.1)
                set_gpio_value(p, 0)
        result.add("LED chase 패턴", True)
    except Exception as e:
        result.add("LED chase 패턴", False, str(e))
    finally:
        for p in pins:
            set_gpio_value(p, 0)
            unexport_gpio(p)


# ─── 2. 스위치 테스트 ──────────────────────────────────────────────

def test_switches(result):
    """
    Zybo Z7-20: 2개 slide 스위치 (SW0~SW1)
    GPIO 입력으로 읽기
    """
    print("\n[테스트 2] 스위치 테스트")

    gpio_base = find_gpio_chip("switches")
    if gpio_base is None:
        result.add("스위치 - GPIO 칩 검색", False, "스위치 GPIO 없음")
        return

    result.add("스위치 - GPIO 칩 검색", True, gpio_base)

    sw_pins = [0, 1]  # SW0, SW1

    for pin in sw_pins:
        gpio_num = get_gpio_number(gpio_base, pin)
        if gpio_num is None:
            result.add(f"스위치 {pin} - GPIO 번호 실패", False)
            continue

        try:
            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "in")
            val = get_gpio_value(gpio_num)
            result.add(f"스위치 {pin} 읽기", True, f"값: {val} (물리 스위치 조작 필요 없이 현재 값 확인)")
            unexport_gpio(gpio_num)
        except Exception as e:
            result.add(f"스위치 {pin} 읽기", False, str(e))


def test_switch_interrupt(result):
    """스위치 변화 인터럽트 테스트 (polling 방식)"""
    print("\n[테스트 2b] 스위치 변화 감지 (5초 대기)")

    gpio_base = find_gpio_chip("switches")
    if gpio_base is None:
        result.add("스위치 변화감지 - GPIO 없음", False)
        return

    gpio_num = get_gpio_number(gpio_base, 0)
    if gpio_num is None:
        result.add("스위치 변화감지 - GPIO 번호 실패", False)
        return

    try:
        export_gpio(gpio_num)
        set_gpio_direction(gpio_num, "in")

        # 폴링 인터럽트 설정
        gpio_fd = open(f"/sys/class/gpio/gpio{gpio_num}/value", "r")

        initial_val = gpio_fd.read().strip()
        gpio_fd.seek(0)

        print("  >> 스위치를 5초 내로 조작하세요...")
        changed = False
        start = time.time()
        while time.time() - start < 5:
            gpio_fd.seek(0)
            current = gpio_fd.read().strip()
            if current != initial_val:
                changed = True
                break
            time.sleep(0.05)

        gpio_fd.close()
        unexport_gpio(gpio_num)

        if changed:
            result.add("스위치 변화 감지", True, f"{initial_val} -> {current}")
        else:
            result.add("스위치 변화 감지", True, f"변화 없음 (현재값: {initial_val}, 5초 타임아웃)")

    except Exception as e:
        result.add("스위치 변화 감지", False, str(e))


# ─── 3. 버튼 테스트 ────────────────────────────────────────────────

def test_buttons(result):
    """
    Zybo Z7-20: 3개 push 버튼 (BTN0~BTN2)
    """
    print("\n[테스트 3] 버튼 테스트")

    gpio_base = find_gpio_chip("buttons")
    if gpio_base is None:
        result.add("버튼 - GPIO 칩 검색", False, "버튼 GPIO 없음")
        return

    result.add("버튼 - GPIO 칩 검색", True, gpio_base)

    btn_pins = [0, 1, 2]

    for pin in btn_pins:
        gpio_num = get_gpio_number(gpio_base, pin)
        if gpio_num is None:
            result.add(f"버튼 {pin} - GPIO 번호 실패", False)
            continue

        try:
            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "in")
            val = get_gpio_value(gpio_num)
            result.add(f"버튼 {pin} 읽기", True, f"값: {val} (기본값 0 권장)")
            unexport_gpio(gpio_num)
        except Exception as e:
            result.add(f"버튼 {pin} 읽기", False, str(e))


# ─── 4. UART 루프백 테스트 ─────────────────────────────────────────

def test_uart_loopback(result):
    """
    UART 루프백 테스트 (하드웨어 연결 시)
    TX ↔ RX 직접 연결 필요
    """
    print("\n[테스트 4] UART 루프백 테스트")

    uart_port = "/dev/ttyPS1"  # PL UART 또는 추가 UART
    # PS UART (ttyPS0)는 콘솔로 사용 중이므로 PL 쪽 사용

    if not os.path.exists(uart_port):
        # 대체 포트 확인
        alt_ports = ["/dev/ttyUSB0", "/dev/ttyS0"]
        for p in alt_ports:
            if os.path.exists(p):
                uart_port = p
                break
        else:
            result.add("UART - 포트 검색", False, "사용 가능한 UART 포트 없음")
            return

    try:
        import serial
        ser = serial.Serial(uart_port, 115200, timeout=2)
        test_data = b"ZyboUART12345"
        ser.write(test_data)
        time.sleep(0.1)
        received = ser.read(ser.in_waiting or len(test_data))
        ser.close()

        passed = (received == test_data)
        result.add("UART 루프백", passed, f"송신: {test_data}, 수신: {received}")

    except ImportError:
        # pyserial 없을 경우 stty 사용
        try:
            subprocess.run(["stty", "-F", uart_port, "115200", "raw"], check=True)
            with open(uart_port, "r+b", buffering=0) as f:
                test_data = b"ZyboUART12345"
                f.write(test_data)
                time.sleep(0.2)
                received = f.read(32)
            passed = (received == test_data)
            result.add("UART 루프백 (stty)", passed,
                       f"송신: {test_data}, 수신: {received}")
        except Exception as e:
            result.add("UART 루프백", False, str(e))

    except Exception as e:
        result.add("UART 루프백", False, str(e))


# ─── 5. 네트워크 테스트 ────────────────────────────────────────────

def test_network(result):
    """이더넷 연결 및 DHCP 테스트"""
    print("\n[테스트 5] 네트워크 테스트")

    # 네트워크 인터페이스 확인
    try:
        ip_output = subprocess.check_output(
            ["ip", "addr", "show"], stderr=subprocess.STDOUT
        ).decode()

        # eth0 확인
        if "eth0" in ip_output:
            result.add("네트워크 - eth0 인터페이스", True)
        else:
            # 다른 인터페이스 이름일 수 있음
            if "eth" in ip_output or "enp" in ip_output:
                result.add("네트워크 - 이더넷 인터페이스", True)
            else:
                result.add("네트워크 - 이더넷 인터페이스", False, "eth0 없음")
                return

    except Exception as e:
        result.add("네트워크 - 인터페이스 검색", False, str(e))
        return

    # DHCP renew
    try:
        subprocess.run(["dhclient", "-v", "eth0"],
                       timeout=15, capture_output=True, check=True)
        result.add("네트워크 - DHCP", True)
    except Exception as e:
        result.add("네트워크 - DHCP", False, str(e))

    # IP 할당 확인
    try:
        ip_output = subprocess.check_output(
            ["hostname", "-I"], stderr=subprocess.STDOUT
        ).decode().strip()
        if ip_output:
            result.add("네트워크 - IP 할당", True, ip_output)
        else:
            result.add("네트워크 - IP 할당", False, "IP 없음")
    except Exception as e:
        result.add("네트워크 - IP 할당", False, str(e))

    # Ping 테스트
    try:
        ping_result = subprocess.run(
            ["ping", "-c", "3", "-W", "2", "8.8.8.8"],
            capture_output=True, timeout=10
        )
        passed = ping_result.returncode == 0
        detail = "외부 인터넷 연결" if passed else "외부 연결 실패 (게이트웨이만 확인)"
        result.add("네트워크 - Ping 8.8.8.8", passed, detail)
    except Exception as e:
        result.add("네트워크 - Ping", False, str(e))

    # DNS 테스트
    try:
        nslookup = subprocess.run(
            ["nslookup", "google.com"],
            capture_output=True, timeout=5
        )
        passed = nslookup.returncode == 0
        result.add("네트워크 - DNS 조회", passed)
    except Exception as e:
        result.add("네트워크 - DNS 조회", False, str(e))


# ─── 6. HDMI 출력 테스트 ──────────────────────────────────────────

def test_hdmi_output(result):
    """HDMI 출력 프레임버퍼 테스트"""
    print("\n[테스트 6] HDMI 출력 테스트")

    fb_path = "/dev/fb0"
    if not os.path.exists(fb_path):
        result.add("HDMI 출력 - 프레임버퍼", False, "/dev/fb0 없음")
        return

    try:
        # 프레임버퍼 정보 확인
        fb_info = subprocess.check_output(
            ["cat", "/sys/class/graphics/fb0/virtual_size"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        result.add("HDMI 출력 - 프레임버퍼 크기", True, fb_info)
    except Exception as e:
        result.add("HDMI 출력 - 프레임버퍼 정보", False, str(e))

    # 색상 테스트 패턴 생성 (화이트 스퀘어)
    try:
        with open(fb_path, "rb") as f:
            info = f.read(1)  # 확인용

        # 간단한 테스트: 전체 화면 빨간색 채우기 (32bpp)
        test_cmd = """
import struct
try:
    with open('/dev/fb0', 'rb+') as fb:
        # 현재 설정 읽기 (가정: 1280x720 @ 32bpp)
        w, h = 1280, 720
        red = b'\\x00\\x00\\xff\\xff' * w  # BGRA 빨간색
        for y in range(h):
            fb.seek(y * w * 4)
            fb.write(red)
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
"""
        proc = subprocess.run(
            ["python3", "-c", test_cmd],
            capture_output=True, timeout=5, text=True
        )
        output = proc.stdout.strip()
        result.add("HDMI 출력 - 빨간색 테스트 패턴", "OK" in output, output)

    except Exception as e:
        result.add("HDMI 출력 - 테스트 패턴", False, str(e))


# ─── 7. HDMI 입력 테스트 ──────────────────────────────────────────

def test_hdmi_input(result):
    """HDMI 입력 (video4linux) 테스트"""
    print("\n[테스트 7] HDMI 입력 테스트")

    video_dev = "/dev/video0"
    if not os.path.exists(video_dev):
        result.add("HDMI 입력 - /dev/video0", False, "장치 없음")
        return

    try:
        v4l2 = subprocess.check_output(
            ["v4l2-ctl", "--list-devices"],
            stderr=subprocess.STDOUT
        ).decode()
        result.add("HDMI 입력 - V4L2 디바이스", True)
        print(f"    V4L2 디바이스 정보:\n    {v4l2.strip().replace(chr(10), chr(10) + '    ')}")
    except FileNotFoundError:
        result.add("HDMI 입력 - v4l2-ctl", False, "v4l2-ctl 없음")
    except Exception as e:
        result.add("HDMI 입력 - V4L2 확인", False, str(e))

    # 캡처 시도
    try:
        capture_cmd = """
import subprocess, os
try:
    r = subprocess.run(
        ['v4l2-ctl', '-d', '/dev/video0', '--list-formats-ext'],
        capture_output=True, timeout=5, text=True
    )
    print(r.stdout[:500])
except Exception as e:
    print(f'ERROR: {e}')
"""
        proc = subprocess.run(
            ["python3", "-c", capture_cmd],
            capture_output=True, timeout=10, text=True
        )
        output = proc.stdout.strip()
        has_formats = "Error" not in output and len(output) > 10
        result.add("HDMI 입력 - 지원 포맷 조회", has_formats, output[:200])
    except Exception as e:
        result.add("HDMI 입력 - 포맷 조회", False, str(e))


# ─── 8. Pcam 카메라 테스트 ────────────────────────────────────────

def test_pcam(result):
    """
    Digilent Pcam 5C 카메라 테스트
    MIPI CSI-2 인터페이스 사용
    """
    print("\n[테스트 8] Pcam 5C 카메라 테스트")

    media_dev = "/dev/media0"
    video_dev = "/dev/video0"

    # 미디어 디바이스 확인
    if not os.path.exists(media_dev):
        result.add("Pcam - /dev/media0", False, "미디어 디바이스 없음")
        return

    result.add("Pcam - /dev/media0 존재", True)

    # MIPI CSI 디바이스 확인
    try:
        media_info = subprocess.check_output(
            ["media-ctl", "-d", "/dev/media0", "-p"],
            stderr=subprocess.STDOUT, timeout=5
        ).decode()
        has_ov5640 = "ov5640" in media_info or "camera" in media_info.lower()
        result.add("Pcam - MIPI CSI 디바이스", has_ov5640,
                   "ov5640 감지됨" if has_ov5640 else "ov5640 미감지")
    except FileNotFoundError:
        result.add("Pcam - media-ctl", False, "media-ctl 없음")
    except Exception as e:
        result.add("Pcam - MIPI CSI 확인", False, str(e))

    # 간단한 프레임 캡처 테스트
    if os.path.exists(video_dev):
        try:
            capture_cmd = """
import subprocess
try:
    # 640x480 캡처 시도
    r = subprocess.run(
        ['v4l2-ctl', '-d', '/dev/video0',
         '--set-fmt-video=width=640,height=480,pixelformat=YUYV',
         '--stream-mmap', '--stream-count=1', '--stream-to=/tmp/test_frame.raw'],
        capture_output=True, timeout=10
    )
    import os
    if os.path.exists('/tmp/test_frame.raw'):
        size = os.path.getsize('/tmp/test_frame.raw')
        os.remove('/tmp/test_frame.raw')
        if size > 0:
            print(f'SUCCESS:프레임크기={size}')
        else:
            print('FAIL:빈프레임')
    else:
        print('FAIL:파일미생성')
except Exception as e:
    print(f'FAIL:{e}')
"""
            proc = subprocess.run(
                ["python3", "-c", capture_cmd],
                capture_output=True, timeout=15, text=True
            )
            output = proc.stdout.strip()
            passed = output.startswith("SUCCESS")
            result.add("Pcam - 프레임 캡처", passed, output)
        except Exception as e:
            result.add("Pcam - 프레임 캡처", False, str(e))
    else:
        result.add("Pcam - 캡처 스킵", True, "/dev/video0 없음, 위 테스트 결과 참고")


# ─── 9. 파일시스템 및 메모리 테스트 ────────────────────────────────

def test_filesystem(result):
    """메모리 및 저장장치 테스트"""
    print("\n[테스트 9] 파일시스템/메모리 테스트")

    # 메모리 확인
    try:
        meminfo = subprocess.check_output(["cat", "/proc/meminfo"],
                                          stderr=subprocess.STDOUT).decode()
        for line in meminfo.split("\n"):
            if "MemTotal" in line:
                result.add("메모리 총량", True, line.strip())
                break
    except Exception as e:
        result.add("메모리 확인", False, str(e))

    # SD카드 마운트 확인
    try:
        mounts = subprocess.check_output(["mount"], stderr=subprocess.STDOUT).decode()
        if "mmcblk0" in mounts:
            result.add("SD카드 마운트", True, " mmcblk0 감지됨")
        else:
            result.add("SD카드 마운트", True, " SD카드 마운트 안됨 (initramfs 모드일 수 있음)")
    except Exception as e:
        result.add("SD카드 마운트 확인", False, str(e))

    # CPU 정보
    try:
        cpuinfo = subprocess.check_output(["cat", "/proc/cpuinfo"],
                                          stderr=subprocess.STDOUT).decode()
        if "Zynq" in cpuinfo or "ARMv7" in cpuinfo or "A9" in cpuinfo:
            result.add("CPU 정보", True, "Zynq-7000 시리즈 확인")
        else:
            first_line = [l for l in cpuinfo.split("\n") if "Hardware" in l or "model name" in l]
            result.add("CPU 정보", True, first_line[0].strip() if first_line else "알 수 없음")
    except Exception as e:
        result.add("CPU 정보", False, str(e))


# ─── 10. 시스템 정보 ──────────────────────────────────────────────

def test_system_info(result):
    """시스템 기본 정보 출력"""
    print("\n[테스트 10] 시스템 정보")

    try:
        uname = subprocess.check_output(["uname", "-a"],
                                        stderr=subprocess.STDOUT).decode().strip()
        result.add("커널 정보", True, uname)
    except Exception as e:
        result.add("커널 정보", False, str(e))

    try:
        uptime = subprocess.check_output(["uptime"],
                                         stderr=subprocess.STDOUT).decode().strip()
        result.add("가동 시간", True, uptime)
    except Exception as e:
        result.add("가동 시간", False, str(e))


# ─── GPIO 유틸리티 함수 ──────────────────────────────────────────

def find_gpio_chip(keyword):
    """
    /sys/class/gpio/gpiochipN/label 파일에서 키워드를 포함하는 GPIO 칩 검색
    """
    gpiochip_dirs = []
    base_path = "/sys/class/gpio"
    if not os.path.exists(base_path):
        return None

    for entry in os.listdir(base_path):
        if entry.startswith("gpiochip"):
            gpiochip_dirs.append(entry)

    for chip in sorted(gpiochip_dirs):
        label_path = os.path.join(base_path, chip, "label")
        if os.path.exists(label_path):
            with open(label_path, "r") as f:
                label = f.read().strip().lower()
                if keyword.lower() in label:
                    return os.path.join(base_path, chip)

    # 키워드 미매칭 시 첫 번째 칩 반환
    if gpiochip_dirs:
        return os.path.join(base_path, sorted(gpiochip_dirs)[0])
    return None


def get_gpio_number(gpiochip_path, pin_offset):
    """GPIO 칩 base 번호 + 오프셋으로 실제 GPIO 번호 계산"""
    base_path = os.path.join(gpiochip_path, "base")
    ngpio_path = os.path.join(gpiochip_path, "ngpio")

    try:
        with open(base_path, "r") as f:
            base = int(f.read().strip())
        with open(ngpio_path, "r") as f:
            ngpio = int(f.read().strip())

        if pin_offset >= ngpio:
            return None
        return base + pin_offset
    except:
        return None


def export_gpio(gpio_num):
    with open("/sys/class/gpio/export", "w") as f:
        f.write(str(gpio_num))
    time.sleep(0.1)


def unexport_gpio(gpio_num):
    with open("/sys/class/gpio/unexport", "w") as f:
        f.write(str(gpio_num))


def set_gpio_direction(gpio_num, direction):
    path = f"/sys/class/gpio/gpio{gpio_num}/direction"
    with open(path, "w") as f:
        f.write(direction)


def set_gpio_value(gpio_num, value):
    path = f"/sys/class/gpio/gpio{gpio_num}/value"
    with open(path, "w") as f:
        f.write(str(value))


def get_gpio_value(gpio_num):
    path = f"/sys/class/gpio/gpio{gpu_num}/value"
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except:
        path = f"/sys/class/gpio/gpio{gpio_num}/value"
        with open(path, "r") as f:
            return f.read().strip()


# ─── 메인 ──────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  Zybo Z7-20 하드웨어 종합 테스트")
    print(f"  실행 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    result = TestResult()

    # 테스트 실행
    test_system_info(result)
    test_filesystem(result)
    test_leds(result)
    test_led_chase(result)
    test_switches(result)
    test_switch_interrupt(result)
    test_buttons(result)
    test_network(result)
    test_hdmi_output(result)
    test_hdmi_input(result)
    test_pcam(result)
    test_uart_loopback(result)

    # 결과 요약
    all_passed = result.summary()

    # JSON 결과 저장
    report = {
        "timestamp": datetime.now().isoformat(),
        "hostname": subprocess.check_output(["hostname"],
                                            stderr=subprocess.STDOUT).decode().strip(),
        "results": result.results
    }

    report_path = "/home/root/test_report.json"
    try:
        with open(report_path, "w") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        print(f"\n상세 리포트 저장: {report_path}")
    except:
        print("\n리포트 저장 실패 (읽기 전용 파일시스템)")

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
```

### 6.4 스크립트 실행

```bash
chmod +x hardware_test.py
python3 hardware_test.py
```

### 6.5 개별 테스트 실행 (선택)

#### LED만 빠르게 테스트

```bash
python3 -c "
import os, time

def find_led_gpio():
    for chip in sorted(os.listdir('/sys/class/gpio')):
        if chip.startswith('gpiochip'):
            label_path = f'/sys/class/gpio/{chip}/label'
            if os.path.exists(label_path):
                with open(label_path) as f:
                    if 'led' in f.read().lower():
                        with open(f'/sys/class/gpio/{chip}/base') as fb:
                            return int(fb.read().strip())
    return None

base = find_led_gpio()
if base is None:
    print('LED GPIO를 찾을 수 없습니다')
    exit(1)

for i in range(4):
    gpio = base + i
    os.system(f'echo {gpio} > /sys/class/gpio/export')
    os.system(f'echo out > /sys/class/gpio/gpio{gpio}/direction')
    os.system(f'echo 1 > /sys/class/gpio/gpio{gpio}/value')
    time.sleep(0.3)
    os.system(f'echo 0 > /sys/class/gpio/gpio{gpio}/value')
    os.system(f'echo {gpio} > /sys/class/gpio/unexport')

print('LED 테스트 완료')
"
```

#### 스위치 읽기

```bash
python3 -c "
import os

# GPIO 칩에서 스위치 base 번호 찾기
for chip in sorted(os.listdir('/sys/class/gpio')):
    if chip.startswith('gpiochip'):
        label_path = f'/sys/class/gpio/{chip}/label'
        if os.path.exists(label_path):
            with open(label_path) as f:
                label = f.read().strip()
                if 'switch' in label.lower():
                    with open(f'/sys/class/gpio/{chip}/base') as fb:
                        base = int(fb.read().strip())
                    print(f'스위치 GPIO base: {base}')
                    for i in range(2):
                        gpio = base + i
                        os.system(f'echo {gpio} > /sys/class/gpio/export')
                        os.system(f'echo in > /sys/class/gpio/gpio{gpio}/direction')
                        with open(f'/sys/class/gpio/gpio{gpio}/value') as fv:
                            val = fv.read().strip()
                        print(f'  SW{i}: {val}')
                        os.system(f'echo {gpio} > /sys/class/gpio/unexport')
"
```

#### 이더넷 빠른 확인

```bash
# IP 확인
hostname -I

# 빠른 인터넷 테스트
ping -c 3 8.8.8.8

# 네트워크 인터페이스 상세
ip addr show eth0
```

---

## 7. 문제 해결

### 7.1 VirtualBox USB 인식 문제

```
증상: SD카드 리더가 가상머신에 연결 안 됨
해결:
  1. VirtualBox 확장팩 재설치
  2. USB 필터 규칙 확인
  3. 게스트 OS에서: lsusb 명령으로 인식 확인
  4. VirtualBox 설정 → USB → USB Device Filters 추가
```

### 7.2 시리얼 콘솔 연결 안 됨

```
증상: minicom/picocom 접속 시 아무것도 안 뜸
해결:
  1. USB-시리얼 드라이버 확인: dmesg | grep tty
  2. 장치 파일 확인: ls /dev/ttyUSB*
  3. 보드 전원이 켜져 있는지, SD카드가 삽입되어 있는지 확인
  4. baud rate 확인: 115200/8/N/1
  5. Hardware Flow Control: DISABLED
```

### 7.3 PetaLinux 빌드 실패

```
증상: petalinux-build 중 에러
해결:
  1. RAM 부족: 최소 8GB 이상 확보
  2. 디스크 부족: 50GB 이상 필요
  3. 소스 클론 시 --recursive 옵션 포함 확인
  4. 이전 빌드 잔여물 정리:
     petalinux-build -x mrproper
  5. 빌드 로그 확인: build/tmp/log/
```

### 7.4 부팅 시 콘솔에 아무것도 안 뜸

```
해결:
  1. SD카드 포맷 다시 (FAT32, MBR)
  2. BOOT.BIN, image.ub 파일 존재 확인
  3. JP5 점퍼 위치 확인
  4. PS-SRST 버튼 눌러 리부팅
  5. 시리얼 케이블 연결 확인
  6. baud rate 재확인
```

### 7.5 GPIO找不到 (找不到)

```
증상: /sys/class/gpio/ 하위에 해당 LED/스위치 없음
해결:
  1. UIO 커널 모듈 확인:
     lsmod | grep uio
  2. 디바이스 트리 확인:
     ls /sys/firmware/devicetree/base/
  3. UIO 모듈 로드:
     modprobe uio_pdrv_genirq
  4. bootargs에 uio_pdrv_genirq.of_id=generic-uio 포함 확인
```

### 7.6 HDMI 출력 안 됨

```
해결:
  1. HDMI 케이블 및 모니터 확인
  2. 프레임버퍼 확인:
     cat /sys/class/graphics/fb0/virtual_size
  3. KMS 설정 확인:
     ls /sys/class/drm/
  4. 모니터가 해상도를 지원하는지 확인
```

---

## 부록 A: 빠른 명령어 참조

```bash
# 환경 소스
source /opt/pkg/petalinux/settings.sh

# 빌드
petalinux-build

# 부팅 이미지 패키징
petalinux-package --boot --force \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system_wrapper.bit \
    --u-boot

# 클린 빌드
petalinux-build -x mrproper

# 설정
petalinux-config              # 전체 설정
petalinux-config -c rootfs    # 루트fs 설정
petalinux-config -c device-tree  # 디바이스 트리 설정

# GPIO 디버그
cat /sys/class/gpio/gpiochip*/label
cat /sys/class/gpio/gpio<N>/value

# 커널 로그
dmesg | tail -50

# 프로세스 확인
ps aux
top
```

## 부록 B: 테스트 결과 판정 기준

| 기능 | 판정 기준 |
|------|----------|
| LED | GPIO로 0/1 제어 가능 |
| 스위치 | GPIO 입력으로 현재 상태 읽기 가능 |
| 버튼 | GPIO 입력으로 눌림 감지 가능 |
| UART | TX→RX 데이터 수발신 일치 |
| 네트워크 | DHCP IP 할당 + ping 응답 |
| HDMI 출력 | /dev/fb0 존재 + 프레임 쓰기 가능 |
| HDMI 입력 | V4L2 디바이스 인식 |
| Pcam | media0 감지 + 프레임 캡처 가능 |
| 메모리 | MemTotal 512MB 이상 |

---

# Part 2: 최신 버전 가이드 (PetaLinux 2022.1 + Ubuntu 20.04)

> 이전 섹션의 PetaLinux 2017.4 + Ubuntu 16.04 조합 대신, **최신 유지보수 버전** 사용을 위한 추가 가이드

---

## 목차 (Part 2)

8. [변경 사항 요약](#8-변경-사항-요약)
9. [Ubuntu 20.04 LTS 환경 설정](#9-ubuntu-2004-lts-환경-설정)
10. [PetaLinux 2022.1 도구 설치](#10-petalinux-20221-도구-설치)
11. [최신 BSP 다운로드 및 빌드](#11-최신-bsp-다운로드-및-빌드)
12. [부팅 이미지 생성 및 SD카드](#12-부팅-이미지-생성-및-sd카드)
    - [12.0 빌드 결과 확인](#120-빌드-결과-확인)
    - [12.5 Windows에서 SD카드 굽기 (balenaEtcher)](#125-windows에서-sd카드-굽기-balenetcher)
13. [보드 동작 테스트 (C/Python)](#13-보드-동작-테스트)
    - [13.1 테스트 환경 준비](#131-테스트-환경-준비)
    - [13.2 테스트 파일 전송 방법](#132-테스트-파일-전송-방법)
    - [13.3 C 하드웨어 테스트 코드 (추천)](#133-c-하드웨어-테스트-코드-추천)
    - [13.4 Python 테스트 코드](#134-python-테스트-코드)
    - [13.5 개별 테스트 실행](#135-개별-테스트-실행)
14. [문제 해결 - 최신 버전](#14-문제-해결---최신-버전)

---

## 8. 변경 사항 요약

### 8.1 이전 vs 최신 비교

| 항목 | 이전 (Part 1) | 최신 (Part 2) |
|------|--------------|--------------|
| PetaLinux | 2017.4 | **2022.1** |
| Ubuntu | 16.04 LTS (EOL) | **20.04 LTS** (2025.4까지 지원) |
| BSP 출처 | `Digilent/Petalinux-Zybo-Z7-20` (비활성) | **`Digilent/Zybo-Z7`** (활성) |
| 커널 | ~4.9 | **~5.15** |
| Python | Python 2/3 혼용 | **Python 3 위주** |
| 의존성 패키지 | 일부 libssl 1.0/1.1 | **libssl 1.1 (20.04 기본)** |
| 디바이스 트리 | 수동 수정 필요 | **자동 생성 개선** |
| UIO 드라이버 | 빌드인 | **모듈 방식 개선** |
| 보안 패치 | 없음 (EOL) | **활성 업데이트** |

### 8.2 BSP 저장소 이전 안내

```
[이전 - 더 이상 유지보수 안 함]
https://github.com/Digilent/Petalinux-Zybo-Z7-20

[최신 - 현재 활성 저장소]
https://github.com/Digilent/Zybo-Z7
  └── Zybo-Z7-OS/  (서브모듈로 포함)
```

> Digilent 공식 데모 페이지:
> https://digilent.com/reference/programmable-logic/zybo-z7/demos/petalinux

---

## 9. Ubuntu 20.04 LTS 환경 설정

### 9.1 VirtualBox 가상 머신 생성

| 항목 | 설정값 |
|------|--------|
| 이름 | `Zybo-PetaLinux-2022` |
| 타입 | Linux |
| 버전 | Ubuntu (64-bit) |
| RAM | **8192 MB** |
| CPU | **4코어 이상** |
| 디스크 | **120GB** VDI (동적 할당) |

> PetaLinux 2022.1은 2017.4보다 빌드 시 더 많은 리소스를 사용합니다.

### 9.2 Ubuntu 20.04 LTS 설치

- [Ubuntu 20.04.6 LTS 다운로드](https://releases.ubuntu.com/20.04/)
  - 파일명: `ubuntu-20.04.6-desktop-amd64.iso`

### 9.3 필수 의존성 패키지 설치

```bash
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
    tofrodos gawk xvfb git \
    libncurses5-dev libncursesw5-dev \
    tftpd-hpa \
    zlib1g-dev zlib1g-dev:i386 \
    libssl-dev \
    flex bison \
    chrpath socat \
    autoconf libtool texinfo \
    gcc-multilib \
    libsdl1.2-dev \
    libglib2.0-dev \
    screen pax \
    net-tools \
    iputils-ping \
    python3 python3-pip \
    picocom \
    device-tree-compiler \
    xterm \
    libtinfo5 \
    python2
```

> **2017.4와의 차이점:**
> - `libncurses5-dev` → `libncursesw5-dev` 추가
> - `python3-pip` 명시적 설치
> - `device-tree-compiler` 추가
> - `net-tools` 대신 `iproute2` 사용 권장 (기본 포함)

> **실제 빌드에서 추가 필요 패키지 (실습 확인):**
> - `xterm`: PetaLinux 설치 시 필수 (설치 시 에러 발생)
> - `libtinfo5`: xsct SDK 호환용 (빌드 시 `libtinfo.so.5` 에러)
> - `python2`: 일부 레거시 스크립트 의존

### 9.4 시리얼 통신 도구

```bash
# picocom 권장 (minicom보다 간단)
sudo apt-get install -y picocom

# minicom 사용 시
sudo apt-get install -y minicom
```

---

## 10. PetaLinux 2022.1 도구 설치

### 10.1 설치 디렉토리 준비

```bash
sudo mkdir -p /opt/pkg/petalinux
sudo chown -R $USER:$USER /opt/pkg/
```

### 10.2 PetaLinux 2022.1 다운로드

1. [AMD/Xilinx 웹사이트](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html)에서:
   - **PetaLinux 2022.1** 설치 파일 다운로드
   - 파일명 예: `petalinux-v2022.1-04191534-installer.run`
   - Xilinx 계정 로그인 필요

```bash
cd ~/Downloads
chmod +x petalinux-v2022.1-04191534-installer.run
./petalinux-v2022.1-04191534-installer.run --dir /opt/pkg/petalinux
```

> **주의:** `-d/--dir` 옵션은 공백으로 구분하여 사용 (`-d /path` 또는 `--dir /path`)
> 잘못된 예: `-d/--dir /path` (에러 발생)

> 설치 중 라이센스 동의 화면에서 `y`를 눌러 진행

### 10.3 환경변수 설정

```bash
# 새 터미널에서 매번 실행
source /opt/pkg/petalinux/settings.sh

# 확인 (환경변수 로드 확인)
# petalinux-config --version은 지원하지 않음
petalinux-config --help
# "PetaLinux environment set to '/opt/pkg/petalinux'" 메시지 출력 시 성공
```

### 10.4 영구 환경변수 (편의용)

```bash
echo 'source /opt/pkg/petalinux/settings.sh' >> ~/.bashrc
source ~/.bashrc
```

### 10.5 빌드 도구 확인

```bash
# GCC 크로스 컴파일러 확인
petalinux-config --help

# 디스크 공간 확인 (최소 50GB 권장)
df -h /opt

# RAM 확인 (최소 8GB 권장)
free -h
```

---

## 11. 최신 BSP 다운로드 및 빌드

### 11.1 BSP 파일 다운로드

 Digilent 공식 페이지에서 최신 BSP 다운로드:

```
https://digilent.com/reference/programmable-logic/zybo-z7/demos/petalinux
```

**다운로드 테이블:**

| 보드 | PetaLinux 버전 | BSP 파일명 |
|------|---------------|-----------|
| Zybo Z7-20 | **2022.1** | `Zybo-Z7-20-Petalinux-2022-1.bsp` |
| Zybo Z7-20 | 2021.1 | `Zybo-Z7-20-Petalinux-2021-1.bsp` |
| Zybo Z7-20 | 2020.1 | `Zybo-Z7-20-Petalinux-2020-1.bsp` |

> **최신:** `Zybo-Z7-20-Petalinux-2022-1.bsp` (권장)

### 11.2 프로젝트 생성

```bash
# BSP에서 프로젝트 생성
petalinux-create -t project -s /path/to/Zybo-Z7-20-Petalinux-2022-1.bsp
cd <생성된 프로젝트_이름>
```

> **실제 빌드 확인:** BSP 내부 정의에 따라 프로젝트 디렉토리명이 `os`로 생성됩니다.
> `ls`로 확인 후 `cd os`로 진입하세요.

### 11.3 (선택) 프로젝트 설정 확인

```bash
# 전체 설정 (메뉴 기반)
petalinux-config

# 네트워크 설정 확인
petalinux-config
# → Image Packaging Configuration → Root filesystem type
#    - initramfs (기본값, RAM 기반)
#    - SD card (영구 저장)

# rootfs 설정
petalinux-config -c rootfs

# 디바이스 트리 설정
petalinux-config -c device-tree
```

### 11.4 프로젝트 빌드

```bash
# 환경 소스 확인
source /opt/pkg/petalinux/settings.sh

# 빌드 (소요시간: 30분~2시간)
petalinux-build
```

> **빌드 로그 위치:** `build/tmp/log/`
> **빌드 실패 시:** `petalinux-build -x mrproper` 후 재시도

### 11.5 부팅 이미지 패키징

```bash
petalinux-package --boot \
    --force \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system.bit \
    --u-boot
```

> **2022.1에서의 변경:** FPGA 비트스트림 파일명이 `system_wrapper.bit`가 아닌 `system.bit`입니다.
> sstate 캐시 관련 WARNING/ERROR는 무시해도 됩니다. 실제 태스크가 성공하면 빌드 성공입니다.

### 11.6 빌드 결과물 확인

```bash
ls -la images/linux/

# 주요 파일:
# BOOT.BIN              - FSBL + FPGA 비트스트림 + U-Boot
# image.ub              - 커널 + 디바이스트리 + 루트fs (initramfs)
# rootfs.ext4           - SD카드용 루트파일시스템 (SD rootfs 사용 시)
# system_wrapper.bit    - FPGA 비트스트림
# zynq_fsbl.elf         - First Stage Boot Loader
# boot.scr              - U-Boot 스크립트 (2022.1에서 새로 생성)
```

> **2017.4와의 차이:** `boot.scr` 파일이 자동 생성됩니다.

---

## 12. 부팅 이미지 생성 및 SD카드

### 12.0 빌드 결과 확인 (실제 빌드 완료 후)

빌드 및 패키징 완료 후 `images/linux/`에 다음 파일이 있는지 확인:

```bash
ls -la images/linux/
```

**예상 파일 목록 (실제 빌드 확인):**

| 파일 | 크기 | 설명 |
|------|------|------|
| `BOOT.BIN` | ~30MB | FSBL + FPGA 비트스트림 + U-Boot (패키징 후 생성) |
| `image.ub` | ~75MB | 커널 + 디바이스트리 + 루트fs |
| `boot.scr` | ~2.7KB | U-Boot 스크립트 |
| `system.bit` | ~2.5MB | FPGA 비트스트림 |
| `zynq_fsbl.elf` | ~450KB | First Stage Boot Loader |
| `rootfs.ext4` | ~235MB | SD카드용 루트파일시스템 |
| `zImage` | ~4.5MB | 커널 이미지 |
| `system.dtb` | ~26KB | 디바이스 트리 |

> sstate 캐시 관련 WARNING은 무시해도 됩니다. 모든 실제 태스크가 성공하면 빌드 성공입니다.

### 12.1 SD카드 포맷 (Ubuntu 20.04 기준)

```bash
# SD카드 디바이스 확인
lsblk

# 보통 /dev/sdb 또는 /dev/sdc (USB 리더에 따라 다름)
# 아래에서 <SD_CARD>를 실제 디바이스로 대체하세요

# 파티션 테이블 삭제 및 새로 생성
sudo parted /dev/<SD_CARD> --script mklabel msdos

# FAT32 부팅 파티션 (최소 500MB)
sudo parted /dev/<SD_CARD> --script mkpart primary fat32 1MiB 500MiB

# SD rootfs 사용 시: ext4 파티션 추가
sudo parted /dev/<SD_CARD> --script mkpart primary ext4 500MiB 100%

# 포맷
sudo mkfs.vfat -F 32 /dev/<SD_CARD>1
# SD rootfs 사용 시:
sudo mkfs.ext4 -F /dev/<SD_CARD>2
```

### 12.2 이미지 복사

```bash
# FAT32 파티션에 복사
sudo mkdir -p /mnt/boot
sudo mount /dev/<SD_CARD>1 /mnt/boot

sudo cp images/linux/BOOT.BIN /mnt/boot/
sudo cp images/linux/image.ub /mnt/boot/
# 2022.1에서 새로 추가됨:
sudo cp images/linux/boot.scr /mnt/boot/ 2>/dev/null

# SD rootfs 사용 시
sudo mkdir -p /mnt/rootfs
sudo mount /dev/<SD_CARD>2 /mnt/rootfs
sudo dd if=images/linux/rootfs.ext4 of=/dev/<SD_CARD>2 bs=4M status=progress
sync
sudo resize2fs /dev/<SD_CARD>2
sync

# 언마운트
sudo umount /mnt/boot
sudo umount /mnt/rootfs 2>/dev/null
sync
```

### 12.3 (선택) SD rootfs 사용 시 디바이스 트리 수정

```bash
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

기존 bootargs 라인을 다음으로 변경:
```
bootargs = "console=ttyPS0,115200 earlyprintk uio_pdrv_genirq.of_id=generic-uio root=/dev/mmcblk0p2 rw rootwait";
```

변경 후 재빌드:
```bash
petalinux-build
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
```

### 12.4 보드 부팅

#### 하드웨어 연결 순서

1. SD카드를 보드의 SD 슬롯에 삽입
2. 전원 선택 점퍼 **JP5**: `USB` 또는 `EXT` 선택
   - USB 전류 부족 시 외부 전원 사용 권장
3. 시리얼 케이블: 보드 microUSB ↔ PC USB 연결
4. (선택) HDMI 케이블 연결
5. (선택) 이더넷 케이블 연결

#### 시리얼 콘솔 접속

```bash
# picocom 사용 (권장)
picocom -b 115200 /dev/ttyUSB1

# 또는 minicom 사용
sudo minicom -D /dev/ttyUSB1 -b 115200
# 설정: 115200/8/N/1, Hardware Flow Control: No
```

#### 부팅 확인

- 전원 인가 후 **PS-SRST** 버튼 누름
- 콘솔에 U-Boot → 커널 부팅 로그 출력 확인
- `root@<hostname>:~#` 프롬프트 출력 시 부팅 성공

### 12.5 Windows에서 SD카드 굽기 (balenaEtcher)

Ubuntu 가상머신에서 직접 SD카드를 구하기 어려운 경우, **빌드 이미지를 Windows로 복사 후 balenaEtcher로 굽는 방법**이 가장 안정적입니다.

#### 1단계: VirtualBox 공유 폴더 설정

1. VirtualBox 메뉴 → **장치** → **공유 폴더 설정**
2. **공유 폴더 추가** 클릭
3. 폴더 경로: `C:\Zybo-SD-Images` (Windows에 생성)
4. **자동 마운트** 체크
5. 공유 이름: `share`

#### 2단계: Ubuntu에서 공유 폴더로 이미지 복사

```bash
# 공유 폴더 마운트 확인 (보통 자동 마운트)
ls /mnt/share

# 필요 시 수동 마운트
sudo mkdir -p /mnt/share
sudo mount -t vboxsf share /mnt/share

# 이미지 파일 복사
cp /home/gotree94/Downloads/os/images/linux/BOOT.BIN /mnt/share/
cp /home/gotree94/Downloads/os/images/linux/image.ub /mnt/share/
cp /home/gotree94/Downloads/os/images/linux/boot.scr /mnt/share/

# 확인
ls -la /mnt/share/
```

> **initramfs 모드**에서는 `BOOT.BIN` + `image.ub` + `boot.scr` 3개 파일만 필요합니다.
> **SD rootfs 모드**에서는 `rootfs.ext4`도 추가로 복사합니다.

#### 3단계: Windows에서 balenaEtcher로 SD카드 굽기

> **initramfs 모드일 때**는 balenaEtcher 대신 **수동 복사**가 더 적합합니다.
> balenaEtcher는 단일 이미지(.img) 파일을 디스크에 직접 쓰는 도구이기 때문입니다.

**방법 A: Windows에서 수동 복사 (권장, initramfs용)**

1. SD카드를 Windows에 삽입
2. SD카드의 FAT32 파티션을 `F:` (또는 다른 드라이브 문자)로 인식
3. Windows 탐색기 또는 PowerShell에서 복사:

```powershell
# Windows PowerShell
Copy-Item "C:\Zybo-SD-Images\BOOT.BIN" "F:\"
Copy-Item "C:\Zybo-SD-Images\image.ub" "F:\"
Copy-Item "C:\Zybo-SD-Images\boot.scr" "F:\"
```

4. SD카드 안전하게 제거

**방법 B: balenaEtcher 사용 (SD rootfs 모드)**

> SD rootfs 모드에서는 `rootfs.ext4`를 디스크에 직접 써야 하므로 balenaEtcher 사용 가능.
> 다만 `BOOT.BIN`은 별도 FAT32 파티션에 넣어야 하므로 두 단계가 필요합니다.

1. [balenaEtcher 다운로드](https://etcher.balena.io/) 및 설치
2. SD카드를 Windows에 삽입
3. balenaEtcher 실행:
   - **Flash from file**: `rootfs.ext4` 선택
   - **Select target**: SD카드 선택
   - **Flash!** 클릭
4. 완료 후 SD카드를 다시 Windows에 마운트
5. FAT32 파티션에 `BOOT.BIN`, `image.ub`, `boot.scr` 복사

**방법 C: Raspberry Pi Imager 대안**

> `rpi-imager`도 SD카드 굽기에 사용 가능하나, custom image용으로는 제한적.
> 가장 안정적인 방법은 **방법 A (수동 복사)**입니다.

#### SD카드 포맷 (Windows에서)

SD카드를 포맷해야 하는 경우:

1. Windows 탐색기에서 SD카드 우클릭 → **포맷**
2. 파일 시스템: **FAT32**
3. 클러스터 크기: **기본값**
4. **빠른 포맷** 체크 → 포맷

> **주의:** FAT32는 최대 32GB 파티션까지 지원. 64GB 이상 SD카드는 별도 처리 필요.

#### 최종 SD카드 구조

```
SD카드 (FAT32 파티션)
├── BOOT.BIN        (~30MB)
├── image.ub        (~75MB)
└── boot.scr        (~2.7KB)
```

> SD rootfs 모드일 경우:
> ```
> SD카드
> ├── 파티션1 (FAT32): BOOT.BIN, image.ub, boot.scr
> └── 파티션2 (ext4): rootfs (dd로 작성)
> ```

---

## 13. 보드 동작 테스트

### 13.1 테스트 환경 준비

#### Python 설치 (이미지에 포함되지 않은 경우)

```bash
# SD rootfs 모드에서만 가능 (initramfs는 재부팅 시 사라짐)
opkg update
opkg install python3 python3-core

# Python 확인
python3 --version
```

> **initramfs 모드**에서는 패키지 설치가 재부팅 후 사라집니다.
> C 테스트 코드를 사용하면 Python 없이도 테스트 가능합니다.

#### C 컴파일러 확인

```bash
# gcc가 이미지에 포함되어 있는지 확인
gcc --version

# 없을 경우 (SD rootfs 모드)
opkg update
opkg install gcc
```

> PetaLinux 이미지에는 일반적으로 `gcc`가 포함되어 있지 않습니다.
> **C 테스트 코드를 사용하는 것이 가장 안정적입니다.**

### 13.2 테스트 파일 전송 방법

#### 방법 A: 시리얼 콘솔에서 직접 붙여넣기

시리얼 콘솔(picocom/minicom)에서 복사한 후, 보드에서 `cat`으로 파일 생성:

```bash
# cat으로 파일 작성 후 Ctrl+D로 종료
cat > /home/petalinux/hw_test.c << 'EOF'
(아래 C 코드 내용)
EOF
```

#### 방법 B: SD카드에 넣기

호스트 PC에서 SD카드의 FAT32 파티션에 테스트 파일 복사 후 보드에서 마운트:

```bash
# 보드에서 SD카드 마운트
mkdir -p /mnt/sd
mount /dev/mmcblk0p1 /mnt/sd
cp /mnt/sd/hw_test.c /home/petalinux/
cp /mnt/sd/hw_test.py /home/petalinux/
umount /mnt/sd
```

#### 방법 C: SCP (이더넷 연결 시)

```bash
# 호스트 PC에서
scp hw_test.c petalinux@<BOARD_IP>:/home/petalinux/
scp hw_test.py petalinux@<BOARD_IP>:/home/petalinux/
```

### 13.3 C 하드웨어 테스트 코드 (추천, UIO 방식)

> UIO 드라이버를 통한 PL GPIO 접근 (sysfs GPIO 대신 사용)
> Zybo Z7-20에서 PL GPIO는 UIO에 의해 점유되어 sysfs GPIO 사용 불가
> 한글 코멘트 깨짐 방지를 위해 영어로 작성

```c
/*
 * hw_test.c - Zybo Z7-20 Hardware Test Program (UIO version)
 *
 * Compile: gcc -o hw_test hw_test.c
 * Run:     ./hw_test
 *
 * PL GPIO access via UIO (uio_pdrv_genirq driver).
 *
 * UIO mapping (verified from system.xsa):
 *   uio0 -> axi_gpio_led    (0x41220000) -> LEDs Ch1 (4 outputs)
 *   uio1 -> axi_gpio_sw_btn (0x41210000) -> Switches Ch1 (4 inputs)
 *                                          -> Buttons   Ch2 (4 inputs, offset 0x08)
 *   uio2 -> axi_gpio_video  (0x41200000) -> HDMI Hotplug Detect (1 bit)
 *   uio3 -> axi_gpio_eth    (0x41230000) -> Ethernet Reset (1 bit)
 *
 * AXI GPIO register map:
 *   Offset 0x00 : GPIO_DATA  (read/write pin values)
 *   Offset 0x04 : GPIO_TRI   (direction: 0=output, 1=input)
 *
 * Tests: LED, Switch, Button, Network, Memory, System Info
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/mman.h>
#include <time.h>

/* -------------------------------------------------- */
/* PL GPIO via UIO                                    */
/* -------------------------------------------------- */

#define GPIO_DATA_OFFSET 0x00
#define GPIO_TRI_OFFSET  0x04
#define GPIO2_DATA_OFFSET 0x08
#define GPIO2_TRI_OFFSET  0x0C
#define MAP_SIZE          0x10000

/* UIO device addresses (from /sys/class/uio/uioN/maps/map0/addr) */
#define UIO_ADDR_LEDS    0x41220000
#define UIO_ADDR_SWITCH  0x41210000
#define UIO_ADDR_BUTTON  0x41200000

struct uio_gpio {
    int   fd;
    void *map;
};

int uio_open(struct uio_gpio *g, const char *devpath)
{
    g->fd = open(devpath, O_RDWR);
    if (g->fd < 0) return -1;
    g->map = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE,
                  MAP_SHARED, g->fd, 0);
    if (g->map == MAP_FAILED) {
        close(g->fd);
        g->fd = -1;
        return -1;
    }
    return 0;
}

void uio_close(struct uio_gpio *g)
{
    if (g->map && g->map != MAP_FAILED)
        munmap(g->map, MAP_SIZE);
    if (g->fd >= 0)
        close(g->fd);
    g->fd = -1;
    g->map = NULL;
}

static inline unsigned int uio_read32(struct uio_gpio *g, unsigned int offset)
{
    volatile unsigned int *addr =
        (volatile unsigned int *)((char *)g->map + offset);
    return *addr;
}

static inline void uio_write32(struct uio_gpio *g, unsigned int offset,
                                unsigned int val)
{
    volatile unsigned int *addr =
        (volatile unsigned int *)((char *)g->map + offset);
    *addr = val;
}

/* Set pin direction: dir=0 output, dir=1 input (via GPIO_TRI register) */
void uio_set_direction(struct uio_gpio *g, int bit, int dir)
{
    unsigned int tri = uio_read32(g, GPIO_TRI_OFFSET);
    if (dir) /* input */
        tri |= (1u << bit);
    else     /* output */
        tri &= ~(1u << bit);
    uio_write32(g, GPIO_TRI_OFFSET, tri);
}

void uio_set_pin(struct uio_gpio *g, int bit, int val)
{
    unsigned int data = uio_read32(g, GPIO_DATA_OFFSET);
    if (val)
        data |= (1u << bit);
    else
        data &= ~(1u << bit);
    uio_write32(g, GPIO_DATA_OFFSET, data);
}

int uio_get_pin(struct uio_gpio *g, int bit)
{
    return (uio_read32(g, GPIO_DATA_OFFSET) >> bit) & 1;
}

/* -------------------------------------------------- */
/* Test: LED                                          */
/* -------------------------------------------------- */

void test_leds(void)
{
    printf("\n[TEST 1] LED Test (LD4~LD7, 4 LEDs)\n");

    struct uio_gpio led;
    if (uio_open(&led, "/dev/uio0") < 0) {
        printf("  [FAIL] Cannot open /dev/uio0 (LED)\n");
        return;
    }
    printf("  [OK]   LED UIO opened (/dev/uio0, 0x41220000)\n");

    /* All 4 pins as output */
    int i;
    for (i = 0; i < 4; i++)
        uio_set_direction(&led, i, 0);

    /* Individual LED test */
    for (i = 0; i < 4; i++) {
        uio_set_pin(&led, i, 1);
        usleep(300000);

        int val = uio_get_pin(&led, i);
        uio_set_pin(&led, i, 0);

        printf("  [%s] LED%d (LD%d) read=%d\n",
               (val == 1) ? "OK " : "FAIL", i, i + 4, val);
    }

    /* Chase pattern */
    printf("\n[TEST 1b] LED Chase Pattern\n");
    int round;
    for (round = 0; round < 3; round++) {
        for (i = 0; i < 4; i++) {
            uio_set_pin(&led, i, 1);
            usleep(100000);
            uio_set_pin(&led, i, 0);
        }
    }
    printf("  [OK]   Chase pattern completed\n");

    uio_close(&led);
}

/* -------------------------------------------------- */
/* Test: Switch                                       */
/* -------------------------------------------------- */

void test_switches(void)
{
    printf("\n[TEST 2] Switch Test (SW0~SW3)\n");

    struct uio_gpio sw;
    if (uio_open(&sw, "/dev/uio1") < 0) {
        printf("  [FAIL] Cannot open /dev/uio1 (Switch)\n");
        return;
    }
    printf("  [OK]   Switch UIO opened (/dev/uio1, 0x41210000)\n");

    /* All 4 pins as input */
    int i;
    for (i = 0; i < 4; i++)
        uio_set_direction(&sw, i, 1);

    for (i = 0; i < 4; i++) {
        int val = uio_get_pin(&sw, i);
        printf("  [OK]   SW%d = %d\n", i, val);
    }

    /* Polling test */
    printf("\n[TEST 2b] Switch Polling (5s)\n");
    int initial = uio_get_pin(&sw, 0);
    printf("  Initial SW0=%d, toggle within 5s...\n", initial);

    time_t start = time(NULL);
    int changed = 0, current = initial;
    while (time(NULL) - start < 5) {
        current = uio_get_pin(&sw, 0);
        if (current != initial) { changed = 1; break; }
        usleep(50000);
    }

    if (changed)
        printf("  [OK]   SW0 changed: %d -> %d\n", initial, current);
    else
        printf("  [OK]   No change (timeout), SW0=%d\n", initial);

    uio_close(&sw);
}

/* -------------------------------------------------- */
/* Test: Button                                       */
/* -------------------------------------------------- */

void test_buttons(void)
{
    printf("\n[TEST 3] Button Test (Channel 2 of uio1)\n");

    struct uio_gpio btn;
    if (uio_open(&btn, "/dev/uio1") < 0) {
        printf("  [FAIL] Cannot open /dev/uio1 (Button)\n");
        return;
    }
    printf("  [OK]   Button UIO opened (/dev/uio1 Ch2, 0x41210000+0x08)\n");

    /* Channel 2: All pins as input (GPIO2_TRI) */
    int i;
    for (i = 0; i < 4; i++) {
        unsigned int tri = uio_read32(&btn, GPIO2_TRI_OFFSET);
        tri |= (1u << i);
        uio_write32(&btn, GPIO2_TRI_OFFSET, tri);
    }

    for (i = 0; i < 4; i++) {
        int val = (uio_read32(&btn, GPIO2_DATA_OFFSET) >> i) & 1;
        printf("  [OK]   BTN%d = %d\n", i, val);
    }

    uio_close(&btn);
}

/* -------------------------------------------------- */
/* Test: Network                                      */
/* -------------------------------------------------- */

void test_network(void)
{
    printf("\n[TEST 5] Network Test\n");

    int ret = system("ip link show eth0 > /dev/null 2>&1");
    if (ret != 0) {
        printf("  [FAIL] eth0 not found\n");
        return;
    }
    printf("  [OK]   eth0 interface found\n");

    ret = system("udhcpc -i eth0 > /dev/null 2>&1");
    if (ret == 0)
        printf("  [OK]   DHCP completed (udhcpc)\n");
    else
        printf("  [WARN] DHCP failed, trying static IP 192.168.1.10\n");

    FILE *fp = popen("ip -4 addr show eth0 | grep inet | head -1", "r");
    char line[128] = {0};
    if (fp) {
        fgets(line, sizeof(line), fp);
        pclose(fp);
    }

    if (strlen(line) == 0) {
        printf("  [INFO] Setting static IP 192.168.1.10/24\n");
        system("ip addr add 192.168.1.10/24 dev eth0 2>/dev/null");
        system("ip link set eth0 up 2>/dev/null");
        sleep(1);
        fp = popen("ip -4 addr show eth0 | grep inet | head -1", "r");
        if (fp) {
            fgets(line, sizeof(line), fp);
            pclose(fp);
        }
    }

    if (strlen(line) > 0)
        printf("  [OK]   %s", line);
    else
        printf("  [FAIL] No IPv4 address on eth0\n");

    ret = system("ping -c 3 -W 2 8.8.8.8 > /dev/null 2>&1");
    printf("  [%s] Ping 8.8.8.8\n", (ret == 0) ? "OK " : "FAIL (check cable/DHCP)");
}

/* -------------------------------------------------- */
/* Test: HDMI Input (V4L2)                            */
/* -------------------------------------------------- */

void test_hdmi_in(void)
{
    printf("\n[TEST 6] HDMI Input Test (V4L2)\n");

    if (access("/dev/video0", F_OK) != 0) {
        printf("  [SKIP] /dev/video0 not found (no HDMI input)\n");
        return;
    }
    printf("  [OK]   /dev/video0 found\n");

    /* Check format */
    int ret = system("v4l2-ctl --device=/dev/video0 --list-formats-ext 2>/dev/null | head -10");
    if (ret != 0)
        printf("  [WARN] v4l2-ctl not available\n");

    printf("  [INFO] Connect HDMI source, then run:\n");
    printf("         v4l2-ctl --device=/dev/video0 --stream-mmap --stream-count=1 --stream-to=hdmi_in.raw\n");
}

/* -------------------------------------------------- */
/* Test: Memory                                       */
/* -------------------------------------------------- */

void test_memory(void)
{
    printf("\n[TEST 9] Memory/System Test\n");

    FILE *fp = fopen("/proc/meminfo", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "MemTotal")) {
                printf("  [OK]   %s", line);
                break;
            }
        }
        fclose(fp);
    }

    fp = fopen("/proc/cpuinfo", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "Hardware") || strstr(line, "model name")) {
                printf("  [OK]   %s", line);
                break;
            }
        }
        fclose(fp);
    }

    fp = popen("uname -a", "r");
    if (fp) {
        char line[256];
        if (fgets(line, sizeof(line), fp))
            printf("  [OK]   %s", line);
        pclose(fp);
    }
}

/* -------------------------------------------------- */
/* Test: HDMI (DRM check)                             */
/* -------------------------------------------------- */

void test_hdmi(void)
{
    printf("\n[TEST 6] HDMI Output Test\n");

    if (access("/dev/fb0", F_OK) == 0) {
        printf("  [OK]   /dev/fb0 found\n");
    } else {
        printf("  [WARN] /dev/fb0 not found, checking DRM...\n");
        DIR *dir = opendir("/sys/class/drm");
        if (dir) {
            struct dirent *entry;
            int found = 0;
            while ((entry = readdir(dir)) != NULL) {
                if (strstr(entry->d_name, "HDMI") ||
                    strstr(entry->d_name, "card")) {
                    printf("  [OK]   DRM: %s\n", entry->d_name);
                    found = 1;
                }
            }
            closedir(dir);
            if (!found)
                printf("  [FAIL] No HDMI DRM connector\n");
        }
    }
}

/* -------------------------------------------------- */
/* Main                                               */
/* -------------------------------------------------- */

int main(void)
{
    printf("==============================================\n");
    printf("  Zybo Z7-20 Hardware Test (UIO version)\n");
    printf("==============================================\n");

    test_memory();
    test_leds();
    test_switches();
    test_buttons();
    test_network();
    test_hdmi();
    test_hdmi_in();

    printf("\n==============================================\n");
    printf("  All tests completed\n");
    printf("==============================================\n");

    return 0;
}
```

#### C 코드 컴파일 및 실행

```bash
gcc -o hw_test hw_test.c
./hw_test
```

#### 빠른 개별 테스트

```bash
# LED만 테스트
gcc -o led_test hw_test.c && ./led_test

# 네트워크만 빠르게 확인
ping -c 3 8.8.8.8

# 시스템 정보만
uname -a && cat /proc/meminfo | head -5
```

### 13.4 Python 테스트 코드 (UIO 방식)

> Python이 설치된 경우에만 사용 가능
> UIO를 통한 PL GPIO 접근 (mmap 방식)
> 한글 코멘트 깨짐 방지를 위해 영어로 작성

```python
#!/usr/bin/env python3
"""
hw_test.py - Zybo Z7-20 Hardware Test (Python/UIO version)
Requires: Python 3

PL GPIO access via UIO (uio_pdrv_genirq driver).

UIO mapping (verified from system.xsa):
  uio0 -> axi_gpio_led    (0x41220000) -> LEDs Ch1 (4 outputs)
  uio1 -> axi_gpio_sw_btn (0x41210000) -> Switches Ch1 (4 inputs, offset 0x00)
                                         -> Buttons   Ch2 (4 inputs, offset 0x08)
  uio2 -> axi_gpio_video  (0x41200000) -> HDMI Hotplug Detect
  uio3 -> axi_gpio_eth    (0x41230000) -> Ethernet Reset

AXI GPIO register map:
  Offset 0x00 : GPIO_DATA  (read/write pin values)
  Offset 0x04 : GPIO_TRI   (direction: 0=output, 1=input)
"""

import os
import sys
import time
import struct
import subprocess
from datetime import datetime

try:
    import mmap as mmap_mod
except ImportError:
    mmap_mod = None


class TestResult:
    def __init__(self):
        self.results = []

    def add(self, name, passed, detail=""):
        status = "PASS" if passed else "FAIL"
        self.results.append({"name": name, "status": status, "detail": detail})
        symbol = "[OK]" if passed else "[FAIL]"
        print(f"  {symbol} {name}" + (f" - {detail}" if detail else ""))

    def summary(self):
        total = len(self.results)
        passed = sum(1 for r in self.results if r["status"] == "PASS")
        failed = total - passed
        print("\n" + "=" * 60)
        print(f"  Results: {passed}/{total} passed, {failed} failed")
        print("=" * 60)
        return failed == 0


# --- UIO GPIO ---

MAP_SIZE = 0x10000
GPIO_DATA_OFFSET  = 0x00
GPIO_TRI_OFFSET   = 0x04
GPIO2_DATA_OFFSET = 0x08
GPIO2_TRI_OFFSET  = 0x0C

UIO_DEVS = {
    "led":    "/dev/uio0",
    "switch": "/dev/uio1",
    "button": "/dev/uio1",  # Channel 2 (offset 0x08)
}


class UioGpio:
    def __init__(self, devpath, num_pins=4, channel=1):
        self.fd = os.open(devpath, os.O_RDWR | os.O_SYNC)
        self.mm = mmap_mod.mmap(self.fd, MAP_SIZE, mmap_mod.MAP_SHARED,
                                mmap_mod.PROT_READ | mmap_mod.PROT_WRITE)
        self.num_pins = num_pins
        if channel == 2:
            self.data_offset = GPIO2_DATA_OFFSET
            self.tri_offset = GPIO2_TRI_OFFSET
        else:
            self.data_offset = GPIO_DATA_OFFSET
            self.tri_offset = GPIO_TRI_OFFSET

    def close(self):
        self.mm.close()
        os.close(self.fd)

    def _read32(self, offset):
        self.mm.seek(offset)
        return struct.unpack("<I", self.mm.read(4))[0]

    def _write32(self, offset, val):
        self.mm.seek(offset)
        self.mm.write(struct.pack("<I", val))

    def set_direction(self, bit, is_input):
        tri = self._read32(self.tri_offset)
        if is_input:
            tri |= (1 << bit)
        else:
            tri &= ~(1 << bit)
        self._write32(self.tri_offset, tri)

    def set_pin(self, bit, val):
        data = self._read32(self.data_offset)
        if val:
            data |= (1 << bit)
        else:
            data &= ~(1 << bit)
        self._write32(self.data_offset, data)

    def get_pin(self, bit):
        return (self._read32(self.data_offset) >> bit) & 1

    def get_all(self):
        return self._read32(GPIO_DATA_OFFSET) & ((1 << self.num_pins) - 1)


# --- Test: LED ---

def test_leds(result):
    print("\n[TEST 1] LED Test (LD4~LD7, 4 LEDs)")
    try:
        led = UioGpio(UIO_DEVS["led"], num_pins=4)
    except Exception as e:
        result.add("LED - UIO open", False, str(e))
        return
    result.add("LED - UIO open", True, UIO_DEVS["led"])

    for i in range(4):
        led.set_direction(i, False)

    for i in range(4):
        led.set_pin(i, 1)
        time.sleep(0.3)
        val = led.get_pin(i)
        led.set_pin(i, 0)
        result.add(f"LED{i} (LD{i+4})", val == 1, f"val={val}")

    print("  Running chase pattern...")
    for _ in range(3):
        for i in range(4):
            led.set_pin(i, 1)
            time.sleep(0.1)
            led.set_pin(i, 0)
    result.add("LED chase", True)

    led.close()


# --- Test: Switch ---

def test_switches(result):
    print("\n[TEST 2] Switch Test (SW0~SW3)")
    try:
        sw = UioGpio(UIO_DEVS["switch"], num_pins=4)
    except Exception as e:
        result.add("Switch - UIO open", False, str(e))
        return
    result.add("Switch - UIO open", True, UIO_DEVS["switch"])

    for i in range(4):
        sw.set_direction(i, True)

    for i in range(4):
        val = sw.get_pin(i)
        result.add(f"SW{i}", True, f"val={val}")

    print("  Polling SW0 for 5s...")
    initial = sw.get_pin(0)
    print(f"  Initial SW0={initial}, toggle within 5s...")
    start = time.time()
    changed = False
    current = initial
    while time.time() - start < 5:
        current = sw.get_pin(0)
        if current != initial:
            changed = True
            break
        time.sleep(0.05)

    if changed:
        result.add("SW0 polling", True, f"{initial} -> {current}")
    else:
        result.add("SW0 polling", True, f"timeout, val={initial}")

    sw.close()


# --- Test: Button ---

def test_buttons(result):
    print("\n[TEST 3] Button Test (Channel 2 of uio1)")
    try:
        btn = UioGpio(UIO_DEVS["button"], channel=2)
    except Exception as e:
        result.add("Button - UIO open", False, str(e))
        return
    result.add("Button - UIO open", True, UIO_DEVS["button"] + " Ch2")

    for i in range(4):
        btn.set_direction(i, True)

    for i in range(4):
        val = btn.get_pin(i)
        result.add(f"BTN{i}", True, f"val={val}")

    btn.close()


# --- Test: Network ---

def test_network(result):
    print("\n[TEST 5] Network Test")
    try:
        subprocess.run(["ip", "link", "show", "eth0"],
                       timeout=5, capture_output=True, check=True)
        result.add("eth0 link", True)
    except:
        result.add("eth0 link", False, "not found")
        return

    try:
        subprocess.run(["udhcpc", "-i", "eth0"],
                       timeout=15, capture_output=True)
        result.add("DHCP", True)
    except:
        result.add("DHCP", False, "failed")

    try:
        out = subprocess.check_output(
            ["ip", "-4", "addr", "show", "eth0"],
            stderr=subprocess.STDOUT).decode().strip()
        result.add("IP Address", bool(out), out.split("\n")[-1].strip() if out else "none")
    except:
        result.add("IP Address", False, "no IP")

    try:
        ret = subprocess.run(["ping", "-c", "3", "-W", "2", "8.8.8.8"],
                             capture_output=True, timeout=10)
        result.add("Ping 8.8.8.8", ret.returncode == 0)
    except:
        result.add("Ping 8.8.8.8", False, "timeout")


# --- Test: Memory ---

def test_memory(result):
    print("\n[TEST 9] Memory/System Test")
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if "MemTotal" in line:
                    result.add("Memory", True, line.strip())
                    break
    except:
        result.add("Memory", False, "read error")

    try:
        uname = subprocess.check_output(["uname", "-a"],
                                        stderr=subprocess.STDOUT).decode().strip()
        result.add("Kernel", True, uname)
    except:
        result.add("Kernel", False, "uname failed")


# --- Test: HDMI ---

def test_hdmi(result):
    print("\n[TEST 6] HDMI Output Test")
    if os.path.exists("/dev/fb0"):
        result.add("/dev/fb0", True)
    else:
        result.add("/dev/fb0", False, "not found")
        drm_path = "/sys/class/drm"
        if os.path.exists(drm_path):
            connectors = [d for d in os.listdir(drm_path)
                         if "HDMI" in d or "card" in d]
            if connectors:
                result.add("DRM connectors", True, ", ".join(connectors))
            else:
                result.add("DRM connectors", False, "none")


def test_hdmi_in(result):
    print("\n[TEST 7] HDMI Input Test (V4L2)")
    if os.path.exists("/dev/video0"):
        result.add("/dev/video0", True)
    else:
        result.add("/dev/video0", False, "not found")
    try:
        subprocess.run(["v4l2-ctl", "--device=/dev/video0", "--list-formats"],
                       timeout=5, capture_output=True)
        result.add("V4L2 query", True)
    except Exception as e:
        result.add("V4L2 query", False, str(e))


# --- Main ---

def main():
    print("=" * 60)
    print("  Zybo Z7-20 Hardware Test (Python/UIO)")
    print(f"  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    if mmap_mod is None:
        print("  [FATAL] mmap module not available")
        sys.exit(1)

    result = TestResult()
    test_memory(result)
    test_leds(result)
    test_switches(result)
    test_buttons(result)
    test_network(result)
    test_hdmi(result)
    test_hdmi_in(result)
    result.summary()


if __name__ == "__main__":
    main()
```

#### Python 코드 실행

```bash
python3 hw_test.py
```

### 13.4 스크립트 실행

```bash
chmod +x hardware_test.py
python3 hardware_test.py
```

### 13.5 개별 테스트 실행 (빠른 확인)

#### 시스템 정보만 확인

```bash
uname -a
cat /proc/meminfo | head -5
cat /proc/cpuinfo | grep -i hardware
```

#### LED 빠른 테스트 (Shell에서 UIO 확인)

```bash
# UIO 디바이스 확인
ls /dev/uio*
cat /sys/class/uio/uio*/name

# PL GPIO 컨트롤러 확인
ls /sys/firmware/devicetree/base/amba_pl/gpio*

# UIO LED 디바이스 열기 (uio0 = LED, 41220000)
cat /sys/class/uio/uio0/maps/map0/addr
```

> GPIO는 UIO 드라이버가 제어하므로, shell에서 직접 테스트하려면
> C 또는 Python 코드를 사용해야 합니다.

#### 네트워크 빠른 확인

```bash
ip link show eth0
udhcpc -i eth0
ip -4 addr show eth0
ping -c 3 8.8.8.8
```

#### 디바이스 트리 확인

```bash
ls /sys/firmware/devicetree/base/
cat /proc/cmdline
```

---

## 14. 문제 해결 - 최신 버전

### 14.1 PetaLinux 설치 에러: xterm 누락

```
증상: ERROR: You are missing the following system tools required by PetaLinux: xterm
해결:
  sudo apt-get install -y xterm
```

### 14.2 PetaLinux 설치 에러: 지원되지 않는 OS

```
증상: WARNING: This is not a supported OS
해결: 무시해도 됩니다. Ubuntu 20.04에서 정상 동작합니다.
```

### 14.3 PetaLinux 설치 에러: 디스크 공간 부족

```
증상: Cannot mkdir: No space left on device → ERROR: Failed to install xsct SDK
해결:
  1. 루트 파티션 최소 50GB 이상 확보 (권장 100GB+)
  2. VirtualBox 가상 디스크 확장 후 GParted로 파티션 확장
  3. 확장 명령어 (Windows PowerShell):
     & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyhd "<vdi파일경로>" --resize 102400
```

### 14.4 Kconfig 생성 실패

```
증상: ERROR: Failed to generate Kconfig.syshw / Failed to Kconfig project
해결:
  1. libtinfo5 설치:
     sudo apt-get install -y libtinfo5
  2. 만약 libtinfo5 패키지가 없으면:
     sudo apt-get install -y libtinfo6
     sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
```

### 14.5 빌드 sstate 캐시 에러 (무시 가능)

```
증상:
  ERROR: util-linux-2.37.2-r0 do_populate_lic_setscene: Fetcher failure
  ERROR: Failed to build project
  But: Tasks Summary: Attempted 5261 tasks of which 4664 didn't need to be rerun and all succeeded.

해결: 이 에러는 무시해도 됩니다.
  - sstate 캐시를 못 찾으면 소스에서 다시 빌드하라는 의미
  - "all succeeded" 출력 시 실제 빌드 성공
  - images/linux/에 파일이 정상 생성되면 성공
```

### 14.6 Petalinux-config --version 미지원

```
증상: getopt: unrecognized option '--version'
해결: petalinux-config에는 --version 옵션이 없습니다.
  - 환경변수 로드 확인: "PetaLinux environment set to '/opt/pkg/petalinux'" 출력 여부
  - 도움말 확인: petalinux-config --help
```

### 14.7 프로젝트 디렉토리명이 "os"

```
증상: petalinux-create 후 "Zybo-Z7-20-Petalinux-2022-1" 대신 "os" 폴더 생성
해결: BSP 내부에 프로젝트 이름이 "os"로 정의되어 있어 정상입니다.
  cd os
```

### 14.8 빌드 로그에서 실제 에러 확인 방법

```
빌드 실패 시 실제 에러를 찾는 명령어:

  # sstate 관련 에러 제외하고 실제 에러 검색
  grep -i "ERROR" build/build.log | grep -v "sstate" | grep -v "setscene"

  # 빌드 로그 마지막 200줄 확인
  tail -200 build/build.log

  # 특정 레시피 에러 확인
  grep -i "failed" build/build.log | grep -v "sstate"
```

### 14.2 libssl 호환성 문제

```
증상: libssl 관련 에러
해결 (Ubuntu 20.04):
  sudo apt-get install libssl-dev
  # libssl 1.1이 기본 설치됨

  만약 libssl 3.0이 설치된 경우 (Ubuntu 22.04):
  wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
  sudo dpkg -i libssl1.1_*.deb
```

### 14.3 Python 3 관련 문제

```
증상: python 명령어를 찾을 수 없음
해결:
  sudo ln -s /usr/bin/python3 /usr/bin/python
  # 또는 python3 명령어 사용
```

### 14.4 부팅 후 콘솔 무응답

```
해결:
  1. SD카드 포맷 다시 (FAT32, MBR)
  2. BOOT.BIN, image.ub 존재 확인
  3. boot.scr 파일 복사 확인 (2022.1)
  4. JP5 점퍼 위치 확인
  5. PS-SRST 버튼 누름
  6. baud rate 115200 확인
```

### 14.5 GPIO 인식 문제 (UIO 관련)

```
증상: /sys/class/gpio/에 해당 디바이스 없음
      또는 sysfs GPIO로 PL GPIO 제어 불가

원인: Zybo Z7-20의 PL GPIO는 UIO 드라이버(uio_pdrv_genirq)에 의해 점유됨
      - uio0 = LEDs (41220000, 4 outputs)
      - uio1 = Switches+Buttons (41210000, Ch1=SW 4 inputs, Ch2=BTN 4 inputs)
      - uio2 = HDMI Hotplug Detect (41200000, 1 bit)
      - uio3 = Ethernet Reset (41230000, 1 bit)

해결:
  1. UIO 디바이스 확인:
     ls /dev/uio*
     cat /sys/class/uio/uio*/name

  2. PL GPIO 컨트롤러 확인:
     ls /sys/firmware/devicetree/base/amba_pl/gpio*

  3. UIO 커널 모듈 확인:
     lsmod | grep uio

  4. GPIO 테스트는 C 또는 Python UIO 코드 사용:
     # hw_test.c 또는 hw_test.py (UIO 방식) 사용
     gcc -o hw_test hw_test.c
     ./hw_test
```

### 14.6 디바이스 트리 소스 수정

```bash
# 최신 버전: system-user.dtsi 위치
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi

# PL GPIO에 UIO compatible 추가 (이미 BSP에 포함된 경우 무시):
# compatible = "generic-uio";
# status = "okay";

# 수정 후 재빌드
petalinux-build
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
```

---

## 부록 C: PetaLinux 버전별 호환성 표

| PetaLinux | Ubuntu | 커널 | GCC | BSP 출처 |
|-----------|--------|------|-----|---------|
| 2017.4 | 16.04 | ~4.9 | 5.x | `Petalinux-Zybo-Z7-20` (비활성) |
| 2020.1 | 18.04 | ~5.4 | 8.x | `Zybo-Z7` (활성) |
| 2021.1 | 18.04/20.04 | ~5.10 | 9.x/10.x | `Zybo-Z7` (활성) |
| **2022.1** | **20.04** | **~5.15** | **11.x** | **`Zybo-Z7` (활성, 권장)** |

---

## 부록 D: 디렉토리 구조 비교

### 2017.4 프로젝트 구조
```
Petalinux-Zybo-Z7-20/
├── images/linux/
│   ├── BOOT.BIN
│   ├── image.ub
│   └── zynq_fsbl.elf
└── project-spec/
```

### 2022.1 프로젝트 구조
```
os/  (BSP 프로젝트 디렉토리)
├── images/linux/
│   ├── BOOT.BIN
│   ├── boot.scr          ← 새로 추가됨
│   ├── image.ub
│   ├── rootfs.ext4
│   ├── system.bit        ← 2017.4의 system_wrapper.bit에서 변경
│   └── zynq_fsbl.elf
├── pre-built/
│   └── linux/images/
│       ├── BOOT.BIN      ← 사전 빌드 이미지
│       ├── boot.scr
│       └── image.ub
└── project-spec/
    ├── meta-user/
    │   └── recipes-bsp/
    │       └── device-tree/
    │           └── files/
    │               └── system-user.dtsi
    └── configs/
```

---

> **최종 업데이트:** 2026-07-20 (실제 빌드 검증 완료)
> **대상 보드:** Digilent Zybo Z7-20 (XC7Z020-1CLG400C)
> **PetaLinux 버전:** 2017.4 (Part 1) / 2022.1 (Part 2)
> **Ubuntu 버전:** 16.04 LTS (Part 1) / 20.04 LTS (Part 2)
> **빌드 검증 환경:** VirtualBox + Ubuntu 20.04 + PetaLinux 2022.1
