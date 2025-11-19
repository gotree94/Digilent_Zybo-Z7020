# Make 완벽 가이드: 초급에서 중급까지

리눅스 환경에서 Make를 사용한 빌드 자동화를 체계적으로 학습하기 위한 종합 가이드입니다.

## 📚 목차

1. [Make 기초](./docs/01-basics.md)
   - Make란 무엇인가?
   - Makefile 기본 구조
   - 첫 번째 Makefile 작성하기
   - 기본 타겟과 의존성

2. [Make 문법과 규칙](./docs/02-syntax.md)
   - 명시적 규칙 (Explicit Rules)
   - 암시적 규칙 (Implicit Rules)
   - 패턴 규칙 (Pattern Rules)
   - 변수와 매크로

3. [Make 변수 활용](./docs/03-variables.md)
   - 변수 정의와 할당
   - 자동 변수 (Automatic Variables)
   - 내장 변수
   - 조건부 할당

4. [고급 Make 기능](./docs/04-advanced.md)
   - 함수 사용하기
   - 조건문과 분기
   - Include와 모듈화
   - 재귀적 Make

5. [실전 프로젝트 예제](./docs/05-examples.md)
   - C 프로젝트 빌드
   - C++ 프로젝트 빌드
   - 멀티 디렉토리 프로젝트
   - 라이브러리 생성 및 링크

6. [Make 최적화와 디버깅](./docs/06-optimization.md)
   - 병렬 빌드
   - 의존성 자동 생성
   - 디버깅 기법
   - 베스트 프랙티스

## 🎯 학습 목표

이 가이드를 완료하면 다음을 할 수 있습니다:

- ✅ Makefile의 기본 구조와 문법 이해
- ✅ 실제 C/C++ 프로젝트에 Make 적용
- ✅ 복잡한 의존성 관리
- ✅ 효율적이고 유지보수 가능한 Makefile 작성
- ✅ Make의 고급 기능 활용

## 🛠️ 준비사항

- Linux 환경 (Ubuntu, CentOS 등)
- GNU Make 설치 (`sudo apt-get install make` 또는 `sudo yum install make`)
- 기본적인 C/C++ 지식
- 텍스트 에디터 (vim, nano, VS Code 등)

## 📖 사용 방법

1. 순서대로 각 문서를 학습하세요
2. 예제 코드를 직접 작성하고 실행해보세요
3. 각 섹션의 연습 문제를 풀어보세요
4. 실전 프로젝트로 학습 내용을 종합하세요

## 🔍 Make 버전 확인

```bash
make --version
```

이 가이드는 GNU Make 4.0 이상을 기준으로 작성되었습니다.

## 📝 기여하기

오타나 개선사항이 있다면 Pull Request를 보내주세요!

## 📄 라이선스

MIT License

---

**시작하기:** [Make 기초](./docs/01-basics.md)로 이동하세요!
