# 카카오맵 설정 가이드

## ⚠️ 중요: API 키 종류에 대한 안내

**`kakao_map_plugin`은 JavaScript 키를 사용합니다. Android 네이티브 키가 아닙니다!**

## 1. 카카오 API 키 발급
1. [카카오 디벨로퍼스](https://developers.kakao.com/) 에 접속
2. 애플리케이션 추가하기 클릭
3. 앱 이름과 회사명 입력
4. **"앱 키" 탭에서 "JavaScript 키" 복사** (네이티브 앱 키가 아님!)

## 2. API 키 설정

### ✅ 필요한 설정 (1곳만)
`lib/main.dart` 파일에서:
```dart
kakao_map.AuthRepository.initialize(appKey: 'YOUR_KAKAO_API_KEY');
```
`YOUR_KAKAO_API_KEY` 부분을 실제 발급받은 **JavaScript 키**로 변경

### ❌ 불필요한 설정 (제거됨)
~~`AndroidManifest.xml`의 meta-data는 제거되었습니다.~~ 
이 플러그인에서는 필요하지 않습니다.

## 3. 플랫폼 설정 (선택사항)
보안 강화를 위해 카카오 콘솔에서:
1. 플랫폼 설정에서 Android 추가
2. 패키지명 입력: `com.example.recap_today`
3. 키 해시는 나중에 필요할 때 등록

## 4. 보안 관련 FAQ

### Q: JavaScript 키가 노출되어도 괜찮나요?
**A: 네, 괜찮습니다.** 
- JavaScript 키는 클라이언트에서 사용하도록 설계됨
- 카카오에서 패키지명과 키 해시로 접근 제한 가능
- 무료 사용량 제한으로 남용 방지

### Q: 두 곳에 같은 키를 써야 하나요?
**A: 아니요, 한 곳만 사용합니다.**
- AndroidManifest.xml ❌ (제거됨)
- main.dart의 AuthRepository.initialize() ✅ (JavaScript 키 사용)

## 5. 권한 설정
이미 설정되어 있습니다:
- `android.permission.INTERNET`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`

## 6. 확인사항
- 카카오맵 플러그인 버전: ^0.3.7
- 패키지 설치 완료: `flutter pub get`
- **JavaScript 키**가 올바르게 설정되면 오버레이가 제거되고 실제 지도가 표시됩니다.

## 7. 추가 기능
현재는 기본 지도만 표시됩니다. 추후 다음 기능들을 추가할 수 있습니다:
- 현재 위치 표시
- 마커 추가
- 장소 검색
- 경로 표시
