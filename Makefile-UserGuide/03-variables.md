# 3. Make 변수 활용

## 변수 정의와 할당

Make 변수는 반복되는 값을 저장하고 재사용하는 데 사용됩니다.

### 변수 할당 방법

```makefile
# 1. 재귀적 할당 (=)
# 변수가 사용될 때 확장됨
CC = gcc
CFLAGS = -Wall $(OPTIMIZATION)
OPTIMIZATION = -O2

# 2. 단순 할당 (:=)
# 변수가 정의될 때 즉시 확장됨
DIR := /home/user
FILES := $(wildcard $(DIR)/*.c)

# 3. 조건부 할당 (?=)
# 변수가 정의되지 않았을 때만 할당
CC ?= gcc
CFLAGS ?= -Wall

# 4. 추가 할당 (+=)
# 기존 값에 추가
CFLAGS = -Wall
CFLAGS += -g
CFLAGS += -O2
# 결과: CFLAGS = -Wall -g -O2
```

### 할당 방법 비교

```makefile
# 재귀적 할당 (=) 예제
A = $(B)
B = $(C)
C = Hello
# A 사용 시: Hello

# 단순 할당 (:=) 예제
X := $(Y)
Y := World
# X 값: (비어있음, Y가 아직 정의 안됨)

# 실용 예제
SHELL_OUTPUT = $(shell date)  # 매번 실행
SHELL_OUTPUT := $(shell date) # 한 번만 실행
```

### 변수 사용

```makefile
CC = gcc
CFLAGS = -Wall -g

# 변수 참조: $(변수명) 또는 ${변수명}
program: main.c
	$(CC) $(CFLAGS) -o program main.c

# 한 글자 변수는 괄호 없이 가능 (비추천)
program: main.c
	$C $C -o program main.c  # 권장하지 않음
```

## 자동 변수 (Automatic Variables)

Make가 자동으로 설정하는 특수 변수들입니다.

### 주요 자동 변수

```makefile
# $@ - 현재 타겟 이름
program: main.o utils.o
	gcc -o $@ main.o utils.o
	# $@ = program

# $< - 첫 번째 의존 파일
%.o: %.c
	gcc -c $< -o $@
	# $< = 해당 .c 파일

# $^ - 모든 의존 파일 (중복 제거)
program: main.o utils.o common.o
	gcc -o $@ $^
	# $^ = main.o utils.o common.o

# $+ - 모든 의존 파일 (중복 포함)
archive.a: obj1.o obj2.o obj1.o
	ar rcs $@ $+
	# $+ = obj1.o obj2.o obj1.o

# $? - 타겟보다 최신인 의존 파일들
program: main.o utils.o
	gcc -o $@ $?
	# 변경된 파일만 포함

# $* - 패턴 매칭에서 % 부분
%.o: %.c
	gcc -c $*.c -o $*.o
	# main.c -> main.o 일 때, $* = main
```

### 자동 변수 활용 예제

```makefile
# 패턴 규칙에서 자동 변수 사용
CC = gcc
CFLAGS = -Wall -g

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "Created $@"

program: main.o utils.o calc.o
	@echo "Linking $@..."
	$(CC) -o $@ $^
	@echo "Target $@ built from: $^"
```

### 자동 변수 변형

```makefile
# 디렉토리 추출
SRC = src/main.c
DIR = $(dir $(SRC))      # DIR = src/
FILE = $(notdir $(SRC))  # FILE = main.c

# 자동 변수에도 적용 가능
%.o: %.c
	@echo "Directory: $(dir $<)"
	@echo "Filename: $(notdir $<)"
	@echo "Basename: $(basename $<)"
	gcc -c $< -o $@
```

## 내장 변수

Make에 미리 정의된 변수들입니다.

### 컴파일러 관련 변수

```makefile
# C 컴파일러
CC = gcc
CFLAGS = -Wall -g -O2

# C++ 컴파일러
CXX = g++
CXXFLAGS = -Wall -g -O2 -std=c++17

# Fortran 컴파일러
FC = gfortran
FFLAGS = -Wall

# 어셈블러
AS = as
ASFLAGS =

# 링커 플래그
LDFLAGS = -L/usr/local/lib
LDLIBS = -lm -lpthread

# 전처리기 플래그
CPPFLAGS = -I./include -DDEBUG
```

### 프로그램 관련 변수

```makefile
# 아카이브 관리
AR = ar
ARFLAGS = rcs

# Make 프로그램
MAKE = make
MAKEFLAGS = 

# 셸
SHELL = /bin/bash

# 삭제 명령
RM = rm -f

# 설치 명령
INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
```

### 내장 변수 사용 예제

```makefile
CC = gcc
CFLAGS = -Wall -g -O2
CPPFLAGS = -I./include -I/usr/local/include
LDFLAGS = -L/usr/local/lib
LDLIBS = -lm -lpthread

SOURCES = main.c utils.c calc.c
OBJECTS = $(SOURCES:.c=.o)
TARGET = myprogram

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(TARGET) $(OBJECTS)
```

## 변수 치환 (Substitution References)

### 접미사 치환

```makefile
SOURCES = main.c utils.c calc.c
OBJECTS = $(SOURCES:.c=.o)
# OBJECTS = main.o utils.o calc.o

# 더 복잡한 치환
CSOURCES = main.c utils.c
CPPSOURCES = app.cpp helper.cpp
COBJECTS = $(CSOURCES:.c=.o)
CPPOBJECTS = $(CPPSOURCES:.cpp=.o)
ALL_OBJECTS = $(COBJECTS) $(CPPOBJECTS)
```

### 패턴 치환

```makefile
SOURCES = src/main.c src/utils.c src/calc.c

# src/*.c -> obj/*.o
OBJECTS = $(SOURCES:src/%.c=obj/%.o)
# OBJECTS = obj/main.o obj/utils.o obj/calc.o

# 또는 patsubst 함수 사용
OBJECTS = $(patsubst src/%.c,obj/%.o,$(SOURCES))
```

## 환경 변수

### 환경 변수 사용

```makefile
# 환경 변수는 자동으로 Make 변수가 됨
# 예: export CC=clang; make

# Makefile에서 환경 변수 참조
CC ?= gcc  # CC 환경 변수가 없으면 gcc 사용

# 환경 변수 우선순위
# 1. 명령행 변수 (make CC=clang)
# 2. Makefile 내 변수
# 3. 환경 변수

# 환경 변수 export
export PATH := $(PATH):/custom/path
export LD_LIBRARY_PATH := /usr/local/lib
```

### 실용 예제

```makefile
# 빌드 타입 환경 변수
BUILD_TYPE ?= debug

ifeq ($(BUILD_TYPE),debug)
    CFLAGS = -Wall -g -DDEBUG
else ifeq ($(BUILD_TYPE),release)
    CFLAGS = -Wall -O3 -DNDEBUG
else
    $(error Invalid BUILD_TYPE: $(BUILD_TYPE))
endif

# 사용법:
# make BUILD_TYPE=debug
# make BUILD_TYPE=release
```

## 변수 고급 기법

### 다중 라인 변수

```makefile
# 백슬래시로 연결
SOURCES = main.c \
          utils.c \
          calc.c \
          helper.c

# define 사용
define COMPILE_COMMAND
	@echo "Compiling $<"
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "Done"
endef

%.o: %.c
	$(COMPILE_COMMAND)
```

### 변수 내 변수

```makefile
# 간접 참조
PLATFORM = x86
x86_CC = gcc
arm_CC = arm-linux-gcc

CC = $($(PLATFORM)_CC)
# PLATFORM=x86 일 때, CC = gcc
# PLATFORM=arm 일 때, CC = arm-linux-gcc
```

### override 지시자

```makefile
# 명령행 인자를 무시하고 강제 설정
override CFLAGS += -Wall

# make CFLAGS="-O2" 실행 시
# CFLAGS = -O2 -Wall (추가됨)
```

## 실전 예제: 설정 관리

```makefile
# ============================================
# 프로젝트 설정
# ============================================
PROJECT := myapp
VERSION := 1.0.0

# ============================================
# 빌드 환경 설정
# ============================================
BUILD_TYPE ?= debug
PLATFORM ?= linux
ARCH ?= x86_64

# ============================================
# 컴파일러 설정
# ============================================
CC := gcc
CXX := g++
AR := ar

# ============================================
# 플래그 설정 (빌드 타입별)
# ============================================
COMMON_FLAGS := -Wall -Wextra
DEBUG_FLAGS := -g -O0 -DDEBUG
RELEASE_FLAGS := -O3 -DNDEBUG

ifeq ($(BUILD_TYPE),debug)
    CFLAGS := $(COMMON_FLAGS) $(DEBUG_FLAGS)
    CXXFLAGS := $(COMMON_FLAGS) $(DEBUG_FLAGS)
else
    CFLAGS := $(COMMON_FLAGS) $(RELEASE_FLAGS)
    CXXFLAGS := $(COMMON_FLAGS) $(RELEASE_FLAGS)
endif

# ============================================
# 디렉토리 설정
# ============================================
SRCDIR := src
INCDIR := include
OBJDIR := build/$(BUILD_TYPE)/obj
BINDIR := build/$(BUILD_TYPE)/bin

# ============================================
# 소스 및 오브젝트 파일
# ============================================
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(OBJECTS:.o=.d)

TARGET := $(BINDIR)/$(PROJECT)

# ============================================
# 빌드 규칙
# ============================================
.PHONY: all clean info

all: $(TARGET)
	@echo "Build complete: $(BUILD_TYPE) mode"

$(TARGET): $(OBJECTS)
	@mkdir -p $(BINDIR)
	$(CC) -o $@ $^ $(LDFLAGS) $(LDLIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	$(RM) -r build

info:
	@echo "Project: $(PROJECT) v$(VERSION)"
	@echo "Build Type: $(BUILD_TYPE)"
	@echo "Platform: $(PLATFORM)"
	@echo "Architecture: $(ARCH)"
	@echo "Compiler: $(CC)"
	@echo "Flags: $(CFLAGS)"
	@echo "Sources: $(SOURCES)"
	@echo "Objects: $(OBJECTS)"
	@echo "Target: $(TARGET)"

# 의존성 포함
-include $(DEPENDS)
```

## 연습 문제

### 문제 1: 변수 변환

다음 변수들을 변환하세요:
```makefile
SOURCES = lib/core.c lib/util.c app/main.c app/ui.c
```
- `lib/*.c` 파일만 추출
- `.c`를 `.o`로 변환
- `lib/`를 `build/lib/`로 변환

### 문제 2: 조건부 설정

다음 요구사항을 구현하세요:
- `VERBOSE=1` 옵션 시 모든 명령 출력
- `VERBOSE=0` 또는 미설정 시 조용한 빌드
- 최적화 레벨 `OPT=0,1,2,3` 지원

### 문제 3: 플랫폼별 설정

Linux, Windows, macOS에서 다른 컴파일러와 플래그를 사용하는 Makefile 작성

## 핵심 정리

✅ 변수 할당: `=` (재귀), `:=` (즉시), `?=` (조건), `+=` (추가)  
✅ 자동 변수: `$@` (타겟), `$<` (첫 의존성), `$^` (모든 의존성)  
✅ 내장 변수: `CC`, `CFLAGS`, `LDFLAGS` 등 표준 변수 활용  
✅ 변수 치환: `$(VAR:.c=.o)` 또는 `$(patsubst)` 함수  
✅ 환경 변수와 명령행 변수 활용 가능  

---

**이전 장**: [Make 문법과 규칙](./02-syntax.md)  
**다음 장**: [고급 Make 기능](./04-advanced.md)
