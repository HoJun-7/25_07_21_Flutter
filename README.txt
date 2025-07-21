# 한번에 명령어 3개 다 치는법
flutter clean; flutter pub get; flutter run

# 돌릴수 있는 기기목록 확인
flutter devices

# run 어떤걸로 할지 미리 고정
flutter run -d 기기이름

# flutter run 할때 세부 log 볼수있음
flutter run -d 기기이름 --verbose

# 실행전 변경
example/lib/main.dart 16번째 줄
const String globalBaseUrl = "http://127.0.0.1:5000/api";
http://127.0.0.1:5000 이부분 백엔드에 맞게 바꾸기

# 모델 없다고 나올때
https://drive.google.com/file/d/17YLl0OEjSUmHuzjPny9U_tE8EXJBmqZ6/view?usp=sharing
여기서 바로 다운로드후
example/assets/models에 옮기기

# 실행
cd example
flutter clean; flutter pub get; flutter run