#!/usr/bin/env python3
"""
교통수단 분류기 (Airplanes, Cars, Ships) - 수정 버전
Teachable Machine TFLite 모델 전처리 방식 적용
"""

import sys
import os
import time
import argparse
import numpy as np
from PIL import Image
import json
from datetime import datetime

# TensorFlow Lite 임포트
try:
    import tflite_runtime.interpreter as tflite
    TF_LITE_RUNTIME = True
    print("✓ TFLite Runtime 사용")
except ImportError:
    try:
        import tensorflow.lite as tflite
        TF_LITE_RUNTIME = False
        print("✓ TensorFlow Lite 사용")
    except ImportError:
        print("\n" + "="*70)
        print("❌ 오류: TensorFlow Lite를 찾을 수 없습니다.")
        print("="*70)
        print("\n설치 방법:")
        print("  pip install tflite-runtime")
        print("  또는")
        print("  pip install tensorflow")
        print("\n" + "="*70)
        sys.exit(1)


class VehicleClassifier:
    """교통수단 분류 모델 래퍼"""
    
    def __init__(self, model_path, labels_path, verbose=True):
        """
        모델 초기화
        
        Args:
            model_path: .tflite 모델 파일 경로
            labels_path: labels.txt 파일 경로
            verbose: 상세 정보 출력 여부
        """
        self.model_path = model_path
        self.labels_path = labels_path
        self.verbose = verbose
        
        # 모델 존재 확인
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"모델 파일을 찾을 수 없습니다: {model_path}")
        
        if not os.path.exists(labels_path):
            raise FileNotFoundError(f"라벨 파일을 찾을 수 없습니다: {labels_path}")
        
        # 라벨 로드
        self.labels = self._load_labels()
        
        # TFLite 인터프리터 생성
        try:
            self.interpreter = tflite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()
        except Exception as e:
            raise RuntimeError(f"모델 로드 실패: {e}")
        
        # 입출력 텐서 정보
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # 입력 이미지 크기
        self.input_shape = self.input_details[0]['shape']
        self.height = self.input_shape[1]
        self.width = self.input_shape[2]
        self.channels = self.input_shape[3]
        
        # 입력 데이터 타입
        self.input_dtype = self.input_details[0]['dtype']
        
        if self.verbose:
            self._print_model_info()
    
    def _print_model_info(self):
        """모델 정보 출력"""
        print("\n" + "="*70)
        print("🚗 교통수단 분류 모델 정보")
        print("="*70)
        print(f"모델 파일: {os.path.basename(self.model_path)}")
        print(f"모델 경로: {self.model_path}")
        print(f"라벨 파일: {os.path.basename(self.labels_path)}")
        print(f"입력 크기: {self.width}x{self.height}x{self.channels}")
        print(f"입력 타입: {self.input_dtype.__name__}")
        print(f"클래스 수: {len(self.labels)}")
        print(f"클래스 목록:")
        for i, label in enumerate(self.labels):
            print(f"  [{i}] {label}")
        
        # 모델 타입
        if self.input_dtype == np.uint8:
            print(f"\n✓ 양자화 모델 (INT8)")
        else:
            print(f"\n✓ Float 모델 (FP32)")
        
        print(f"\n⚙️  전처리: Teachable Machine 방식 ([-1, 1] 정규화)")
        print("="*70 + "\n")
    
    def _load_labels(self):
        """라벨 파일 로드"""
        labels = []
        try:
            with open(self.labels_path, 'r', encoding='utf-8') as f:
                for line in f:
                    label = line.strip()
                    # 빈 줄이나 'EOF' 같은 불필요한 라벨 제외
                    if label and label.upper() not in ['EOF', '']:
                        labels.append(label)
        except Exception as e:
            raise RuntimeError(f"라벨 로드 실패: {e}")
        
        if len(labels) == 0:
            raise ValueError("라벨이 비어있습니다.")
        
        return labels
    
    def preprocess_image(self, image_path_or_image):
        """
        이미지 전처리 (Teachable Machine 방식)
        
        Args:
            image_path_or_image: 이미지 경로(str) 또는 PIL Image 객체
            
        Returns:
            전처리된 numpy 배열
        """
        try:
            # 이미지 로드
            if isinstance(image_path_or_image, str):
                if not os.path.exists(image_path_or_image):
                    raise FileNotFoundError(f"이미지를 찾을 수 없습니다: {image_path_or_image}")
                img = Image.open(image_path_or_image)
            else:
                img = image_path_or_image
            
            # RGB 변환
            img = img.convert('RGB')
            
            # 크기 조정 (고품질 리샘플링)
            img = img.resize((self.width, self.height), Image.LANCZOS)
            
            # numpy 배열로 변환
            img_array = np.array(img, dtype=np.float32)
            
            # *** Teachable Machine 정규화 방식 ***
            # 범위: [0, 255] -> [-1, 1]
            img_array = (img_array - 127.5) / 127.5
            
            # 배치 차원 추가 [1, height, width, channels]
            img_array = np.expand_dims(img_array, axis=0)
            
            return img_array
            
        except Exception as e:
            if self.verbose:
                print(f"❌ 이미지 전처리 실패: {e}")
                import traceback
                traceback.print_exc()
            return None
    
    def predict(self, image_path):
        """
        이미지 분류 예측
        
        Args:
            image_path: 입력 이미지 경로
            
        Returns:
            dict: 예측 결과
        """
        # 이미지 전처리
        input_data = self.preprocess_image(image_path)
        if input_data is None:
            return None
        
        # 추론 시작
        start_time = time.time()
        
        try:
            self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
            self.interpreter.invoke()
            
            # 결과 가져오기
            output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
            probabilities = output_data[0]
        except Exception as e:
            if self.verbose:
                print(f"❌ 추론 실패: {e}")
            return None
        
        inference_time = (time.time() - start_time) * 1000  # ms
        
        # 최고 확률 클래스
        predicted_index = np.argmax(probabilities)
        confidence = float(probabilities[predicted_index])
        predicted_label = self.labels[predicted_index] if predicted_index < len(self.labels) else "Unknown"
        
        return {
            'label': predicted_label,
            'confidence': confidence,
            'probabilities': probabilities.tolist(),
            'inference_time': inference_time,
            'predicted_index': int(predicted_index)
        }


def print_single_result(result, labels, show_all=True):
    """단일 예측 결과 출력"""
    if result is None:
        print("❌ 예측 실패")
        return
    
    # 이모지 선택
    emoji_map = {
        'airplanes': '✈️',
        'cars': '🚗',
        'ships': '🚢'
    }
    emoji = emoji_map.get(result['label'], '📦')
    
    print("\n" + "="*70)
    print(f"{emoji} 예측 결과")
    print("="*70)
    print(f"✓ 예측 클래스: {result['label'].upper()}")
    print(f"✓ 신뢰도: {result['confidence']*100:.2f}%")
    print(f"✓ 추론 시간: {result['inference_time']:.2f}ms")
    
    if show_all:
        print("\n📊 모든 클래스 확률:")
        print("-"*70)
        
        probs = np.array(result['probabilities'])
        
        # 라벨 개수만큼만 출력
        for idx in range(len(labels)):
            label_name = labels[idx]
            prob = probs[idx] if idx < len(probs) else 0.0
            bar_length = int(prob * 50)
            bar = "█" * bar_length + "░" * (50 - bar_length)
            emoji = emoji_map.get(label_name, '📦')
            print(f"  {emoji} {label_name:12s} | {prob*100:6.2f}% | {bar}")
    
    print("="*70)


def test_single_image(classifier, image_path, show_all=True):
    """단일 이미지 테스트"""
    print(f"\n📸 이미지 테스트: {image_path}")
    
    if not os.path.exists(image_path):
        print(f"❌ 오류: 파일을 찾을 수 없습니다: {image_path}")
        return None
    
    result = classifier.predict(image_path)
    print_single_result(result, classifier.labels, show_all)
    
    return result


def test_directory(classifier, directory, save_results=None):
    """디렉토리 내 모든 이미지 테스트"""
    import glob
    
    if not os.path.isdir(directory):
        print(f"❌ 오류: 디렉토리를 찾을 수 없습니다: {directory}")
        return None
    
    # 지원 이미지 형식
    extensions = ['*.jpg', '*.jpeg', '*.png', '*.bmp', '*.gif']
    
    image_files = []
    for ext in extensions:
        image_files.extend(glob.glob(os.path.join(directory, ext)))
        image_files.extend(glob.glob(os.path.join(directory, ext.upper())))
        # Windows 경로 구분자 고려
        image_files.extend(glob.glob(os.path.join(directory, '**', ext), recursive=False))
    
    if not image_files:
        print(f"❌ 오류: {directory}에 이미지 파일이 없습니다.")
        return None
    
    image_files.sort()
    
    print(f"\n📁 디렉토리: {directory}")
    print(f"📊 총 {len(image_files)}개 이미지 테스트")
    print("="*70)
    
    results = []
    total_time = 0
    
    for i, img_path in enumerate(image_files, 1):
        filename = os.path.basename(img_path)
        print(f"\n[{i}/{len(image_files)}] {filename}")
        
        result = classifier.predict(img_path)
        
        if result:
            total_time += result['inference_time']
            results.append({
                'file': filename,
                'path': img_path,
                'label': result['label'],
                'confidence': result['confidence'],
                'inference_time': result['inference_time'],
                'probabilities': result['probabilities']
            })
            
            # 간단한 결과 출력
            emoji_map = {'airplanes': '✈️', 'cars': '🚗', 'ships': '🚢'}
            emoji = emoji_map.get(result['label'], '📦')
            print(f"  {emoji} {result['label']:12s} | {result['confidence']*100:6.2f}% | {result['inference_time']:6.2f}ms")
        else:
            print(f"  ❌ 예측 실패")
    
    # 요약
    print_summary(results, len(image_files), total_time)
    
    # 결과 저장
    if save_results and results:
        save_results_to_json(results, save_results)
    
    return results


def test_subdirectories(classifier, root_dir, save_results=None):
    """하위 디렉토리별로 테스트"""
    
    print(f"\n📂 루트 디렉토리: {root_dir}")
    print("="*70)
    
    all_results = {}
    
    # 각 클래스별 디렉토리 테스트
    for label in classifier.labels:
        subdir = os.path.join(root_dir, label)
        
        if not os.path.isdir(subdir):
            print(f"\n⚠️  디렉토리 없음: {subdir}")
            continue
        
        print(f"\n{'='*70}")
        print(f"📁 {label.upper()} 테스트")
        print(f"{'='*70}")
        
        results = test_directory(classifier, subdir, save_results=None)
        
        if results:
            all_results[label] = results
            
            # 정확도 계산
            correct = sum(1 for r in results if r['label'] == label)
            accuracy = (correct / len(results)) * 100
            
            print(f"\n✓ {label} 정확도: {correct}/{len(results)} ({accuracy:.1f}%)")
    
    # 전체 요약
    print_overall_summary(all_results, classifier.labels)
    
    # 결과 저장
    if save_results:
        save_all_results_to_json(all_results, save_results)
    
    return all_results


def print_summary(results, total_images, total_time):
    """테스트 요약 출력"""
    print("\n" + "="*70)
    print("📊 테스트 요약")
    print("="*70)
    print(f"총 이미지: {total_images}")
    print(f"성공: {len(results)}")
    print(f"실패: {total_images - len(results)}")
    
    if results:
        print(f"평균 추론 시간: {total_time/len(results):.2f}ms")
        
        print("\n클래스별 분포:")
        print("-"*70)
        
        class_counts = {}
        for r in results:
            label = r['label']
            class_counts[label] = class_counts.get(label, 0) + 1
        
        emoji_map = {'airplanes': '✈️', 'cars': '🚗', 'ships': '🚢'}
        for label, count in sorted(class_counts.items(), key=lambda x: x[1], reverse=True):
            percentage = (count / len(results)) * 100
            emoji = emoji_map.get(label, '📦')
            bar_length = int(percentage / 2)
            bar = "█" * bar_length
            print(f"  {emoji} {label:12s}: {count:3d} ({percentage:5.1f}%) {bar}")
    
    print("="*70)


def print_overall_summary(all_results, labels):
    """전체 요약"""
    print("\n" + "="*70)
    print("🎯 전체 테스트 요약")
    print("="*70)
    
    total_images = 0
    total_correct = 0
    
    emoji_map = {'airplanes': '✈️', 'cars': '🚗', 'ships': '🚢'}
    
    print("\n클래스별 정확도:")
    print("-"*70)
    
    for label in labels:
        if label not in all_results:
            continue
        
        results = all_results[label]
        correct = sum(1 for r in results if r['label'] == label)
        total = len(results)
        accuracy = (correct / total) * 100 if total > 0 else 0
        
        total_images += total
        total_correct += correct
        
        emoji = emoji_map.get(label, '📦')
        bar_length = int(accuracy / 2)
        bar = "█" * bar_length
        print(f"  {emoji} {label:12s}: {correct:3d}/{total:3d} ({accuracy:6.2f}%) {bar}")
    
    overall_accuracy = (total_correct / total_images) * 100 if total_images > 0 else 0
    
    print("-"*70)
    print(f"  🎯 전체 정확도: {total_correct}/{total_images} ({overall_accuracy:.2f}%)")
    print("="*70)


def save_results_to_json(results, output_path):
    """결과를 JSON 파일로 저장"""
    try:
        output_data = {
            'timestamp': datetime.now().isoformat(),
            'total_images': len(results),
            'results': results
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✓ 결과 저장: {output_path}")
    except Exception as e:
        print(f"❌ 결과 저장 실패: {e}")


def save_all_results_to_json(all_results, output_path):
    """모든 클래스 결과를 JSON 파일로 저장"""
    try:
        stats = {}
        total_images = 0
        total_correct = 0
        
        for label, results in all_results.items():
            correct = sum(1 for r in results if r['label'] == label)
            total = len(results)
            accuracy = (correct / total) * 100 if total > 0 else 0
            
            total_images += total
            total_correct += correct
            
            stats[label] = {
                'total': total,
                'correct': correct,
                'accuracy': accuracy
            }
        
        overall_accuracy = (total_correct / total_images) * 100 if total_images > 0 else 0
        
        output_data = {
            'timestamp': datetime.now().isoformat(),
            'overall_accuracy': overall_accuracy,
            'total_images': total_images,
            'total_correct': total_correct,
            'class_stats': stats,
            'detailed_results': all_results
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✓ 전체 결과 저장: {output_path}")
    except Exception as e:
        print(f"❌ 결과 저장 실패: {e}")


def main():
    """메인 함수"""
    parser = argparse.ArgumentParser(
        description='교통수단 분류기 (Airplanes, Cars, Ships)',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('-m', '--model', required=True,
                       help='TFLite 모델 파일 경로')
    parser.add_argument('-l', '--labels', required=True,
                       help='라벨 파일 경로')
    parser.add_argument('-i', '--image',
                       help='테스트할 단일 이미지')
    parser.add_argument('-d', '--directory',
                       help='테스트할 이미지 디렉토리')
    parser.add_argument('-s', '--subdirs',
                       help='클래스별 하위 디렉토리 테스트')
    parser.add_argument('-o', '--output',
                       help='결과 저장 파일 (JSON)')
    parser.add_argument('--no-details', action='store_true',
                       help='상세 정보 숨기기')
    
    args = parser.parse_args()
    
    try:
        # 모델 로드
        classifier = VehicleClassifier(args.model, args.labels, verbose=True)
        
        # 테스트 실행
        if args.image:
            test_single_image(classifier, args.image, show_all=not args.no_details)
        elif args.subdirs:
            test_subdirectories(classifier, args.subdirs, args.output)
        elif args.directory:
            test_directory(classifier, args.directory, args.output)
        else:
            print("❌ 오류: -i, -d, 또는 -s 중 하나를 지정해야 합니다.")
            parser.print_help()
            sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()