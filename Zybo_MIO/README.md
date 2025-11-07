# Digilent Zybo Z7-20 PetaLinux : PS/PL GPIO

<img width="495" height="488" alt="023" src="https://github.com/user-attachments/assets/afda69d2-ebfb-4386-aa20-884d4a5d97f5" />

## Zybo MIO GPIO Test

```
# /home/root/test_gpio.sh
#!/bin/sh
```

---

```
echo "=== GPIO Test ==="

# LED 초기화
echo 913 > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio913/direction

# 스위치 초기화
echo 956 > /sys/class/gpio/export 2>/dev/null
echo in > /sys/class/gpio/gpio956/direction
echo 957 > /sys/class/gpio/export 2>/dev/null
echo in > /sys/class/gpio/gpio957/direction

# LED 깜빡임 테스트
echo "LED Blinking Test..."
for i in 1 2 3 4 5; do
    echo 1 > /sys/class/gpio/gpio913/value
    sleep 0.5
    echo 0 > /sys/class/gpio/gpio913/value
    sleep 0.5
done

# 스위치 읽기
echo "Press switches (Ctrl+C to exit)..."
while true; do
    SW0=$(cat /sys/class/gpio/gpio956/value)
    SW1=$(cat /sys/class/gpio/gpio957/value)
   
    if [ "$SW0" = "0" ]; then
        echo "SW0 pressed - LED ON"
        echo 1 > /sys/class/gpio/gpio913/value
    elif [ "$SW1" = "0" ]; then
        echo "SW1 pressed - LED OFF"
        echo 0 > /sys/class/gpio/gpio913/value
    fi
   
    sleep 0.1
done
```

---

```
chmod +x /home/root/test_gpio.sh
```

---

```
./test_gpio.sh
```

```
Linux GPIO 번호 = 906 + MIO 번호

따라서:
- **MIO 7**  → GPIO **913** (906 + 7)
- **MIO 50** → GPIO **956** (906 + 50)
- **MIO 51** → GPIO **957** (906 + 51)

## 왜 906을 더하나?

Zynq-7000의 GPIO 컨트롤러 구조:
GPIO Bank 0 (MIO):  GPIO 906 ~ 959 (MIO 0-53)
GPIO Bank 1 (MIO):  GPIO 960 ~ 1023 (MIO 54-117)
GPIO Bank 2 (EMIO): GPIO 1024 ~ 1087 (EMIO 0-63)
GPIO Bank 3 (EMIO): GPIO 1088 ~ 1151 (EMIO 64-127)
```

```
# gpiochip 정보 확인
 ls /sys/class/gpio/
export       gpio913      gpio956      gpio957      gpiochip906  unexport

# GPIO 컨트롤러 정보
root@myproject:~# cat /sys/class/gpio/gpiochip906/label
zynq_gpio
root@myproject:~# cat /sys/class/gpio/gpiochip906/base
906
root@myproject:~# cat /sys/class/gpio/gpiochip906/ngpio
118
```

```c
// gpio_test.c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define GPIO_LED 913    // MIO 7
#define GPIO_SW0 956    // MIO 50
#define GPIO_SW1 957    // MIO 51

void gpio_export(int gpio) {
    int fd = open("/sys/class/gpio/export", O_WRONLY);
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_direction(int gpio, const char *dir) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/direction", gpio);
    int fd = open(path, O_WRONLY);
    write(fd, dir, strlen(dir));
    close(fd);
}

void gpio_write(int gpio, int value) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_WRONLY);
    char buf[2] = {value + '0', '\0'};
    write(fd, buf, 1);
    close(fd);
}

int gpio_read(int gpio) {
    char path[50], buf[2];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_RDONLY);
    read(fd, buf, 1);
    close(fd);
    return buf[0] - '0';
}

int main() {
    // GPIO 초기화
    gpio_export(GPIO_LED);
    gpio_export(GPIO_SW0);
    gpio_export(GPIO_SW1);
    
    usleep(100000);  // export 후 대기
    
    gpio_direction(GPIO_LED, "out");
    gpio_direction(GPIO_SW0, "in");
    gpio_direction(GPIO_SW1, "in");
    
    printf("GPIO Test - Press switches to control LED\n");
    
    while(1) {
        int sw0 = gpio_read(GPIO_SW0);
        int sw1 = gpio_read(GPIO_SW1);
        
        if(sw0 == 0) {  // 스위치 눌림 (일반적으로 active low)
            gpio_write(GPIO_LED, 1);
            printf("SW0 pressed - LED ON\n");
        } else if(sw1 == 0) {
            gpio_write(GPIO_LED, 0);
            printf("SW1 pressed - LED OFF\n");
        }
        
        usleep(100000);  // 100ms 대기
    }
    
    return 0;
}
```

```c
// gpio_test.c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define GPIO_LED 913    // MIO 7

void gpio_export(int gpio) {
    int fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("Failed to open export");
        return;
    }
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_unexport(int gpio) {
    int fd = open("/sys/class/gpio/unexport", O_WRONLY);
    if (fd < 0) {
        perror("Failed to open unexport");
        return;
    }
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_direction(int gpio, const char *dir) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/direction", gpio);
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Failed to set direction");
        return;
    }
    write(fd, dir, strlen(dir));
    close(fd);
}

void gpio_write(int gpio, int value) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Failed to write value");
        return;
    }
    char buf[2] = {value + '0', '\0'};
    write(fd, buf, 1);
    close(fd);
}

int main() {
    int led_state = 0;
    int count = 0;
    
    printf("=== LED Toggle Test ===\n");
    printf("MIO 7 (GPIO 913) will toggle continuously\n");
    printf("Press Ctrl+C to exit\n\n");
    
    // 기존 export가 있을 수 있으니 먼저 unexport 시도
    gpio_unexport(GPIO_LED);
    usleep(100000);
    
    // GPIO 초기화
    gpio_export(GPIO_LED);
    usleep(500000);  // export 후 충분한 대기 (500ms)
    
    gpio_direction(GPIO_LED, "out");
    usleep(100000);
    
    printf("Starting LED toggle...\n");
    
    // LED 계속 토글
    while(1) {
        led_state = !led_state;
        gpio_write(GPIO_LED, led_state);
        
        if (led_state) {
            printf("[%d] LED ON\n", count);
        } else {
            printf("[%d] LED OFF\n", count);
        }
        
        count++;
        usleep(500000);  // 500ms 대기 (0.5초마다 토글)
    }
    
    // 정리 (Ctrl+C로 종료되므로 실행되지 않음)
    gpio_write(GPIO_LED, 0);
    gpio_unexport(GPIO_LED);
    
    return 0;
}
```

```
arm-linux-gnueabihf-gcc -o gpio_test gpio_test.c
# 보드에 복사 후
./gpio_test
```

```
gotree94@gotree94-VirtualBox:~/projects/myproject$ arm-linux-gnueabihf-gcc -o gpio_test gpio_test.c
Command 'arm-linux-gnueabihf-gcc' not found, but can be installed with:
sudo apt install gcc-arm-linux-gnueabihf
gotree94@gotree94-VirtualBox:~/projects/myproject$ sudo apt install gcc-arm-linux-gnueabihf
[sudo] password for gotree94: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  binutils-arm-linux-gnueabihf cpp-11-arm-linux-gnueabihf cpp-arm-linux-gnueabihf gcc-11-arm-linux-gnueabihf gcc-11-arm-linux-gnueabihf-base gcc-11-cross-base gcc-12-cross-base libasan6-armhf-cross libatomic1-armhf-cross libc6-armhf-cross libc6-dev-armhf-cross
  libgcc-11-dev-armhf-cross libgcc-s1-armhf-cross libgomp1-armhf-cross libstdc++6-armhf-cross libubsan1-armhf-cross linux-libc-dev-armhf-cross
Suggested packages:
  binutils-doc gcc-11-locales cpp-doc gcc-11-doc gdb-arm-linux-gnueabihf gcc-doc
The following packages will be REMOVED:
  g++-multilib gcc-multilib
The following NEW packages will be installed:
  binutils-arm-linux-gnueabihf cpp-11-arm-linux-gnueabihf cpp-arm-linux-gnueabihf gcc-11-arm-linux-gnueabihf gcc-11-arm-linux-gnueabihf-base gcc-11-cross-base gcc-12-cross-base gcc-arm-linux-gnueabihf libasan6-armhf-cross libatomic1-armhf-cross libc6-armhf-cross
  libc6-dev-armhf-cross libgcc-11-dev-armhf-cross libgcc-s1-armhf-cross libgomp1-armhf-cross libstdc++6-armhf-cross libubsan1-armhf-cross linux-libc-dev-armhf-cross
0 upgraded, 18 newly installed, 2 to remove and 0 not upgraded.
Need to get 38.2 MB of archives.
After this operation, 122 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 gcc-11-arm-linux-gnueabihf-base amd64 11.4.0-1ubuntu1~22.04cross1 [20.5 kB]
Get:2 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 cpp-11-arm-linux-gnueabihf amd64 11.4.0-1ubuntu1~22.04cross1 [8,863 kB]
Get:3 http://kr.archive.ubuntu.com/ubuntu jammy/main amd64 cpp-arm-linux-gnueabihf amd64 4:11.2.0-1ubuntu1 [3,472 B]
Get:4 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 binutils-arm-linux-gnueabihf amd64 2.38-4ubuntu2.10 [3,493 kB]
Get:5 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 gcc-11-cross-base all 11.4.0-1ubuntu1~22.04cross1 [15.5 kB]
Get:6 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 gcc-12-cross-base all 12.3.0-1ubuntu1~22.04cross1 [15.7 kB]
Get:7 http://kr.archive.ubuntu.com/ubuntu jammy/main amd64 libc6-armhf-cross all 2.35-0ubuntu1cross3 [957 kB]
Get:8 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgcc-s1-armhf-cross all 12.3.0-1ubuntu1~22.04cross1 [42.6 kB]
Get:9 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgomp1-armhf-cross all 12.3.0-1ubuntu1~22.04cross1 [108 kB]
Get:10 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libatomic1-armhf-cross all 12.3.0-1ubuntu1~22.04cross1 [7,440 B]
Get:11 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libasan6-armhf-cross all 11.4.0-1ubuntu1~22.04cross1 [2,235 kB]
Get:12 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libstdc++6-armhf-cross all 12.3.0-1ubuntu1~22.04cross1 [569 kB]
Get:13 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libubsan1-armhf-cross all 12.3.0-1ubuntu1~22.04cross1 [958 kB]
Get:14 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgcc-11-dev-armhf-cross all 11.4.0-1ubuntu1~22.04cross1 [836 kB]
Get:15 http://kr.archive.ubuntu.com/ubuntu jammy-updates/main amd64 gcc-11-arm-linux-gnueabihf amd64 11.4.0-1ubuntu1~22.04cross1 [17.6 MB]
Get:16 http://kr.archive.ubuntu.com/ubuntu jammy/main amd64 gcc-arm-linux-gnueabihf amd64 4:11.2.0-1ubuntu1 [1,242 B]
Get:17 http://kr.archive.ubuntu.com/ubuntu jammy/main amd64 linux-libc-dev-armhf-cross all 5.15.0-22.22cross3 [1,204 kB]
Get:18 http://kr.archive.ubuntu.com/ubuntu jammy/main amd64 libc6-dev-armhf-cross all 2.35-0ubuntu1cross3 [1,334 kB]
Fetched 38.2 MB in 5s (6,967 kB/s)                     
(Reading database ... 220489 files and directories currently installed.)
Removing g++-multilib (4:11.2.0-1ubuntu1) ...
Removing gcc-multilib (4:11.2.0-1ubuntu1) ...
Selecting previously unselected package gcc-11-arm-linux-gnueabihf-base:amd64.
(Reading database ... 220486 files and directories currently installed.)
Preparing to unpack .../00-gcc-11-arm-linux-gnueabihf-base_11.4.0-1ubuntu1~22.04cross1_amd64.deb ...
Unpacking gcc-11-arm-linux-gnueabihf-base:amd64 (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package cpp-11-arm-linux-gnueabihf.
Preparing to unpack .../01-cpp-11-arm-linux-gnueabihf_11.4.0-1ubuntu1~22.04cross1_amd64.deb ...
Unpacking cpp-11-arm-linux-gnueabihf (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package cpp-arm-linux-gnueabihf.
Preparing to unpack .../02-cpp-arm-linux-gnueabihf_4%3a11.2.0-1ubuntu1_amd64.deb ...
Unpacking cpp-arm-linux-gnueabihf (4:11.2.0-1ubuntu1) ...
Selecting previously unselected package binutils-arm-linux-gnueabihf.
Preparing to unpack .../03-binutils-arm-linux-gnueabihf_2.38-4ubuntu2.10_amd64.deb ...
Unpacking binutils-arm-linux-gnueabihf (2.38-4ubuntu2.10) ...
Selecting previously unselected package gcc-11-cross-base.
Preparing to unpack .../04-gcc-11-cross-base_11.4.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking gcc-11-cross-base (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package gcc-12-cross-base.
Preparing to unpack .../05-gcc-12-cross-base_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking gcc-12-cross-base (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libc6-armhf-cross.
Preparing to unpack .../06-libc6-armhf-cross_2.35-0ubuntu1cross3_all.deb ...
Unpacking libc6-armhf-cross (2.35-0ubuntu1cross3) ...
Selecting previously unselected package libgcc-s1-armhf-cross.
Preparing to unpack .../07-libgcc-s1-armhf-cross_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libgcc-s1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libgomp1-armhf-cross.
Preparing to unpack .../08-libgomp1-armhf-cross_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libgomp1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libatomic1-armhf-cross.
Preparing to unpack .../09-libatomic1-armhf-cross_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libatomic1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libasan6-armhf-cross.
Preparing to unpack .../10-libasan6-armhf-cross_11.4.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libasan6-armhf-cross (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libstdc++6-armhf-cross.
Preparing to unpack .../11-libstdc++6-armhf-cross_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libstdc++6-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libubsan1-armhf-cross.
Preparing to unpack .../12-libubsan1-armhf-cross_12.3.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libubsan1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package libgcc-11-dev-armhf-cross.
Preparing to unpack .../13-libgcc-11-dev-armhf-cross_11.4.0-1ubuntu1~22.04cross1_all.deb ...
Unpacking libgcc-11-dev-armhf-cross (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package gcc-11-arm-linux-gnueabihf.
Preparing to unpack .../14-gcc-11-arm-linux-gnueabihf_11.4.0-1ubuntu1~22.04cross1_amd64.deb ...
Unpacking gcc-11-arm-linux-gnueabihf (11.4.0-1ubuntu1~22.04cross1) ...
Selecting previously unselected package gcc-arm-linux-gnueabihf.
Preparing to unpack .../15-gcc-arm-linux-gnueabihf_4%3a11.2.0-1ubuntu1_amd64.deb ...
Unpacking gcc-arm-linux-gnueabihf (4:11.2.0-1ubuntu1) ...
Selecting previously unselected package linux-libc-dev-armhf-cross.
Preparing to unpack .../16-linux-libc-dev-armhf-cross_5.15.0-22.22cross3_all.deb ...
Unpacking linux-libc-dev-armhf-cross (5.15.0-22.22cross3) ...
Selecting previously unselected package libc6-dev-armhf-cross.
Preparing to unpack .../17-libc6-dev-armhf-cross_2.35-0ubuntu1cross3_all.deb ...
Unpacking libc6-dev-armhf-cross (2.35-0ubuntu1cross3) ...
Setting up libc6-armhf-cross (2.35-0ubuntu1cross3) ...
Setting up gcc-12-cross-base (12.3.0-1ubuntu1~22.04cross1) ...
Setting up libgcc-s1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Setting up libatomic1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Setting up libstdc++6-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Setting up gcc-11-arm-linux-gnueabihf-base:amd64 (11.4.0-1ubuntu1~22.04cross1) ...
Setting up linux-libc-dev-armhf-cross (5.15.0-22.22cross3) ...
Setting up libubsan1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Setting up gcc-11-cross-base (11.4.0-1ubuntu1~22.04cross1) ...
Setting up binutils-arm-linux-gnueabihf (2.38-4ubuntu2.10) ...
Setting up cpp-11-arm-linux-gnueabihf (11.4.0-1ubuntu1~22.04cross1) ...
Setting up libgomp1-armhf-cross (12.3.0-1ubuntu1~22.04cross1) ...
Setting up libc6-dev-armhf-cross (2.35-0ubuntu1cross3) ...
Setting up libasan6-armhf-cross (11.4.0-1ubuntu1~22.04cross1) ...
Setting up cpp-arm-linux-gnueabihf (4:11.2.0-1ubuntu1) ...
Setting up libgcc-11-dev-armhf-cross (11.4.0-1ubuntu1~22.04cross1) ...
Setting up gcc-11-arm-linux-gnueabihf (11.4.0-1ubuntu1~22.04cross1) ...
Setting up gcc-arm-linux-gnueabihf (4:11.2.0-1ubuntu1) ...
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for libc-bin (2.35-0ubuntu3.11) ...
gotree94@gotree94-VirtualBox:~/projects/myproject$ arm-linux-gnueabihf-gcc -o gpio_test gpio_test.c

```

```
source ~/petalinux/2022.2/settings.sh
petalinux-config -c rootfs
```

```
Symbol: lrzsz [=y]                                                                                                                                                                                                                                              │  
Type  : boolean                                                                                                                                                                                                                                                 │  
Prompt: lrzsz                                                                                                                                                                                                                                                   │  
   Location:                                                                                                                                                                                                                                                     │  
     -> Filesystem Packages                                                                                                                                                                                                                                      │  
       -> console                                                                                                                                                                                                                                                │  
         -> network                                                                                                                                                                                                                                              │  
 (1)       -> lrzsz                                                                                                                                                                                                                                              │  
   Defined at /home/gotree94/projects/myproject/build/misc/rootfs_config/Kconfig:1117 
```

```
cd ~/projects/myproject

# PetaLinux 환경 확인
source ~/petalinux/2022.2/settings.sh

# 빌드 시작
petalinux-build

cd ~/projects/myproject

petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

cd ~/projects/myproject

# WIC 이미지 생성
petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
```



```
# 시리얼 파일 전송 사용법 (TeraTerm)

lrzsz 패키지 설치 후, TeraTerm을 통해 파일을 전송할 수 있습니다.

보드에서 파일 수신 (PC → 보드):

# 보드 콘솔에서
cd /home/root

# ZMODEM으로 수신 대기 (가장 권장)
rz

# 또는 YMODEM으로 수신
ry

TeraTerm에서 파일 전송:

File → Transfer → ZMODEM → Send 클릭
전송할 파일 선택 (예: gpio_test 실행파일)
전송 완료 후 실행 권한 부여:

chmod +x gpio_test
./gpio_test

보드에서 파일 송신 (보드 → PC):

# 보드 콘솔에서
cd /home/root

# ZMODEM으로 송신
sz filename

TeraTerm에서 파일 수신:

File → Transfer → ZMODEM → Receive 클릭
저장 위치 선택

프로토콜 비교:

XMODEM: 느림, 단일 파일만 (rx/sx)
YMODEM: 중간, 배치 전송 가능 (ry/sy)
ZMODEM: 빠름, 오류 복구, 이어받기 지원 (rz/sz) ← 권장
```



## 전체 작업 흐름

* Vivado에서 하드웨어 설계 (PL 영역 GPIO 추가)
* XSA 파일 재생성 및 내보내기
* PetaLinux 프로젝트 업데이트
* 디바이스 트리 수정
* 리눅스에서 GPIO 테스트

---

1. Vivado에서 하드웨어 설계
1.1 AXI GPIO IP 추가

```tcl
# Vivado에서 Block Design 열기
# IP Catalog에서 "AXI GPIO" 검색

# 3개의 AXI GPIO IP 추가:
# - axi_gpio_btn (4-bit 입력) - Buttons용
# - axi_gpio_led (4-bit 출력) - LEDs용  
# - axi_gpio_sw (4-bit 입력) - Switches용
```
### 1.2 GPIO IP 설정
```
**Buttons (axi_gpio_btn):**
- GPIO Width: 4
- All Inputs 체크
- 듀얼 채널 불필요

**LEDs (axi_gpio_led):**
- GPIO Width: 4
- All Outputs 체크
- 듀얼 채널 불필요

**Switches (axi_gpio_sw):**
- GPIO Width: 4
- All Inputs 체크
- 듀얼 채널 불필요
```

### 1.3 AXI Interconnect 연결
```
PS7 M_AXI_GP0 → AXI Interconnect → 각 GPIO의 S_AXI
```

1.4 외부 핀 연결 (Constraints 파일)

constraints.xdc 파일 생성 또는 수정:
```tcl
# Buttons
set_property PACKAGE_PIN Y16 [get_ports {btn_tri_i[0]}]
set_property PACKAGE_PIN K19 [get_ports {btn_tri_i[1]}]
set_property PACKAGE_PIN P16 [get_ports {btn_tri_i[2]}]
set_property PACKAGE_PIN K18 [get_ports {btn_tri_i[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_tri_i[*]}]

# LEDs
set_property PACKAGE_PIN D18 [get_ports {led_tri_o[0]}]
set_property PACKAGE_PIN G14 [get_ports {led_tri_o[1]}]
set_property PACKAGE_PIN M15 [get_ports {led_tri_o[2]}]
set_property PACKAGE_PIN M14 [get_ports {led_tri_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_tri_o[*]}]

# Switches
set_property PACKAGE_PIN T16 [get_ports {sw_tri_i[0]}]
set_property PACKAGE_PIN W13 [get_ports {sw_tri_i[1]}]
set_property PACKAGE_PIN P15 [get_ports {sw_tri_i[2]}]
set_property PACKAGE_PIN G15 [get_ports {sw_tri_i[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_tri_i[*]}]
```

1.5 Address 할당 확인
Address Editor에서 각 GPIO의 베이스 주소 확인:
   * axi_gpio_btn: 예) 0x41200000
   * axi_gpio_led: 예) 0x41210000
   * axi_gpio_sw: 예) 0x41220000

1.6 비트스트림 생성 및 XSA 내보내기
```tcl
# Validate Design
# Generate Bitstream
# File → Export → Export Hardware (Include bitstream 체크)
# design_top_wrapper.xsa 생성
```
2. PetaLinux 프로젝트 업데이트
2.1 새 XSA 파일로 하드웨어 업데이트
```bash
cd ~/projects/myproject

# 새 XSA 파일 복사
cp /mnt/share/design_top_wrapper.xsa ~/projects/

# 하드웨어 설정 업데이트
petalinux-config --get-hw-description=~/projects/
```

2.2 디바이스 트리 수정
```bash
# 커스텀 디바이스 트리 파일 생성
cd ~/projects/myproject
petalinux-create -t apps --template devicetree --name device-tree --enable
```

디바이스 트리 파일 편집:
```bash
vi project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

system-user.dtsi 내용:
```c
/include/ "system-conf.dtsi"
/ {
};

&axi_gpio_btn {
    status = "okay";
    #gpio-cells = <2>;
    gpio-controller;
};

&axi_gpio_led {
    status = "okay";
    #gpio-cells = <2>;
    gpio-controller;
};

&axi_gpio_sw {
    status = "okay";
    #gpio-cells = <2>;
    gpio-controller;
};
```

3. 재빌드 및 부팅
3.1 PetaLinux 빌드
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

3.2 SD 카드 프로그래밍
```bash
# SD 카드 장치 확인
lsblk

# WIC 이미지 쓰기 (예: /dev/sdb)
sudo dd if=images/linux/petalinux-sdimage.wic of=/dev/sdb bs=4M status=progress
sync
```
4. 리눅스에서 GPIO 제어
Zybo Z7-20을 부팅한 후:

4.1 GPIO 베이스 번호 확인
```bash
# GPIO chip 확인
ls /sys/class/gpio/

# GPIO 베이스 번호 확인
cat /sys/class/gpio/gpiochip*/label
cat /sys/class/gpio/gpiochip*/base

# 예상 출력:
# gpiochip0: base 1020 (Zynq PS GPIO)
# gpiochip1: base 1016 (axi_gpio_sw)
# gpiochip2: base 1012 (axi_gpio_led)
# gpiochip3: base 1008 (axi_gpio_btn)
```

4.2 LED 제어 예제
```bash
# LED GPIO export (base + 0~3)
echo 1012 > /sys/class/gpio/export
echo 1013 > /sys/class/gpio/export
echo 1014 > /sys/class/gpio/export
echo 1015 > /sys/class/gpio/export

# 출력 모드 설정
echo out > /sys/class/gpio/gpio1012/direction
echo out > /sys/class/gpio/gpio1013/direction
echo out > /sys/class/gpio/gpio1014/direction
echo out > /sys/class/gpio/gpio1015/direction

# LED 켜기/끄기
echo 1 > /sys/class/gpio/gpio1012/value  # LED0 ON
echo 0 > /sys/class/gpio/gpio1012/value  # LED0 OFF
echo 1 > /sys/class/gpio/gpio1013/value  # LED1 ON
```

4.3 Button 읽기 예제
```bash
# Button GPIO export
echo 1008 > /sys/class/gpio/export
echo 1009 > /sys/class/gpio/export
echo 1010 > /sys/class/gpio/export
echo 1011 > /sys/class/gpio/export

# 입력 모드 설정
echo in > /sys/class/gpio/gpio1008/direction
echo in > /sys/class/gpio/gpio1009/direction
echo in > /sys/class/gpio/gpio1010/direction
echo in > /sys/class/gpio/gpio1011/direction

# 버튼 상태 읽기
cat /sys/class/gpio/gpio1008/value  # BTN0
cat /sys/class/gpio/gpio1009/value  # BTN1
```

4.4 Shell 스크립트 예제
```bash
vi /home/root/gpio_test.sh
```

```bash
#!/bin/bash

# LED 깜빡임 테스트
LED_BASE=1012

for i in 0 1 2 3; do
    GPIO=$((LED_BASE + i))
    echo $GPIO > /sys/class/gpio/export 2>/dev/null
    echo out > /sys/class/gpio/gpio$GPIO/direction
done

while true; do
    for i in 0 1 2 3; do
        GPIO=$((LED_BASE + i))
        echo 1 > /sys/class/gpio/gpio$GPIO/value
        sleep 0.2
        echo 0 > /sys/class/gpio/gpio$GPIO/value
    done
done
```

```bash
chmod +x /home/root/gpio_test.sh
./gpio_test.sh
```

5. C 프로그램으로 GPIO 제어
더 효율적인 제어를 원한다면 C 프로그램 작성:
```bash
cd ~/projects/myproject
petalinux-create -t apps --name gpio-app --enable
```

---

# C 프로그램으로 GPIO를 제어

1. PetaLinux 애플리케이션 생성

```bash
cd ~/projects/myproject
petalinux-create -t apps --name gpio-app --enable
```

2. GPIO 제어 C 프로그램 작성
2.1 메인 프로그램 (gpio_control.c)

```bash
vi project-spec/meta-user/recipes-apps/gpio-app/files/gpio_control.c
```

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

// GPIO 베이스 번호 (실제 시스템에 맞게 조정)
#define GPIO_BTN_BASE   1008
#define GPIO_LED_BASE   1012
#define GPIO_SW_BASE    1016

#define NUM_BUTTONS     4
#define NUM_LEDS        4
#define NUM_SWITCHES    4

typedef struct {
    int gpio_num;
    int fd_value;
    int fd_direction;
    char path_value[64];
    char path_direction[64];
    int is_exported;
} GPIO_Pin;

GPIO_Pin buttons[NUM_BUTTONS];
GPIO_Pin leds[NUM_LEDS];
GPIO_Pin switches[NUM_SWITCHES];

volatile int running = 1;

// 시그널 핸들러
void signal_handler(int signum) {
    printf("\nReceived signal %d, cleaning up...\n", signum);
    running = 0;
}

// GPIO Export
int gpio_export(int gpio_num) {
    int fd;
    char buf[64];
    
    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("Error opening export");
        return -1;
    }
    
    snprintf(buf, sizeof(buf), "%d", gpio_num);
    if (write(fd, buf, strlen(buf)) < 0) {
        if (errno != EBUSY) {  // 이미 export된 경우는 무시
            perror("Error writing to export");
            close(fd);
            return -1;
        }
    }
    
    close(fd);
    usleep(100000);  // 100ms 대기
    return 0;
}

// GPIO Unexport
int gpio_unexport(int gpio_num) {
    int fd;
    char buf[64];
    
    fd = open("/sys/class/gpio/unexport", O_WRONLY);
    if (fd < 0) {
        perror("Error opening unexport");
        return -1;
    }
    
    snprintf(buf, sizeof(buf), "%d", gpio_num);
    write(fd, buf, strlen(buf));
    close(fd);
    return 0;
}

// GPIO 방향 설정
int gpio_set_direction(int gpio_num, const char *direction) {
    int fd;
    char path[64];
    
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/direction", gpio_num);
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Error opening direction");
        return -1;
    }
    
    if (write(fd, direction, strlen(direction)) < 0) {
        perror("Error writing direction");
        close(fd);
        return -1;
    }
    
    close(fd);
    return 0;
}

// GPIO 값 쓰기
int gpio_write(GPIO_Pin *pin, int value) {
    char buf[2];
    
    snprintf(buf, sizeof(buf), "%d", value ? 1 : 0);
    
    if (write(pin->fd_value, buf, 1) < 0) {
        perror("Error writing value");
        return -1;
    }
    
    lseek(pin->fd_value, 0, SEEK_SET);
    return 0;
}

// GPIO 값 읽기
int gpio_read(GPIO_Pin *pin) {
    char buf[2];
    
    lseek(pin->fd_value, 0, SEEK_SET);
    if (read(pin->fd_value, buf, 1) < 0) {
        perror("Error reading value");
        return -1;
    }
    
    return (buf[0] == '1') ? 1 : 0;
}

// GPIO 초기화
int gpio_init_pin(GPIO_Pin *pin, int gpio_num, const char *direction) {
    pin->gpio_num = gpio_num;
    pin->is_exported = 0;
    
    snprintf(pin->path_value, sizeof(pin->path_value), 
             "/sys/class/gpio/gpio%d/value", gpio_num);
    snprintf(pin->path_direction, sizeof(pin->path_direction), 
             "/sys/class/gpio/gpio%d/direction", gpio_num);
    
    // Export
    if (gpio_export(gpio_num) < 0) {
        return -1;
    }
    pin->is_exported = 1;
    
    // 방향 설정
    if (gpio_set_direction(gpio_num, direction) < 0) {
        return -1;
    }
    
    // Value 파일 열기
    pin->fd_value = open(pin->path_value, O_RDWR);
    if (pin->fd_value < 0) {
        perror("Error opening value file");
        return -1;
    }
    
    return 0;
}

// GPIO 정리
void gpio_cleanup_pin(GPIO_Pin *pin) {
    if (pin->fd_value >= 0) {
        close(pin->fd_value);
        pin->fd_value = -1;
    }
    
    if (pin->is_exported) {
        gpio_unexport(pin->gpio_num);
        pin->is_exported = 0;
    }
}

// 모든 GPIO 초기화
int init_all_gpio(void) {
    int i;
    
    printf("Initializing GPIOs...\n");
    
    // Buttons 초기화 (입력)
    for (i = 0; i < NUM_BUTTONS; i++) {
        printf("Initializing Button %d (GPIO %d)...\n", i, GPIO_BTN_BASE + i);
        if (gpio_init_pin(&buttons[i], GPIO_BTN_BASE + i, "in") < 0) {
            fprintf(stderr, "Failed to initialize button %d\n", i);
            return -1;
        }
    }
    
    // LEDs 초기화 (출력)
    for (i = 0; i < NUM_LEDS; i++) {
        printf("Initializing LED %d (GPIO %d)...\n", i, GPIO_LED_BASE + i);
        if (gpio_init_pin(&leds[i], GPIO_LED_BASE + i, "out") < 0) {
            fprintf(stderr, "Failed to initialize LED %d\n", i);
            return -1;
        }
        gpio_write(&leds[i], 0);  // LED 끄기
    }
    
    // Switches 초기화 (입력)
    for (i = 0; i < NUM_SWITCHES; i++) {
        printf("Initializing Switch %d (GPIO %d)...\n", i, GPIO_SW_BASE + i);
        if (gpio_init_pin(&switches[i], GPIO_SW_BASE + i, "in") < 0) {
            fprintf(stderr, "Failed to initialize switch %d\n", i);
            return -1;
        }
    }
    
    printf("All GPIOs initialized successfully!\n\n");
    return 0;
}

// 모든 GPIO 정리
void cleanup_all_gpio(void) {
    int i;
    
    printf("\nCleaning up GPIOs...\n");
    
    // LEDs 끄기
    for (i = 0; i < NUM_LEDS; i++) {
        gpio_write(&leds[i], 0);
        gpio_cleanup_pin(&leds[i]);
    }
    
    for (i = 0; i < NUM_BUTTONS; i++) {
        gpio_cleanup_pin(&buttons[i]);
    }
    
    for (i = 0; i < NUM_SWITCHES; i++) {
        gpio_cleanup_pin(&switches[i]);
    }
    
    printf("Cleanup complete!\n");
}

// LED 테스트 - 순차 깜빡임
void test_led_sequence(void) {
    int i;
    printf("Testing LED sequence...\n");
    
    for (i = 0; i < NUM_LEDS; i++) {
        gpio_write(&leds[i], 1);
        usleep(200000);  // 200ms
        gpio_write(&leds[i], 0);
    }
}

// LED 테스트 - 모두 깜빡임
void test_led_blink(void) {
    int i;
    printf("Testing LED blink all...\n");
    
    for (i = 0; i < NUM_LEDS; i++) {
        gpio_write(&leds[i], 1);
    }
    usleep(500000);
    
    for (i = 0; i < NUM_LEDS; i++) {
        gpio_write(&leds[i], 0);
    }
    usleep(500000);
}

// 버튼으로 LED 제어 모드
void mode_button_to_led(void) {
    int i, btn_state;
    
    printf("\n=== Button to LED Mode ===\n");
    printf("Press buttons to control LEDs\n");
    printf("Press Ctrl+C to exit\n\n");
    
    while (running) {
        for (i = 0; i < NUM_BUTTONS; i++) {
            btn_state = gpio_read(&buttons[i]);
            if (btn_state >= 0) {
                gpio_write(&leds[i], btn_state);
            }
        }
        usleep(10000);  // 10ms
    }
}

// 스위치로 LED 제어 모드
void mode_switch_to_led(void) {
    int i, sw_state;
    int last_state[NUM_SWITCHES] = {-1, -1, -1, -1};
    
    printf("\n=== Switch to LED Mode ===\n");
    printf("Toggle switches to control LEDs\n");
    printf("Press Ctrl+C to exit\n\n");
    
    while (running) {
        for (i = 0; i < NUM_SWITCHES; i++) {
            sw_state = gpio_read(&switches[i]);
            if (sw_state >= 0 && sw_state != last_state[i]) {
                printf("Switch %d: %s\n", i, sw_state ? "ON" : "OFF");
                gpio_write(&leds[i], sw_state);
                last_state[i] = sw_state;
            }
        }
        usleep(10000);  // 10ms
    }
}

// 버튼 카운터 모드
void mode_button_counter(void) {
    int i, btn_state;
    int last_btn[NUM_BUTTONS] = {0, 0, 0, 0};
    int counter = 0;
    
    printf("\n=== Button Counter Mode ===\n");
    printf("Press buttons to count (binary display on LEDs)\n");
    printf("BTN0: +1, BTN1: -1, BTN2: Reset, BTN3: Exit\n\n");
    
    while (running) {
        for (i = 0; i < NUM_BUTTONS; i++) {
            btn_state = gpio_read(&buttons[i]);
            
            if (btn_state == 1 && last_btn[i] == 0) {  // 버튼 눌림 감지
                switch(i) {
                    case 0:  // +1
                        counter++;
                        if (counter > 15) counter = 15;
                        break;
                    case 1:  // -1
                        counter--;
                        if (counter < 0) counter = 0;
                        break;
                    case 2:  // Reset
                        counter = 0;
                        break;
                    case 3:  // Exit
                        running = 0;
                        break;
                }
                
                printf("Counter: %d (0b", counter);
                for (int j = 3; j >= 0; j--) {
                    printf("%d", (counter >> j) & 1);
                }
                printf(")\n");
                
                // LED에 이진수로 표시
                for (int j = 0; j < NUM_LEDS; j++) {
                    gpio_write(&leds[j], (counter >> j) & 1);
                }
            }
            
            last_btn[i] = btn_state;
        }
        usleep(10000);  // 10ms
    }
}

// 상태 모니터링
void mode_monitor(void) {
    int i;
    
    printf("\n=== GPIO Monitor Mode ===\n");
    printf("Monitoring all GPIO states\n");
    printf("Press Ctrl+C to exit\n\n");
    
    while (running) {
        printf("\rButtons: ");
        for (i = 0; i < NUM_BUTTONS; i++) {
            printf("BTN%d:%d ", i, gpio_read(&buttons[i]));
        }
        
        printf("| Switches: ");
        for (i = 0; i < NUM_SWITCHES; i++) {
            printf("SW%d:%d ", i, gpio_read(&switches[i]));
        }
        
        printf("| LEDs: ");
        for (i = 0; i < NUM_LEDS; i++) {
            printf("LED%d:%d ", i, gpio_read(&leds[i]));
        }
        
        fflush(stdout);
        usleep(100000);  // 100ms
    }
    printf("\n");
}

// 메인 메뉴
void print_menu(void) {
    printf("\n");
    printf("╔═══════════════════════════════════════╗\n");
    printf("║     Zybo Z7-20 GPIO Control App      ║\n");
    printf("╚═══════════════════════════════════════╝\n");
    printf("\n");
    printf("  1. LED Sequence Test\n");
    printf("  2. LED Blink Test\n");
    printf("  3. Button → LED Mode\n");
    printf("  4. Switch → LED Mode\n");
    printf("  5. Button Counter Mode\n");
    printf("  6. GPIO Monitor Mode\n");
    printf("  0. Exit\n");
    printf("\n");
    printf("Select option: ");
}

int main(int argc, char *argv[]) {
    int choice;
    
    // 시그널 핸들러 등록
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    printf("\n");
    printf("╔═══════════════════════════════════════╗\n");
    printf("║  Zybo Z7-20 GPIO Control Application ║\n");
    printf("╚═══════════════════════════════════════╝\n");
    printf("\n");
    
    // GPIO 초기화
    if (init_all_gpio() < 0) {
        fprintf(stderr, "Failed to initialize GPIOs\n");
        fprintf(stderr, "Please check:\n");
        fprintf(stderr, "  1. GPIO base numbers are correct\n");
        fprintf(stderr, "  2. Device tree is properly configured\n");
        fprintf(stderr, "  3. You have root permissions\n");
        return 1;
    }
    
    // 메인 루프
    while (running) {
        print_menu();
        
        if (scanf("%d", &choice) != 1) {
            while (getchar() != '\n');  // 입력 버퍼 클리어
            continue;
        }
        
        running = 1;  // 서브메뉴용 리셋
        
        switch (choice) {
            case 1:
                test_led_sequence();
                break;
            case 2:
                test_led_blink();
                break;
            case 3:
                mode_button_to_led();
                break;
            case 4:
                mode_switch_to_led();
                break;
            case 5:
                mode_button_counter();
                break;
            case 6:
                mode_monitor();
                break;
            case 0:
                running = 0;
                break;
            default:
                printf("Invalid option!\n");
                break;
        }
    }
    
    // 정리
    cleanup_all_gpio();
    
    printf("\nGoodbye!\n\n");
    return 0;
}
```

3. Makefile 수정
```bash
vi project-spec/meta-user/recipes-apps/gpio-app/gpio-app.bb
```

```makefile
SUMMARY = "GPIO Control Application for Zybo Z7-20"
SECTION = "applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gpio_control.c \
           file://Makefile \
          "

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} gpio_control.c -o gpio-app
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 gpio-app ${D}${bindir}
}

FILES_${PN} += "${bindir}/gpio-app"
```

실제 Makefile 생성:
```bash
vi project-spec/meta-user/recipes-apps/gpio-app/files/Makefile
```

```makefile
APP = gpio-app
SRC = gpio_control.c

# Cross compiler
CC ?= gcc
CFLAGS += -Wall -O2

all: $(APP)

$(APP): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(APP) *.o

install: $(APP)
	install -d $(DESTDIR)/usr/bin
	install -m 0755 $(APP) $(DESTDIR)/usr/bin/

.PHONY: all clean install
```

4. PetaLinux 빌드
```bash
cd ~/projects/myproject

# 애플리케이션만 빌드
petalinux-build -c gpio-app

# 전체 빌드
petalinux-build

# 이미지 패키징
petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_top_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
```

5. 실행 방법
Zybo Z7-20 부팅 후:
```bash
# 프로그램 실행 (root 권한 필요)
gpio-app

# 또는
/usr/bin/gpio-app
```

6. 프로그램 기능 설명
모드 1: LED Sequence Test
* LED가 순차적으로 켜졌다 꺼집니다
모드 2: LED Blink Test
* 모든 LED가 동시에 깜빡입니다
모드 3: Button → LED Mode
* 버튼을 누르면 해당 LED가 켜집니다
* 실시간 제어
모드 4: Switch → LED Mode
* 스위치를 올리면 해당 LED가 켜집니다
* 상태 변화 출력
모드 5: Button Counter Mode
*BTN0: 카운터 +1
*BTN1: 카운터 -1
*BTN2: 리셋
*BTN3: 종료
*LED에 이진수로 카운터 표시
모드 6: GPIO Monitor Mode
*모든 GPIO 상태를 실시간 모니터링

7. GPIO 베이스 번호 확인 및 수정
실제 시스템에서 GPIO 베이스 번호가 다를 수 있습니다:

```bash
# Zybo에서 확인
ls /sys/class/gpio/
cat /sys/class/gpio/gpiochip*/label
cat /sys/class/gpio/gpiochip*/base
```

프로그램의 상단 정의 수정:
```c
#define GPIO_BTN_BASE   1008  // 실제 버튼 GPIO 베이스로 변경
#define GPIO_LED_BASE   1012  // 실제 LED GPIO 베이스로 변경
#define GPIO_SW_BASE    1016  // 실제 스위치 GPIO 베이스로 변경
```
