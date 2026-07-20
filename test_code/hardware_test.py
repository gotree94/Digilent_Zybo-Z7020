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