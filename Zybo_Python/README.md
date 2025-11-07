# ZYBO Python MIO

<img width="514" height="487" alt="019" src="https://github.com/user-attachments/assets/79e1df63-061c-43a6-8111-a604efad5b0b" />

1. 커널 설정 - GPIO 드라이버 활성화
먼저 GPIO 인터페이스를 활성화해야 합니다.
```bash
cd  ~/projects/myproject

# 커널 설정
petalinux-config -c kernel
```

다음 옵션들을 활성화하세요:
```
Device Drivers --->
    GPIO Support --->
        [*] /sys/class/gpio/... (sysfs interface)
        [*] Debug GPIO calls
        <*> Memory mapped GPIO drivers --->
            <*> Xilinx Zynq GPIO support
```
저장 후 종료합니다.

<img width="564" height="358" alt="001" src="https://github.com/user-attachments/assets/56058530-8cbf-4f75-90b6-47e2bda452bb" />
<br>
<img width="557" height="358" alt="002" src="https://github.com/user-attachments/assets/55aa338b-583d-460a-9e68-46a8b59d06e9" />
<br>
<img width="556" height="353" alt="003" src="https://github.com/user-attachments/assets/ffa4c2c6-463a-4f95-8691-d7b42002d70c" />
<br>
<img width="555" height="356" alt="004" src="https://github.com/user-attachments/assets/009760b4-5881-4919-974e-b46c50b969ba" />
<br>
<img width="556" height="357" alt="005" src="https://github.com/user-attachments/assets/4d8dcc15-2211-40d3-9e20-9fcf69e2d9d5" />
<br>
<img width="555" height="354" alt="006" src="https://github.com/user-attachments/assets/ac6ce0e0-294c-496f-876d-707cbf560001" />
<br>
<img width="555" height="359" alt="007" src="https://github.com/user-attachments/assets/0bbb9aa8-b97f-44e6-bcaa-0b50e1780a5c" />
<br>

2. RootFS 설정 - Python 및 필수 패키지 추가

```bash
cd ~/projects/myproject

# RootFS 설정
petalinux-config -c rootfs
```

다음 패키지들을 활성화하세요:

```
Filesystem Packages --->
    misc --->
        python3 --->
            [*] python3
            [*] python3-core
            [*] python3-modules
    devel --->
        python3-numpy --->
            [*] python3-numpy
    
    console/utils --->
        [*] vim
        [*] nano
```
저장 후 종료합니다.

<img width="556" height="356" alt="001" src="https://github.com/user-attachments/assets/a06e32ef-fa77-48d7-a7ca-58bbc478622f" />
<br>
<img width="557" height="358" alt="002" src="https://github.com/user-attachments/assets/f28c68ff-6129-4ba7-8ad6-d5fdc9a6fa9b" />
<br>
<img width="558" height="362" alt="003" src="https://github.com/user-attachments/assets/f3126b8b-9d3b-47cf-a4b9-94a73ad0d3f6" />
<br>
<img width="556" height="357" alt="004" src="https://github.com/user-attachments/assets/e43122a8-d4bb-4f79-826b-c30e9d2c1228" />
<br>

3. Python GPIO 제어 스크립트 작성
프로젝트 디렉토리에 Python 스크립트를 만듭니다:
```bash
cd ~/projects/myproject
```
# 사용자 애플리케이션 디렉토리 생성
```
mkdir -p project-spec/meta-user/recipes-apps/mio-control
cd project-spec/meta-user/recipes-apps/mio-control
```

3.1 Python 스크립트 생성
files/mio_control.py 파일을 생성합니다:
```bash
mkdir -p files
vi files/mio_control.py
```

다음 내용을 입력합니다:

```python

#!/usr/bin/env python3

"""
Zybo Z7-20 MIO 핀 제어 예제
- MIO5, MIO50: 버튼 입력
- MIO7: LED 출력
"""

import os
import sys
import time

class GPIOController:
    """GPIO 제어 클래스"""
    
    GPIO_BASE_PATH = "/sys/class/gpio"
    
    def __init__(self, gpio_num):
        self.gpio_num = gpio_num
        self.gpio_path = f"{self.GPIO_BASE_PATH}/gpio{gpio_num}"
        
    def export(self):
        """GPIO 핀 export"""
        if not os.path.exists(self.gpio_path):
            try:
                with open(f"{self.GPIO_BASE_PATH}/export", "w") as f:
                    f.write(str(self.gpio_num))
                time.sleep(0.1)  # export 후 안정화 대기
                print(f"GPIO{self.gpio_num} exported")
            except IOError as e:
                print(f"Failed to export GPIO{self.gpio_num}: {e}")
                return False
        else:
            print(f"GPIO{self.gpio_num} already exported")
        return True
    
    def unexport(self):
        """GPIO 핀 unexport"""
        if os.path.exists(self.gpio_path):
            try:
                with open(f"{self.GPIO_BASE_PATH}/unexport", "w") as f:
                    f.write(str(self.gpio_num))
                print(f"GPIO{self.gpio_num} unexported")
            except IOError as e:
                print(f"Failed to unexport GPIO{self.gpio_num}: {e}")
    
    def set_direction(self, direction):
        """GPIO 방향 설정 (in/out)"""
        try:
            with open(f"{self.gpio_path}/direction", "w") as f:
                f.write(direction)
            print(f"GPIO{self.gpio_num} direction set to {direction}")
            return True
        except IOError as e:
            print(f"Failed to set direction for GPIO{self.gpio_num}: {e}")
            return False
    
    def write(self, value):
        """GPIO 출력 (0 or 1)"""
        try:
            with open(f"{self.gpio_path}/value", "w") as f:
                f.write(str(value))
            return True
        except IOError as e:
            print(f"Failed to write to GPIO{self.gpio_num}: {e}")
            return False
    
    def read(self):
        """GPIO 입력 읽기"""
        try:
            with open(f"{self.gpio_path}/value", "r") as f:
                value = int(f.read().strip())
            return value
        except IOError as e:
            print(f"Failed to read from GPIO{self.gpio_num}: {e}")
            return None
    
    def set_edge(self, edge):
        """인터럽트 엣지 설정 (none/rising/falling/both)"""
        try:
            with open(f"{self.gpio_path}/edge", "w") as f:
                f.write(edge)
            print(f"GPIO{self.gpio_num} edge set to {edge}")
            return True
        except IOError as e:
            print(f"Failed to set edge for GPIO{self.gpio_num}: {e}")
            return False


def test_led_blink(led_gpio):
    """LED 깜빡임 테스트"""
    print("\n=== LED Blink Test (MIO7) ===")
    print("LED를 10번 깜빡입니다...")
    
    for i in range(10):
        led_gpio.write(1)  # LED ON
        print(f"  {i+1}. LED ON")
        time.sleep(0.5)
        
        led_gpio.write(0)  # LED OFF
        print(f"  {i+1}. LED OFF")
        time.sleep(0.5)


def test_button_polling(btn5_gpio, btn50_gpio, led_gpio):
    """버튼 폴링 테스트"""
    print("\n=== Button Polling Test ===")
    print("버튼을 눌러보세요:")
    print("  - MIO5 버튼: LED ON")
    print("  - MIO50 버튼: LED OFF")
    print("  - 두 버튼 동시: 종료")
    print("Ctrl+C로도 종료 가능합니다.\n")
    
    try:
        while True:
            btn5_state = btn5_gpio.read()
            btn50_state = btn50_gpio.read()
            
            # 버튼은 Active-Low (눌렀을 때 0)
            if btn5_state == 0 and btn50_state == 0:
                print("두 버튼 동시 누름 - 종료합니다.")
                led_gpio.write(0)
                break
            elif btn5_state == 0:
                print("MIO5 버튼 눌림 - LED ON")
                led_gpio.write(1)
                time.sleep(0.2)  # 디바운싱
            elif btn50_state == 0:
                print("MIO50 버튼 눌림 - LED OFF")
                led_gpio.write(0)
                time.sleep(0.2)  # 디바운싱
            
            time.sleep(0.1)  # CPU 사용률 낮추기
            
    except KeyboardInterrupt:
        print("\n\n프로그램을 종료합니다.")
        led_gpio.write(0)


def test_pwm_led(led_gpio):
    """LED PWM 효과 테스트"""
    print("\n=== LED PWM Test ===")
    print("LED 밝기 조절 효과를 시뮬레이션합니다...")
    
    try:
        for cycle in range(3):  # 3번 반복
            print(f"\n사이클 {cycle+1}/3")
            
            # 점점 밝아지기
            print("  밝아지는 중...")
            for duty in range(0, 101, 5):
                on_time = duty / 1000.0
                off_time = (100 - duty) / 1000.0
                
                for _ in range(10):  # 각 duty cycle에서 10번 반복
                    if duty > 0:
                        led_gpio.write(1)
                        time.sleep(on_time)
                    if duty < 100:
                        led_gpio.write(0)
                        time.sleep(off_time)
            
            # 점점 어두워지기
            print("  어두워지는 중...")
            for duty in range(100, -1, -5):
                on_time = duty / 1000.0
                off_time = (100 - duty) / 1000.0
                
                for _ in range(10):
                    if duty > 0:
                        led_gpio.write(1)
                        time.sleep(on_time)
                    if duty < 100:
                        led_gpio.write(0)
                        time.sleep(off_time)
        
        led_gpio.write(0)
        print("\nPWM 테스트 완료!")
        
    except KeyboardInterrupt:
        print("\n\nPWM 테스트를 중단합니다.")
        led_gpio.write(0)


def main():
    """메인 함수"""
    # Zybo Z7-20 MIO 핀 번호
    MIO5_BTN = 905   # 버튼 (실제 GPIO 번호는 시스템에 따라 다를 수 있음)
    MIO50_BTN = 950  # 버튼
    MIO7_LED = 907   # LED
    
    print("="*50)
    print("Zybo Z7-20 MIO 제어 예제")
    print("="*50)
    
    # GPIO 객체 생성
    btn5 = GPIOController(MIO5_BTN)
    btn50 = GPIOController(MIO50_BTN)
    led = GPIOController(MIO7_LED)
    
    try:
        # GPIO export
        if not (btn5.export() and btn50.export() and led.export()):
            print("GPIO export 실패")
            sys.exit(1)
        
        # GPIO 방향 설정
        btn5.set_direction("in")
        btn50.set_direction("in")
        led.set_direction("out")
        
        # 초기 LED 상태
        led.write(0)
        
        # 테스트 메뉴
        while True:
            print("\n" + "="*50)
            print("테스트 메뉴:")
            print("  1. LED 깜빡임 테스트")
            print("  2. 버튼 입력 테스트")
            print("  3. LED PWM 효과 테스트")
            print("  4. 종료")
            print("="*50)
            
            choice = input("선택하세요 (1-4): ").strip()
            
            if choice == "1":
                test_led_blink(led)
            elif choice == "2":
                test_button_polling(btn5, btn50, led)
            elif choice == "3":
                test_pwm_led(led)
            elif choice == "4":
                print("프로그램을 종료합니다.")
                break
            else:
                print("잘못된 선택입니다. 다시 선택해주세요.")
        
    except Exception as e:
        print(f"오류 발생: {e}")
    
    finally:
        # 정리
        led.write(0)
        btn5.unexport()
        btn50.unexport()
        led.unexport()
        print("\nGPIO 정리 완료")


if __name__ == "__main__":
    main()
```
3.2 BitBake 레시피 생성
mio-control_1.0.bb 파일을 생성합니다:
```bash
vi mio-control_1.0.bb
```

다음 내용을 입력합니다:
```bitbake
SUMMARY = "MIO Control Python Application"
DESCRIPTION = "Python script to control Zybo Z7-20 MIO pins"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://mio_control.py"

S = "${WORKDIR}"

RDEPENDS_${PN} = "python3-core"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mio_control.py ${D}${bindir}/mio-control
}

FILES_${PN} = "${bindir}/mio-control"
```

3.3 RootFS에 애플리케이션 추가

```bash
cd ~/projects/myproject
petalinux-config -c rootfs
```

다음 경로로 이동하여 활성화:
```
Filesystem Packages --->
    user packages --->
        [*] mio-control
```

저장 후 종료합니다.

4. Device Tree 수정 (중요!)

MIO 핀을 GPIO로 사용하려면 Device Tree를 수정해야 합니다:
```
bashcd ~/projects/myproject
vi project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```
다음 내용을 추가합니다:

```dts
/include/ "system-conf.dtsi"

/ {
    chosen {
        bootargs = "console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootwait";
    };
};

&gpio0 {
    status = "okay";
};

/* MIO 핀 정의 */
&pinctrl0 {
    pinctrl_gpio_mio: gpio-mio-pins {
        mux {
            groups = "gpio0_5_grp", "gpio0_7_grp", "gpio0_50_grp";
            function = "gpio0";
        };
        
        conf {
            groups = "gpio0_5_grp", "gpio0_7_grp", "gpio0_50_grp";
            slew-rate = <0>;
            io-standard = <1>;
        };
    };
};
```

5. 빌드 및 배포

```bash
cd ~/projects/myproject

# 전체 빌드
petalinux-build

# BOOT.BIN 재생성
petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

# WIC 이미지 생성
petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
```

6. SD 카드에 이미지 쓰기
```bash

# SD 카드 장치 확인
lsblk

# WIC 이미지 쓰기 (sdX는 실제 SD 카드 장치명으로 변경)
sudo dd if=images/linux/petalinux-sdimage.wic of=/dev/sdX bs=4M status=progress
sudo sync
```

7. 보드에서 실행
SD 카드를 Zybo Z7-20에 삽입하고 부팅 후:
```bash
# 루트로 로그인 (비밀번호: root)

# GPIO 번호 확인 (실제 번호는 다를 수 있음)
ls /sys/class/gpio/

# 스크립트 실행
mio-control

# 또는
python3 /usr/bin/mio-control
```

8. GPIO 번호 확인 방법
실제 MIO 핀의 GPIO 번호를 확인하려면:
```bash
# 보드 부팅 후
cat /sys/kernel/debug/gpio

# 또는
gpioinfo
스크립트의 MIO 번호(MIO5_BTN, MIO50_BTN, MIO7_LED)를 실제 GPIO 번호로 수정해야 할 수 있습니다.
```
