# 위치 추적 최적화 기능

## 개요
`LocationTrackingService`에 사용자가 정적 상태일 때 GPS 체크를 최적화하는 기능을 추가했습니다. 이는 배터리 수명을 연장하고 불필요한 네트워크 트래픽을 줄이는 데 도움이 됩니다.

## 주요 기능

### 1. 정적 상태 감지
- **거리 임계값**: 50미터 미만 이동 시 정적 상태로 판단
- **연속 체크 횟수**: 3번 연속 정적 상태일 때 최적화 모드로 전환
- **하버사인 공식**: 정확한 거리 계산을 위해 지구의 곡률을 고려한 계산 방식 사용

### 2. 적응형 추적 간격
- **정상 간격**: 1분마다 위치 체크 (움직임이 있을 때)
- **정적 간격**: 5분마다 위치 체크 (정적 상태일 때)
- **동적 조정**: 움직임 감지 시 즉시 정상 간격으로 복구

### 3. 배터리 최적화
- 정적 상태에서는 GPS 체크 빈도 80% 감소
- 불필요한 위치 기록 방지
- 움직임 감지 시 즉시 정상 모드로 복구

## 구현 세부사항

### 핵심 상수들
```dart
static const double _stationaryThresholdMeters = 50.0;  // 정적 상태 판단 임계값
static const int _stationaryCheckCount = 3;             // 정적 상태 확인 횟수
static const Duration _normalInterval = Duration(minutes: 1);     // 정상 추적 간격
static const Duration _stationaryInterval = Duration(minutes: 5); // 정적 상태 추적 간격
```

### 새로운 메서드들

#### `_checkLocationChange(double latitude, double longitude) -> bool`
- 현재 위치와 이전 위치 비교
- 정적 상태 감지 및 카운터 관리
- 위치 기록 여부 결정

#### `_calculateDistance(double lat1, double lon1, double lat2, double lon2) -> double`
- 하버사인 공식을 사용한 정확한 거리 계산
- 지구의 곡률을 고려하여 미터 단위로 반환

#### `_adjustTrackingInterval(String userId)`
- 현재 상태에 따른 추적 간격 동적 조정
- 정적/움직임 상태 전환 시 타이머 재시작

#### `_resetLocationOptimization()`
- 최적화 관련 상태 변수들 초기화
- 추적 시작/중지 시 호출

### 새로운 Getter 메서드들

#### `bool get isStationary`
- 현재 정적 상태 여부 확인

#### `int get currentTrackingIntervalMinutes`
- 현재 추적 간격(분 단위) 확인

## 사용 방법

### 기본 사용법
```dart
final trackingService = LocationTrackingService.instance;
trackingService.initialize();

// 위치 추적 시작 (최적화 자동 적용)
await trackingService.startTracking('user123');

// 상태 확인
print('추적 중: ${trackingService.isTracking}');
print('정적 상태: ${trackingService.isStationary}');
print('현재 간격: ${trackingService.currentTrackingIntervalMinutes}분');

// 위치 추적 중지
trackingService.stopTracking();
```

### 상태 모니터링
```dart
// 정적 상태 감지 시 UI 업데이트
if (trackingService.isStationary) {
    print('사용자가 정적 상태입니다. 배터리 절약 모드 활성화.');
} else {
    print('사용자가 움직이고 있습니다. 정상 추적 모드.');
}
```

## 동작 시나리오

### 1. 정상 → 정적 상태 전환
1. 사용자가 50미터 미만으로 3번 연속 이동
2. 시스템이 정적 상태로 판단
3. 추적 간격이 1분에서 5분으로 변경
4. 콘솔에 "정적 상태 감지됨" 메시지 출력

### 2. 정적 → 정상 상태 전환
1. 사용자가 50미터 이상 이동
2. 시스템이 움직임 감지
3. 추적 간격이 5분에서 1분으로 즉시 변경
4. 콘솔에 "움직임 감지됨" 메시지 출력

### 3. 정적 상태에서의 주기적 기록
- 정적 상태에서도 5분마다 위치 확인
- 실제 움직임이 있을 경우에만 DB에 기록
- 완전히 추적을 중단하지 않아 급작스러운 움직임도 감지 가능

## 성능 향상 효과

### 배터리 수명
- 정적 상태 시 GPS 사용량 80% 감소
- 불필요한 위치 서비스 호출 최소화

### 네트워크 트래픽
- 중복된 위치 데이터 전송 방지
- 서버 동기화 부하 감소

### 데이터베이스 효율성
- 의미 있는 위치 변화만 저장
- 스토리지 사용량 최적화

## 향후 개선 가능사항

1. **사용자 설정 가능한 임계값**: 사용자가 민감도를 조정할 수 있도록
2. **학습 알고리즘**: 사용자의 이동 패턴을 학습하여 더 정확한 예측
3. **배터리 상태 연동**: 배터리 잔량에 따른 동적 최적화
4. **시간대별 최적화**: 수면 시간 등을 고려한 추가 최적화

## 테스트 방법

### 단위 테스트
```dart
void testLocationOptimization() {
  final service = LocationTrackingService.instance;
  
  // 정적 상태 테스트
  assert(!service.isStationary);
  
  // 거리 계산 테스트
  final distance = service._calculateDistance(37.5665, 126.9780, 37.5665, 126.9780);
  assert(distance == 0.0);
}
```

### 통합 테스트
1. 앱 실행 후 위치 추적 시작
2. 정적 상태에서 5분간 대기
3. 콘솔 로그에서 "정적 상태 감지됨" 확인
4. 50미터 이상 이동
5. 콘솔 로그에서 "움직임 감지됨" 확인
