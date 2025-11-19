# 1. Make 기초

## Make란 무엇인가?

Make는 소프트웨어 빌드 자동화 도구입니다. 파일 간의 의존성을 파악하여 필요한 파일만 선택적으로 다시 컴파일함으로써 빌드 시간을 크게 단축시킵니다.

### Make의 주요 기능

- **선택적 컴파일**: 변경된 파일만 다시 컴파일
- **의존성 관리**: 파일 간 의존 관계 자동 추적
- **빌드 자동화**: 복잡한 빌드 과정을 단순한 명령으로 실행
- **이식성**: 다양한 Unix/Linux 시스템에서 동작

## Makefile 기본 구조

Makefile은 다음과 같은 규칙(rule)들로 구성됩니다:

```makefile
target: dependencies
	command
```

### 구성 요소 설명

- **target**: 생성하려는 파일 또는 실행할 작업 이름
- **dependencies**: target을 생성하기 위해 필요한 파일들
- **command**: target을 생성하기 위해 실행할 명령어 (반드시 TAB으로 들여쓰기)

⚠️ **중요**: 명령어 앞의 들여쓰기는 반드시 TAB 문자여야 합니다. 스페이스를 사용하면 오류가 발생합니다!

## 첫 번째 Makefile 작성하기

### 예제 1: Hello World

먼저 간단한 C 프로그램을 만들어봅시다.

**hello.c**
```c
#include <stdio.h>

int main() {
    printf("Hello, Make!\n");
    return 0;
}
```

**Makefile**
```makefile
hello: hello.c
	gcc -o hello hello.c

clean:
	rm -f hello
```

### 실행 방법

```bash
# 빌드
make hello

# 또는 그냥
make

# 실행
./hello

# 정리
make clean
```

### 작동 원리

1. `make hello` 명령 실행
2. Make는 `hello` 타겟을 찾음
3. `hello.c`가 존재하고, `hello`가 없거나 `hello.c`보다 오래되었는지 확인
4. 조건이 맞으면 `gcc -o hello hello.c` 명령 실행

## 기본 타겟과 의존성

### 기본 타겟

Makefile의 첫 번째 타겟은 기본 타겟입니다. `make` 명령을 인자 없이 실행하면 이 타겟이 실행됩니다.

```makefile
# 첫 번째 타겟 - 기본 타겟
all: program

program: main.c utils.c
	gcc -o program main.c utils.c

clean:
	rm -f program
```

이제 `make`만 입력하면 `all` 타겟이 실행되고, 이는 `program` 타겟에 의존하므로 프로그램이 빌드됩니다.

### 의존성 체인

의존성은 체인처럼 연결될 수 있습니다.

```makefile
all: program

program: main.o utils.o
	gcc -o program main.o utils.o

main.o: main.c
	gcc -c main.c

utils.o: utils.c
	gcc -c utils.c

clean:
	rm -f program *.o
```

### 작동 순서

1. `make` 실행
2. `all` 타겟 확인 → `program` 필요
3. `program` 확인 → `main.o`, `utils.o` 필요
4. `main.o` 확인 → `main.c`에서 생성
5. `utils.o` 확인 → `utils.c`에서 생성
6. 모든 의존성 준비 후 `program` 생성

## 예제 2: 다중 파일 프로젝트

실제로 사용 가능한 예제를 만들어봅시다.

**main.c**
```c
#include <stdio.h>
#include "utils.h"

int main() {
    int a = 10, b = 20;
    printf("Sum: %d\n", add(a, b));
    printf("Product: %d\n", multiply(a, b));
    return 0;
}
```

**utils.h**
```c
#ifndef UTILS_H
#define UTILS_H

int add(int a, int b);
int multiply(int a, int b);

#endif
```

**utils.c**
```c
#include "utils.h"

int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}
```

**Makefile**
```makefile
# 컴파일러 설정
CC = gcc
CFLAGS = -Wall -g

# 타겟 설정
TARGET = myprogram

# 소스 파일
SOURCES = main.c utils.c
OBJECTS = $(SOURCES:.c=.o)

# 기본 타겟
all: $(TARGET)

# 실행 파일 생성
$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS)

# 오브젝트 파일 생성
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 정리
clean:
	rm -f $(TARGET) $(OBJECTS)

# 재빌드
rebuild: clean all

.PHONY: all clean rebuild
```

### 실행 및 테스트

```bash
# 빌드
make

# 실행
./myprogram

# 파일 수정 후 다시 빌드 (변경된 파일만 컴파일됨)
# utils.c를 수정했다면
make
# utils.o만 다시 컴파일되고 링킹됨

# 정리
make clean

# 완전 재빌드
make rebuild
```

## Phony 타겟

`.PHONY`는 실제 파일이 아닌 타겟을 선언합니다.

```makefile
.PHONY: clean all rebuild test

clean:
	rm -f *.o program

all: program

rebuild: clean all

test: program
	./program
```

**왜 필요한가?**

만약 `clean`이라는 파일이 실제로 존재한다면, Make는 `clean` 타겟이 이미 최신이라고 판단하여 명령을 실행하지 않습니다. `.PHONY`로 선언하면 이런 문제를 방지할 수 있습니다.

## 연습 문제

### 문제 1: 기본 Makefile 작성

다음 파일들로 구성된 프로그램의 Makefile을 작성하세요:
- `calculator.c`: main 함수 포함
- `add.c`, `sub.c`, `mul.c`, `div.c`: 각각 덧셈, 뺄셈, 곱셈, 나눗셈 함수
- `operations.h`: 함수 선언 헤더

요구사항:
- 실행 파일 이름: `calc`
- `clean` 타겟 포함
- 컴파일 옵션: `-Wall -Wextra`

### 문제 2: 의존성 이해

다음 상황에서 어떤 파일들이 재컴파일되는지 설명하세요:
1. `main.c`를 수정한 경우
2. `utils.h`를 수정한 경우
3. `utils.c`를 수정한 경우

## 핵심 정리

✅ Make는 파일의 타임스탬프를 비교하여 필요한 부분만 재빌드합니다  
✅ Makefile의 기본 구조는 `target: dependencies` 다음 줄에 TAB + 명령어  
✅ 첫 번째 타겟이 기본 타겟입니다  
✅ `.PHONY`는 실제 파일이 아닌 타겟을 선언할 때 사용  
✅ 의존성은 체인으로 연결될 수 있습니다  

---

**다음 장**: [Make 문법과 규칙](./02-syntax.md)
