# 백그라운드 위치 추적 설정 가이드

## 개요
Recap Today 앱에 백그라운드 위치 추적 기능이 통합되었습니다. `LocationTrackingService`에서 포어그라운드와 백그라운드 위치 추적을 모두 관리하여 더욱 효율적인 위치 수집이 가능합니다.

## 기술적 개선사항

### 통합된 서비스 아키텍처
- 기존의 `BackgroundLocationService`와 `LocationTrackingService`를 하나로 통합
- 중복 코드 제거 및 메모리 효율성 개선
- 일관된 위치 데이터 처리 로직

### 주요 기능
- **포어그라운드 추적**: 앱 사용 중 스마트 위치 수집 (정적 상태 감지)
- **백그라운드 추적**: 앱이 백그라운드에서도 2분마다 위치 수집
- **통합 스트림**: 포어그라운드/백그라운드 위치 이벤트를 하나의 스트림으로 처리

## 필요한 설정

### 1. 앱 권한 설정
앱을 설치한 후 다음 권한들을 허용해야 합니다:

#### 기본 위치 권한
- 설정 > 앱 > Recap Today > 권한 > 위치
- "앱 사용 중에만 허용" 또는 "항상 허용" 선택

#### 백그라운드 위치 권한 (Android 10+)
- 설정 > 앱 > Recap Today > 권한 > 위치
- "항상 허용" 선택 (백그라운드 추적을 위해 필수)

### 2. 배터리 최적화 해제 (권장)
정확한 백그라운드 위치 추적을 위해 배터리 최적화를 해제하는 것을 권장합니다:
- 설정 > 배터리 > 배터리 최적화
- Recap Today 앱 찾기
- "최적화하지 않음" 선택

### 3. 백그라운드 앱 새로고침 허용
- 설정 > 앱 > Recap Today > 배터리
- "백그라운드 활동" 허용

## 사용 방법

### 백그라운드 추적 시작
1. 앱의 "하루 동선" 섹션으로 이동
2. GPS 아이콘 버튼 클릭 (회색에서 녹색으로 변함)
3. 필요한 권한이 없으면 자동으로 권한 요청 다이얼로그가 표시됩니다

### 백그라운드 추적 중지
1. "하루 동선" 섹션의 녹색 GPS 아이콘 클릭
2. 아이콘이 회색으로 변하면서 추적이 중지됩니다

## 기술적 세부사항

### 통합된 LocationTrackingService
- **단일 서비스**: 포어그라운드/백그라운드 추적을 하나의 서비스에서 관리
- **스마트 추적**: 정적 상태 감지로 배터리 최적화
- **이벤트 스트림**: 위치 저장 이벤트를 실시간으로 UI에 전달

### 추적 모드
1. **포어그라운드 모드**
   - 1분 간격으로 위치 수집
   - 정적 상태 감지 시 5분 간격으로 변경
   - 10미터 이상 이동 시에만 저장

2. **백그라운드 모드**
   - 2분 간격으로 위치 수집
   - 포어그라운드 서비스로 안정적 동작
   - 배터리 최적화 고려한 적절한 간격

### 추가된 패키지
- `flutter_background_service: ^5.0.5` - 백그라운드 서비스 실행
- `workmanager: ^0.5.2` - 작업 관리 (필요시)
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### 위치 수집 주기
- **포어그라운드**: 1분 간격 (정적 상태 시 5분)
- **백그라운드**: 2분 간격 고정
- **포어그라운드 알림**으로 사용자에게 추적 상태 표시

### API 메서드
```dart
// 백그라운드 추적 시작
await LocationTrackingService.instance.startBackgroundTracking(userId);

// 백그라운드 추적 중지
await LocationTrackingService.instance.stopBackgroundTracking();

// 추적 상태 확인
bool isActive = await LocationTrackingService.instance.isBackgroundTrackingActive();
```

## 주의사항

1. **배터리 소모**: 백그라운드 위치 추적은 배터리를 더 많이 소모합니다.
2. **정확도**: 실내에서는 GPS 신호가 약해 정확도가 떨어질 수 있습니다.
3. **권한**: Android 버전에 따라 권한 설정 방법이 다를 수 있습니다.
4. **데이터 사용량**: 위치 데이터 수집으로 인한 미미한 데이터 사용량이 있을 수 있습니다.

## 문제 해결

### 백그라운드 추적이 작동하지 않는 경우
1. 모든 필요한 권한이 허용되었는지 확인
2. 배터리 최적화가 해제되었는지 확인
3. 앱을 완전히 종료 후 재시작
4. 디바이스 재부팅

### 위치 정확도가 낮은 경우
1. GPS가 켜져 있는지 확인
2. 실외에서 테스트
3. 고정밀 위치 모드 사용 (설정 > 위치 > 위치 모드)
