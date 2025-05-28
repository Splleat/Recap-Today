// 기본 Flutter 위젯 테스트
//
// 위젯과의 상호작용을 테스트하려면 flutter_test 패키지의 WidgetTester를 사용하세요.
// 예를 들어, 탭 및 스크롤 제스처를 보낼 수 있습니다. 또한 WidgetTester를 사용하여
// 위젯 트리에서 자식 위젯을 찾고, 텍스트를 읽고, 위젯 속성 값이 올바른지 확인할 수 있습니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recap_today/main.dart';

void main() {
  testWidgets('앱 초기화 및 기본 화면 로드 테스트', (WidgetTester tester) async {
    // 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(const RecapToday());

    // 홈 화면이 로드되었는지 확인합니다.
    expect(find.text('오늘 하루'), findsOneWidget);

    // 네비게이션 바가 있는지 확인합니다.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('네비게이션 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const RecapToday());

    // 캘린더 탭을 탭합니다.
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pump();

    // 요약 탭을 탭합니다.
    await tester.tap(find.byIcon(Icons.analytics));
    await tester.pump();

    // 설정 탭을 탭합니다.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
  });
}
