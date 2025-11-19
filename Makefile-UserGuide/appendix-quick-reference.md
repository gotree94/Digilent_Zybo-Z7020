# 부록: Make 빠른 참조 가이드

## 자주 사용하는 Make 명령어

```bash
# 기본 빌드
make
make all

# 특정 타겟 빌드
make clean
make install
make test

# 변수 오버라이드
make CC=clang
make BUILD_TYPE=release
make PREFIX=/opt/myapp

# 병렬 빌드
make -j4              # 4개 병렬
make -j$(nproc)       # CPU 코어 수만큼

# 디버깅
make -n               # Dry run (실행하지 않고 출력만)
make -d               # 디버그 모드
make print-VARIABLE   # 변수 값 출력

# 특정 디렉토리에서 실행
make -C path/to/dir

# Makefile 이름 지정
make -f MyMakefile
```

## 기본 Makefile 구조

```makefile
# 변수 정의
CC = gcc
CFLAGS = -Wall -g
LDLIBS = -lm

# 타겟: 의존성
target: dependency1 dependency2
	command   # 반드시 TAB으로 들여쓰기

# 패턴 규칙
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Phony 타겟
.PHONY: clean
clean:
	rm -f *.o program
```

## 자동 변수

| 변수 | 의미 | 예제 |
|------|------|------|
| `$@` | 현재 타겟 | `program: main.o` → `$@` = `program` |
| `$<` | 첫 번째 의존성 | `%.o: %.c` → `$<` = `main.c` |
| `$^` | 모든 의존성 (중복 제거) | `$^` = `main.o utils.o` |
| `$+` | 모든 의존성 (중복 포함) | `$+` = `main.o utils.o main.o` |
| `$?` | 타겟보다 최신인 의존성 | 변경된 파일만 |
| `$*` | 패턴의 % 부분 | `main.o: main.c` → `$*` = `main` |

## 변수 할당

| 문법 | 설명 | 예제 |
|------|------|------|
| `=` | 재귀적 할당 | `X = $(Y)` (Y가 나중에 정의 가능) |
| `:=` | 단순 할당 | `X := $(Y)` (즉시 확장) |
| `?=` | 조건부 할당 | `X ?= value` (X가 없을 때만) |
| `+=` | 추가 할당 | `X += value` (기존 값에 추가) |

## 주요 함수

### 문자열 함수

```makefile
# 치환
$(subst from,to,text)
$(patsubst pattern,replacement,text)

# 필터
$(filter pattern,text)
$(filter-out pattern,text)

# 정렬 및 추출
$(sort list)
$(word n,text)
$(words text)
$(firstword text)
$(lastword text)

# 공백 제거
$(strip text)

# 검색
$(findstring find,text)
```

### 파일 이름 함수

```makefile
# 경로 처리
$(dir names)          # 디렉토리 부분
$(notdir names)       # 파일명만
$(suffix names)       # 확장자
$(basename names)     # 확장자 제거

# 추가
$(addprefix prefix,names)
$(addsuffix suffix,names)
$(join list1,list2)

# 검색
$(wildcard pattern)
$(realpath names)
$(abspath names)
```

### 제어 함수

```makefile
# 조건
$(if condition,then-part,else-part)

# 반복
$(foreach var,list,text)

# 함수 호출
$(call function,param1,param2,...)

# 셸 명령
$(shell command)

# 메시지
$(info text)
$(warning text)
$(error text)
```

## 조건문

```makefile
# ifeq/ifneq
ifeq ($(VAR),value)
    # 같으면
else
    # 다르면
endif

ifneq ($(VAR),value)
    # 다르면
endif

# ifdef/ifndef
ifdef VAR
    # 정의되어 있으면
endif

ifndef VAR
    # 정의되어 있지 않으면
endif

# 다중 조건
ifeq ($(BUILD),debug)
    CFLAGS = -g
else ifeq ($(BUILD),release)
    CFLAGS = -O3
else
    $(error Invalid BUILD)
endif
```

## 내장 규칙 변수

### 컴파일러

```makefile
CC          # C 컴파일러 (기본: cc)
CXX         # C++ 컴파일러 (기본: g++)
FC          # Fortran 컴파일러
AS          # 어셈블러
AR          # 아카이브 (기본: ar)
```

### 플래그

```makefile
CFLAGS      # C 컴파일 플래그
CXXFLAGS    # C++ 컴파일 플래그
CPPFLAGS    # 전처리기 플래그 (-I, -D)
LDFLAGS     # 링커 플래그 (-L)
LDLIBS      # 링크 라이브러리 (-l)
ARFLAGS     # ar 플래그 (기본: rv)
```

### 프로그램

```makefile
RM          # 삭제 명령 (기본: rm -f)
SHELL       # 셸 (기본: /bin/sh)
MAKE        # Make 프로그램
```

## 특수 타겟

```makefile
# 기본 타겟 지정
.DEFAULT_GOAL := all

# Phony 타겟 선언
.PHONY: clean all install

# 순차 실행
.NOTPARALLEL:

# 중간 파일 유지
.PRECIOUS: %.o

# 중간 파일 삭제
.INTERMEDIATE: %.i

# 접미사 규칙
.SUFFIXES: .c .o

# 기본 규칙 무시
.SUFFIXES:
```

## 디버깅 팁

```makefile
# 변수 값 출력
$(info Variable X = $(X))
$(warning This is a warning)
$(error This stops the build)

# 타겟 추적
target:
	@echo "Building $@"
	@echo "From: $^"
	@echo "Changed: $?"

# 변수 출력 타겟
print-%:
	@echo '$* = $($*)'

# 사용: make print-CFLAGS
```

## 의존성 자동 생성

```makefile
# GCC를 이용한 자동 의존성
DEPFLAGS = -MMD -MP

%.o: %.c
	$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

# 의존성 파일 포함
-include $(OBJECTS:.o=.d)
```

## 병렬 빌드 최적화

```makefile
# CPU 코어 수만큼 병렬
MAKEFLAGS += -j$(shell nproc)

# 출력 동기화
MAKEFLAGS += --output-sync=target

# 디렉토리를 order-only prerequisite로
$(OBJECTS): | $(OBJDIR)

$(OBJDIR):
	@mkdir -p $@
```

## 일반적인 패턴

### 기본 C 프로젝트

```makefile
CC = gcc
CFLAGS = -Wall -g
LDLIBS = -lm

SOURCES = $(wildcard *.c)
OBJECTS = $(SOURCES:.c=.o)
TARGET = program

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) -o $@ $^ $(LDLIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJECTS)

.PHONY: all clean
```

### 디렉토리 구조화된 프로젝트

```makefile
SRCDIR = src
OBJDIR = obj
BINDIR = bin

SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TARGET = $(BINDIR)/program

all: $(TARGET)

$(TARGET): $(OBJECTS) | $(BINDIR)
	$(CC) -o $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR) $(BINDIR):
	mkdir -p $@

clean:
	rm -rf $(OBJDIR) $(BINDIR)

.PHONY: all clean
```

### 정적 라이브러리

```makefile
LIB = libmylib.a

SOURCES = $(wildcard src/*.c)
OBJECTS = $(SOURCES:.c=.o)

$(LIB): $(OBJECTS)
	$(AR) rcs $@ $^

clean:
	rm -f $(LIB) $(OBJECTS)
```

### 공유 라이브러리

```makefile
LIB = libmylib.so
CFLAGS += -fPIC

$(LIB): $(OBJECTS)
	$(CC) -shared -o $@ $^

install:
	install -m 755 $(LIB) $(PREFIX)/lib
	ldconfig
```

## 자주 하는 실수

### 1. TAB vs 스페이스

```makefile
# ❌ 잘못됨 (스페이스 사용)
target:
    command

# ✅ 올바름 (TAB 사용)
target:
	command
```

### 2. 의존성 누락

```makefile
# ❌ 잘못됨
program: main.o
	gcc -o program main.o

# ✅ 올바름 (헤더 의존성 포함)
program: main.o utils.h
	gcc -o program main.o
```

### 3. 변수 할당

```makefile
# ❌ 잘못됨 (무한 재귀)
CFLAGS = $(CFLAGS) -Wall

# ✅ 올바름
CFLAGS += -Wall
# 또는
CFLAGS := $(CFLAGS) -Wall
```

### 4. Phony 타겟 미선언

```makefile
# ❌ clean 파일이 존재하면 실행 안됨
clean:
	rm -f *.o

# ✅ 올바름
.PHONY: clean
clean:
	rm -f *.o
```

## 유용한 Make 트릭

### 색상 출력

```makefile
# 색상 정의
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m # No Color

# 사용
$(TARGET): $(OBJECTS)
	@echo "$(GREEN)Linking $@...$(NC)"
	$(CC) -o $@ $^
```

### 진행률 표시

```makefile
TOTAL_SOURCES := $(words $(SOURCES))
CURRENT := 0

%.o: %.c
	$(eval CURRENT=$(shell echo $$(($(CURRENT)+1))))
	@echo "[$(CURRENT)/$(TOTAL_SOURCES)] Compiling $<"
	$(CC) $(CFLAGS) -c $< -o $@
```

### 타임스탬프

```makefile
BUILD_TIME := $(shell date +%Y%m%d_%H%M%S)
CFLAGS += -DBUILD_TIME=\"$(BUILD_TIME)\"
```

## 참고 자료

- [GNU Make 공식 문서](https://www.gnu.org/software/make/manual/)
- [Make 튜토리얼](https://makefiletutorial.com/)
- `man make` - Make 매뉴얼 페이지
- `info make` - GNU Info 문서

---

**처음으로**: [README](../README.md)
