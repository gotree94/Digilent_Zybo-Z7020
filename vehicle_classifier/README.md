# PC / Zybo ML Test

# Teachable Machine

https://teachablemachine.withgoogle.com/

**#학습 및 모델 생성**

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

<img width="551" height="140" alt="019" src="https://github.com/user-attachments/assets/77c24028-4dd6-4dc8-a6d9-177e432dec6e" />


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
