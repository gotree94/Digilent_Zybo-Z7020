# 5. 실전 프로젝트 예제

## C 프로젝트 빌드

### 간단한 C 프로젝트

프로젝트 구조:
```
simple_c_project/
├── Makefile
├── src/
│   ├── main.c
│   ├── math_ops.c
│   └── string_ops.c
├── include/
│   ├── math_ops.h
│   └── string_ops.h
└── README.md
```

**Makefile**
```makefile
# ============================================
# 프로젝트 설정
# ============================================
PROJECT := calculator
VERSION := 1.0.0

# ============================================
# 컴파일러 및 플래그
# ============================================
CC := gcc
CFLAGS := -Wall -Wextra -Werror -std=c11 -pedantic
CPPFLAGS := -I./include
LDFLAGS :=
LDLIBS := -lm

# ============================================
# 디렉토리
# ============================================
SRCDIR := src
INCDIR := include
OBJDIR := obj
BINDIR := bin

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
.PHONY: all clean rebuild run info

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@mkdir -p $(BINDIR)
	@echo "Linking $@..."
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Build complete: $@"

# 자동 의존성 생성
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

# ============================================
# 유틸리티 타겟
# ============================================
clean:
	@echo "Cleaning..."
	$(RM) -r $(OBJDIR) $(BINDIR)

rebuild: clean all

run: $(TARGET)
	@echo "Running $(PROJECT)..."
	@$(TARGET)

info:
	@echo "Project: $(PROJECT) v$(VERSION)"
	@echo "Sources: $(SOURCES)"
	@echo "Objects: $(OBJECTS)"
	@echo "Target: $(TARGET)"

# ============================================
# 의존성 포함
# ============================================
-include $(DEPENDS)
```

## C++ 프로젝트 빌드

### 객체지향 C++ 프로젝트

프로젝트 구조:
```
cpp_project/
├── Makefile
├── src/
│   ├── main.cpp
│   ├── Application.cpp
│   ├── Database.cpp
│   └── Logger.cpp
├── include/
│   ├── Application.hpp
│   ├── Database.hpp
│   └── Logger.hpp
└── tests/
    ├── test_main.cpp
    └── test_database.cpp
```

**Makefile**
```makefile
# ============================================
# 프로젝트 설정
# ============================================
PROJECT := myapp
VERSION := 2.0.0

# ============================================
# 컴파일러 설정
# ============================================
CXX := g++
CXXFLAGS := -Wall -Wextra -Werror -std=c++17 -pedantic
CPPFLAGS := -I./include
LDFLAGS :=
LDLIBS := -lpthread -lsqlite3

# ============================================
# 빌드 모드
# ============================================
BUILD_MODE ?= debug

ifeq ($(BUILD_MODE),debug)
    CXXFLAGS += -g -O0 -DDEBUG
    BUILD_SUFFIX := _debug
else ifeq ($(BUILD_MODE),release)
    CXXFLAGS += -O3 -DNDEBUG
    BUILD_SUFFIX := _release
else ifeq ($(BUILD_MODE),profile)
    CXXFLAGS += -g -O2 -pg
    LDFLAGS += -pg
    BUILD_SUFFIX := _profile
else
    $(error Invalid BUILD_MODE: $(BUILD_MODE))
endif

# ============================================
# 디렉토리
# ============================================
SRCDIR := src
INCDIR := include
TESTDIR := tests
BUILDDIR := build/$(BUILD_MODE)
OBJDIR := $(BUILDDIR)/obj
BINDIR := $(BUILDDIR)/bin
TEST_OBJDIR := $(BUILDDIR)/test_obj

# ============================================
# 소스 및 오브젝트 파일
# ============================================
SOURCES := $(wildcard $(SRCDIR)/*.cpp)
OBJECTS := $(SOURCES:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)
DEPENDS := $(OBJECTS:.o=.d)

TEST_SOURCES := $(wildcard $(TESTDIR)/*.cpp)
TEST_OBJECTS := $(TEST_SOURCES:$(TESTDIR)/%.cpp=$(TEST_OBJDIR)/%.o)
TEST_DEPENDS := $(TEST_OBJECTS:.o=.d)

TARGET := $(BINDIR)/$(PROJECT)$(BUILD_SUFFIX)
TEST_TARGET := $(BINDIR)/test_runner$(BUILD_SUFFIX)

# ============================================
# 기본 타겟
# ============================================
.PHONY: all clean rebuild test run info help

all: $(TARGET)

# ============================================
# 메인 프로그램 빌드
# ============================================
$(TARGET): $(OBJECTS)
	@mkdir -p $(BINDIR)
	@echo "Linking $@..."
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Build complete: $@"

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	@echo "Compiling $<..."
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

# ============================================
# 테스트 빌드
# ============================================
test: $(TEST_TARGET)
	@echo "Running tests..."
	@$(TEST_TARGET)

$(TEST_TARGET): $(TEST_OBJECTS) $(filter-out $(OBJDIR)/main.o,$(OBJECTS))
	@mkdir -p $(BINDIR)
	@echo "Linking $@..."
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(TEST_OBJDIR)/%.o: $(TESTDIR)/%.cpp
	@mkdir -p $(TEST_OBJDIR)
	@echo "Compiling test $<..."
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -I$(SRCDIR) -MMD -MP -c $< -o $@

# ============================================
# 유틸리티
# ============================================
clean:
	@echo "Cleaning..."
	$(RM) -r build

rebuild: clean all

run: $(TARGET)
	@$(TARGET)

info:
	@echo "Project: $(PROJECT) v$(VERSION)"
	@echo "Build Mode: $(BUILD_MODE)"
	@echo "CXX: $(CXX)"
	@echo "CXXFLAGS: $(CXXFLAGS)"
	@echo "Sources: $(SOURCES)"
	@echo "Target: $(TARGET)"

help:
	@echo "Usage: make [target] [BUILD_MODE=debug|release|profile]"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Build the project (default)"
	@echo "  test    - Build and run tests"
	@echo "  clean   - Remove build artifacts"
	@echo "  rebuild - Clean and rebuild"
	@echo "  run     - Build and run the program"
	@echo "  info    - Show project information"
	@echo "  help    - Show this help"

# ============================================
# 의존성 포함
# ============================================
-include $(DEPENDS)
-include $(TEST_DEPENDS)
```

## 멀티 디렉토리 프로젝트

### 복잡한 프로젝트 구조

```
complex_project/
├── Makefile
├── config/
│   ├── compiler.mk
│   └── platform.mk
├── libs/
│   ├── core/
│   │   ├── Makefile
│   │   ├── src/
│   │   └── include/
│   └── utils/
│       ├── Makefile
│       ├── src/
│       └── include/
├── apps/
│   ├── server/
│   │   ├── Makefile
│   │   └── src/
│   └── client/
│       ├── Makefile
│       └── src/
└── tests/
    ├── Makefile
    └── src/
```

**Makefile (최상위)**
```makefile
# ============================================
# 최상위 Makefile
# ============================================
PROJECT_ROOT := $(CURDIR)
export PROJECT_ROOT

# ============================================
# 설정 포함
# ============================================
include config/compiler.mk
include config/platform.mk

# ============================================
# 서브디렉토리
# ============================================
LIB_DIRS := libs/core libs/utils
APP_DIRS := apps/server apps/client
TEST_DIRS := tests

ALL_DIRS := $(LIB_DIRS) $(APP_DIRS)

# ============================================
# 타겟
# ============================================
.PHONY: all libs apps tests clean install help $(ALL_DIRS) $(TEST_DIRS)

all: libs apps

libs: $(LIB_DIRS)

apps: $(APP_DIRS)

# 각 디렉토리 빌드
$(ALL_DIRS):
	@echo "=== Building $@ ==="
	@$(MAKE) -C $@

# 의존성 명시
apps/server: libs/core libs/utils
apps/client: libs/core libs/utils

# ============================================
# 테스트
# ============================================
tests: libs
	@echo "=== Running tests ==="
	@$(MAKE) -C tests run

# ============================================
# 정리
# ============================================
clean:
	@echo "Cleaning all subdirectories..."
	@for dir in $(ALL_DIRS) $(TEST_DIRS); do \
		$(MAKE) -C $$dir clean; \
	done
	@$(RM) -r build

# ============================================
# 설치
# ============================================
PREFIX ?= /usr/local
INSTALL_BIN := $(PREFIX)/bin
INSTALL_LIB := $(PREFIX)/lib
INSTALL_INC := $(PREFIX)/include

install: all
	@echo "Installing to $(PREFIX)..."
	@install -d $(INSTALL_BIN)
	@install -d $(INSTALL_LIB)
	@install -d $(INSTALL_INC)
	@for dir in $(APP_DIRS); do \
		$(MAKE) -C $$dir install PREFIX=$(PREFIX); \
	done
	@for dir in $(LIB_DIRS); do \
		$(MAKE) -C $$dir install PREFIX=$(PREFIX); \
	done

# ============================================
# 도움말
# ============================================
help:
	@echo "Multi-directory Project Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build all libraries and applications"
	@echo "  libs     - Build all libraries"
	@echo "  apps     - Build all applications"
	@echo "  tests    - Run all tests"
	@echo "  clean    - Clean all build artifacts"
	@echo "  install  - Install to PREFIX (default: /usr/local)"
	@echo "  help     - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_MODE  - debug|release (default: debug)"
	@echo "  PREFIX      - Installation prefix"
	@echo ""
	@echo "Examples:"
	@echo "  make BUILD_MODE=release"
	@echo "  make install PREFIX=/opt/myapp"
```

**libs/core/Makefile**
```makefile
# ============================================
# Core Library Makefile
# ============================================
LIB_NAME := core
LIB_TARGET := lib$(LIB_NAME).a

# ============================================
# 디렉토리
# ============================================
SRCDIR := src
INCDIR := include
OBJDIR := ../../build/libs/$(LIB_NAME)/obj

# ============================================
# 소스 파일
# ============================================
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(OBJECTS:.o=.d)

# ============================================
# 컴파일러 플래그
# ============================================
CFLAGS += -I$(INCDIR)

# ============================================
# 빌드 규칙
# ============================================
.PHONY: all clean install

all: $(LIB_TARGET)

$(LIB_TARGET): $(OBJECTS)
	@echo "Creating library $@..."
	$(AR) rcs $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

clean:
	$(RM) $(LIB_TARGET) $(OBJECTS) $(DEPENDS)
	$(RM) -r $(OBJDIR)

install:
	@install -d $(INSTALL_LIB)
	@install -d $(INSTALL_INC)/$(LIB_NAME)
	@install -m 644 $(LIB_TARGET) $(INSTALL_LIB)
	@install -m 644 $(INCDIR)/*.h $(INSTALL_INC)/$(LIB_NAME)

-include $(DEPENDS)
```

**apps/server/Makefile**
```makefile
# ============================================
# Server Application Makefile
# ============================================
APP_NAME := server
APP_TARGET := $(APP_NAME)

# ============================================
# 디렉토리
# ============================================
SRCDIR := src
OBJDIR := ../../build/apps/$(APP_NAME)/obj
BINDIR := ../../build/apps/$(APP_NAME)/bin

CORE_LIB := ../../libs/core
UTILS_LIB := ../../libs/utils

# ============================================
# 소스 파일
# ============================================
SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS := $(OBJECTS:.o=.d)

TARGET := $(BINDIR)/$(APP_TARGET)

# ============================================
# 컴파일러 플래그
# ============================================
CFLAGS += -I$(CORE_LIB)/include -I$(UTILS_LIB)/include
LDFLAGS += -L$(CORE_LIB) -L$(UTILS_LIB)
LDLIBS += -lcore -lutils

# ============================================
# 빌드 규칙
# ============================================
.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(OBJECTS) $(CORE_LIB)/libcore.a $(UTILS_LIB)/libutils.a
	@mkdir -p $(BINDIR)
	@echo "Linking $@..."
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

clean:
	$(RM) $(TARGET) $(OBJECTS) $(DEPENDS)
	$(RM) -r $(OBJDIR) $(BINDIR)

install:
	@install -d $(INSTALL_BIN)
	@install -m 755 $(TARGET) $(INSTALL_BIN)

-include $(DEPENDS)
```

## 라이브러리 생성 및 링크

### 정적 라이브러리 생성

**Makefile**
```makefile
# ============================================
# 정적 라이브러리 프로젝트
# ============================================
LIB_NAME := mymath
LIB_STATIC := lib$(LIB_NAME).a

SRCDIR := src
INCDIR := include
OBJDIR := obj

SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# ============================================
# 정적 라이브러리 생성
# ============================================
$(LIB_STATIC): $(OBJECTS)
	@echo "Creating static library $@..."
	$(AR) rcs $@ $^
	@echo "Static library created: $@"

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# ============================================
# 예제 프로그램 (라이브러리 사용)
# ============================================
example: examples/main.c $(LIB_STATIC)
	$(CC) $(CFLAGS) -I$(INCDIR) -o $@ $< -L. -l$(LIB_NAME) -lm

.PHONY: clean
clean:
	$(RM) $(LIB_STATIC) $(OBJECTS) example
	$(RM) -r $(OBJDIR)
```

### 공유 라이브러리 생성

**Makefile**
```makefile
# ============================================
# 공유 라이브러리 프로젝트
# ============================================
LIB_NAME := mymath
LIB_SHARED := lib$(LIB_NAME).so
LIB_VERSION := 1.0.0
LIB_SONAME := $(LIB_SHARED).1

SRCDIR := src
INCDIR := include
OBJDIR := obj

SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# PIC (Position Independent Code) 플래그
CFLAGS += -fPIC

# ============================================
# 공유 라이브러리 생성
# ============================================
$(LIB_SHARED).$(LIB_VERSION): $(OBJECTS)
	@echo "Creating shared library $@..."
	$(CC) -shared -Wl,-soname,$(LIB_SONAME) -o $@ $^ -lm
	@ln -sf $@ $(LIB_SHARED).1
	@ln -sf $@ $(LIB_SHARED)
	@echo "Shared library created: $@"

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# ============================================
# 예제 프로그램
# ============================================
example: examples/main.c $(LIB_SHARED).$(LIB_VERSION)
	$(CC) $(CFLAGS) -I$(INCDIR) -o $@ $< -L. -l$(LIB_NAME)

# ============================================
# 설치
# ============================================
install: $(LIB_SHARED).$(LIB_VERSION)
	@install -d $(DESTDIR)$(PREFIX)/lib
	@install -d $(DESTDIR)$(PREFIX)/include/$(LIB_NAME)
	@install -m 755 $(LIB_SHARED).$(LIB_VERSION) $(DESTDIR)$(PREFIX)/lib
	@ln -sf $(LIB_SHARED).$(LIB_VERSION) $(DESTDIR)$(PREFIX)/lib/$(LIB_SONAME)
	@ln -sf $(LIB_SONAME) $(DESTDIR)$(PREFIX)/lib/$(LIB_SHARED)
	@install -m 644 $(INCDIR)/*.h $(DESTDIR)$(PREFIX)/include/$(LIB_NAME)
	@ldconfig

.PHONY: clean
clean:
	$(RM) $(LIB_SHARED)* $(OBJECTS) example
	$(RM) -r $(OBJDIR)
```

### 정적+공유 라이브러리 통합 Makefile

**Makefile**
```makefile
# ============================================
# 정적 및 공유 라이브러리 빌드
# ============================================
LIB_NAME := mymath
LIB_STATIC := lib$(LIB_NAME).a
LIB_SHARED := lib$(LIB_NAME).so
LIB_VERSION := 1.0.0

SRCDIR := src
INCDIR := include
OBJDIR_STATIC := obj/static
OBJDIR_SHARED := obj/shared

SOURCES := $(wildcard $(SRCDIR)/*.c)
OBJECTS_STATIC := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR_STATIC)/%.o)
OBJECTS_SHARED := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR_SHARED)/%.o)

# ============================================
# 타겟
# ============================================
.PHONY: all static shared clean install

all: static shared

static: $(LIB_STATIC)

shared: $(LIB_SHARED).$(LIB_VERSION)

# ============================================
# 정적 라이브러리
# ============================================
$(LIB_STATIC): $(OBJECTS_STATIC)
	$(AR) rcs $@ $^

$(OBJDIR_STATIC)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR_STATIC)
	$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# ============================================
# 공유 라이브러리
# ============================================
$(LIB_SHARED).$(LIB_VERSION): $(OBJECTS_SHARED)
	$(CC) -shared -Wl,-soname,$(LIB_SHARED).1 -o $@ $^ -lm
	@ln -sf $@ $(LIB_SHARED).1
	@ln -sf $@ $(LIB_SHARED)

$(OBJDIR_SHARED)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR_SHARED)
	$(CC) $(CFLAGS) -fPIC -I$(INCDIR) -c $< -o $@

# ============================================
# 설치
# ============================================
PREFIX ?= /usr/local
INSTALL_LIB := $(PREFIX)/lib
INSTALL_INC := $(PREFIX)/include/$(LIB_NAME)

install: all
	@install -d $(INSTALL_LIB) $(INSTALL_INC)
	@install -m 644 $(LIB_STATIC) $(INSTALL_LIB)
	@install -m 755 $(LIB_SHARED).$(LIB_VERSION) $(INSTALL_LIB)
	@ln -sf $(LIB_SHARED).$(LIB_VERSION) $(INSTALL_LIB)/$(LIB_SHARED).1
	@ln -sf $(LIB_SHARED).1 $(INSTALL_LIB)/$(LIB_SHARED)
	@install -m 644 $(INCDIR)/*.h $(INSTALL_INC)
	@ldconfig

clean:
	$(RM) $(LIB_STATIC) $(LIB_SHARED)* $(OBJECTS_STATIC) $(OBJECTS_SHARED)
	$(RM) -r obj
```

## 핵심 정리

✅ C 프로젝트: 자동 의존성 생성 (`-MMD -MP`), 깔끔한 디렉토리 구조  
✅ C++ 프로젝트: 빌드 모드 지원, 테스트 통합, 현대 C++ 표준  
✅ 멀티 디렉토리: 재귀적 Make, 의존성 관리, 모듈화된 설정  
✅ 정적 라이브러리: `ar rcs`로 생성, 헤더 파일 관리  
✅ 공유 라이브러리: `-fPIC`, `-shared`, soname 버전 관리  

---

**이전 장**: [고급 Make 기능](./04-advanced.md)  
**다음 장**: [Make 최적화와 디버깅](./06-optimization.md)
