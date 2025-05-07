import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:recap_today/provider/checklist_provider.dart';

/// 날짜 변경을 감지하고 체크리스트 아이템 관리를 처리하는 서비스
class DateChangeService {
  static const String _lastCheckedDateKey = 'last_checked_date';
  static DateTime? _lastCheck;

  /// 날짜 변경을 확인하고 필요한 작업 수행
  static Future<bool> checkForDateChange(ChecklistProvider provider) async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      // 마지막 체크 시간 확인 (메모리 캐시)
      if (_lastCheck != null) {
        final lastDate = DateFormat('yyyy-MM-dd').format(_lastCheck!);
        if (lastDate == today) {
          // 오늘 이미 체크했으면 처리 건너뛰기
          return false;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final String? lastCheckedDate = prefs.getString(_lastCheckedDateKey);

      // 마지막 체크 날짜가 없거나 오늘과 다른 경우
      if (lastCheckedDate == null || lastCheckedDate != today) {
        // 날짜가 변경되었을 때 수행할 작업
        if (lastCheckedDate != null) {
          // 이전에 체크된 적이 있고, 날짜가 변경된 경우에만 처리
          debugPrint('날짜 변경 감지: $lastCheckedDate → $today');
          await provider.clearCompletedItems();
        }

        // 마지막 체크 날짜 업데이트
        await prefs.setString(_lastCheckedDateKey, today);
        _lastCheck = now;
        return true; // 날짜 변경됨
      }

      _lastCheck = now;
      return false; // 날짜 변경 없음
    } catch (e) {
      debugPrint('날짜 변경 확인 중 오류 발생: $e');
      return false; // 오류 발생 시 날짜 변경 없음으로 처리
    }
  }

  /// 특정 날짜의 시작 시간(00:00:00) 가져오기
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 특정 날짜의 종료 시간(23:59:59.999) 가져오기
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// 오늘의 날짜 문자열 가져오기 (yyyy-MM-dd 형식)
  static String getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
