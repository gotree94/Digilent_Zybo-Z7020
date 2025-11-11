# ALU AXI 프로젝트 파일 목록

## 📁 프로젝트 구조

```
zybo_alu_axi/
│
├── hdl/                              # 하드웨어 설계 파일
│   ├── alu.v                        # 원본 8비트 ALU 모듈
│   └── alu_axi_lite_v1_0.v         # AXI-Lite 인터페이스 래퍼
│
├── tcl/                              # Vivado 자동화 스크립트
│   └── create_project.tcl           # Vivado 프로젝트 생성 스크립트
│
├── sw/                               # 소프트웨어 (드라이버 및 애플리케이션)
│   ├── alu_driver.c                 # Linux 커널 드라이버 (sysfs 지원)
│   ├── alu-overlay.dts              # 디바이스 트리 오버레이
│   ├── alu_test_devmem.c            # 테스트 프로그램 (/dev/mem 버전)
│   ├── alu_test_sysfs.c             # 테스트 프로그램 (sysfs 버전)
│   ├── alu_test.sh                  # 쉘 스크립트 테스트 유틸리티
│   └── Makefile                     # 빌드 스크립트
│
├── docs/                             # 문서
│   ├── PETALINUX_SETUP.md           # PetaLinux 상세 설정 가이드
│   ├── QUICKSTART.md                # 빠른 시작 가이드
│   └── PROJECT_FILES.md             # 이 파일
│
└── README.md                         # 프로젝트 메인 문서
```

## 📄 파일 상세 설명

### 하드웨어 설계 (HDL)

#### 1. `hdl/alu.v`
- **설명**: 원본 8비트 ALU 모듈
- **입력**: 
  - `a[7:0]`: 8비트 피연산자 A
  - `b[7:0]`: 8비트 피연산자 B
  - `opcode[2:0]`: 3비트 연산 코드
  - `ena`: 활성화 신호
- **출력**: 
  - `result[15:0]`: 16비트 결과
- **연산**: ADD, SUB, MUL, DIV, MOD, EQ, GT, LT

#### 2. `hdl/alu_axi_lite_v1_0.v`
- **설명**: AXI-Lite 슬레이브 인터페이스 래퍼
- **기능**:
  - ALU를 AXI-Lite 버스에 연결
  - 4개의 32비트 레지스터 제공
  - Zynq PS에서 메모리 맵 방식으로 접근 가능
- **레지스터 맵**:
  - 0x00: OPERAND_A (R/W)
  - 0x04: OPERAND_B (R/W)
  - 0x08: CONTROL (R/W)
  - 0x0C: RESULT (R)
- **베이스 주소**: 0x43C00000

### Vivado 자동화

#### 3. `tcl/create_project.tcl`
- **설명**: Vivado 프로젝트 자동 생성 스크립트
- **기능**:
  - Zybo Z7-20용 프로젝트 생성
  - PS7 설정 및 구성
  - ALU 모듈을 Block Design에 추가
  - AXI Interconnect 연결
  - 주소 할당
- **사용법**: `vivado -mode tcl -source create_project.tcl`

### 소프트웨어

#### 4. `sw/alu_driver.c`
- **설명**: Linux 커널 모듈 드라이버
- **기능**:
  - 플랫폼 드라이버로 구현
  - Sysfs 인터페이스 제공
  - 디바이스 트리 연동
- **Sysfs 노드**:
  - `/sys/.../operand_a` - 피연산자 A 설정/읽기
  - `/sys/.../operand_b` - 피연산자 B 설정/읽기
  - `/sys/.../opcode` - 연산 코드 설정/읽기
  - `/sys/.../enable` - 활성화 설정/읽기
  - `/sys/.../result` - 결과 읽기 (읽기 전용)

#### 5. `sw/alu-overlay.dts`
- **설명**: 디바이스 트리 오버레이
- **목적**: 커널에 ALU 하드웨어 정보 전달
- **내용**:
  - compatible 문자열
  - 레지스터 베이스 주소 및 크기
  - 디바이스 활성화 상태

#### 6. `sw/alu_test_devmem.c`
- **설명**: 직접 메모리 접근 테스트 프로그램
- **기능**:
  - `/dev/mem`을 통한 레지스터 직접 접근
  - 모든 ALU 연산 테스트
  - 인터랙티브 모드
  - 성능 벤치마크
- **요구사항**: root 권한 필요
- **사용법**:
  ```bash
  sudo alu_test_devmem -t        # 전체 테스트
  sudo alu_test_devmem -i        # 인터랙티브
  sudo alu_test_devmem -c a b op # 단일 연산
  sudo alu_test_devmem -b        # 벤치마크
  ```

#### 7. `sw/alu_test_sysfs.c`
- **설명**: Sysfs 인터페이스 테스트 프로그램
- **기능**:
  - Sysfs를 통한 ALU 제어
  - 모든 ALU 연산 테스트
  - 인터랙티브 모드
- **장점**: root 권한 불필요 (드라이버가 로드된 경우)
- **사용법**:
  ```bash
  alu_test_sysfs -t        # 전체 테스트
  alu_test_sysfs -i        # 인터랙티브
  alu_test_sysfs -c a b op # 단일 연산
  ```

#### 8. `sw/alu_test.sh`
- **설명**: 쉘 스크립트 기반 빠른 테스트 유틸리티
- **기능**:
  - devmem 명령어를 사용한 직접 제어
  - 하드웨어 접근성 확인
  - 레지스터 덤프
  - 빠른 스모크 테스트
  - 벤치마크
- **사용법**:
  ```bash
  sudo ./alu_test.sh test       # 기본 테스트
  sudo ./alu_test.sh compute 10 5 0  # 단일 연산
  sudo ./alu_test.sh dump       # 레지스터 덤프
  sudo ./alu_test.sh smoke      # 스모크 테스트
  sudo ./alu_test.sh benchmark  # 벤치마크
  ```

#### 9. `sw/Makefile`
- **설명**: C 프로그램 빌드 스크립트
- **타겟**:
  - `all` - 모든 프로그램 빌드
  - `alu_test_devmem` - devmem 버전 빌드
  - `alu_test_sysfs` - sysfs 버전 빌드
  - `clean` - 빌드 산출물 삭제
  - `install` - 프로그램 설치
- **크로스 컴파일**: `CROSS_COMPILE` 변수 수정

### 문서

#### 10. `docs/PETALINUX_SETUP.md`
- **설명**: PetaLinux 상세 설정 가이드
- **내용**:
  - 사전 요구사항
  - Vivado 프로젝트 생성 단계
  - PetaLinux 프로젝트 생성
  - 커널 드라이버 통합
  - 디바이스 트리 설정
  - 애플리케이션 추가
  - 빌드 및 부팅
  - 트러블슈팅

#### 11. `docs/QUICKSTART.md`
- **설명**: 5분 빠른 시작 가이드
- **내용**:
  - 체크리스트
  - 단계별 빠른 가이드
  - 예상 결과
  - 주요 명령어
  - 트러블슈팅

#### 12. `README.md`
- **설명**: 프로젝트 메인 문서
- **내용**:
  - 프로젝트 개요
  - 아키텍처 설명
  - 레지스터 맵
  - 사용 예제
  - 성능 정보
  - 확장 가능성

## 🔄 워크플로우

### 개발 워크플로우
```
1. HDL 설계 (alu.v, alu_axi_lite_v1_0.v)
   ↓
2. Vivado 프로젝트 생성 (create_project.tcl)
   ↓
3. 비트스트림 생성
   ↓
4. 하드웨어 내보내기 (.xsa)
   ↓
5. PetaLinux 프로젝트 생성
   ↓
6. 드라이버 추가 (alu_driver.c, alu-overlay.dts)
   ↓
7. 애플리케이션 추가 (alu_test_*.c)
   ↓
8. PetaLinux 빌드
   ↓
9. SD 카드 준비
   ↓
10. 보드 부팅 및 테스트
```

### 테스트 워크플로우
```
1. 하드웨어 접근성 확인
   └─> ./alu_test.sh check
   
2. 스모크 테스트
   └─> ./alu_test.sh smoke
   
3. 전체 기능 테스트
   └─> alu_test_devmem -t
   
4. 인터랙티브 테스트
   └─> alu_test_devmem -i
   
5. 성능 벤치마크
   └─> alu_test_devmem -b
```

## 📊 파일 크기 및 라인 수

| 파일 | 언어 | 라인 수 (대략) | 용도 |
|------|------|----------------|------|
| alu.v | Verilog | 49 | ALU 로직 |
| alu_axi_lite_v1_0.v | Verilog | 250 | AXI 인터페이스 |
| create_project.tcl | Tcl | 100 | 프로젝트 자동화 |
| alu_driver.c | C | 300 | 커널 드라이버 |
| alu_test_devmem.c | C | 450 | 테스트 앱 (devmem) |
| alu_test_sysfs.c | C | 350 | 테스트 앱 (sysfs) |
| alu_test.sh | Bash | 350 | 쉘 유틸리티 |

## 🔧 빌드 요구사항

### 호스트 시스템
- Ubuntu 20.04/22.04
- 8GB RAM 이상
- 100GB 이상 디스크 공간
- Vivado 2022.2 이상
- PetaLinux 2022.2 이상

### 타겟 시스템
- Zybo Z7-20 보드
- 8GB 이상 SD 카드
- USB-UART 케이블
- 5V/2A 전원 어댑터

## 📝 버전 정보

- **프로젝트 버전**: 1.0
- **작성 날짜**: 2025-11-12
- **작성자**: 나무
- **타겟 보드**: Digilent Zybo Z7-20
- **Vivado 버전**: 2022.2+
- **PetaLinux 버전**: 2022.2+

## 🔗 의존성

### HDL 파일
- `alu_axi_lite_v1_0.v` depends on `alu.v`

### 소프트웨어
- `alu_test_devmem.c` - 독립적 (libc만 필요)
- `alu_test_sysfs.c` - 드라이버 필요
- `alu_driver.c` - 커널 헤더 필요
- `alu_test.sh` - devmem 명령어 필요

## 📦 배포

### 최소 배포 패키지
보드에서 실행하기 위한 최소 파일:
- BOOT.BIN
- image.ub
- boot.scr
- rootfs.tar.gz (드라이버 및 앱 포함)

### 개발 패키지
전체 소스코드 및 빌드 스크립트:
- 모든 hdl/ 파일
- 모든 tcl/ 파일
- 모든 sw/ 파일
- 모든 docs/ 파일

## 🎯 사용 시나리오

1. **교육용**: FPGA 기반 하드웨어 가속기 학습
2. **프로토타입**: 커스텀 연산 유닛 검증
3. **벤치마크**: 하드웨어 vs 소프트웨어 성능 비교
4. **개발 템플릿**: AXI 기반 IP 개발의 시작점

---

**문서 버전**: 1.0  
**마지막 업데이트**: 2025-11-12
