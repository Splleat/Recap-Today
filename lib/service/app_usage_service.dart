import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:permission_handler/permission_handler.dart';

/// 직접 구현한 앱 사용 통계 서비스
/// 안드로이드 기기에서만 작동
class AppUsageService {
  final AbstractDatabase _database;
  static const String _dateFormat = 'yyyy-MM-dd';
  static const MethodChannel _channel = MethodChannel('app_usage_channel');

  AppUsageService(this._database);

  /// 앱 사용 통계 권한 확인
  Future<bool> hasUsageStatsPermission() async {
    // 안드로이드에서만 작동
    if (!Platform.isAndroid) return false;

    // 사용 통계 접근 권한 확인
    try {
      // MethodChannel을 통해 네이티브 코드의 권한 확인 메서드 호출
      final bool hasPermission = await _channel.invokeMethod(
        'hasUsageStatsPermission',
      );
      return hasPermission;
    } catch (e) {
      debugPrint('앱 사용 통계 권한 확인 중 오류: $e');
      return false;
    }
  }

  /// 사용 통계 권한 요청을 위한 설정 화면 오픈
  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      debugPrint('설정 화면 열기 실패: $e');
      // 대체 방법으로 일반 설정 화면 열기
      await openAppSettings();
    }
  }

  /// 오늘의 앱 사용 통계 가져오기
  Future<AppUsageSummary?> getTodayAppUsage() async {
    // 안드로이드에서만 작동
    if (!Platform.isAndroid) return null;

    // 사용 통계 권한 확인
    if (!await hasUsageStatsPermission()) {
      return null;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // 오늘 0시 0분 0초
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1,
      ); // 내일 0시 0분 0초
      final dateStr = DateFormat(_dateFormat).format(today);

      // 기존 데이터 삭제
      await _database.deleteAppUsagesByDate(dateStr);

      // 네이티브 코드로 앱 사용 통계 조회
      final result = await _channel.invokeMethod('getAppUsage', {
        'startTime': today.millisecondsSinceEpoch, // 오늘 0시
        'endTime': tomorrow.millisecondsSinceEpoch, // 내일 0시 (오늘 하루 전체를 의미)
      });

      if (result == null) {
        return null;
      }

      // 데이터 파싱
      final List<dynamic> usageData = result;
      final appUsageList = <AppUsageModel>[];
      int totalUsageTime = 0;

      for (var data in usageData) {
        try {
          final packageName = data['packageName'] as String;
          final appName = data['appName'] as String;
          final usageTimeInMillis = data['usageTime'] as int;

          // 1분 미만 사용은 제외 (노이즈 데이터 제거)
          if (usageTimeInMillis >= 60000) {
            totalUsageTime += usageTimeInMillis;

            appUsageList.add(
              AppUsageModel(
                date: dateStr,
                packageName: packageName,
                appName: appName,
                usageTimeInMillis: usageTimeInMillis,
              ),
            );
          }
        } catch (e) {
          debugPrint('앱 사용 데이터 파싱 중 오류: $e');
        }
      }

      // 사용 시간 순으로 정렬
      appUsageList.sort(
        (a, b) => b.usageTimeInMillis.compareTo(a.usageTimeInMillis),
      );

      // 상위 3개 앱만 저장 (또는 설정된 개수만큼)
      final topApps = appUsageList.take(3).toList();

      // 데이터베이스에 저장
      if (topApps.isNotEmpty) {
        await _database.insertAppUsages(topApps);
      }

      return AppUsageSummary(
        date: dateStr,
        totalUsageTimeInMillis: totalUsageTime,
        topApps: topApps,
      );
    } catch (e) {
      debugPrint('오늘의 앱 사용 통계 가져오기 실패: $e');
      return null;
    }
  }

  /// 특정 날짜의 앱 사용 요약 정보 가져오기
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date) async {
    try {
      return await _database.getAppUsageSummaryForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 앱 사용 요약 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// 사용 시간을 보기 좋은 문자열로 변환 (예: 1h 30m)
  static String formatUsageTime(int milliseconds) {
    if (milliseconds < 0) return 'N/A';
    if (milliseconds == 0) return '0m';

    int seconds = (milliseconds / 1000).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    minutes %= 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '< 1m'; // 1분 미만 사용 시간
    }
  }
}
