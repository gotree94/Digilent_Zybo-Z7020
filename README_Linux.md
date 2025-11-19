# Linux 명령어 & 쉘스크립트 가이드

리눅스 기본 명령어와 쉘스크립트 작성법을 정리한 문서입니다.

## 📑 목차

- [기본 명령어](#기본-명령어)
- [파일 및 디렉토리 관리](#파일-및-디렉토리-관리)
- [파일 내용 확인 및 편집](#파일-내용-확인-및-편집)
- [권한 관리](#권한-관리)
- [프로세스 관리](#프로세스-관리)
- [네트워크 관리](#네트워크-관리)
- [시스템 정보](#시스템-정보)
- [압축 및 아카이브](#압축-및-아카이브)
- [쉘스크립트 기초](#쉘스크립트-기초)
- [쉘스크립트 고급](#쉘스크립트-고급)

---

## 기본 명령어

### 디렉토리 이동 및 확인

```bash
pwd                    # 현재 작업 디렉토리 출력
cd /path/to/directory  # 디렉토리 이동
cd ~                   # 홈 디렉토리로 이동
cd ..                  # 상위 디렉토리로 이동
cd -                   # 이전 디렉토리로 이동
```

### 디렉토리 내용 확인

```bash
ls                     # 파일 및 디렉토리 목록 출력
ls -l                  # 상세 정보 포함 출력
ls -a                  # 숨김 파일 포함 출력
ls -lh                 # 사람이 읽기 쉬운 형식으로 출력
ls -lt                 # 수정 시간순 정렬
tree                   # 디렉토리 구조를 트리 형태로 출력
```

---

## 파일 및 디렉토리 관리

### 생성

```bash
touch filename.txt              # 빈 파일 생성
mkdir directory_name            # 디렉토리 생성
mkdir -p parent/child/grandson  # 중첩 디렉토리 생성
```

### 복사

```bash
cp source.txt dest.txt          # 파일 복사
cp -r source_dir dest_dir       # 디렉토리 복사 (재귀적)
cp -i source.txt dest.txt       # 덮어쓰기 전 확인
```

### 이동 및 이름 변경

```bash
mv oldname.txt newname.txt      # 파일 이름 변경
mv file.txt /path/to/directory/ # 파일 이동
mv -i source.txt dest.txt       # 덮어쓰기 전 확인
```

### 삭제

```bash
rm filename.txt                 # 파일 삭제
rm -r directory_name            # 디렉토리 삭제 (재귀적)
rm -f filename.txt              # 강제 삭제
rm -rf directory_name           # 디렉토리 강제 삭제 (주의!)
rmdir empty_directory           # 빈 디렉토리 삭제
```

### 검색

```bash
find /path -name "*.txt"        # 이름으로 파일 검색
find /path -type f -size +10M   # 10MB 이상 파일 검색
find /path -mtime -7            # 최근 7일 내 수정된 파일
locate filename                 # 데이터베이스에서 파일 검색
which command                   # 명령어 경로 찾기
whereis command                 # 명령어 관련 파일 찾기
```

---

## 파일 내용 확인 및 편집

### 파일 내용 확인

```bash
cat file.txt                    # 파일 전체 내용 출력
less file.txt                   # 페이지 단위로 파일 보기
more file.txt                   # 페이지 단위로 파일 보기 (less보다 제한적)
head file.txt                   # 파일 앞부분 10줄 출력
head -n 20 file.txt             # 파일 앞부분 20줄 출력
tail file.txt                   # 파일 뒷부분 10줄 출력
tail -f /var/log/syslog         # 실시간으로 파일 끝 내용 모니터링
```

### 텍스트 처리

```bash
grep "pattern" file.txt         # 패턴 검색
grep -r "pattern" /path         # 디렉토리 내 재귀 검색
grep -i "pattern" file.txt      # 대소문자 구분 없이 검색
grep -n "pattern" file.txt      # 줄 번호와 함께 출력
grep -v "pattern" file.txt      # 패턴과 일치하지 않는 줄 출력

sed 's/old/new/' file.txt       # 첫 번째 일치 항목 치환
sed 's/old/new/g' file.txt      # 모든 일치 항목 치환
sed -i 's/old/new/g' file.txt   # 파일 내용 직접 수정

awk '{print $1}' file.txt       # 첫 번째 필드 출력
awk -F',' '{print $2}' file.csv # CSV의 두 번째 필드 출력
```

### 파일 비교

```bash
diff file1.txt file2.txt        # 두 파일의 차이점 출력
diff -u file1.txt file2.txt     # unified 형식으로 출력
comm file1.txt file2.txt        # 정렬된 파일 비교
```

---

## 권한 관리

### 권한 확인 및 변경

```bash
ls -l                           # 파일 권한 확인
chmod 755 file.sh               # rwxr-xr-x 권한 설정
chmod +x file.sh                # 실행 권한 추가
chmod -w file.txt               # 쓰기 권한 제거
chmod u+x file.sh               # 소유자에게 실행 권한 추가
chmod go-w file.txt             # 그룹과 기타 사용자의 쓰기 권한 제거
```

### 소유권 변경

```bash
chown user:group file.txt       # 소유자 및 그룹 변경
chown -R user:group directory/  # 디렉토리 및 하위 항목 소유권 변경
chgrp groupname file.txt        # 그룹만 변경
```

### 권한 숫자 표기법

- `r (읽기)` = 4
- `w (쓰기)` = 2
- `x (실행)` = 1

```bash
chmod 644 file.txt              # rw-r--r--
chmod 755 script.sh             # rwxr-xr-x
chmod 600 private.key           # rw-------
```

---

## 프로세스 관리

### 프로세스 확인

```bash
ps                              # 현재 셸의 프로세스 출력
ps aux                          # 모든 프로세스 상세 정보 출력
ps aux | grep process_name      # 특정 프로세스 검색
top                             # 실시간 프로세스 모니터링
htop                            # 향상된 프로세스 뷰어 (설치 필요)
pgrep process_name              # 프로세스 이름으로 PID 검색
```

### 프로세스 제어

```bash
kill PID                        # 프로세스 종료 (SIGTERM)
kill -9 PID                     # 프로세스 강제 종료 (SIGKILL)
killall process_name            # 이름으로 프로세스 종료
pkill process_name              # 패턴으로 프로세스 종료
```

### 백그라운드 실행

```bash
command &                       # 백그라운드에서 명령 실행
nohup command &                 # 로그아웃 후에도 실행 유지
jobs                            # 백그라운드 작업 목록
fg %1                           # 작업을 포그라운드로 가져오기
bg %1                           # 작업을 백그라운드로 보내기
Ctrl+Z                          # 현재 프로세스 일시 중지
```

---

## 네트워크 관리

### 네트워크 정보

```bash
ifconfig                        # 네트워크 인터페이스 정보 (구식)
ip addr                         # IP 주소 정보
ip link                         # 네트워크 인터페이스 상태
hostname                        # 호스트 이름 출력
hostname -I                     # IP 주소 출력
```

### 연결 테스트

```bash
ping google.com                 # 연결 테스트
ping -c 4 8.8.8.8               # 4번만 ping
traceroute google.com           # 경로 추적
netstat -tuln                   # 열린 포트 확인
ss -tuln                        # 소켓 통계 (netstat 대체)
```

### 파일 전송

```bash
scp file.txt user@host:/path    # 원격으로 파일 복사
scp -r dir user@host:/path      # 디렉토리 복사
rsync -avz source/ dest/        # 동기화 (증분 전송)
wget http://example.com/file    # 파일 다운로드
curl -O http://example.com/file # 파일 다운로드
```

### SSH

```bash
ssh user@hostname               # 원격 서버 접속
ssh -p 2222 user@hostname       # 특정 포트로 접속
ssh-keygen                      # SSH 키 생성
ssh-copy-id user@hostname       # 공개키 복사
```

---

## 시스템 정보

### 시스템 상태

```bash
uname -a                        # 시스템 정보 출력
uptime                          # 시스템 가동 시간
date                            # 현재 날짜 및 시간
cal                             # 달력 출력
whoami                          # 현재 사용자 이름
who                             # 로그인한 사용자 정보
w                               # 사용자 활동 정보
```

### 디스크 및 메모리

```bash
df -h                           # 디스크 사용량 (사람이 읽기 쉬운 형식)
du -sh directory/               # 디렉토리 크기
du -h --max-depth=1             # 하위 디렉토리별 크기
free -h                         # 메모리 사용량
```

### 시스템 리소스

```bash
lscpu                           # CPU 정보
lsblk                           # 블록 디바이스 정보
lsusb                           # USB 디바이스 목록
lspci                           # PCI 디바이스 목록
dmesg | tail                    # 커널 메시지 확인
```

---

## 압축 및 아카이브

### tar (아카이브)

```bash
tar -cvf archive.tar files/     # tar 아카이브 생성
tar -xvf archive.tar            # tar 아카이브 압축 해제
tar -czvf archive.tar.gz files/ # gzip으로 압축된 tar 생성
tar -xzvf archive.tar.gz        # gzip tar 압축 해제
tar -cjvf archive.tar.bz2 files/# bzip2로 압축된 tar 생성
tar -xjvf archive.tar.bz2       # bzip2 tar 압축 해제
tar -tvf archive.tar            # tar 내용 확인
```

### 압축

```bash
gzip file.txt                   # gzip 압축 (file.txt.gz 생성)
gunzip file.txt.gz              # gzip 압축 해제
bzip2 file.txt                  # bzip2 압축
bunzip2 file.txt.bz2            # bzip2 압축 해제
zip archive.zip files/          # zip 압축
unzip archive.zip               # zip 압축 해제
```

---

## 쉘스크립트 기초

### 쉘스크립트 시작하기

```bash
#!/bin/bash
# 첫 줄은 shebang으로 인터프리터 지정

echo "Hello, World!"            # 메시지 출력
```

### 변수

```bash
#!/bin/bash

# 변수 선언 및 할당 (= 앞뒤에 공백 없음)
name="John"
age=25

# 변수 사용
echo "My name is $name"
echo "I am ${age} years old"

# 명령 결과를 변수에 저장
current_date=$(date)
files=$(ls -l)

# 읽기 전용 변수
readonly PI=3.14159
```

### 사용자 입력

```bash
#!/bin/bash

# 사용자로부터 입력 받기
echo "What is your name?"
read username
echo "Hello, $username!"

# 프롬프트와 함께 입력 받기
read -p "Enter your age: " age

# 비밀번호 입력 (입력 숨김)
read -sp "Enter password: " password
echo
```

### 명령줄 인자

```bash
#!/bin/bash

# $0: 스크립트 이름
# $1, $2, ...: 첫 번째, 두 번째 인자
# $#: 인자 개수
# $@: 모든 인자
# $?: 마지막 명령의 종료 상태

echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "Number of arguments: $#"
echo "All arguments: $@"
```

### 산술 연산

```bash
#!/bin/bash

# 방법 1: expr (구식)
result=$(expr 5 + 3)

# 방법 2: let
let result=5+3

# 방법 3: (( )) (권장)
((result = 5 + 3))
echo $result

# 방법 4: $[ ] (구식)
result=$[5 + 3]

# 부동소수점 연산 (bc 사용)
result=$(echo "scale=2; 10 / 3" | bc)
```

---

## 쉘스크립트 고급

### 조건문

```bash
#!/bin/bash

# if-else 문
if [ $age -ge 18 ]; then
    echo "You are an adult"
elif [ $age -ge 13 ]; then
    echo "You are a teenager"
else
    echo "You are a child"
fi

# 파일 존재 확인
if [ -f "/path/to/file" ]; then
    echo "File exists"
fi

# 디렉토리 존재 확인
if [ -d "/path/to/directory" ]; then
    echo "Directory exists"
fi

# 문자열 비교
if [ "$str1" = "$str2" ]; then
    echo "Strings are equal"
fi

# 논리 연산자
if [ $age -gt 18 ] && [ $age -lt 65 ]; then
    echo "Working age"
fi
```

### 비교 연산자

**숫자 비교:**
- `-eq`: 같음 (equal)
- `-ne`: 같지 않음 (not equal)
- `-gt`: 크다 (greater than)
- `-ge`: 크거나 같다 (greater or equal)
- `-lt`: 작다 (less than)
- `-le`: 작거나 같다 (less or equal)

**문자열 비교:**
- `=` 또는 `==`: 같음
- `!=`: 같지 않음
- `-z`: 문자열이 비어있음
- `-n`: 문자열이 비어있지 않음

**파일 테스트:**
- `-e`: 파일 존재
- `-f`: 일반 파일
- `-d`: 디렉토리
- `-r`: 읽기 가능
- `-w`: 쓰기 가능
- `-x`: 실행 가능

### 반복문

```bash
#!/bin/bash

# for 루프 - 범위
for i in {1..5}; do
    echo "Number: $i"
done

# for 루프 - 배열
fruits=("apple" "banana" "cherry")
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done

# for 루프 - 파일
for file in *.txt; do
    echo "Processing: $file"
done

# C 스타일 for 루프
for ((i=0; i<5; i++)); do
    echo "Count: $i"
done

# while 루프
count=0
while [ $count -lt 5 ]; do
    echo "Count: $count"
    ((count++))
done

# until 루프
count=0
until [ $count -ge 5 ]; do
    echo "Count: $count"
    ((count++))
done

# 무한 루프
while true; do
    echo "Press Ctrl+C to stop"
    sleep 1
done
```

### 배열

```bash
#!/bin/bash

# 배열 선언
arr=("apple" "banana" "cherry")

# 배열 요소 접근
echo ${arr[0]}              # 첫 번째 요소
echo ${arr[@]}              # 모든 요소
echo ${#arr[@]}             # 배열 길이

# 배열 요소 추가
arr+=("date")

# 배열 순회
for item in "${arr[@]}"; do
    echo $item
done

# 연관 배열 (Bash 4.0+)
declare -A assoc_arr
assoc_arr[key1]="value1"
assoc_arr[key2]="value2"
echo ${assoc_arr[key1]}
```

### 함수

```bash
#!/bin/bash

# 함수 정의
greet() {
    echo "Hello, $1!"
}

# 함수 호출
greet "Alice"

# 반환값이 있는 함수
add() {
    local result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "Sum: $sum"

# return을 사용한 함수 (0-255 정수만 가능)
is_even() {
    if [ $(($1 % 2)) -eq 0 ]; then
        return 0  # true
    else
        return 1  # false
    fi
}

if is_even 4; then
    echo "4 is even"
fi
```

### case 문

```bash
#!/bin/bash

read -p "Enter a choice (a/b/c): " choice

case $choice in
    a|A)
        echo "You chose A"
        ;;
    b|B)
        echo "You chose B"
        ;;
    c|C)
        echo "You chose C"
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
```

### 파일 처리

```bash
#!/bin/bash

# 파일 읽기 - 방법 1
while read line; do
    echo "Line: $line"
done < input.txt

# 파일 읽기 - 방법 2
while IFS= read -r line; do
    echo "Line: $line"
done < input.txt

# 파일에 쓰기
echo "Hello, World!" > output.txt    # 덮어쓰기
echo "Another line" >> output.txt    # 추가

# 파일 존재 여부 확인 후 처리
if [ -f "config.txt" ]; then
    source config.txt
else
    echo "Config file not found!"
    exit 1
fi
```

### 에러 처리

```bash
#!/bin/bash

# set 옵션
set -e  # 에러 발생 시 스크립트 종료
set -u  # 미정의 변수 사용 시 에러
set -o pipefail  # 파이프라인에서 에러 전파

# 에러 핸들링
command || {
    echo "Command failed!"
    exit 1
}

# 조건부 실행
mkdir temp_dir && cd temp_dir && echo "Success"

# trap을 이용한 에러 처리
trap 'echo "Error occurred"; exit 1' ERR

# 정리 작업
trap 'rm -rf temp_dir' EXIT
```

### 유용한 패턴

```bash
#!/bin/bash

# 스크립트가 실행 중인 디렉토리 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 타임스탬프
timestamp=$(date +"%Y%m%d_%H%M%S")

# 로그 파일에 출력
exec > >(tee -a logfile.log)
exec 2>&1

# 진행 표시
for i in {1..10}; do
    echo -ne "Progress: $i/10\r"
    sleep 1
done
echo

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e "${RED}Error!${NC}"
echo -e "${GREEN}Success!${NC}"
```

### 실용 예제

```bash
#!/bin/bash

# 시스템 백업 스크립트
BACKUP_DIR="/backup"
SOURCE_DIR="/data"
DATE=$(date +%Y%m%d)
BACKUP_FILE="backup_$DATE.tar.gz"

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

# 백업 수행
echo "Starting backup..."
tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE_DIR"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE"
    # 7일 이상 된 백업 파일 삭제
    find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +7 -delete
else
    echo "Backup failed!"
    exit 1
fi
```

```bash
#!/bin/bash

# 로그 분석 스크립트
LOG_FILE="/var/log/application.log"
ERROR_COUNT=$(grep -c "ERROR" $LOG_FILE)
WARNING_COUNT=$(grep -c "WARNING" $LOG_FILE)

echo "=== Log Analysis Report ==="
echo "Date: $(date)"
echo "Log file: $LOG_FILE"
echo "Total errors: $ERROR_COUNT"
echo "Total warnings: $WARNING_COUNT"

# 가장 많이 발생한 에러 메시지 상위 5개
echo -e "\nTop 5 Error Messages:"
grep "ERROR" $LOG_FILE | awk '{print $NF}' | sort | uniq -c | sort -rn | head -5
```

---

## 추가 팁

### 쉘스크립트 디버깅

```bash
# 디버그 모드로 실행
bash -x script.sh

# 스크립트 내에서 디버그 모드 활성화
set -x  # 디버그 켜기
# 코드...
set +x  # 디버그 끄기

# 문법 검사만 수행 (실행 안 함)
bash -n script.sh
```

### 성능 측정

```bash
# 명령 실행 시간 측정
time command

# 스크립트 내에서 시간 측정
start=$(date +%s)
# 작업 수행...
end=$(date +%s)
echo "Elapsed time: $((end - start)) seconds"
```

### 유용한 단축키

- `Ctrl + C`: 현재 명령 중단
- `Ctrl + Z`: 현재 프로세스 일시 중지
- `Ctrl + D`: 로그아웃 또는 EOF
- `Ctrl + L`: 화면 지우기 (clear 명령과 동일)
- `Ctrl + R`: 명령 기록 검색
- `Ctrl + A`: 줄의 맨 앞으로 이동
- `Ctrl + E`: 줄의 맨 뒤로 이동
- `Ctrl + U`: 커서 앞의 모든 내용 삭제
- `Ctrl + K`: 커서 뒤의 모든 내용 삭제

---

## 참고 자료

- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [ShellCheck](https://www.shellcheck.net/) - 쉘스크립트 린터

---

## 라이센스

이 문서는 자유롭게 사용 및 수정 가능합니다.
