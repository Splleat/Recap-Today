import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recap_today/dao/app_usage_dao.dart';
import 'package:recap_today/model/appusage/app_usage_model.dart';
import 'package:recap_today/model/appusage/app_usage_summary_model.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUsageService {
  final AppUsageDao _dao;
  static const MethodChannel _channel = MethodChannel('app_usage_channel');

  AppUsageService(this._dao);

  static String formatUsageTime(int millis) {
    final duration = Duration(milliseconds: millis);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  Future<bool> hasUsageStatsPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('hasUsageStatsPermission');
    } catch (_) {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  /// 앱 사용 통계 API로 요청하고 DB에 저장 후 요약 반환
  Future<AppUsageSummary?> fetchAndSaveAppUsageForDate(
      String userId, DateTime date) async {
    if (!Platform.isAndroid || !await hasUsageStatsPermission()) return null;

    final nextDay = date.add(const Duration(days: 1));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      final result = await _channel.invokeMethod('getAppUsage', {
        'startTime': date.millisecondsSinceEpoch,
        'endTime': nextDay.millisecondsSinceEpoch,
      });

      if (result == null) return null;

      final List<AppUsageModel> appList = (result as List).map((e) {
        return AppUsageModel(
          id: UniqueKey().toString(),
          userId: userId,
          date: dateStr,
          packageName: e['packageName'],
          appName: e['appName'],
          usageTimeInMillis: e['usageTime'],
        );
      }).where((a) => a.usageTimeInMillis >= 60000).toList();

      if (appList.isEmpty) return null;

      await _dao.replaceAppUsagesForDate(userId, dateStr, appList);

      appList.sort((a, b) => b.usageTimeInMillis.compareTo(a.usageTimeInMillis));

      return AppUsageSummary(
        date: dateStr,
        totalUsageTimeInMillis:
            appList.fold(0, (sum, a) => sum + a.usageTimeInMillis),
        topApps: appList.take(3).toList(),
      );
    } catch (e) {
      debugPrint('앱 사용 통계 오류: $e');
      return null;
    }
  }

  /// DB에서 해당 날짜의 요약 정보 불러오기 (캐시)
  Future<AppUsageSummary?> getAppUsageSummaryForDate(
      String userId, String date) async {
    final list = await _dao.getAllAppUsages();
    final filtered =
        list.where((u) => u.date == date && u.userId == userId).toList();

    if (filtered.isEmpty) return null;

    filtered.sort((a, b) => b.usageTimeInMillis.compareTo(a.usageTimeInMillis));
    return AppUsageSummary(
      date: date,
      totalUsageTimeInMillis:
          filtered.fold(0, (sum, a) => sum + a.usageTimeInMillis),
      topApps: filtered.take(3).toList(),
    );
  }

  /// 특정 사용자와 날짜의 앱 사용 기록 조회
  Future<List<AppUsageModel>> getAppUsageRecordsForUserAndDate(String userId, String date) async {
    try {
      final records = await _dao.getAllAppUsages();
      return records.where((record) => record.userId == userId && record.date == date).toList();
    } catch (e) {
      debugPrint('앱 사용 기록 조회 오류: $e');
      return [];
    }
  }
}
