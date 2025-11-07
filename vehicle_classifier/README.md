# PC / Zybo ML Test

# Teachable Machine

https://teachablemachine.withgoogle.com/

<details>
<summary>🖼️ 학습 및 모델 생성 </summary>
<img width="640" height="640" alt="001" src="https://github.com/user-attachments/assets/ebe47177-9fe8-42db-9a97-c2f134eda096" />
<br>
<img width="640" height="640" alt="002" src="https://github.com/user-attachments/assets/35b841f4-5c5e-420e-9a80-05213666e4dd" />
<br>
<img width="640" height="640" alt="003" src="https://github.com/user-attachments/assets/0071f72b-1783-4546-ae96-4a436df6c834" />
<br>
<img width="640" height="640" alt="004" src="https://github.com/user-attachments/assets/927096cb-bdc3-42e7-944d-f9b4f1da344b" />
<br>
<img width="640" height="640" alt="005" src="https://github.com/user-attachments/assets/2b0a8726-0e77-443a-9803-1ee3f5266f62" />
<br>
<img width="640" height="640" alt="006" src="https://github.com/user-attachments/assets/8ab5a76f-8495-4e2e-956d-64d7f949418b" />
<br>
<img width="640" height="640" alt="007" src="https://github.com/user-attachments/assets/ab37fc36-1280-48b8-9f57-18c316c27823" />
<br>
<img width="640" height="640" alt="008" src="https://github.com/user-attachments/assets/07456d98-5613-41a4-bb5b-ca620e0c8e27" />
<br>
<img width="640" height="640" alt="009" src="https://github.com/user-attachments/assets/25606f54-75eb-47a3-b484-6ad00bbf6038" />
<br>
<img width="640" height="640" alt="010" src="https://github.com/user-attachments/assets/4aba4289-012b-4a73-b017-a186ccd782a2" />
<br>
<img width="640" height="640" alt="011" src="https://github.com/user-attachments/assets/f979ca5d-223b-4326-9b1e-0b13ca72a676" />
<br>
<img width="640" height="640" alt="012" src="https://github.com/user-attachments/assets/dafeff83-bd37-4d70-895c-28f5bf80ebdd" />
<br>
<img width="640" height="640" alt="013" src="https://github.com/user-attachments/assets/f7fe2264-b9cd-4ae0-8e38-fa0dbf88c253" />
<br>
<img width="640" height="640" alt="014" src="https://github.com/user-attachments/assets/8ae486b4-dd02-47f5-8c87-4e5dc9e3aaf1" />
<br>
<img width="640" height="640" alt="015" src="https://github.com/user-attachments/assets/a913acbc-77e4-4f3e-941c-0017fe0fc2ff" />
<br>
<img width="640" height="640" alt="016" src="https://github.com/user-attachments/assets/3b00c0a1-6f7b-4f43-a4b6-3ac9e77d455a" />
<br>
<img width="640" height="640" alt="017" src="https://github.com/user-attachments/assets/b419a35d-5448-4cd3-b8df-77d9f4fcf0b8" />
<br>
<img width="640" height="640" alt="018" src="https://github.com/user-attachments/assets/d782db22-9c2b-4e87-b575-fecbe797e0e4" />
<br>
<img width="640" height="640" alt="020" src="https://github.com/user-attachments/assets/323746d6-c369-4dab-b8fe-d73f849372ae" />
<br>
</details>

**#디렉토리 구조**
```
teachable_machine_test/
├── vehicle_classifier.py (부동소수점)
├── vehicle_classifier_quantized.py (양자화됨)
├── model_unquant.tflite (부동소수점)
├── model.tflite (양자화됨)
├── labels.txt          # Class 0: cars \ Class 1: airplanes \ Class 2: ships
└── test_images/
    ├── airplanes ├── airplane1.jpg
    |             ├── airplane2.jpg
    |             ├── airplane3.jpg
    |             └── ...
    ├── cars      ├── cars1.jpg
    |             ├── cars2.jpg
    |             ├── cars3.jpg
    |             └── ...
    └── ships     ├── 2122710.jpg
                  ├── 2123631.jpg
                  ├── 2125162.jpg
                  └── ...
```

<img width="651" height="135" alt="020" src="https://github.com/user-attachments/assets/b8b5b462-2bc8-44d2-a6b1-9b36dd2cfcb6" />


* test_images.zip : https://drive.google.com/file/d/1j6IP2A7kdL3q7s2HmFmBlznltVjphpnA/view?usp=sharing
* train.zip : https://drive.google.com/file/d/1oQQlkj5Lb8Kwphzzd17-OlMqaLpR9yaY/view?usp=sharing

# Tensorflow Lite : 부동소수점

<details>
<summary>🚗 Vehicle Classifier 테스트 명령어 가이드 </summary>

### 📋 기본 구조

```bash
python vehicle_classifier.py -m <모델> -l <라벨> [옵션]
```

---

### 🎯 1. 단일 이미지 테스트

#### 기본 명령어
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg
```

#### 상세 정보 없이 테스트
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test.jpg --no-details
```

#### 결과 JSON 저장
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test.jpg -o result.json
```

---

### 📁 2. 디렉토리 전체 테스트

#### 한 디렉토리의 모든 이미지 테스트
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d test_images\airplanes
```

#### 여러 이미지가 섞인 디렉토리
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d mixed_images
```

#### 결과 JSON 저장
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d test_images\cars -o cars_results.json
```

---

### 🗂️ 3. 클래스별 하위 디렉토리 테스트 (정확도 측정)

#### 기본 구조
```
test_images/
├── airplanes/
│   ├── airplane1.jpg
│   ├── airplane2.jpg
│   └── ...
├── cars/
│   ├── car1.jpg
│   ├── car2.jpg
│   └── ...
└── ships/
    ├── ship1.jpg
    ├── ship2.jpg
    └── ...
```

#### 전체 클래스 테스트 (정확도 계산)
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images
```

#### 결과 JSON 저장
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o full_test_results.json
```

---

### 💡 실전 명령어 예제

#### 예제 1: 비행기 이미지 1장 테스트
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg
```
**출력 예시:**
```
✈️ 예측 결과
✓ 예측 클래스: AIRPLANES
✓ 신뢰도: 98.45%
✓ 추론 시간: 2.22ms

📊 모든 클래스 확률:
  ✈️ airplanes   |  98.45% | ██████████████████████████████████████████████████
  🚗 cars        |   0.52% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  🚢 ships       |   1.03% | █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
```

#### 예제 2: 자동차 폴더 전체 테스트
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d test_images\cars
```
**출력 예시:**
```
[1/10] car1.jpg
  🚗 cars         |  99.23% |   2.15ms
[2/10] car2.jpg
  🚗 cars         |  97.84% |   2.08ms
...

📊 테스트 요약
총 이미지: 10
성공: 10
실패: 0
평균 추론 시간: 2.11ms
```

#### 예제 3: 전체 데이터셋 정확도 평가
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o accuracy_report.json
```
**출력 예시:**
```
📁 AIRPLANES 테스트
[1/20] airplane1.jpg
  ✈️ airplanes    |  98.45% |   2.22ms
...
✓ airplanes 정확도: 19/20 (95.0%)

📁 CARS 테스트
[1/30] car1.jpg
  🚗 cars         |  99.23% |   2.15ms
...
✓ cars 정확도: 29/30 (96.7%)

📁 SHIPS 테스트
[1/25] ship1.jpg
  🚢 ships        |  97.89% |   2.18ms
...
✓ ships 정확도: 24/25 (96.0%)

🎯 전체 테스트 요약
클래스별 정확도:
  ✈️ airplanes   :  19/ 20 ( 95.00%) ███████████████████████████████████████████████
  🚗 cars        :  29/ 30 ( 96.67%) ████████████████████████████████████████████████
  🚢 ships       :  24/ 25 ( 96.00%) ████████████████████████████████████████████████
  🎯 전체 정확도: 72/75 (96.00%)

✓ 전체 결과 저장: accuracy_report.json
```

---

### 🔧 Windows vs PetaLinux 명령어 차이

#### Windows (PowerShell/CMD)
```bash
# 역슬래시 사용
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg

# 또는 슬래시도 작동
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images/airplanes/airplane1.jpg
```

### PetaLinux (Zybo 7020)
```bash
# 슬래시 사용
python3 vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images/airplanes/airplane1.jpg

# 실행 권한 부여 (최초 1회)
chmod +x vehicle_classifier.py
./vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test.jpg
```

---

### 📊 JSON 결과 파일 구조

#### 단일/디렉토리 테스트 (`-o result.json`)
```json
{
  "timestamp": "2025-11-04T11:36:50.123456",
  "total_images": 10,
  "results": [
    {
      "file": "airplane1.jpg",
      "path": "test_images/airplanes/airplane1.jpg",
      "label": "airplanes",
      "confidence": 0.9845,
      "inference_time": 2.22,
      "probabilities": [0.9845, 0.0052, 0.0103]
    },
    ...
  ]
}
```

#### 클래스별 테스트 (`-s` + `-o results.json`)
```json
{
  "timestamp": "2025-11-04T11:36:50.123456",
  "overall_accuracy": 96.0,
  "total_images": 75,
  "total_correct": 72,
  "class_stats": {
    "airplanes": {
      "total": 20,
      "correct": 19,
      "accuracy": 95.0
    },
    "cars": {
      "total": 30,
      "correct": 29,
      "accuracy": 96.67
    },
    "ships": {
      "total": 25,
      "correct": 24,
      "accuracy": 96.0
    }
  },
  "detailed_results": { ... }
}
```

---

### 🎨 명령어 옵션 정리

| 옵션 | 필수 | 설명 | 예제 |
|------|------|------|------|
| `-m`, `--model` | ✓ | TFLite 모델 파일 | `-m model.tflite` |
| `-l`, `--labels` | ✓ | 라벨 파일 | `-l labels.txt` |
| `-i`, `--image` | | 단일 이미지 테스트 | `-i test.jpg` |
| `-d`, `--directory` | | 디렉토리 테스트 | `-d images/` |
| `-s`, `--subdirs` | | 클래스별 하위 디렉토리 | `-s test_images/` |
| `-o`, `--output` | | 결과 JSON 저장 | `-o results.json` |
| `--no-details` | | 상세 정보 숨기기 | `--no-details` |

---

### 🚀 빠른 시작 가이드

#### 1단계: 모델 및 라벨 확인
```bash
# 파일 존재 확인
dir model_unquant.tflite
dir labels.txt
```

#### 2단계: 단일 이미지로 테스트
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg
```

#### 3단계: 정확도 평가
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o accuracy_report.json
```

---

### 🐛 문제 해결

#### 모델 파일 없음
```
❌ FileNotFoundError: 모델 파일을 찾을 수 없습니다
```
**해결:** 모델 파일 경로 확인
```bash
python vehicle_classifier.py -m ./model_unquant.tflite -l ./labels.txt -i test.jpg
```

#### 이미지 경로 오류
```
❌ FileNotFoundError: 이미지를 찾을 수 없습니다
```
**해결:** 절대 경로 사용
```bash
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i C:\Users\52\Desktop\test.jpg
```

#### TensorFlow 오류
```
❌ TensorFlow Lite를 찾을 수 없습니다
```
**해결:** TensorFlow 설치
```bash
pip install tensorflow==2.15.0
```

---

### 📝 실제 워크플로우 예제

#### 시나리오 1: 새 모델 빠른 검증
```bash
# 1. 각 클래스에서 1장씩 테스트
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\cars\car1.jpg
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test_images\ships\ship1.jpg
```

#### 시나리오 2: 전체 데이터셋 평가
```bash
# 모든 클래스 테스트 + JSON 저장
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o evaluation_results.json
```

#### 시나리오 3: 특정 클래스 집중 테스트
```bash
# 비행기만 집중 테스트
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d test_images\airplanes -o airplane_results.json
```

#### 시나리오 4: 배치 처리
```bash
# 여러 모델 비교
python vehicle_classifier.py -m model_v1.tflite -l labels.txt -s test_images -o results_v1.json
python vehicle_classifier.py -m model_v2.tflite -l labels.txt -s test_images -o results_v2.json
python vehicle_classifier.py -m model_v3.tflite -l labels.txt -s test_images -o results_v3.json
```

---

### 🎯 성능 벤치마크 명령어

#### 추론 속도 측정
```bash
# 100장 이미지로 속도 테스트
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d large_dataset --no-details
```

#### 정확도 vs 속도 비교
```bash
# 양자화 모델
python vehicle_classifier.py -m model_quantized.tflite -l labels.txt -s test_images -o quant_results.json

# 비양자화 모델
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o unquant_results.json
```

---

### 💻 스크립트 자동화 예제 (배치 파일)

#### Windows: `test_all.bat`
```batch
@echo off
echo 전체 테스트 시작...

python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o results_%date:~0,4%%date:~5,2%%date:~8,2%.json

echo 테스트 완료!
pause
```

#### Linux: `test_all.sh`
```bash
#!/bin/bash
echo "전체 테스트 시작..."

python3 vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o results_$(date +%Y%m%d).json

echo "테스트 완료!"
```

---

### 📌 요약: 가장 많이 쓰는 명령어 TOP 5

```bash
# 1. 단일 이미지 테스트 (가장 기본)
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test.jpg

# 2. 전체 정확도 평가 (가장 중요)
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -s test_images -o results.json

# 3. 특정 폴더 테스트
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d test_images\cars

# 4. 간단한 결과만 보기
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -i test.jpg --no-details

# 5. 디렉토리 테스트 + 결과 저장
python vehicle_classifier.py -m model_unquant.tflite -l labels.txt -d images -o results.json
```
</details>


<details>
<summary>🖼️ 부동소수점 실험결과 </summary>
    
```
(base) C:\Users\Administrator\Desktop\ML\vehicle_classifier>python vehicle_classifier1.py -m model_unquant.tflite -l labels.txt -i test_images\airplanes\airplane1.jpg
2025-11-04 01:07:11.491887: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
2025-11-04 01:07:12.455840: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
✓ TensorFlow Lite 사용
C:\ProgramData\anaconda3\Lib\site-packages\tensorflow\lite\python\interpreter.py:457: UserWarning:     Warning: tf.lite.Interpreter is deprecated and is scheduled for deletion in
    TF 2.20. Please use the LiteRT interpreter from the ai_edge_litert package.
    See the [migration guide](https://ai.google.dev/edge/litert/migration)
    for details.

  warnings.warn(_INTERPRETER_DELETION_WARNING)
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.

======================================================================
🚗 교통수단 분류 모델 정보
======================================================================
모델 파일: model_unquant.tflite
모델 경로: model_unquant.tflite
라벨 파일: labels.txt
입력 크기: 224x224x3
입력 타입: float32
클래스 수: 3
클래스 목록:
  [0] cars
  [1] airplanes
  [2] ships

✓ Float 모델 (FP32)

⚙️  전처리: Teachable Machine 방식 ([-1, 1] 정규화)
======================================================================


📸 이미지 테스트: test_images\airplanes\airplane1.jpg

======================================================================
✈️ 예측 결과
======================================================================
✓ 예측 클래스: AIRPLANES
✓ 신뢰도: 100.00%
✓ 추론 시간: 2.07ms

📊 모든 클래스 확률:
----------------------------------------------------------------------
  🚗 cars         |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ✈️ airplanes    | 100.00% | ██████████████████████████████████████████████████
  🚢 ships        |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
======================================================================

(base) C:\Users\Administrator\Desktop\ML\vehicle_classifier>python vehicle_classifier1.py -m model_unquant.tflite -l labels.txt -i test_images\cars\cars1.jpg
2025-11-04 01:07:33.339322: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
2025-11-04 01:07:34.306372: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
✓ TensorFlow Lite 사용
C:\ProgramData\anaconda3\Lib\site-packages\tensorflow\lite\python\interpreter.py:457: UserWarning:     Warning: tf.lite.Interpreter is deprecated and is scheduled for deletion in
    TF 2.20. Please use the LiteRT interpreter from the ai_edge_litert package.
    See the [migration guide](https://ai.google.dev/edge/litert/migration)
    for details.

  warnings.warn(_INTERPRETER_DELETION_WARNING)
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.

======================================================================
🚗 교통수단 분류 모델 정보
======================================================================
모델 파일: model_unquant.tflite
모델 경로: model_unquant.tflite
라벨 파일: labels.txt
입력 크기: 224x224x3
입력 타입: float32
클래스 수: 3
클래스 목록:
  [0] cars
  [1] airplanes
  [2] ships

✓ Float 모델 (FP32)

⚙️  전처리: Teachable Machine 방식 ([-1, 1] 정규화)
======================================================================


📸 이미지 테스트: test_images\cars\cars1.jpg

======================================================================
🚗 예측 결과
======================================================================
✓ 예측 클래스: CARS
✓ 신뢰도: 100.00%
✓ 추론 시간: 2.05ms

📊 모든 클래스 확률:
----------------------------------------------------------------------
  🚗 cars         | 100.00% | █████████████████████████████████████████████████░
  ✈️ airplanes    |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  🚢 ships        |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
======================================================================

(base) C:\Users\Administrator\Desktop\ML\vehicle_classifier>python vehicle_classifier1.py -m model_unquant.tflite -l labels.txt -i test_images\ships\2122710.jpg
2025-11-04 01:07:54.027551: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
2025-11-04 01:07:54.964717: I tensorflow/core/util/port.cc:153] oneDNN custom operations are on. You may see slightly different numerical results due to floating-point round-off errors from different computation orders. To turn them off, set the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
✓ TensorFlow Lite 사용
C:\ProgramData\anaconda3\Lib\site-packages\tensorflow\lite\python\interpreter.py:457: UserWarning:     Warning: tf.lite.Interpreter is deprecated and is scheduled for deletion in
    TF 2.20. Please use the LiteRT interpreter from the ai_edge_litert package.
    See the [migration guide](https://ai.google.dev/edge/litert/migration)
    for details.

  warnings.warn(_INTERPRETER_DELETION_WARNING)
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.

======================================================================
🚗 교통수단 분류 모델 정보
======================================================================
모델 파일: model_unquant.tflite
모델 경로: model_unquant.tflite
라벨 파일: labels.txt
입력 크기: 224x224x3
입력 타입: float32
클래스 수: 3
클래스 목록:
  [0] cars
  [1] airplanes
  [2] ships

✓ Float 모델 (FP32)

⚙️  전처리: Teachable Machine 방식 ([-1, 1] 정규화)
======================================================================


📸 이미지 테스트: test_images\ships\2122710.jpg

======================================================================
🚢 예측 결과
======================================================================
✓ 예측 클래스: SHIPS
✓ 신뢰도: 100.00%
✓ 추론 시간: 2.59ms

📊 모든 클래스 확률:
----------------------------------------------------------------------
  🚗 cars         |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ✈️ airplanes    |   0.00% | ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  🚢 ships        | 100.00% | █████████████████████████████████████████████████░
======================================================================
```

</details>


---


# Tensorflow Lite : 양자화됨

**#실행 결과**

```

```


# Tensorflow Lite : Zybo 환경만들기

**#실행 결과**

```

```
