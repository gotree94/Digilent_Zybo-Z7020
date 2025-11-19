# Hello Make 예제

가장 기본적인 Make 사용 예제입니다.

## 📝 파일 구성

```
hello_make/
├── README.md       # 이 파일
├── Makefile        # Make 빌드 파일
└── hello.c         # C 소스 코드
```

## 🎯 학습 목표

- Makefile의 기본 구조 이해
- 타겟과 의존성 개념
- 기본 빌드 및 clean 타겟 작성

## 📖 코드 설명

**hello.c**
```c
#include <stdio.h>

int main(void) {
    printf("Hello, Make!\n");
    printf("This is my first Makefile.\n");
    return 0;
}
```

**Makefile**
```makefile
# 컴파일러 설정
CC = gcc
CFLAGS = -Wall -Wextra

# 타겟 설정
TARGET = hello

# 기본 타겟 (첫 번째 타겟)
all: $(TARGET)

# hello 실행 파일 생성
hello: hello.c
	$(CC) $(CFLAGS) -o $(TARGET) hello.c

# 생성된 파일 삭제
clean:
	rm -f $(TARGET)

# 재빌드
rebuild: clean all

# 실행
run: $(TARGET)
	./$(TARGET)

# Phony 타겟 선언
.PHONY: all clean rebuild run
```

## 🚀 사용 방법

### 1. 빌드

```bash
make
# 또는
make all
```

출력:
```
gcc -Wall -Wextra -o hello hello.c
```

### 2. 실행

```bash
./hello
# 또는
make run
```

출력:
```
Hello, Make!
This is my first Makefile.
```

### 3. 정리

```bash
make clean
```

### 4. 재빌드

```bash
make rebuild
```

## 🔍 주요 개념

### 타겟 (Target)
- `all`: 기본 빌드 타겟
- `hello`: 실행 파일 생성
- `clean`: 빌드 결과물 삭제
- `rebuild`: 정리 후 재빌드
- `run`: 빌드 후 실행

### 변수
- `CC`: 사용할 컴파일러
- `CFLAGS`: 컴파일 옵션
- `TARGET`: 생성할 실행 파일 이름

### Phony 타겟
실제 파일이 아닌 명령을 나타내는 타겟
```makefile
.PHONY: all clean rebuild run
```

## 💡 실험해보기

### 실험 1: 컴파일러 변경
```bash
make CC=clang
```

### 실험 2: 최적화 옵션 추가
Makefile의 CFLAGS 수정:
```makefile
CFLAGS = -Wall -Wextra -O2
```

### 실험 3: 파일 수정 후 재빌드
1. `hello.c` 파일 수정
2. `make` 실행
3. 변경된 파일만 재컴파일되는지 확인

## ❓ 연습 문제

1. 새로운 타겟 `debug`를 추가하여 `-g` 옵션으로 빌드하세요
2. `VERSION` 변수를 추가하고 프로그램에서 출력하세요
3. `install` 타겟을 추가하여 `/usr/local/bin`에 설치하세요

## 📚 다음 단계

이 예제를 이해했다면 다음 예제로 넘어가세요:
- [simple_project](../simple_project/) - 멀티 파일 프로젝트
