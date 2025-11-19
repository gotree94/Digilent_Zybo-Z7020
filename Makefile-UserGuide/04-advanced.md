# 4. 고급 Make 기능

## Make 함수

Make는 문자열 처리와 파일 조작을 위한 다양한 내장 함수를 제공합니다.

### 함수 호출 문법

```makefile
# 문법: $(function arguments)
# 또는: ${function arguments}

result = $(subst old,new,$(variable))
```

### 문자열 함수

```makefile
# 1. subst - 문자열 치환
SOURCES = main.c utils.c calc.c
OBJECTS = $(subst .c,.o,$(SOURCES))
# OBJECTS = main.o utils.o calc.o

# 2. patsubst - 패턴 치환
SOURCES = src/main.c src/utils.c
OBJECTS = $(patsubst src/%.c,obj/%.o,$(SOURCES))
# OBJECTS = obj/main.o obj/utils.o

# 3. strip - 공백 제거
TEXT = "  hello   world  "
CLEAN = $(strip $(TEXT))
# CLEAN = "hello world"

# 4. findstring - 문자열 찾기
TEXT = "Hello World"
RESULT = $(findstring World,$(TEXT))
# RESULT = "World" (찾으면 문자열 반환, 못찾으면 빈 문자열)

# 5. filter - 패턴 매칭 필터
FILES = main.c utils.c readme.txt calc.c
CFILES = $(filter %.c,$(FILES))
# CFILES = main.c utils.c calc.c

# 6. filter-out - 패턴 매칭 제외
FILES = main.c utils.c test.c
SOURCES = $(filter-out test.c,$(FILES))
# SOURCES = main.c utils.c

# 7. sort - 정렬 및 중복 제거
LIST = c b a c b
SORTED = $(sort $(LIST))
# SORTED = a b c

# 8. word - n번째 단어 추출
TEXT = one two three four
SECOND = $(word 2,$(TEXT))
# SECOND = two

# 9. words - 단어 개수
TEXT = one two three
COUNT = $(words $(TEXT))
# COUNT = 3

# 10. firstword, lastword
LIST = a b c d
FIRST = $(firstword $(LIST))  # FIRST = a
LAST = $(lastword $(LIST))    # LAST = d
```

### 파일 이름 함수

```makefile
# 1. dir - 디렉토리 경로 추출
PATH = src/utils/helper.c
DIR = $(dir $(PATH))
# DIR = src/utils/

# 2. notdir - 파일명만 추출
PATH = src/utils/helper.c
FILE = $(notdir $(PATH))
# FILE = helper.c

# 3. suffix - 확장자 추출
FILE = main.c
EXT = $(suffix $(FILE))
# EXT = .c

# 4. basename - 확장자 제거
FILE = main.c
BASE = $(basename $(FILE))
# BASE = main

# 5. addsuffix - 접미사 추가
FILES = main utils calc
CFILES = $(addsuffix .c,$(FILES))
# CFILES = main.c utils.c calc.c

# 6. addprefix - 접두사 추가
FILES = main.c utils.c
SOURCES = $(addprefix src/,$(FILES))
# SOURCES = src/main.c src/utils.c

# 7. join - 두 리스트 결합
DIRS = src/ lib/ app/
FILES = main.c util.c core.c
PATHS = $(join $(DIRS),$(FILES))
# PATHS = src/main.c lib/util.c app/core.c

# 8. wildcard - 파일 검색
SOURCES = $(wildcard src/*.c)
HEADERS = $(wildcard include/*.h)

# 9. realpath - 절대 경로 변환
RELPATH = ../src/main.c
ABSPATH = $(realpath $(RELPATH))
# ABSPATH = /home/user/project/src/main.c

# 10. abspath - 절대 경로 (심볼릭 링크 유지)
PATH = ./src
ABSOLUTE = $(abspath $(PATH))
```

### 제어 함수

```makefile
# 1. if - 조건문
DEBUG = 1
CFLAGS = $(if $(DEBUG),-g,-O2)
# DEBUG가 비어있지 않으면 -g, 비어있으면 -O2

# 2. foreach - 반복문
DIRS = src include lib
CREATE_DIRS = $(foreach dir,$(DIRS),mkdir -p $(dir);)
# CREATE_DIRS = mkdir -p src; mkdir -p include; mkdir -p lib;

# 실용 예제
SOURCES = main.c utils.c calc.c
OBJECTS = $(foreach src,$(SOURCES),$(src:.c=.o))

# 3. call - 사용자 정의 함수 호출
define COMPILE
	gcc -c $(1) -o $(2)
endef

main.o: main.c
	$(call COMPILE,$<,$@)

# 4. eval - 동적 규칙 생성
define PROGRAM_template
$(1): $(1).o
	gcc -o $(1) $(1).o
endef

PROGRAMS = prog1 prog2 prog3
$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))

# 5. origin - 변수 출처 확인
$(info CC origin: $(origin CC))
# undefined, default, environment, file, command line, override, automatic

# 6. flavor - 변수 타입 확인
VAR1 = value
VAR2 := value
$(info VAR1 flavor: $(flavor VAR1))  # recursive
$(info VAR2 flavor: $(flavor VAR2))  # simple

# 7. shell - 셸 명령 실행
CURRENT_DATE = $(shell date +%Y-%m-%d)
GIT_COMMIT = $(shell git rev-parse --short HEAD)
CPU_COUNT = $(shell nproc)

# 8. error, warning, info - 메시지 출력
$(error This is an error message)
$(warning This is a warning message)
$(info This is an info message)
```

## 조건문과 분기

### ifeq/ifneq - 문자열 비교

```makefile
# 같으면 (ifeq)
ifeq ($(CC),gcc)
    CFLAGS += -fdiagnostics-color=always
endif

# 다르면 (ifneq)
ifneq ($(BUILD_TYPE),release)
    CFLAGS += -DDEBUG
endif

# 다중 값 비교
ifeq ($(PLATFORM),linux)
    LDFLAGS += -ldl
else ifeq ($(PLATFORM),macos)
    LDFLAGS += -framework CoreFoundation
else ifeq ($(PLATFORM),windows)
    LDFLAGS += -lws2_32
else
    $(error Unknown platform: $(PLATFORM))
endif
```

### ifdef/ifndef - 변수 정의 확인

```makefile
# 정의되어 있으면
ifdef DEBUG
    CFLAGS += -g -O0
endif

# 정의되어 있지 않으면
ifndef VERBOSE
    MAKEFLAGS += --silent
endif

# 중첩 조건문
ifdef RELEASE
    CFLAGS += -O3
    ifndef NO_STRIP
        LDFLAGS += -s
    endif
endif
```

### 실용적인 조건문 예제

```makefile
# ============================================
# 플랫폼 감지
# ============================================
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
    PLATFORM = linux
    CFLAGS += -D__LINUX__
    LDLIBS += -lpthread -ldl
else ifeq ($(UNAME_S),Darwin)
    PLATFORM = macos
    CFLAGS += -D__MACOS__
    LDLIBS += -framework CoreFoundation
else ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
    PLATFORM = windows
    CFLAGS += -D__WINDOWS__
    LDLIBS += -lws2_32
else
    $(error Unsupported platform: $(UNAME_S))
endif

# ============================================
# 컴파일러 감지
# ============================================
CC_VERSION := $(shell $(CC) --version)

ifneq (,$(findstring gcc,$(CC_VERSION)))
    COMPILER = gcc
    CFLAGS += -fdiagnostics-color=always
else ifneq (,$(findstring clang,$(CC_VERSION)))
    COMPILER = clang
    CFLAGS += -fcolor-diagnostics
endif

# ============================================
# 빌드 모드 설정
# ============================================
BUILD_MODE ?= debug

ifeq ($(BUILD_MODE),debug)
    CFLAGS += -g -O0 -DDEBUG
    $(info Building in DEBUG mode)
else ifeq ($(BUILD_MODE),release)
    CFLAGS += -O3 -DNDEBUG
    $(info Building in RELEASE mode)
else ifeq ($(BUILD_MODE),profile)
    CFLAGS += -g -O2 -pg
    LDFLAGS += -pg
    $(info Building in PROFILE mode)
else
    $(error Invalid BUILD_MODE: $(BUILD_MODE). Use debug, release, or profile)
endif
```

## Include와 모듈화

### 기본 include

```makefile
# config.mk 파일 포함
include config.mk

# 여러 파일 포함
include rules.mk variables.mk

# 와일드카드 사용
include *.mk

# 파일이 없어도 에러 없이 계속 진행
-include optional.mk
```

### 실전 모듈화 예제

**Makefile** (메인)
```makefile
# ============================================
# 메인 Makefile
# ============================================
PROJECT = myapp

# 설정 파일 포함
include config/compiler.mk
include config/platform.mk
include config/directories.mk

# 빌드 규칙 포함
include rules/build.mk
include rules/test.mk

# 의존성 파일 포함 (있으면)
-include $(DEPENDS)

.PHONY: all clean test

all: $(TARGET)

clean:
	$(RM) -r $(BUILDDIR)

test: $(TEST_TARGET)
	@./$(TEST_TARGET)
```

**config/compiler.mk**
```makefile
# ============================================
# 컴파일러 설정
# ============================================
CC := gcc
CXX := g++
AR := ar
RANLIB := ranlib

# 공통 플래그
COMMON_FLAGS := -Wall -Wextra -Werror
DEBUG_FLAGS := -g -O0 -DDEBUG
RELEASE_FLAGS := -O3 -DNDEBUG

# 빌드 타입에 따른 플래그
BUILD_TYPE ?= debug

ifeq ($(BUILD_TYPE),debug)
    CFLAGS := $(COMMON_FLAGS) $(DEBUG_FLAGS)
else
    CFLAGS := $(COMMON_FLAGS) $(RELEASE_FLAGS)
endif
```

**config/platform.mk**
```makefile
# ============================================
# 플랫폼별 설정
# ============================================
UNAME := $(shell uname -s)

ifeq ($(UNAME),Linux)
    PLATFORM := linux
    CFLAGS += -D_GNU_SOURCE
    LDLIBS += -lpthread -ldl
else ifeq ($(UNAME),Darwin)
    PLATFORM := macos
    CFLAGS += -D_DARWIN_C_SOURCE
    LDLIBS += -framework CoreFoundation
endif

$(info Detected platform: $(PLATFORM))
```

**config/directories.mk**
```makefile
# ============================================
# 디렉토리 구조
# ============================================
SRCDIR := src
INCDIR := include
BUILDDIR := build/$(BUILD_TYPE)
OBJDIR := $(BUILDDIR)/obj
BINDIR := $(BUILDDIR)/bin
TESTDIR := tests

# 디렉토리 생성
$(shell mkdir -p $(OBJDIR) $(BINDIR))
```

**rules/build.mk**
```makefile
# ============================================
# 빌드 규칙
# ============================================
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(OBJECTS:.o=.d)

TARGET := $(BINDIR)/$(PROJECT)

$(TARGET): $(OBJECTS)
	@echo "Linking $@..."
	$(CC) -o $@ $^ $(LDFLAGS) $(LDLIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@
```

**rules/test.mk**
```makefile
# ============================================
# 테스트 규칙
# ============================================
TEST_SOURCES := $(wildcard $(TESTDIR)/*.c)
TEST_OBJECTS := $(TEST_SOURCES:$(TESTDIR)/%.c=$(OBJDIR)/test_%.o)
TEST_TARGET := $(BINDIR)/test_runner

$(TEST_TARGET): $(TEST_OBJECTS) $(filter-out $(OBJDIR)/main.o,$(OBJECTS))
	$(CC) -o $@ $^ $(LDFLAGS) $(LDLIBS)

$(OBJDIR)/test_%.o: $(TESTDIR)/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -I$(SRCDIR) -c $< -o $@
```

## 재귀적 Make

### 서브디렉토리 빌드

```makefile
# ============================================
# 메인 Makefile
# ============================================
SUBDIRS = lib app tests

.PHONY: all clean $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

# 또는 더 간단하게
clean:
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
```

### 변수 전달

```makefile
# ============================================
# 부모 Makefile
# ============================================
export CC := gcc
export CFLAGS := -Wall -g
export BUILD_TYPE := debug

SUBDIRS = module1 module2 module3

all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir BUILD_TYPE=$(BUILD_TYPE); \
	done
```

### 병렬 서브디렉토리 빌드

```makefile
SUBDIRS = lib1 lib2 app

# 순차 빌드 (기본)
all:
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done

# 병렬 빌드
.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

# 의존성 명시
app: lib1 lib2
```

### 고급 재귀 Make 예제

```makefile
# ============================================
# 최상위 Makefile
# ============================================
PROJECT_ROOT := $(CURDIR)
export PROJECT_ROOT

SUBDIRS = libs/core libs/utils apps/server apps/client

.PHONY: all clean install test help $(SUBDIRS)

all: $(SUBDIRS)

# 각 서브디렉토리는 타겟이 됨
$(SUBDIRS):
	@echo "=== Building $@ ==="
	@$(MAKE) -C $@ all

# 의존성 관계 명시
apps/server: libs/core libs/utils
apps/client: libs/core

# 정리
clean:
	@echo "Cleaning all subdirectories..."
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

# 설치
install: all
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir install; \
	done

# 테스트
test:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir test || exit 1; \
	done

# 도움말
help:
	@echo "Available targets:"
	@echo "  all     - Build all subdirectories"
	@echo "  clean   - Clean all subdirectories"
	@echo "  install - Install all components"
	@echo "  test    - Run all tests"
	@echo ""
	@echo "Subdirectories: $(SUBDIRS)"
```

## 동적 규칙 생성

### eval을 사용한 규칙 생성

```makefile
# ============================================
# 템플릿 정의
# ============================================
define PROGRAM_template =
$(1)_SOURCES := $$(wildcard $(1)/*.c)
$(1)_OBJECTS := $$($(1)_SOURCES:.c=.o)
$(1)_TARGET := bin/$(1)

$$($(1)_TARGET): $$($(1)_OBJECTS)
	@mkdir -p bin
	$(CC) -o $$@ $$^ $(LDFLAGS) $(LDLIBS)

.PHONY: $(1)
$(1): $$($(1)_TARGET)
endef

# ============================================
# 프로그램 리스트
# ============================================
PROGRAMS = app1 app2 app3

# 각 프로그램에 대한 규칙 생성
$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))

# 모든 프로그램 빌드
all: $(PROGRAMS)
```

### 복잡한 동적 규칙 예제

```makefile
# ============================================
# 라이브러리 템플릿
# ============================================
define LIBRARY_template =
$(1)_SRCDIR := libs/$(1)/src
$(1)_INCDIR := libs/$(1)/include
$(1)_OBJDIR := build/libs/$(1)
$(1)_SOURCES := $$(wildcard $$($(1)_SRCDIR)/*.c)
$(1)_OBJECTS := $$($(1)_SOURCES:$$($(1)_SRCDIR)/%.c=$$($(1)_OBJDIR)/%.o)
$(1)_TARGET := lib$(1).a

$$($(1)_TARGET): $$($(1)_OBJECTS)
	@echo "Creating library $$@"
	$(AR) rcs $$@ $$^

$$($(1)_OBJDIR)/%.o: $$($(1)_SRCDIR)/%.c
	@mkdir -p $$($(1)_OBJDIR)
	$(CC) $(CFLAGS) -I$$($(1)_INCDIR) -c $$< -o $$@

.PHONY: $(1)
$(1): $$($(1)_TARGET)
endef

# 라이브러리 생성
LIBRARIES = core utils network

$(foreach lib,$(LIBRARIES),$(eval $(call LIBRARY_template,$(lib))))

all: $(LIBRARIES)
```

## 연습 문제

### 문제 1: 함수 활용

모든 `.cpp` 파일을 찾아서 `build/debug/` 디렉토리에 `.o` 파일을 생성하는 변수를 작성하세요. (wildcard, patsubst 사용)

### 문제 2: 조건부 빌드

다음 빌드 모드를 지원하는 Makefile 작성:
- `MODE=debug`: `-g -O0`
- `MODE=release`: `-O3 -DNDEBUG`
- `MODE=profile`: `-g -O2 -pg`
- `MODE=sanitize`: `-g -O1 -fsanitize=address`

### 문제 3: 모듈화

프로젝트를 다음과 같이 모듈화하세요:
- `config/`: 설정 파일들
- `rules/`: 빌드 규칙들
- `scripts/`: 보조 스크립트들

### 문제 4: 동적 규칙

여러 실행 파일을 자동으로 생성하는 템플릿 작성 (각 실행 파일은 `apps/*/main.c`에 위치)

## 핵심 정리

✅ Make 함수: `$(subst)`, `$(patsubst)`, `$(filter)`, `$(wildcard)` 등  
✅ 파일 함수: `$(dir)`, `$(notdir)`, `$(basename)`, `$(addprefix)` 등  
✅ 조건문: `ifeq`, `ifneq`, `ifdef`, `ifndef`로 분기 처리  
✅ Include: 설정과 규칙을 모듈화하여 관리  
✅ 재귀 Make: 서브디렉토리 빌드에 `$(MAKE) -C` 사용  
✅ 동적 규칙: `eval`과 `call`로 규칙을 프로그래밍적으로 생성  

---

**이전 장**: [Make 변수 활용](./03-variables.md)  
**다음 장**: [실전 프로젝트 예제](./05-examples.md)
