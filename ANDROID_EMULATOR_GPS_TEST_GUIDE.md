# 안드로이드 에뮬레이터에서 GPS 테스트 가이드

## 개요
실제 GPS가 연동된 LocationTrackingService를 안드로이드 에뮬레이터에서 테스트하는 방법을 설명합니다.

## 구현된 실제 GPS 기능

### 🚀 새로운 기능들
1. **실제 GPS 위치 가져오기**: `Geolocator.getCurrentPosition()` 사용
2. **GPS 서비스 상태 확인**: 위치 서비스 활성화 여부 체크
3. **고급 권한 관리**: `LocationPermission` 세분화된 권한 처리
4. **위치 정확도 설정**: 고정밀도 GPS, 10미터 거리 필터 적용
5. **에러 핸들링**: GPS 오류 시 더미 데이터로 대체하여 테스트 지속

### 📍 위치 설정
```dart
LocationSettings(
  accuracy: LocationAccuracy.high,     // 고정밀도 GPS
  distanceFilter: 10,                 // 10미터 이상 이동 시 업데이트
)
```

## 안드로이드 에뮬레이터 GPS 테스트 방법

### 방법 1: Extended Controls 사용 (권장)

1. **에뮬레이터 실행**
   ```bash
   flutter emulators --launch <emulator-name>
   ```

2. **Extended Controls 열기**
   - 에뮬레이터 사이드바에서 `...` (More) 버튼 클릭
   - 또는 `Ctrl + Shift + P` (Windows) / `Cmd + Shift + P` (Mac)

3. **Location 탭 선택**
   - 왼쪽 메뉴에서 "Location" 선택

4. **위치 설정**
   - **Single Points**: 개별 위치 설정
     - Latitude: 37.5665 (위도)
     - Longitude: 126.9780 (경도)
     - "SEND" 버튼 클릭
   
   - **Routes**: 경로 시뮬레이션
     - "Load GPX/KML" 버튼으로 경로 파일 로드
     - "Play Route" 버튼으로 이동 시뮬레이션 시작

### 방법 2: ADB 명령어 사용

```bash
# 단일 위치 설정
adb emu geo fix 126.9780 37.5665

# 이동하는 위치 시뮬레이션 (스크립트)
adb emu geo fix 126.9780 37.5665    # 시작점
adb emu geo fix 126.9790 37.5675    # 이동
adb emu geo fix 126.9800 37.5685    # 더 이동
```

### 방법 3: Google Maps를 통한 실시간 테스트

1. **에뮬레이터에서 Google Maps 앱 실행**
2. **원하는 위치 검색** (예: "서울역", "강남역")
3. **위치 클릭하여 GPS 좌표 활성화**
4. **우리 앱에서 위치 추적 시작**

### 방법 4: GPX 파일을 이용한 경로 시뮬레이션

1. **GPX 파일 생성** (샘플)
```xml
<?xml version="1.0"?>
<gpx version="1.1" creator="Test Route">
  <trk>
    <name>Seoul Route</name>
    <trkseg>
      <trkpt lat="37.5665" lon="126.9780">
        <time>2024-01-01T09:00:00Z</time>
      </trkpt>
      <trkpt lat="37.5595" lon="126.9745">
        <time>2024-01-01T09:10:00Z</time>
      </trkpt>
      <trkpt lat="37.5547" lon="126.9706">
        <time>2024-01-01T09:20:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
```

2. **Extended Controls > Location > Load GPX/KML**
3. **Play Route로 자동 경로 재생**

## 테스트 시나리오

### 🧪 기본 GPS 기능 테스트

1. **앱 실행 및 위치 추적 시작**
   ```dart
   final trackingService = LocationTrackingService.instance;
   await trackingService.startTracking('test-user');
   ```

2. **위치 권한 확인**
   - 앱에서 위치 권한 요청 허용
   - 설정 > 앱 > 권한에서 위치 권한 상태 확인

3. **GPS 서비스 확인**
   - 설정 > 위치에서 GPS 활성화 확인

### 🔄 정적 상태 최적화 테스트

1. **정적 상태 만들기**
   - Extended Controls에서 동일한 위치 3번 연속 설정
   - 콘솔에서 "정적 상태 감지됨" 메시지 확인

2. **움직임 테스트**
   - 50미터 이상 떨어진 위치로 변경
   - 콘솔에서 "움직임 감지됨" 메시지 확인

### 📱 실시간 위치 추적 테스트

1. **연속 위치 변경**
   ```bash
   # 스크립트로 연속 실행
   for i in {1..10}; do
     lat=$(echo "37.5665 + $i * 0.001" | bc)
     lng=$(echo "126.9780 + $i * 0.001" | bc)
     adb emu geo fix $lng $lat
     sleep 10
   done
   ```

2. **지도에서 폴리라인 확인**
   - 앱의 LocationInfo 위젯에서 동선 확인
   - 자동 지도 범위 조정 확인

## 디버깅 및 로그 확인

### 콘솔 로그 모니터링
```bash
# Flutter 로그 확인
flutter logs

# 특정 로그 필터링
flutter logs | grep "위치"
```

### 예상 로그 메시지들
```
GPS 서비스가 활성화되었습니다.
위치 추적이 시작되었습니다.
위치 로그 로컬 저장됨: 37.5665, 126.9780 (간격: 1분, 정확도: 5.0m)
정적 상태 감지됨. 추적 간격을 5분으로 변경합니다.
움직임 감지됨. 추적 간격을 1분으로 복구합니다.
```

## 문제 해결

### 🚨 일반적인 문제들

1. **GPS 권한 문제**
   ```
   LocationPermission.denied 또는 deniedForever
   ```
   **해결**: 설정 > 앱 > 권한에서 위치 권한 허용

2. **GPS 서비스 비활성화**
   ```
   위치 서비스가 비활성화되어 있습니다.
   ```
   **해결**: 설정 > 위치에서 GPS 활성화

3. **에뮬레이터에서 위치 없음**
   ```
   GPS 위치 가져오기 실패
   ```
   **해결**: Extended Controls에서 위치 수동 설정

### 🔧 고급 디버깅

1. **위치 정확도 확인**
   ```dart
   Position position = await Geolocator.getCurrentPosition();
   print('정확도: ${position.accuracy}m');
   print('고도: ${position.altitude}m');
   print('속도: ${position.speed}m/s');
   ```

2. **위치 스트림 테스트**
   ```dart
   StreamSubscription<Position> positionStream = 
       Geolocator.getPositionStream().listen((Position position) {
     print('실시간 위치: ${position.latitude}, ${position.longitude}');
   });
   ```

## 성능 최적화

### 배터리 효율성 테스트
1. **에뮬레이터 배터리 시뮬레이션**
   - Extended Controls > Battery > 배터리 수준 조정
   - 낮은 배터리에서 GPS 동작 확인

2. **백그라운드 위치 추적**
   - 앱을 백그라운드로 전환
   - 위치 추적 지속성 확인

### 메모리 사용량 모니터링
```bash
# Flutter Inspector 실행
flutter run --observatory-port=9999
```

## 배포 전 체크리스트

- [ ] GPS 권한 정상 요청됨
- [ ] 위치 서비스 상태 체크 정상
- [ ] 정적 상태 최적화 동작 확인
- [ ] 실시간 위치 추적 정상
- [ ] 지도 폴리라인 표시 정상
- [ ] 자동 지도 범위 조정 정상
- [ ] 오류 시 더미 데이터 대체 정상
- [ ] 배터리 최적화 동작 확인

이제 실제 GPS가 연동된 위치 추적 기능을 에뮬레이터에서 충분히 테스트할 수 있습니다! 🚀
