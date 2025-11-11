# ALU AXI 프로젝트 빠른 시작 가이드

## 📋 체크리스트

프로젝트를 시작하기 전에 다음 사항을 확인하세요:

- [ ] Vivado 2022.2 이상 설치
- [ ] PetaLinux 2022.2 이상 설치
- [ ] Zybo Z7-20 보드 준비
- [ ] Ubuntu 20.04/22.04 호스트 시스템
- [ ] 8GB 이상 SD 카드
- [ ] USB-UART 케이블

## 🚀 5분 안에 시작하기

### 1단계: Vivado 프로젝트 생성 (5분)

```bash
cd zybo_alu_axi/tcl
vivado -mode tcl -source create_project.tcl
```

Vivado GUI에서:
1. **Generate Bitstream** 클릭 (15-30분 소요)
2. **File → Export → Export Hardware** 
3. **Include bitstream** 체크
4. `hardware/system_wrapper.xsa`로 저장

### 2단계: PetaLinux 빌드 (1-3시간)

```bash
# 환경 설정
source /tools/Xilinx/PetaLinux/settings.sh

# 프로젝트 생성
cd zybo_alu_axi
petalinux-create --type project --template zynq --name petalinux_alu
cd petalinux_alu

# 하드웨어 임포트
petalinux-config --get-hw-description=../hardware

# 드라이버 추가
petalinux-create -t modules --name alu-driver --enable
cp ../sw/alu_driver.c project-spec/meta-user/recipes-modules/alu-driver/files/

# 애플리케이션 추가
petalinux-create -t apps --name alu-test --enable
cp ../sw/alu_test_*.c project-spec/meta-user/recipes-apps/alu-test/files/
cp ../sw/Makefile project-spec/meta-user/recipes-apps/alu-test/files/

# 빌드
petalinux-build

# 부팅 이미지 생성
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
                          --fpga images/linux/system_wrapper.bit \
                          --u-boot --force
```

### 3단계: SD 카드 준비 (10분)

```bash
# SD 카드 파티션 생성 (8GB 이상)
# Partition 1: 512MB FAT32 (부팅)
# Partition 2: 나머지 ext4 (루트 파일시스템)

# 부팅 파일 복사
sudo mount /dev/sdX1 /mnt/boot
cd petalinux_alu/images/linux
sudo cp BOOT.BIN image.ub boot.scr /mnt/boot/
sudo umount /mnt/boot

# 루트 파일시스템 복사
sudo mount /dev/sdX2 /mnt/rootfs
sudo tar xvf rootfs.tar.gz -C /mnt/rootfs
sudo umount /mnt/rootfs
```

### 4단계: 보드 부팅 및 테스트 (2분)

```bash
# Zybo Z7-20에 SD 카드 삽입
# JP5를 SD 모드로 설정
# USB-UART 연결 (115200 8N1)
# 전원 ON

# 로그인: root / root

# 테스트 실행
alu_test_devmem -t      # 전체 테스트
alu_test_devmem -c 25 5 0  # 단일 연산 (25 + 5)
```

## 📊 예상 결과

```
************************************************************
  ALU AXI Hardware Accelerator Test Program
  Zybo Z7-20 Platform
************************************************************

Testing ALU with A=25, B=5
============================================================

  ADD (+): 25 +  5 = 30
  SUB (-): 25 -  5 = 20
  MUL (*): 25 *  5 = 125
  DIV (/): 25 /  5 = 5
  MOD (%): 25 %  5 = 0
  EQ (==): 25 == 5 = 0 (FALSE)
  GT  (>): 25 >  5 = 1 (TRUE)
  LT  (<): 25 <  5 = 0 (FALSE)
```

## 🛠️ 주요 명령어

### Sysfs 인터페이스

```bash
# 레지스터 설정
echo 100 > /sys/devices/platform/amba/43c00000.alu/operand_a
echo 25 > /sys/devices/platform/amba/43c00000.alu/operand_b
echo 0 > /sys/devices/platform/amba/43c00000.alu/opcode  # ADD
echo 1 > /sys/devices/platform/amba/43c00000.alu/enable

# 결과 읽기
cat /sys/devices/platform/amba/43c00000.alu/result
```

### devmem 직접 접근

```bash
# 100 + 25 계산
devmem 0x43C00000 32 0x64  # operand_a = 100
devmem 0x43C00004 32 0x19  # operand_b = 25
devmem 0x43C00008 32 0x08  # opcode=0, enable=1
devmem 0x43C0000C 32       # 결과 읽기: 125
```

### 쉘 스크립트

```bash
# 간단한 테스트
sudo ./alu_test.sh test

# 커스텀 값 테스트
sudo ./alu_test.sh test 100 25

# 단일 연산
sudo ./alu_test.sh compute 50 10 2  # 50 * 10

# 레지스터 덤프
sudo ./alu_test.sh dump

# 벤치마크
sudo ./alu_test.sh benchmark 10000
```

## 🔍 트러블슈팅

### 문제: 드라이버가 로드되지 않음

```bash
# 확인
lsmod | grep alu
dmesg | grep alu

# 수동 로드
modprobe alu-driver
```

### 문제: 디바이스를 찾을 수 없음

```bash
# 확인
ls /sys/devices/platform/amba/43c00000.alu/
cat /proc/iomem | grep 43c00000

# 디바이스 트리 확인
cat /proc/device-tree/amba/alu@43c00000/compatible
```

### 문제: 권한 거부

```bash
# /dev/mem 접근 권한
sudo chmod 666 /dev/mem

# 또는 root로 실행
sudo alu_test_devmem -t
```

### 문제: 예상과 다른 결과

```bash
# 하드웨어 리셋
devmem 0x43C00000 32 0x00
devmem 0x43C00004 32 0x00
devmem 0x43C00008 32 0x00

# 레지스터 확인
for i in 0 4 8 C; do 
    echo -n "0x43C000$i: "
    devmem 0x43C000$i 32
done
```

## 📚 추가 문서

- **README.md** - 프로젝트 전체 개요
- **PETALINUX_SETUP.md** - 상세한 PetaLinux 설정 가이드
- **hdl/** - Verilog HDL 소스 코드
- **sw/** - C 프로그램 및 드라이버 소스

## 🎯 연산 코드 참고

| Code | Operation | Example | Result |
|------|-----------|---------|--------|
| 0    | ADD (+)   | 25 + 5  | 30     |
| 1    | SUB (-)   | 25 - 5  | 20     |
| 2    | MUL (*)   | 25 * 5  | 125    |
| 3    | DIV (/)   | 25 / 5  | 5      |
| 4    | MOD (%)   | 25 % 5  | 0      |
| 5    | EQ (==)   | 25 == 5 | 0      |
| 6    | GT (>)    | 25 > 5  | 1      |
| 7    | LT (<)    | 25 < 5  | 0      |

## ⚡ 성능 정보

- **ALU 연산 시간**: ~10 µs
- **최대 처리량**: ~100,000 ops/sec
- **레지스터 접근 지연**: ~1 µs

## 🔗 리소스

- [Zybo Z7-20 문서](https://digilent.com/reference/programmable-logic/zybo-z7/start)
- [Xilinx Zynq-7000 TRM](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf)
- [PetaLinux Tools 문서](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2022_2/ug1144-petalinux-tools-reference-guide.pdf)

---

**작성자**: 나무  
**날짜**: 2025-11-12  
**버전**: 1.0
