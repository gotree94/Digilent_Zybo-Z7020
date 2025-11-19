# 6. Make 최적화와 디버깅

## 병렬 빌드

Make는 독립적인 타겟들을 병렬로 빌드하여 빌드 시간을 크게 단축시킬 수 있습니다.

### 기본 병렬 빌드

```bash
# -j 옵션: 병렬 작업 수 지정
make -j4    # 4개의 병렬 작업

# CPU 코어 수만큼 자동 설정
make -j$(nproc)

# 무제한 병렬 (권장하지 않음)
make -j
```

### Makefile에서 병렬 빌드 제어

```makefile
# ============================================
# 병렬 빌드 최적화
# ============================================

# 기본 병렬 작업 수 설정
MAKEFLAGS += -j4

# 또는 CPU 코어 수 자동 감지
NPROCS := $(shell nproc)
MAKEFLAGS += -j$(NPROCS)

# 특정 타겟은 순차 실행 (.NOTPARALLEL)
.NOTPARALLEL: install clean

# 또는 타겟별로 순서 지정
prog1: lib1
prog2: lib1 lib2
# prog1과 prog2는 병렬 가능, 하지만 의존성은 순서대로
```

### 병렬 빌드를 고려한 Makefile 작성

```makefile
# ============================================
# 병렬 빌드 안전 Makefile
# ============================================
CC := gcc
CFLAGS := -Wall -g

SRCDIR := src
OBJDIR := obj
BINDIR := bin

SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

TARGET := $(BINDIR)/program

# ============================================
# 디렉토리 생성을 order-only prerequisite로
# ============================================
$(OBJECTS): | $(OBJDIR)

$(TARGET): $(OBJECTS) | $(BINDIR)
	$(CC) -o $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# order-only prerequisites (|)
# 디렉토리가 존재하기만 하면 됨, 타임스탬프는 무시
$(OBJDIR) $(BINDIR):
	@mkdir -p $@

.PHONY: clean
clean:
	$(RM) -r $(OBJDIR) $(BINDIR)

# ============================================
# 성능 측정
# ============================================
.PHONY: bench
bench:
	@echo "Sequential build:"
	@time $(MAKE) clean all -j1
	@echo ""
	@echo "Parallel build (4 jobs):"
	@time $(MAKE) clean all -j4
	@echo ""
	@echo "Parallel build (8 jobs):"
	@time $(MAKE) clean all -j8
```

### 출력 동기화

병렬 빌드 시 출력이 섞이는 것을 방지:

```makefile
# Make 4.0 이상
MAKEFLAGS += --output-sync=target

# 또는
MAKEFLAGS += -O
```

## 의존성 자동 생성

컴파일러를 이용하여 자동으로 의존성을 생성하고 관리합니다.

### GCC 의존성 생성 옵션

```makefile
# -MMD: 의존성 파일 생성 (.d 파일)
# -MP: Phony 타겟 추가 (헤더 파일 삭제 시 오류 방지)

CC := gcc
CFLAGS := -Wall -g

SOURCES := main.c utils.c calc.c
OBJECTS := $(SOURCES:.c=.o)
DEPENDS := $(OBJECTS:.o=.d)

# ============================================
# 컴파일 시 의존성 자동 생성
# ============================================
%.o: %.c
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

# ============================================
# 의존성 파일 포함
# ============================================
-include $(DEPENDS)

# -include: 파일이 없어도 오류 없이 계속 진행
```

### 의존성 파일 예시

**main.d** (자동 생성됨)
```makefile
main.o: main.c utils.h config.h

# MP 옵션으로 생성된 phony 타겟
utils.h:
config.h:
```

### 완전한 의존성 관리 예제

```makefile
# ============================================
# 자동 의존성 관리 Makefile
# ============================================
CC := gcc
CFLAGS := -Wall -Wextra -g -O2
CPPFLAGS := -I./include

SRCDIR := src
OBJDIR := obj
DEPDIR := $(OBJDIR)/.deps

SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(SOURCES:$(SRCDIR)/%.c=$(DEPDIR)/%.d)

TARGET := program

# ============================================
# 의존성 플래그 생성
# ============================================
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

# ============================================
# 빌드 규칙
# ============================================
$(TARGET): $(OBJECTS)
	$(CC) -o $@ $^

# 컴파일 + 의존성 생성
$(OBJDIR)/%.o: $(SRCDIR)/%.c $(DEPDIR)/%.d | $(OBJDIR) $(DEPDIR)
	$(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# 디렉토리 생성
$(OBJDIR) $(DEPDIR):
	@mkdir -p $@

# 의존성 파일이 없어도 오류 방지
$(DEPENDS):

# 의존성 포함
-include $(DEPENDS)

.PHONY: clean
clean:
	$(RM) -r $(OBJDIR) $(TARGET)
```

## Make 디버깅 기법

### 디버깅 옵션

```bash
# 실행할 명령만 출력 (실행하지 않음)
make -n
make --dry-run
make --just-print

# 디버깅 정보 출력
make -d           # 모든 디버깅 정보
make --debug      # 기본 디버깅
make --debug=b    # 기본 디버깅
make --debug=v    # 상세 디버깅
make --debug=i    # 암시적 규칙 디버깅
make --debug=j    # 작업 정보
make --debug=m    # Makefile 업데이트 정보

# 특정 변수 출력
make --print-data-base
make -p

# 경고 활성화
make --warn-undefined-variables

# 무시 모드
make -i           # 오류 무시하고 계속
make --ignore-errors
```

### Makefile 내부 디버깅

```makefile
# ============================================
# 변수 값 출력
# ============================================

# 1. info 함수 사용
$(info Building for platform: $(PLATFORM))
$(info CFLAGS = $(CFLAGS))

# 2. warning 함수 사용
$(warning This is a warning message)

# 3. error 함수 사용 (빌드 중단)
ifndef CC
    $(error CC is not defined!)
endif

# 4. 변수 값 출력 타겟
.PHONY: debug-vars
debug-vars:
	@echo "CC = $(CC)"
	@echo "CFLAGS = $(CFLAGS)"
	@echo "SOURCES = $(SOURCES)"
	@echo "OBJECTS = $(OBJECTS)"
	@echo "TARGET = $(TARGET)"

# 5. 모든 변수 출력
print-%:
	@echo '$* = $($*)'

# 사용: make print-CFLAGS
```

### 타겟 추적

```makefile
# ============================================
# 타겟 실행 추적
# ============================================

# 각 타겟 시작/종료 로깅
define TRACE_TARGET
	@echo ">>> Building target: $@"
	@echo "    Prerequisites: $^"
	@echo "    Changed: $?"
endef

%.o: %.c
	$(TRACE_TARGET)
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "<<< Finished: $@"
```

### 고급 디버깅 Makefile

```makefile
# ============================================
# 디버깅 기능이 포함된 Makefile
# ============================================

# 디버그 모드 활성화
DEBUG_MAKE ?= 0

ifeq ($(DEBUG_MAKE),1)
    # 모든 명령 출력
    OLD_SHELL := $(SHELL)
    SHELL = $(warning Building $@)$(OLD_SHELL)
    
    # 또는
    MAKEFLAGS += --debug=v
endif

# ============================================
# 빌드 시간 측정
# ============================================
BUILD_START := $(shell date +%s)

# 타겟 시작 시간
define TIME_START
	@echo "[TIME] Start: $@ at $$(date +%T)"
endef

# 타겟 종료 시간
define TIME_END
	@echo "[TIME] End: $@ at $$(date +%T)"
endef

# ============================================
# 상세 출력 제어
# ============================================
VERBOSE ?= 0

ifeq ($(VERBOSE),0)
    Q := @
    ECHO := @echo
else
    Q :=
    ECHO := @\#
endif

# 사용 예
%.o: %.c
	$(ECHO) "Compiling $<..."
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

# ============================================
# 의존성 검증
# ============================================
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@for obj in $(OBJECTS); do \
		echo "Dependencies for $$obj:"; \
		$(CC) -MM $(CPPFLAGS) $${obj%.o}.c; \
	done

# ============================================
# Makefile 문법 검증
# ============================================
.PHONY: lint
lint:
	@echo "Checking Makefile syntax..."
	@$(MAKE) --dry-run --warn-undefined-variables all > /dev/null

# ============================================
# 빌드 통계
# ============================================
.PHONY: stats
stats:
	@echo "Build Statistics:"
	@echo "  Source files: $(words $(SOURCES))"
	@echo "  Object files: $(words $(OBJECTS))"
	@echo "  Header files: $(words $(HEADERS))"
	@echo "  Total files: $(words $(SOURCES) $(HEADERS))"
	@echo "  Lines of code:"
	@cat $(SOURCES) | wc -l
```

## 베스트 프랙티스

### 1. 프로젝트 구조

```makefile
# ============================================
# 권장 프로젝트 구조
# ============================================
# project/
# ├── Makefile           # 메인 Makefile
# ├── config/            # 설정 파일
# │   ├── compiler.mk
# │   └── platform.mk
# ├── rules/             # 빌드 규칙
# │   ├── build.mk
# │   └── test.mk
# ├── src/               # 소스 코드
# ├── include/           # 헤더 파일
# ├── build/             # 빌드 출력 (gitignore)
# ├── tests/             # 테스트 코드
# └── docs/              # 문서
```

### 2. 변수 명명 규칙

```makefile
# ============================================
# 일관된 변수 명명
# ============================================

# 대문자: 사용자가 변경 가능한 변수
CC := gcc
CFLAGS := -Wall -g
PREFIX := /usr/local

# 소문자 또는 혼합: 내부 변수
srcdir := src
objdir := obj
sources := $(wildcard $(srcdir)/*.c)

# 접두사 사용
LIB_NAME := mylib
LIB_VERSION := 1.0.0
LIB_SOURCES := $(wildcard lib/*.c)

APP_NAME := myapp
APP_SOURCES := $(wildcard app/*.c)
```

### 3. 기본값 설정

```makefile
# ============================================
# 합리적인 기본값 제공
# ============================================

# 조건부 할당 사용
CC ?= gcc
CXX ?= g++
AR ?= ar
PREFIX ?= /usr/local
BUILD_TYPE ?= debug

# 플랫폼별 기본값
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LDLIBS ?= -lpthread -ldl
else ifeq ($(UNAME_S),Darwin)
    LDLIBS ?= -framework CoreFoundation
endif
```

### 4. 에러 처리

```makefile
# ============================================
# 적절한 에러 처리
# ============================================

# 필수 변수 검증
ifndef PROJECT_NAME
    $(error PROJECT_NAME is not defined)
endif

# 파일 존재 확인
ifeq (,$(wildcard config.mk))
    $(warning config.mk not found, using defaults)
endif

# 명령 성공 여부 확인
check-tool:
	@which $(CC) > /dev/null || (echo "Error: $(CC) not found" && exit 1)

# 빌드 전 검증
.PHONY: pre-build
pre-build:
	@test -d $(SRCDIR) || (echo "Error: $(SRCDIR) not found" && exit 1)
	@test -n "$(SOURCES)" || (echo "Error: No source files found" && exit 1)

all: pre-build $(TARGET)
```

### 5. 문서화

```makefile
# ============================================
# 자체 문서화된 Makefile
# ============================================

##@ Build

.PHONY: all
all: ## Build the project (default target)
	@$(MAKE) $(TARGET)

.PHONY: clean
clean: ## Remove build artifacts
	$(RM) -r $(BUILDDIR)

##@ Test

.PHONY: test
test: ## Run tests
	@$(MAKE) -C tests run

##@ Install

.PHONY: install
install: ## Install to PREFIX (default: /usr/local)
	@install -d $(INSTALL_BIN)
	@install -m 755 $(TARGET) $(INSTALL_BIN)

##@ Help

.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
```

### 6. 성능 최적화

```makefile
# ============================================
# 빌드 성능 최적화
# ============================================

# 1. 병렬 빌드 활성화
MAKEFLAGS += -j$(shell nproc)

# 2. 출력 동기화
MAKEFLAGS += --output-sync=target

# 3. 불필요한 셸 호출 최소화
# 나쁜 예:
FILES := $(shell find src -name "*.c")

# 좋은 예:
FILES := $(wildcard src/*.c)

# 4. 변수 할당 최적화
# 재귀적 할당 대신 단순 할당 사용 (가능한 경우)
SOURCES := $(wildcard src/*.c)
OBJECTS := $(SOURCES:.c=.o)

# 5. 디렉토리 생성을 order-only prerequisite로
$(OBJECTS): | $(OBJDIR)
$(OBJDIR):
	@mkdir -p $@
```

### 7. 완전한 프로덕션 Makefile 템플릿

```makefile
# ============================================
# Production-Ready Makefile Template
# ============================================

# 프로젝트 정보
PROJECT := myproject
VERSION := 1.0.0
DESCRIPTION := "My awesome project"

# 컴파일러 설정
CC := gcc
CXX := g++
AR := ar
RANLIB := ranlib

# 빌드 플래그
CFLAGS := -Wall -Wextra -Werror -std=c11
CXXFLAGS := -Wall -Wextra -Werror -std=c++17
CPPFLAGS := -I./include
LDFLAGS :=
LDLIBS := -lm

# 빌드 모드
BUILD_TYPE ?= debug

ifeq ($(BUILD_TYPE),debug)
    CFLAGS += -g -O0 -DDEBUG
    CXXFLAGS += -g -O0 -DDEBUG
else ifeq ($(BUILD_TYPE),release)
    CFLAGS += -O3 -DNDEBUG
    CXXFLAGS += -O3 -DNDEBUG
else
    $(error Invalid BUILD_TYPE: $(BUILD_TYPE). Use debug or release)
endif

# 디렉토리 구조
SRCDIR := src
INCDIR := include
BUILDDIR := build/$(BUILD_TYPE)
OBJDIR := $(BUILDDIR)/obj
BINDIR := $(BUILDDIR)/bin
DEPDIR := $(BUILDDIR)/.deps

# 소스 파일
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(SOURCES:$(SRCDIR)/%.c=$(DEPDIR)/%.d)

TARGET := $(BINDIR)/$(PROJECT)

# 설치 경로
PREFIX ?= /usr/local
INSTALL_BIN := $(PREFIX)/bin
INSTALL_LIB := $(PREFIX)/lib
INSTALL_INC := $(PREFIX)/include/$(PROJECT)

# Make 옵션
MAKEFLAGS += -j$(shell nproc)
MAKEFLAGS += --output-sync=target
MAKEFLAGS += --warn-undefined-variables

# 디버그 플래그
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

# ============================================
# Phony 타겟
# ============================================
.PHONY: all clean rebuild install uninstall test help

# ============================================
# 기본 타겟
# ============================================
all: $(TARGET)

# ============================================
# 링크
# ============================================
$(TARGET): $(OBJECTS) | $(BINDIR)
	@echo "Linking $@..."
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Build complete: $@"

# ============================================
# 컴파일
# ============================================
$(OBJDIR)/%.o: $(SRCDIR)/%.c $(DEPDIR)/%.d | $(OBJDIR) $(DEPDIR)
	@echo "Compiling $<..."
	$(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# ============================================
# 디렉토리 생성
# ============================================
$(OBJDIR) $(BINDIR) $(DEPDIR):
	@mkdir -p $@

# ============================================
# 의존성 관리
# ============================================
$(DEPENDS):
-include $(DEPENDS)

# ============================================
# 유틸리티 타겟
# ============================================
clean:
	@echo "Cleaning..."
	$(RM) -r build

rebuild: clean all

install: $(TARGET)
	@echo "Installing to $(PREFIX)..."
	@install -d $(INSTALL_BIN)
	@install -m 755 $(TARGET) $(INSTALL_BIN)
	@echo "Installation complete"

uninstall:
	@echo "Uninstalling from $(PREFIX)..."
	$(RM) $(INSTALL_BIN)/$(PROJECT)
	@echo "Uninstallation complete"

test: $(TARGET)
	@echo "Running tests..."
	@$(TARGET) --test

help:
	@echo "$(PROJECT) v$(VERSION)"
	@echo "$(DESCRIPTION)"
	@echo ""
	@echo "Usage: make [target] [BUILD_TYPE=debug|release]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the project (default)"
	@echo "  clean     - Remove build artifacts"
	@echo "  rebuild   - Clean and rebuild"
	@echo "  install   - Install to PREFIX (default: /usr/local)"
	@echo "  uninstall - Remove installed files"
	@echo "  test      - Run tests"
	@echo "  help      - Show this help"

.DEFAULT_GOAL := all
```

## 핵심 정리

✅ 병렬 빌드: `-j` 옵션으로 빌드 시간 대폭 단축  
✅ 의존성 자동 생성: `-MMD -MP`로 헤더 의존성 자동 관리  
✅ 디버깅: `-n`, `-d`, `$(info)`, `$(warning)` 활용  
✅ 베스트 프랙티스: 일관된 구조, 명명 규칙, 문서화  
✅ 성능 최적화: 병렬 빌드, order-only prerequisites, 불필요한 셸 호출 최소화  

---

**이전 장**: [실전 프로젝트 예제](./05-examples.md)  
**처음으로**: [README](../README.md)
