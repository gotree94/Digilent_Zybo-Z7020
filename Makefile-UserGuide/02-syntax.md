# 2. Make 문법과 규칙

## 명시적 규칙 (Explicit Rules)

명시적 규칙은 특정 타겟을 생성하는 방법을 명확하게 지정하는 규칙입니다.

### 기본 형식

```makefile
target: dependency1 dependency2 ...
	command1
	command2
	...
```

### 예제

```makefile
program: main.o utils.o
	gcc -o program main.o utils.o

main.o: main.c utils.h
	gcc -c main.c

utils.o: utils.c utils.h
	gcc -c utils.c
```

### 다중 타겟

하나의 규칙으로 여러 타겟을 생성할 수 있습니다.

```makefile
# 여러 타겟에 동일한 규칙 적용
prog1 prog2 prog3: common.c
	gcc -o $@ common.c

# 위는 다음과 같음:
# prog1: common.c
#     gcc -o prog1 common.c
# prog2: common.c
#     gcc -o prog2 common.c
# prog3: common.c
#     gcc -o prog3 common.c
```

## 암시적 규칙 (Implicit Rules)

Make는 일반적인 빌드 패턴에 대한 내장 규칙을 가지고 있습니다.

### 주요 암시적 규칙

```makefile
# C 소스에서 오브젝트 파일 생성
# 자동으로 다음 명령이 실행됨: $(CC) $(CFLAGS) -c $< -o $@
main.o: main.c

# C 소스에서 실행 파일 생성
# 자동으로 다음 명령이 실행됨: $(CC) $(LDFLAGS) $^ -o $@
program: main.o utils.o
```

### 암시적 규칙 확인

```bash
# 모든 암시적 규칙 보기
make -p

# 특정 타겟의 규칙 확인
make -n target_name
```

### 암시적 규칙 사용 예제

```makefile
# 컴파일러와 플래그만 정의하면 됨
CC = gcc
CFLAGS = -Wall -g -O2
LDFLAGS = -lm

# 암시적 규칙이 자동으로 적용됨
program: main.o calc.o
	# 링크 규칙은 명시적으로 작성
	$(CC) -o program main.o calc.o $(LDFLAGS)

# .c -> .o 변환은 암시적 규칙 사용
# main.o: main.c 는 생략 가능
# calc.o: calc.c 는 생략 가능
```

## 패턴 규칙 (Pattern Rules)

패턴 규칙은 파일 이름 패턴을 사용하여 일반화된 규칙을 정의합니다.

### 기본 패턴 규칙

```makefile
# % 는 와일드카드 (임의의 문자열)
%.o: %.c
	gcc -c $< -o $@

# 위 규칙은 모든 .c 파일을 .o 파일로 변환
# main.c -> main.o
# utils.c -> utils.o
```

### 실용적인 패턴 규칙 예제

```makefile
CC = gcc
CFLAGS = -Wall -g -I./include
SRCDIR = src
OBJDIR = obj

# src/*.c -> obj/*.o
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# 예: src/main.c -> obj/main.o
```

### 다중 접미사 패턴

```makefile
# .cpp 파일을 .o로 변환
%.o: %.cpp
	g++ -c $< -o $@

# .s 어셈블리 파일을 .o로 변환
%.o: %.s
	as $< -o $@

# .c 파일을 .s 어셈블리로 변환
%.s: %.c
	gcc -S $< -o $@
```

## 정적 패턴 규칙 (Static Pattern Rules)

특정 타겟 리스트에만 적용되는 패턴 규칙입니다.

### 문법

```makefile
targets: target-pattern: dependency-pattern
	commands
```

### 예제

```makefile
OBJECTS = main.o utils.o calc.o

# OBJECTS 리스트의 .o 파일들을 .c 파일로부터 생성
$(OBJECTS): %.o: %.c
	gcc -c $< -o $@

# 위는 다음과 동일:
# main.o: main.c
#     gcc -c main.c -o main.o
# utils.o: utils.c
#     gcc -c utils.c -o utils.o
# calc.o: calc.c
#     gcc -c calc.c -o calc.o
```

### 디렉토리별 정적 패턴

```makefile
SRC_FILES = src/main.c src/utils.c src/calc.c
OBJ_FILES = $(SRC_FILES:src/%.c=obj/%.o)

$(OBJ_FILES): obj/%.o: src/%.c
	@mkdir -p obj
	gcc -c $< -o $@
```

## 접미사 규칙 (Suffix Rules) - 구식 방법

⚠️ 패턴 규칙이 더 현대적이고 권장되지만, 레거시 코드에서 볼 수 있습니다.

```makefile
# 접미사 선언
.SUFFIXES: .c .o

# .c -> .o 규칙
.c.o:
	gcc -c $<

# 패턴 규칙 사용이 권장됨:
# %.o: %.c
#     gcc -c $<
```

## 이중 콜론 규칙 (Double-Colon Rules)

같은 타겟에 대해 여러 독립적인 규칙을 정의할 때 사용합니다.

```makefile
# 일반 규칙은 하나의 타겟에 여러 규칙 불가
# target: dep1
#     command1
# target: dep2  # 오류!
#     command2

# 이중 콜론 사용
all:: build
	@echo "Building..."

all:: test
	@echo "Testing..."

# make all 실행 시 두 명령 모두 실행됨
```

## 실전 예제: 통합 Makefile

```makefile
# ============================================
# 프로젝트 설정
# ============================================
PROJECT = myapp
CC = gcc
CXX = g++
CFLAGS = -Wall -Wextra -g -O2 -I./include
CXXFLAGS = $(CFLAGS) -std=c++11
LDFLAGS = -lm -lpthread

# ============================================
# 디렉토리 구조
# ============================================
SRCDIR = src
OBJDIR = obj
BINDIR = bin
INCDIR = include

# ============================================
# 소스 파일 자동 검색
# ============================================
C_SOURCES = $(wildcard $(SRCDIR)/*.c)
CPP_SOURCES = $(wildcard $(SRCDIR)/*.cpp)
C_OBJECTS = $(C_SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
CPP_OBJECTS = $(CPP_SOURCES:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)
OBJECTS = $(C_OBJECTS) $(CPP_OBJECTS)

TARGET = $(BINDIR)/$(PROJECT)

# ============================================
# 기본 타겟
# ============================================
.PHONY: all clean rebuild run

all: $(TARGET)

# ============================================
# 링크
# ============================================
$(TARGET): $(OBJECTS)
	@mkdir -p $(BINDIR)
	@echo "Linking $@..."
	$(CXX) -o $@ $^ $(LDFLAGS)
	@echo "Build complete: $@"

# ============================================
# C 소스 컴파일 (패턴 규칙)
# ============================================
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# ============================================
# C++ 소스 컴파일 (패턴 규칙)
# ============================================
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	@echo "Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

# ============================================
# 유틸리티 타겟
# ============================================
clean:
	@echo "Cleaning..."
	rm -rf $(OBJDIR) $(BINDIR)
	@echo "Clean complete"

rebuild: clean all

run: $(TARGET)
	@echo "Running $(PROJECT)..."
	@$(TARGET)

# ============================================
# 정보 출력
# ============================================
info:
	@echo "Project: $(PROJECT)"
	@echo "C Sources: $(C_SOURCES)"
	@echo "C++ Sources: $(CPP_SOURCES)"
	@echo "Objects: $(OBJECTS)"
	@echo "Target: $(TARGET)"

# ============================================
# 도움말
# ============================================
help:
	@echo "Available targets:"
	@echo "  all     - Build the project (default)"
	@echo "  clean   - Remove build artifacts"
	@echo "  rebuild - Clean and build"
	@echo "  run     - Build and run the program"
	@echo "  info    - Show project information"
	@echo "  help    - Show this help message"
```

## 규칙 우선순위

Make는 다음 순서로 규칙을 찾습니다:

1. 명시적 규칙
2. 정적 패턴 규칙
3. 암시적 패턴 규칙
4. 내장 암시적 규칙

```makefile
# 1순위: 명시적 규칙
main.o: main.c utils.h
	gcc -DSPECIAL -c main.c

# 2순위: 정적 패턴 규칙
OBJS = utils.o calc.o
$(OBJS): %.o: %.c
	gcc -O2 -c $<

# 3순위: 패턴 규칙
%.o: %.c
	gcc -c $<

# 4순위: 내장 규칙 (자동)
```

## 연습 문제

### 문제 1: 패턴 규칙 작성

다음 요구사항을 만족하는 패턴 규칙을 작성하세요:
- `tests/` 디렉토리의 모든 `.c` 파일을 컴파일
- 오브젝트 파일은 `build/tests/` 디렉토리에 생성
- 테스트 플래그 `-DTEST_MODE` 추가

### 문제 2: 정적 패턴 규칙

다음 파일들에 대한 정적 패턴 규칙을 작성하세요:
- `module1.c`, `module2.c`, `module3.c`
- 각각 다른 최적화 옵션 사용 (`-O1`, `-O2`, `-O3`)

### 문제 3: 복합 규칙

다음 빌드 프로세스를 구현하세요:
1. `.c` 파일을 `.i` (전처리) 파일로 변환
2. `.i` 파일을 `.s` (어셈블리) 파일로 변환
3. `.s` 파일을 `.o` (오브젝트) 파일로 변환
4. 최종 실행 파일 생성

## 핵심 정리

✅ 명시적 규칙은 특정 타겟에 대한 명확한 빌드 방법 정의  
✅ 암시적 규칙은 Make의 내장 규칙으로 자동 적용  
✅ 패턴 규칙 (`%`)은 유연하고 강력한 일반화 방법  
✅ 정적 패턴 규칙은 특정 타겟 그룹에만 패턴 적용  
✅ 규칙 우선순위: 명시적 > 정적 패턴 > 패턴 > 내장  

---

**이전 장**: [Make 기초](./01-basics.md)  
**다음 장**: [Make 변수 활용](./03-variables.md)
