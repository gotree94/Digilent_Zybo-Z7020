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
13. [보드 동작 테스트 (Python) - 최신 버전](#13-보드-동작-테스트-python---최신-버전)
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
    device-tree-compiler
```

> **2017.4와의 차이점:**
> - `libncurses5-dev` → `libncursesw5-dev` 추가
> - `python3-pip` 명시적 설치
> - `device-tree-compiler` 추가
> - `net-tools` 대신 `iproute2` 사용 권장 (기본 포함)

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
   - 파일명 예: `petalinux-v2022.1-final-installer.run`
   - Xilinx 계정 로그인 필요

```bash
cd ~/Downloads
chmod +x petalinux-v2022.1-final-installer.run
./petalinux-v2022.1-final-installer.run /opt/pkg/petalinux
```

> 설치 중 라이센스 동의 화면에서 `y`를 눌러 진행

### 10.3 환경변수 설정

```bash
# 새 터미널에서 매번 실행
source /opt/pkg/petalinux/settings.sh

# 확인
petalinux-config --version
# 예상 출력: PetaLinux 2022.1
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

> 디렉토리 이름은 BSP 파일 이름에서 파생됩니다.
> 예: `Zybo-Z7-20-Petalinux-2022-1` 폴더 생성

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
    --fpga images/linux/system_wrapper.bit \
    --u-boot
```

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
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system_wrapper.bit --u-boot
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

---

## 13. 보드 동작 테스트 (Python) - 최신 버전

### 13.1 테스트 환경 준비

부팅 후 시리얼 콘솔 또는 SSH에서:

```bash
# Python 3 확인 (2022.1 이미지에 포함)
python3 --version

# pip가 없을 경우
python3 -m ensurepip 2>/dev/null || true

# pyserial 설치 (UART 테스트용)
pip3 install pyserial 2>/dev/null || true
```

### 13.2 테스트 스크립트 파일 전송

```bash
# SCP 사용 (이더넷 연결 시)
scp hardware_test.py root@<BOARD_IP>:/home/root/

# 또는 직접 붙여넣기
cat > /home/root/hardware_test.py << 'EOF'
# (아래 스크립트 내용)
EOF
```

### 13.3 최신 버전 호환 테스트 스크립트

> 2022.1 커널에서의 변경사항 반영:
> - Python 3 전용
> - sysfs GPIO 경로 변경 대응
> - V4L2 디바이스 이름 변경 대응

```python
#!/usr/bin/env python3
"""
Zybo Z7-20 하드웨어 종합 테스트 스크립트 (PetaLinux 2022.1 호환)
테스트 대상: LED, 스위치, 버튼, 이더넷, UART, HDMI 출력, HDMI 입력, Pcam
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
    UIO 드라이버 또는 sysfs GPIO로 제어
    """
    print("\n[테스트 1] LED 테스트")

    # 방법 1: gpiochip label 방식
    gpio_base = find_gpio_chip_by_label("led")
    if gpio_base is not None:
        result.add("LED - GPIO 칩 (label)", True, gpio_base)
        pins = [0, 1, 2, 3]
        for pin in pins:
            gpio_num = get_gpio_number(gpio_base, pin)
            if gpio_num is None:
                result.add(f"LED {pin} - GPIO 번호 실패", False)
                continue
            try:
                export_gpio(gpio_num)
                set_gpio_direction(gpio_num, "out")
                set_gpio_value(gpio_num, 1)
                time.sleep(0.5)
                val = get_gpio_value(gpio_num)
                set_gpio_value(gpio_num, 0)
                passed = (val == "1")
                result.add(f"LED {pin} 점등", passed, f"값: {val}")
                unexport_gpio(gpio_num)
            except Exception as e:
                result.add(f"LED {pin} 테스트", False, str(e))
        return

    # 방법 2: 직접 GPIO 번호 사용 (디바이스 트리에서 확인)
    print("  GPIO 칩 label 미발견, 직접 번호로 시도...")
    try:
        gpio_nums = discover_gpio_by_direction("out")
        if gpio_nums:
            result.add("LED - GPIO 출력 핀 탐색", True, f"{len(gpio_nums)}개 출력 핀 발견")
            for i, gpio_num in enumerate(gpio_nums[:4]):
                try:
                    export_gpio(gpio_num)
                    set_gpio_direction(gpio_num, "out")
                    set_gpio_value(gpio_num, 1)
                    time.sleep(0.3)
                    val = get_gpio_value(gpio_num)
                    set_gpio_value(gpio_num, 0)
                    result.add(f"LED GPIO{gpio_num} 점등", val == "1")
                    unexport_gpio(gpio_num)
                except Exception as e:
                    result.add(f"LED GPIO{gpio_num} 테스트", False, str(e))
        else:
            result.add("LED - GPIO 출력 핀 없음", False)
    except Exception as e:
        result.add("LED 테스트 전체", False, str(e))


def test_led_chase(result):
    """LED chase 패턴 테스트"""
    print("\n[테스트 1b] LED chase 패턴")

    gpio_base = find_gpio_chip_by_label("led")
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
    """
    print("\n[테스트 2] 스위치 테스트")

    gpio_base = find_gpio_chip_by_label("switch")
    if gpio_base is None:
        result.add("스위치 - GPIO 칩 검색", False, "스위치 GPIO 없음")
        return

    result.add("스위치 - GPIO 칩 검색", True, gpio_base)

    for pin in [0, 1]:
        gpio_num = get_gpio_number(gpio_base, pin)
        if gpio_num is None:
            result.add(f"스위치 {pin} - GPIO 번호 실패", False)
            continue
        try:
            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "in")
            val = get_gpio_value(gpio_num)
            result.add(f"스위치 {pin} 읽기", True, f"값: {val}")
            unexport_gpio(gpio_num)
        except Exception as e:
            result.add(f"스위치 {pin} 읽기", False, str(e))


def test_switch_interrupt(result):
    """스위치 변화 인터럽트 테스트 (5초 polling)"""
    print("\n[테스트 2b] 스위치 변화 감지 (5초 대기)")

    gpio_base = find_gpio_chip_by_label("switch")
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
            result.add("스위치 변화 감지", True, f"변화 없음 (값: {initial_val}, 5초 타임아웃)")

    except Exception as e:
        result.add("스위치 변화 감지", False, str(e))


# ─── 3. 버튼 테스트 ────────────────────────────────────────────────

def test_buttons(result):
    """
    Zybo Z7-20: 3개 push 버튼 (BTN0~BTN2)
    """
    print("\n[테스트 3] 버튼 테스트")

    gpio_base = find_gpio_chip_by_label("button")
    if gpio_base is None:
        result.add("버튼 - GPIO 칩 검색", False, "버튼 GPIO 없음")
        return

    result.add("버튼 - GPIO 칩 검색", True, gpio_base)

    for pin in [0, 1, 2]:
        gpio_num = get_gpio_number(gpio_base, pin)
        if gpio_num is None:
            result.add(f"버튼 {pin} - GPIO 번호 실패", False)
            continue
        try:
            export_gpio(gpio_num)
            set_gpio_direction(gpio_num, "in")
            val = get_gpio_value(gpio_num)
            result.add(f"버튼 {pin} 읽기", True, f"값: {val} (기본 0 권장)")
            unexport_gpio(gpio_num)
        except Exception as e:
            result.add(f"버튼 {pin} 읽기", False, str(e))


# ─── 4. UART 루프백 테스트 ─────────────────────────────────────────

def test_uart_loopback(result):
    """
    UART 루프백 테스트 (TX ↔ RX 직접 연결 필요)
    """
    print("\n[테스트 4] UART 루프백 테스트")

    uart_port = None
    # PS UART (ttyPS0)는 콘솔로 사용 중 → ttyPS1 또는 USB-UART 탐색
    candidates = ["/dev/ttyPS1", "/dev/ttyUSB0", "/dev/ttyS0"]
    for p in candidates:
        if os.path.exists(p):
            uart_port = p
            break

    if uart_port is None:
        result.add("UART - 사용 가능한 포트 없음", False)
        return

    result.add("UART - 포트 검색", True, uart_port)

    try:
        import serial
        ser = serial.Serial(uart_port, 115200, timeout=2)
        test_data = b"ZyboUART2022"
        ser.write(test_data)
        time.sleep(0.1)
        received = ser.read(ser.in_waiting or len(test_data))
        ser.close()

        passed = (received == test_data)
        result.add("UART 루프백", passed, f"송신: {test_data}, 수신: {received}")

    except ImportError:
        try:
            subprocess.run(["stty", "-F", uart_port, "115200", "raw"], check=True)
            with open(uart_port, "r+b", buffering=0) as f:
                test_data = b"ZyboUART2022"
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

    try:
        ip_output = subprocess.check_output(
            ["ip", "addr", "show"], stderr=subprocess.STDOUT
        ).decode()

        if "eth0" in ip_output:
            result.add("네트워크 - eth0 인터페이스", True)
        elif "eth" in ip_output or "enp" in ip_output:
            result.add("네트워크 - 이더넷 인터페이스", True)
        else:
            result.add("네트워크 - 이더넷 인터페이스", False, "eth0 없음")
            return
    except Exception as e:
        result.add("네트워크 - 인터페이스 검색", False, str(e))
        return

    try:
        subprocess.run(["dhclient", "-v", "eth0"],
                       timeout=15, capture_output=True, check=True)
        result.add("네트워크 - DHCP", True)
    except Exception as e:
        result.add("네트워크 - DHCP", False, str(e))

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

    try:
        ping_result = subprocess.run(
            ["ping", "-c", "3", "-W", "2", "8.8.8.8"],
            capture_output=True, timeout=10
        )
        passed = ping_result.returncode == 0
        result.add("네트워크 - Ping 8.8.8.8", passed,
                   "외부 인터넷 연결" if passed else "외부 연결 실패")
    except Exception as e:
        result.add("네트워크 - Ping", False, str(e))

    try:
        nslookup = subprocess.run(
            ["nslookup", "google.com"],
            capture_output=True, timeout=5
        )
        result.add("네트워크 - DNS 조회", nslookup.returncode == 0)
    except Exception as e:
        result.add("네트워크 - DNS 조회", False, str(e))


# ─── 6. HDMI 출력 테스트 ──────────────────────────────────────────

def test_hdmi_output(result):
    """HDMI 출력 프레임버퍼 테스트"""
    print("\n[테스트 6] HDMI 출력 테스트")

    fb_path = "/dev/fb0"
    if not os.path.exists(fb_path):
        # 2022.1: DRM 기반일 수 있음
        drm_path = "/sys/class/drm"
        if os.path.exists(drm_path):
            connectors = [d for d in os.listdir(drm_path) if "HDMI" in d or "card" in d]
            if connectors:
                result.add("HDMI 출력 - DRM 커넥터", True, ", ".join(connectors))
            else:
                result.add("HDMI 출력 - 프레임버퍼/DRM 없음", False, "/dev/fb0 및 HDMI DRM 없음")
        else:
            result.add("HDMI 출력 - 프레임버퍼 없음", False, "/dev/fb0 없음")
        return

    try:
        fb_info = subprocess.check_output(
            ["cat", "/sys/class/graphics/fb0/virtual_size"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        result.add("HDMI 출력 - 프레임버퍼 크기", True, fb_info)
    except Exception as e:
        result.add("HDMI 출력 - 프레임버퍼 정보", False, str(e))

    try:
        test_cmd = """
try:
    with open('/dev/fb0', 'rb+') as fb:
        w, h = 1280, 720
        red = b'\\x00\\x00\\xff\\xff' * w
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
        print(f"    {v4l2.strip().replace(chr(10), chr(10) + '    ')}")
    except FileNotFoundError:
        result.add("HDMI 입력 - v4l2-ctl 없음", False)
    except Exception as e:
        result.add("HDMI 입력 - V4L2 확인", False, str(e))

    try:
        capture_cmd = """
import subprocess
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
    """Digilent Pcam 5C 카메라 테스트"""
    print("\n[테스트 8] Pcam 5C 카메라 테스트")

    media_dev = "/dev/media0"
    video_dev = "/dev/video0"

    if not os.path.exists(media_dev):
        result.add("Pcam - /dev/media0", False, "미디어 디바이스 없음")
        return

    result.add("Pcam - /dev/media0 존재", True)

    try:
        media_info = subprocess.check_output(
            ["media-ctl", "-d", "/dev/media0", "-p"],
            stderr=subprocess.STDOUT, timeout=5
        ).decode()
        has_ov5640 = "ov5640" in media_info or "camera" in media_info.lower()
        result.add("Pcam - MIPI CSI 디바이스", has_ov5640,
                   "ov5640 감지" if has_ov5640 else "ov5640 미감지")
    except FileNotFoundError:
        result.add("Pcam - media-ctl 없음", False)
    except Exception as e:
        result.add("Pcam - MIPI CSI 확인", False, str(e))

    if os.path.exists(video_dev):
        try:
            capture_cmd = """
import subprocess, os
try:
    r = subprocess.run(
        ['v4l2-ctl', '-d', '/dev/video0',
         '--set-fmt-video=width=640,height=480,pixelformat=YUYV',
         '--stream-mmap', '--stream-count=1', '--stream-to=/tmp/test_frame.raw'],
        capture_output=True, timeout=10
    )
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
        result.add("Pcam - /dev/video0 없음", False)


# ─── 9. 파일시스템 및 메모리 테스트 ────────────────────────────────

def test_filesystem(result):
    """메모리 및 저장장치 테스트"""
    print("\n[테스트 9] 파일시스템/메모리 테스트")

    try:
        meminfo = subprocess.check_output(["cat", "/proc/meminfo"],
                                          stderr=subprocess.STDOUT).decode()
        for line in meminfo.split("\n"):
            if "MemTotal" in line:
                result.add("메모리 총량", True, line.strip())
                break
    except Exception as e:
        result.add("메모리 확인", False, str(e))

    try:
        mounts = subprocess.check_output(["mount"], stderr=subprocess.STDOUT).decode()
        if "mmcblk0" in mounts:
            result.add("SD카드 마운트", True, "mmcblk0 감지됨")
        else:
            result.add("SD카드 마운트", True, "initramfs 모드")
    except Exception as e:
        result.add("SD카드 마운트 확인", False, str(e))

    try:
        cpuinfo = subprocess.check_output(["cat", "/proc/cpuinfo"],
                                          stderr=subprocess.STDOUT).decode()
        if "Zynq" in cpuinfo or "ARMv7" in cpuinfo or "A9" in cpuinfo:
            result.add("CPU 정보", True, "Zynq-7000 시리즈 확인")
        else:
            first_line = [l for l in cpuinfo.split("\n") if "Hardware" in l]
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

def find_gpio_chip_by_label(keyword):
    """gpiochip label에서 키워드 검색 (대소문자 무시)"""
    base_path = "/sys/class/gpio"
    if not os.path.exists(base_path):
        return None

    for entry in sorted(os.listdir(base_path)):
        if entry.startswith("gpiochip"):
            label_path = os.path.join(base_path, entry, "label")
            if os.path.exists(label_path):
                with open(label_path, "r") as f:
                    label = f.read().strip().lower()
                    if keyword.lower() in label:
                        return os.path.join(base_path, entry)

    # 키워드 미매칭 시 첫 번째 칩 반환
    chips = [e for e in os.listdir(base_path) if e.startswith("gpiochip")]
    if chips:
        return os.path.join(base_path, sorted(chips)[0])
    return None


def get_gpio_number(gpiochip_path, pin_offset):
    """GPIO 칩 base + offset으로 실제 GPIO 번호 계산"""
    try:
        with open(os.path.join(gpiochip_path, "base")) as f:
            base = int(f.read().strip())
        with open(os.path.join(gpiochip_path, "ngpio")) as f:
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
    path = f"/sys/class/gpio/gpio{gpio_num}/value"
    with open(path, "r") as f:
        return f.read().strip()


def discover_gpio_by_direction(direction):
    """지정된 direction을 가진 모든 GPIO 번호 탐색"""
    gpio_path = "/sys/class/gpio"
    found = []
    if not os.path.exists(gpio_path):
        return found
    for entry in os.listdir(gpio_path):
        if entry.startswith("gpio") and entry[4:].isdigit():
            dir_path = os.path.join(gpio_path, entry, "direction")
            if os.path.exists(dir_path):
                with open(dir_path, "r") as f:
                    if f.read().strip() == direction:
                        found.append(int(entry[4:]))
    return sorted(found)


# ─── 메인 ──────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  Zybo Z7-20 하드웨어 종합 테스트 (PetaLinux 2022.1 호환)")
    print(f"  실행 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    result = TestResult()

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

    all_passed = result.summary()

    report = {
        "timestamp": datetime.now().isoformat(),
        "petalinux_version": "2022.1",
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

### 13.4 스크립트 실행

```bash
chmod +x hardware_test.py
python3 hardware_test.py
```

### 13.5 개별 테스트 실행 (선택)

#### LED 빠른 테스트

```bash
python3 -c "
import os, time

base = None
for chip in sorted(os.listdir('/sys/class/gpio')):
    if chip.startswith('gpiochip'):
        lp = f'/sys/class/gpio/{chip}/label'
        if os.path.exists(lp):
            with open(lp) as f:
                if 'led' in f.read().lower():
                    with open(f'/sys/class/gpio/{chip}/base') as fb:
                        base = int(fb.read().strip())
                    break

if base is None:
    print('LED GPIO 미발견'); exit(1)

for i in range(4):
    g = base + i
    os.system(f'echo {g} > /sys/class/gpio/export')
    os.system(f'echo out > /sys/class/gpio/gpio{g}/direction')
    os.system(f'echo 1 > /sys/class/gpio/gpio{g}/value')
    time.sleep(0.3)
    os.system(f'echo 0 > /sys/class/gpio/gpio{g}/value')
    os.system(f'echo {g} > /sys/class/gpio/unexport')
print('LED 테스트 완료')
"
```

#### 네트워크 빠른 확인

```bash
hostname -I && ping -c 3 8.8.8.8
```

---

## 14. 문제 해결 - 최신 버전

### 14.1 PetaLinux 2022.1 빌드 에러

```
증상: petalinux-build 중 에러 발생
해결:
  1. RAM 8GB 이상 확보 (16GB 권장)
  2. 디스크 50GB 이상 여유 확인
  3. 이전 빌드 잔여물 정리:
     petalinux-build -x mrproper
  4. 소스 클론 시 --recursive 포함 확인
  5. 빌드 로그 확인:
     build/tmp/log/coordinator.log
     build/tmp/log/petalinux-build.log
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

### 14.5 GPIO 인식 문제

```
증상: /sys/class/gpio/에 해당 디바이스 없음
해결:
  1. UIO 커널 모듈 확인:
     lsmod | grep uio
  2. 모듈 로드:
     modprobe uio_pdrv_genirq
  3. 디바이스 트리 확인:
     ls /sys/firmware/devicetree/base/
  4. bootargs 확인:
     cat /proc/cmdline
     # uio_pdrv_genirq.of_id=generic-uio 포함 여부
```

### 14.6 디바이스 트리 소스 수정

```bash
# 최신 버전: system-user.dtsi 위치
nano project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi

# 수정 후 재빌드
petalinux-build
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system_wrapper.bit --u-boot
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
Zybo-Z7-20-Petalinux-2022-1/
├── images/linux/
│   ├── BOOT.BIN
│   ├── boot.scr          ← 새로 추가됨
│   ├── image.ub
│   ├── rootfs.ext4
│   ├── system_wrapper.bit
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

> **최종 업데이트:** 2026-07-20
> **대상 보드:** Digilent Zybo Z7-20 (XC7Z020-1CLG400C)
> **PetaLinux 버전:** 2017.4 (Part 1) / 2022.1 (Part 2)
> **Ubuntu 버전:** 16.04 LTS (Part 1) / 20.04 LTS (Part 2)
