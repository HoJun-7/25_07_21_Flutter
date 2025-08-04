# test.py

import requests
import threading
import time
import json
from pathlib import Path

# 설정
URL = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api/upload_masked_image"
JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc1Mzk1MjEzOCwianRpIjoiNDdlZDIxOTgtNzk0ZC00YzEwLTg0NzktOTlhMWE3N2NjYWE5IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjE1MTUxNSIsIm5iZiI6MTc1Mzk1MjEzOCwiY3NyZiI6ImVjMjQxZDI3LTc5OGUtNDUzYS05ZTFlLWJiMDAwOTQ4MjgwMCIsImV4cCI6MTc1Mzk1NTczOCwicm9sZSI6IlAifQ.WHQEEP9RX8v8sM9oI5PKSjohu6LoRnMs6t7cNGzyfyQ"  # ⚠️ 반드시 실제 JWT로 바꿔야 합니다, 이부분
IMAGE_PATH = r"C:\Users\302-1\1.jpg"          # ⚠️ 실제 존재하는 이미지 파일로 바꿔야 합니다, 이부분
YOLO_JSON = {
}
SURVEY_JSON = {
    "최근 1주일간 치아 통증을 느낀 적이 있다.": 3,
    "음식을 씹을 때 불편하거나 아픈 부분이 있다.": 3,
    "찬물 또는 뜨거운 음식을 먹을 때 이가 시리다.": 3,
    "잇몸이 붓거나 피가 난 적이 있다.": 3,
    "하루 2회 이상 양치질을 한다.": 3,
    "정기적으로 치실이나 구강 세정제를 사용한다.": 3,
    "양치 후에도 입안이 개운하지 않다고 느낀다.": 3,
    "구취(입 냄새)를 자주 느낀다.": 3,
    "최근 6개월 이내 치과 치료를 받은 적이 있다.": 3,
    "충치나 잇몸질환 진단을 받은 적이 있다.": 3,
    "스케일링이나 기타 정기검진을 받은 적이 있다.": 3,
    "과거 치아 외상 또는 수술 경험이 있다.": 3,
    "자주 단 음식을 섭취한다.": 3,
    "탄산음료나 커피를 자주 마신다.": 3,
    "흡연을 하거나 했던 경험이 있다.": 3,
    "스트레스를 많이 받는 편이다.": 3,
    "정기적인 치과 검진이 필요하다고 생각한다.": 3,
    "치료 비용이 부담되어 진료를 미룬 적이 있다.": 3,
    "구강 건강은 전신 건강과 밀접한 관련이 있다고 생각한다.": 3,
    "필요시 비대면 진료나 AI 기반 진단도 고려할 수 있다.": 3
}

NUM_REQUESTS = 300 # 이부분
CONCURRENCY = 10  # 동시에 몇 개의 쓰레드를 실행할지, 이부분

def upload_image(i):
    try:
        with open(IMAGE_PATH, 'rb') as img_file:
            response = requests.post(
                URL,
                headers={"Authorization": f"Bearer {JWT_TOKEN}"},
                files={"file": img_file},
                data={
                    "image_type": "normal",
                    "yolo_results_json": json.dumps([YOLO_JSON]),
                    "survey": json.dumps(SURVEY_JSON),
                },
                timeout=10
            )
        print(f"[{i}] ✅ Status: {response.status_code}")
    except Exception as e:
        print(f"[{i}] ❌ Error: {e}")

def run_test():
    threads = []
    start_time = time.time()

    for i in range(NUM_REQUESTS):
        thread = threading.Thread(target=upload_image, args=(i,))
        threads.append(thread)
        thread.start()

        # Optional: 제한된 수의 동시 요청 유지
        if i % CONCURRENCY == 0:
            for t in threads:
                t.join()
            threads = []

    # 남은 쓰레드 정리
    for t in threads:
        t.join()

    end_time = time.time()
    print(f"🚀 총 소요 시간: {end_time - start_time:.2f}초")

if __name__ == "__main__":
    if not Path(IMAGE_PATH).exists():
        print(f"❌ 이미지 파일 '{IMAGE_PATH}'이 존재하지 않습니다. 테스트 중단.")
    else:
        run_test()