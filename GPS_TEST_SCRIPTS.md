# 에뮬레이터 GPS 빠른 테스트 스크립트

## PowerShell 스크립트 (Windows용)

### 1. 단일 위치 설정
```powershell
# GPS 위치를 서울역으로 설정
adb emu geo fix 126.9707 37.5547

# GPS 위치를 강남역으로 설정  
adb emu geo fix 127.0276 37.4979

# GPS 위치를 여의도로 설정
adb emu geo fix 126.9244 37.5194
```

### 2. 이동 경로 시뮬레이션 스크립트
```powershell
# 서울 시내 이동 시뮬레이션 (seoul_route.ps1)
$locations = @(
    @{lat=37.5665; lng=126.9780; name="명동"},
    @{lat=37.5547; lng=126.9707; name="서울역"}, 
    @{lat=37.5194; lng=126.9244; name="여의도"},
    @{lat=37.4979; lng=127.0276; name="강남역"},
    @{lat=37.5172; lng=127.0473; name="삼성역"},
    @{lat=37.5663; lng=126.9779; name="명동(복귀)"}
)

foreach ($location in $locations) {
    Write-Host "이동: $($location.name) ($($location.lat), $($location.lng))"
    adb emu geo fix $($location.lng) $($location.lat)
    Start-Sleep -Seconds 30  # 30초 대기
}
```

### 3. 정적 상태 테스트 스크립트
```powershell
# 정적 상태 테스트 (stationary_test.ps1)
Write-Host "정적 상태 테스트 시작 - 명동에서 5분간 대기"
for ($i = 1; $i -le 5; $i++) {
    Write-Host "정적 상태 $i/5"
    adb emu geo fix 126.9780 37.5665
    Start-Sleep -Seconds 60  # 1분 대기
}

Write-Host "움직임 시뮬레이션 - 강남역으로 이동"
adb emu geo fix 127.0276 37.4979
```

## 유용한 GPS 좌표들 (서울 기준)

### 🏢 주요 지역
```powershell
# 명동
adb emu geo fix 126.9780 37.5665

# 강남역
adb emu geo fix 127.0276 37.4979

# 홍대입구
adb emu geo fix 126.9224 37.5563

# 잠실
adb emu geo fix 127.1000 37.5133

# 여의도
adb emu geo fix 126.9244 37.5194
```

### 🏫 대학교
```powershell
# 서울대학교
adb emu geo fix 126.9574 37.4601

# 연세대학교
adb emu geo fix 126.9356 37.5665

# 고려대학교  
adb emu geo fix 127.0258 37.5894
```

### 🏛️ 관광지
```powershell
# 경복궁
adb emu geo fix 126.9769 37.5788

# 남산타워
adb emu geo fix 126.9883 37.5512

# 한강공원(반포)
adb emu geo fix 126.9956 37.5185
```

## Extended Controls 사용법

### 1. 에뮬레이터에서 Extended Controls 열기
- 에뮬레이터 사이드바의 `...` (더보기) 버튼 클릭
- 또는 `Ctrl + Shift + P` 단축키 사용

### 2. Location 탭에서 위치 설정
1. **Single Points**: 개별 위치 설정
   - Latitude (위도): 37.5665
   - Longitude (경도): 126.9780
   - `SEND` 버튼 클릭

2. **Routes**: 경로 시뮬레이션
   - `LOAD GPX/KML` 버튼으로 경로 파일 로드
   - `PLAY ROUTE` 버튼으로 자동 경로 재생

### 3. GPX 파일 예시
```xml
<?xml version="1.0"?>
<gpx version="1.1" creator="GPS Test">
  <trk>
    <name>Seoul Test Route</name>
    <trkseg>
      <trkpt lat="37.5665" lon="126.9780">
        <time>2024-01-01T09:00:00Z</time>
        <name>명동</name>
      </trkpt>
      <trkpt lat="37.5547" lon="126.9707">
        <time>2024-01-01T09:10:00Z</time>
        <name>서울역</name>
      </trkpt>
      <trkpt lat="37.4979" lon="127.0276">
        <time>2024-01-01T09:20:00Z</time>
        <name>강남역</name>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
```

## 실시간 모니터링

### Flutter 로그 확인
```bash
# 모든 로그 확인
flutter logs

# GPS 관련 로그만 필터링
flutter logs | findstr "위치"
flutter logs | findstr "GPS"

# 실시간 위치 추적 로그
flutter logs | findstr "로컬 저장됨"
```

### 예상 로그 패턴
```
GPS 서비스가 활성화되었습니다.
위치 추적이 시작되었습니다.
위치 로그 로컬 저장됨: 37.5665, 126.9780 (간격: 1분, 정확도: 5.0m)
정적 상태 감지됨. 추적 간격을 5분으로 변경합니다.
움직임 감지됨. 추적 간격을 1분으로 복구합니다.
```

## 테스트 시나리오

### 📍 시나리오 1: 기본 GPS 기능 테스트
1. GPS 테스트 화면 접속
2. "GPS 상태 확인" 버튼 클릭
3. "권한 요청" 버튼 클릭 (필요시)
4. "현재 위치 가져오기" 버튼 클릭
5. 에뮬레이터에서 위치 설정 후 다시 시도

### 🚶 시나리오 2: 위치 추적 테스트
1. "위치 추적 시작" 버튼 클릭
2. Extended Controls에서 위치 변경
3. 1분 후 로그에서 위치 저장 확인
4. 다른 위치로 이동 시뮬레이션
5. 지도에서 동선 확인

### ⏸️ 시나리오 3: 정적 상태 최적화 테스트
1. 위치 추적 시작
2. 동일한 위치에서 3분간 대기
3. "정적 상태 감지됨" 로그 확인
4. 50미터 이상 떨어진 위치로 이동
5. "움직임 감지됨" 로그 확인

### 🗺️ 시나리오 4: 지도 동선 확인
1. 여러 위치로 이동 시뮬레이션
2. 요약 화면 > 하루 동선 위젯 확인
3. 폴리라인이 올바르게 표시되는지 확인
4. 지도 자동 범위 조정 확인

## 문제 해결

### GPS 권한 문제
```
설정 > 앱 > Recap Today > 권한 > 위치 > 허용
```

### GPS 서비스 비활성화
```
설정 > 위치 > GPS 위성 > 켜기
```

### 에뮬레이터 GPS 없음
1. Extended Controls > Location
2. 수동으로 위치 설정
3. Google Maps에서 위치 확인

이제 완전한 GPS 테스트 환경이 구축되었습니다! 🚀
