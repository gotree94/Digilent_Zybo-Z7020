# PC / Zybo ML Test

# Teachable Machine

https://teachablemachine.withgoogle.com/

**#학습 및 모델 생성**

<img width="1347" height="907" alt="001" src="https://github.com/user-attachments/assets/d06893c9-7df8-4d95-afd9-7304eca26be3" />
<br>
<img width="1347" height="907" alt="002" src="https://github.com/user-attachments/assets/a9ed4788-5d86-4e95-8a86-27c0663d1b93" />
<br>
<img width="1347" height="907" alt="003" src="https://github.com/user-attachments/assets/9ad89db1-dfb0-4805-8643-e746f43c4212" />
<br>
<img width="1347" height="907" alt="004" src="https://github.com/user-attachments/assets/61c26fc9-9277-4904-88ed-3ca310ca8b5b" />
<br>
<img width="1347" height="907" alt="005" src="https://github.com/user-attachments/assets/9fc069b7-c5e3-4349-91ed-f9ed462ce868" />
<br>
<img width="1347" height="907" alt="006" src="https://github.com/user-attachments/assets/efcee127-bf62-4f4c-96d9-9ea9fab3e112" />
<br>
<img width="1347" height="907" alt="007" src="https://github.com/user-attachments/assets/69d98410-c7c3-437d-9a03-20496a6f25a6" />
<br>
<img width="1347" height="907" alt="008" src="https://github.com/user-attachments/assets/11909c5a-9374-4a95-88b9-eccd43b0f541" />
<br>
<img width="1347" height="907" alt="009" src="https://github.com/user-attachments/assets/13186f40-5db7-4d43-bbf0-1a1586b34384" />
<br>
<img width="1347" height="907" alt="010" src="https://github.com/user-attachments/assets/54c94729-0967-47c8-beba-033b6daa9b90" />
<br>
<img width="1347" height="907" alt="011" src="https://github.com/user-attachments/assets/e9130dd9-fb32-4e66-9003-96caea40c475" />
<br>
<img width="1347" height="907" alt="012" src="https://github.com/user-attachments/assets/29cc9ec2-fdae-4482-abe1-afe080a7ba77" />
<br>
<img width="1347" height="907" alt="013" src="https://github.com/user-attachments/assets/b5500047-35a3-40fb-9c1b-dede8797a506" />
<br>
<img width="1347" height="907" alt="014" src="https://github.com/user-attachments/assets/731ba1d6-cb01-4183-8270-fc5bceb70904" />
<br>
<img width="1347" height="907" alt="015" src="https://github.com/user-attachments/assets/9ec615fb-0871-4167-82d1-72dd66f4eb6d" />
<br>

**#디렉토리 구조**
```
teachable_machine_test/
├── vehicle_classifier.py
├── model_unquant.tflite
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

<img width="491" height="280" alt="018" src="https://github.com/user-attachments/assets/ae1d4a1a-3fae-4c32-87c4-da86feea51f6" />


* test_images.zip : https://drive.google.com/file/d/1j6IP2A7kdL3q7s2HmFmBlznltVjphpnA/view?usp=sharing
* train.zip : https://drive.google.com/file/d/1oQQlkj5Lb8Kwphzzd17-OlMqaLpR9yaY/view?usp=sharing

**#실행 결과**

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
