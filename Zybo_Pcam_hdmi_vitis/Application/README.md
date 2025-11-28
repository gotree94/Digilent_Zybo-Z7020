# Vitis 작업 절차 - PCAM5C HDMI 프로젝트

## 1. 사전 준비

### 1.1 Vivado에서 Hardware Export
```
Vivado에서:
1. Generate Bitstream 완료
2. File → Export → Export Hardware
   - Include bitstream 체크
   - Export to: <project>/vivado/
   - 파일명: design_1_wrapper.xsa
```

## 2. Vitis 프로젝트 생성

### 2.1 Vitis 실행
```bash
# Vitis 2022.x 이상 실행
vitis &
```

### 2.2 Workspace 설정
- Workspace: `<project>/vitis/workspace`

### 2.3 Platform 생성
```
File → New → Platform Project
1. Platform name: zynq_z7_pcam5c_platform
2. Hardware Specification: design_1_wrapper.xsa 선택
3. Operating System: standalone
4. Processor: ps7_cortexa9_0
5. Generate Boot Components 체크
6. Finish
```

### 2.4 Application 프로젝트 생성
```
File → New → Application Project
1. Platform: zynq_z7_pcam5c_platform 선택
2. Application name: pcam5c_hdmi_app
3. System project: pcam5c_hdmi_system
4. Domain: standalone_ps7_cortexa9_0
5. Template: Empty Application
6. Finish
```

## 3. 소스 파일 추가

### 3.1 소스 파일 복사
```
vitis/src/ 폴더의 파일들을 프로젝트에 추가:
- main.c
- ov5640.c
- ov5640.h
- video_display.c
- video_display.h

방법:
1. Project Explorer에서 pcam5c_hdmi_app/src 우클릭
2. Import → General → File System
3. vitis/src 폴더 선택
4. 모든 파일 체크
5. Finish
```

### 3.2 BSP 설정 확인
```
Platform 프로젝트에서:
1. platform.spr 더블클릭
2. Board Support Package 확인
   - xilffs (선택사항: SD 카드 사용시)
   - xilpm (선택사항)
```

## 4. 빌드 설정

### 4.1 Include Path 설정
```
Application 프로젝트 우클릭 → Properties
C/C++ Build → Settings → ARM v7 gcc compiler → Directories
Include paths에 추가:
- ${workspace_loc}/zynq_z7_pcam5c_platform/export/zynq_z7_pcam5c_platform/sw/zynq_z7_pcam5c_platform/standalone_domain/bspinclude/include
```

### 4.2 Linker Script 수정 (필요시)
```
lscript.ld 에서 힙/스택 크기 조정:
_HEAP_SIZE = 0x800000;   /* 8MB heap */
_STACK_SIZE = 0x100000;  /* 1MB stack */
```

## 5. 빌드 및 실행

### 5.1 Platform 빌드
```
Platform 프로젝트 우클릭 → Build Project
```

### 5.2 Application 빌드
```
Application 프로젝트 우클릭 → Build Project
```

### 5.3 하드웨어 연결
```
1. Zybo Z7-20 보드 전원 연결
2. USB-JTAG 케이블 연결
3. PCAM5C 카메라 연결
4. HDMI 모니터 연결
5. JP6 점퍼: 2V5 위치 확인 (MIPI용)
```

### 5.4 프로그램 실행
```
Application 프로젝트 우클릭 → Run As → Launch on Hardware

또는 Debug As로 디버깅 가능
```

## 6. 시리얼 터미널 설정

### 6.1 터미널 연결
```
- Baud Rate: 115200
- Data Bits: 8
- Parity: None
- Stop Bits: 1
- Flow Control: None

Linux:
minicom -D /dev/ttyUSB1 -b 115200

Windows:
PuTTY 또는 TeraTerm 사용
```

### 6.2 예상 출력
```
========================================
  PCAM5C HDMI Output Application
  Zybo Z7-20 + OV5640
========================================

GPIO: Initialized
Camera: Power ON
I2C: Initialized at 100000 Hz
VDMA: Initialized
VideoDisplay: Initialized 1920x1080, 32 bpp
OV5640: Chip ID 0x5640 detected
OV5640: Initialized successfully
OV5640: Mode set to 1920x1080
MIPI: D-PHY and CSI-2 enabled
Video Processing: Demosaic and Gamma configured
VideoDisplay: Test pattern 0 drawn

System initialization complete!
Connect HDMI display and press any key to continue...

========================================
  PCAM5C HDMI Output - Zybo Z7-20
========================================
  1. Start video streaming
  2. Stop video streaming
  3. Switch to 720p @ 60fps
  4. Switch to 1080p @ 30fps
  5. Enable test pattern
  6. Disable test pattern
  7. Display test pattern (SW)
  8. Print status
  9. Reset camera
  0. Exit
========================================
Select option:
```

## 7. 문제 해결

### 7.1 카메라 감지 실패
```
증상: "OV5640: Sensor not detected"

확인사항:
1. PCAM5C 케이블 연결 확인
2. cam_gpio (전원) 신호 확인
3. I2C 연결 확인 (SDA, SCL)
4. JP6 점퍼 위치 확인
```

### 7.2 HDMI 출력 없음
```
증상: 모니터에 영상 출력 없음

확인사항:
1. HDMI 케이블 연결 확인
2. 모니터가 1080p 지원하는지 확인
3. RGB2DVI IP 설정 확인
4. VDMA 상태 확인 (옵션 8)
```

### 7.3 I2C 통신 실패
```
증상: I2C 읽기/쓰기 실패

확인사항:
1. I2C 주소: 0x3C (7-bit)
2. I2C 클럭: 100KHz
3. Pull-up 저항 확인
```

### 7.4 MIPI 오류
```
증상: 영상이 깨지거나 없음

확인사항:
1. MIPI D-PHY 상태 레지스터 확인
2. CSI-2 상태 레지스터 확인
3. 클럭 설정 확인
```

## 8. 파일 구조

```
vitis/
├── src/
│   ├── main.c              # 메인 애플리케이션
│   ├── ov5640.c            # OV5640 카메라 드라이버
│   ├── ov5640.h            # OV5640 헤더
│   ├── video_display.c     # 비디오 디스플레이 드라이버
│   └── video_display.h     # 비디오 디스플레이 헤더
└── workspace/              # Vitis workspace (생성됨)
```

## 9. 주요 기능

### 9.1 지원 해상도
- 1920x1080 @ 30fps (기본)
- 1280x720 @ 60fps

### 9.2 지원 기능
- 실시간 카메라 영상 출력
- 해상도 전환
- 테스트 패턴 표시 (카메라/소프트웨어)
- 상태 모니터링

## 10. 참고 자료

- OV5640 Datasheet
- Zybo Z7 Reference Manual
- Xilinx AXI VDMA Product Guide (PG020)
- Digilent MIPI D-PHY/CSI-2 IP Documentation
- Digilent RGB2DVI IP Documentation
