import '../api/dio_client.dart';
import '../data/sqflite_database.dart';
import 'dart:developer' as developer;

class BackupService {
  static Future<Map<String, dynamic>> backupAllData(String userId) async {
    developer.log('백업 시작 - 사용자 ID: $userId', name: 'BackupService');

    try {
      // 로컬 데이터베이스에서 모든 데이터를 가져옴
      developer.log('로컬 데이터베이스에서 데이터 수집 시작', name: 'BackupService');
      final database = SqfliteDatabase();

      final diaries = await database.getAllDiariesForBackup();
      developer.log('일기 데이터 수집 완료: ${diaries.length}개', name: 'BackupService');

      final checklists = await database.getAllChecklistItemsForBackup();
      developer.log(
        '체크리스트 데이터 수집 완료: ${checklists.length}개',
        name: 'BackupService',
      );

      final schedules = await database.getAllScheduleItemsForBackup();
      developer.log(
        '일정 데이터 수집 완료: ${schedules.length}개',
        name: 'BackupService',
      );

      final appUsages = await database.getAllAppUsageRecords();
      developer.log(
        '앱 사용량 데이터 수집 완료: ${appUsages.length}개',
        name: 'BackupService',
      );

      final emotions = await database.getAllEmotionRecords();
      developer.log(
        '감정 기록 데이터 수집 완료: ${emotions.length}개',
        name: 'BackupService',
      );

      final locations = await database.getAllLocationRecords();
      developer.log(
        '위치 기록 데이터 수집 완료: ${locations.length}개',
        name: 'BackupService',
      );

      final steps = await database.getAllStepRecords();
      developer.log('걸음 수 데이터 수집 완료: ${steps.length}개', name: 'BackupService');
      final aiFeedbacks = await database.getAllAiFeedbackRecords();
      developer.log(
        'AI 피드백 데이터 수집 완료: ${aiFeedbacks.length}개',
        name: 'BackupService',
      );

      // 사진 데이터는 일기 테이블의 photo_paths 필드로 관리되므로 별도 백업 불필요
      developer.log('사진 데이터는 일기의 photo_paths 필드로 백업됨', name: 'BackupService');

      // Transform data keys to match API expectations
      final mappedDiaries =
          diaries
              .map(
                (d) => {
                  'date': d['date'],
                  'title': d['title'] ?? '',
                  'content': d['content'] ?? '',
                  'photoPaths': d['photo_paths'] ?? '',
                  'userId': d['user_id'],
                },
              )
              .toList();

      final mappedChecklists =
          checklists
              .map(
                (c) => {
                  'id': c['id'],
                  'text': c['text'],
                  'subtext': c['subtext'] ?? '',
                  'isChecked': c['is_checked'] == 1,
                  'dueDate': c['due_date'] ?? '',
                  'completedDate': c['completed_date'] ?? '',
                  'userId': c['user_id'],
                },
              )
              .toList();

      final mappedSchedules =
          schedules
              .map(
                (s) => {
                  'id': s['id'],
                  'text': s['text'],
                  'subText': s['sub_text'] ?? '',
                  'dayOfWeek': s['day_of_week'] ?? 0,
                  'selectedDate': s['selected_date'] ?? '',
                  'isRoutine': s['is_routine'] == 1,
                  'startTimeHour': s['start_time_hour'] ?? 0,
                  'startTimeMinute': s['start_time_minute'] ?? 0,
                  'endTimeHour': s['end_time_hour'] ?? 0,
                  'endTimeMinute': s['end_time_minute'] ?? 0,
                  'colorValue': s['color_value'] ?? 0,
                  'hasAlarm': s['has_alarm'] == 1,
                  'alarmOffset': s['alarm_offset_in_minutes'] ?? 0,
                  'userId': s['user_id'],
                },
              )
              .toList();

      final mappedAppUsages =
          appUsages
              .map(
                (u) => {
                  'date': u['date'],
                  'packageName': u['package_name'],
                  'appName': u['app_name'],
                  'usageTime': u['usage_time'],
                  'appIconPath': u['app_icon_path'] ?? '',
                  'userId': u['user_id'],
                },
              )
              .toList();

      final mappedEmotions =
          emotions
              .map(
                (e) => {
                  'id': e['id'],
                  'date': e['date'],
                  'hour': e['hour'],
                  'emotionType': e['emotion_type'],
                  'notes': e['notes'] ?? '',
                  'userId': e['user_id'],
                },
              )
              .toList();

      final mappedLocations =
          locations
              .map(
                (l) => {
                  'id': l['id'],
                  'userId': l['user_id'],
                  'latitude': l['latitude'],
                  'longitude': l['longitude'],
                  'timestamp': l['timestamp'],
                },
              )
              .toList();

      final mappedSteps =
          steps
              .map(
                (s) => {
                  'date': s['date'],
                  'stepCount': s['step_count'],
                  'userId': s['user_id'],
                },
              )
              .toList();

      final mappedAiFeedbacks =
          aiFeedbacks
              .map(
                (f) => {
                  'date': f['date'],
                  'feedbackText': f['feedback_text'],
                  'userId': f['user_id'],
                },
              )
              .toList();
      final backupData = {
        'diaries': mappedDiaries,
        'checklists': mappedChecklists,
        'schedules': mappedSchedules,
        'appUsages': mappedAppUsages,
        'emotions': mappedEmotions,
        'locations': mappedLocations,
        'steps': mappedSteps,
        'aiFeedbacks': mappedAiFeedbacks,
        // 'photos': photos 제거 - 일기의 photo_paths 필드로 관리됨
      };

      developer.log('로컬 데이터 수집 완료, 서버로 전송 시작', name: 'BackupService');

      // 서버로 백업 데이터 전송
      final response = await DioClient.dio.post(
        '/backup/sync/$userId',
        data: backupData,
      );

      developer.log('서버 응답 수신: ${response.statusCode}', name: 'BackupService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('백업 성공 완료', name: 'BackupService');
        return {
          'success': true,
          'data': response.data,
          'message': '데이터 백업이 완료되었습니다.',
        };
      } else {
        developer.log(
          '백업 실패 - 서버 오류: ${response.statusCode}',
          name: 'BackupService',
        );
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
          'message': '데이터 백업에 실패했습니다.',
        };
      }
    } catch (e) {
      developer.log('백업 중 예외 발생: $e', name: 'BackupService');
      return {
        'success': false,
        'error': e.toString(),
        'message': '백업 중 오류가 발생했습니다.',
      };
    }
  }

  static Future<Map<String, dynamic>> restoreAllData(String userId) async {
    developer.log('데이터 복원 시작 - 사용자 ID: $userId', name: 'BackupService');

    try {
      // 서버에서 데이터 복원 요청
      developer.log('서버에서 데이터 복원 요청 전송', name: 'BackupService');
      final response = await DioClient.dio.post('/backup/restore/$userId');

      developer.log('서버 응답 수신: ${response.statusCode}', name: 'BackupService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final restoredData = response.data['data'];
        developer.log('서버에서 데이터 수신 완료', name: 'BackupService');

        // 로컬 데이터베이스 초기화 및 복원된 데이터 저장
        developer.log('로컬 데이터베이스 초기화 시작', name: 'BackupService');
        final database = SqfliteDatabase();
        await database.clearAllData();
        developer.log('로컬 데이터베이스 초기화 완료', name: 'BackupService');

        // 각 데이터 타입별로 복원
        int totalRestored = 0;

        // 일기 데이터 복원
        if (restoredData['diaries'] != null) {
          final diaries = restoredData['diaries'] as List;
          await database.restoreDiaries(diaries);
          totalRestored += diaries.length;
          developer.log(
            '일기 데이터 복원 완료: ${diaries.length}개',
            name: 'BackupService',
          );
        }

        // 체크리스트 데이터 복원
        if (restoredData['checklists'] != null) {
          final checklists = restoredData['checklists'] as List;
          await database.restoreChecklists(checklists);
          totalRestored += checklists.length;
          developer.log(
            '체크리스트 데이터 복원 완료: ${checklists.length}개',
            name: 'BackupService',
          );
        }

        // 일정 데이터 복원
        if (restoredData['schedules'] != null) {
          final schedules = restoredData['schedules'] as List;
          await database.restoreSchedules(schedules);
          totalRestored += schedules.length;
          developer.log(
            '일정 데이터 복원 완료: ${schedules.length}개',
            name: 'BackupService',
          );
        }

        // 앱 사용량 데이터 복원
        if (restoredData['appUsages'] != null) {
          final appUsages = restoredData['appUsages'] as List;
          await database.restoreAppUsages(appUsages);
          totalRestored += appUsages.length;
          developer.log(
            '앱 사용량 데이터 복원 완료: ${appUsages.length}개',
            name: 'BackupService',
          );
        }

        // 감정 기록 데이터 복원
        if (restoredData['emotions'] != null) {
          final emotions = restoredData['emotions'] as List;
          await database.restoreEmotions(emotions);
          totalRestored += emotions.length;
          developer.log(
            '감정 기록 데이터 복원 완료: ${emotions.length}개',
            name: 'BackupService',
          );
        }

        // 위치 기록 데이터 복원
        if (restoredData['locations'] != null) {
          final locations = restoredData['locations'] as List;
          await database.restoreLocations(locations);
          totalRestored += locations.length;
          developer.log(
            '위치 기록 데이터 복원 완료: ${locations.length}개',
            name: 'BackupService',
          );
        }

        // 걸음 수 데이터 복원
        if (restoredData['steps'] != null) {
          final steps = restoredData['steps'] as List;
          await database.restoreSteps(steps);
          totalRestored += steps.length;
          developer.log(
            '걸음 수 데이터 복원 완료: ${steps.length}개',
            name: 'BackupService',
          );
        }

        // AI 피드백 데이터 복원
        if (restoredData['aiFeedbacks'] != null) {
          final aiFeedbacks = restoredData['aiFeedbacks'] as List;
          await database.restoreAiFeedbacks(aiFeedbacks);
          totalRestored += aiFeedbacks.length;
          developer.log(
            'AI 피드백 데이터 복원 완료: ${aiFeedbacks.length}개',
            name: 'BackupService',
          );
        } // 사진 데이터 복원 - 일기의 photo_paths 필드로 이미 복원되므로 별도 처리 불필요
        if (restoredData['photos'] != null) {
          final photos = restoredData['photos'] as List;
          developer.log(
            '사진 데이터는 일기의 photo_paths 필드로 이미 복원됨: ${photos.length}개 스킵',
            name: 'BackupService',
          );
          // await database.restorePhotos(photos); // 비활성화됨
        }

        developer.log(
          '데이터 복원 성공 완료 - 총 복원 항목: ${totalRestored}개',
          name: 'BackupService',
        );
        return {
          'success': true,
          'data': response.data,
          'message': '서버에서 ${totalRestored}개의 데이터를 성공적으로 복원했습니다.',
        };
      } else {
        developer.log(
          '데이터 복원 실패 - 서버 오류: ${response.statusCode}',
          name: 'BackupService',
        );
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
          'message': '서버에서 데이터를 가져오지 못했습니다.',
        };
      }
    } catch (e) {
      developer.log('데이터 복원 중 예외 발생: $e', name: 'BackupService');
      return {
        'success': false,
        'error': e.toString(),
        'message': '데이터 복원 중 오류가 발생했습니다.',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAllData(String userId) async {
    developer.log('데이터 삭제 시작 - 사용자 ID: $userId', name: 'BackupService');

    try {
      // 로컬 데이터 삭제
      developer.log('로컬 데이터 삭제 시작', name: 'BackupService');
      final database = SqfliteDatabase();
      await database.clearAllData();
      developer.log('로컬 데이터 삭제 완료', name: 'BackupService');

      // 서버 데이터 삭제 (선택사항)
      developer.log('서버 데이터 삭제 요청 전송', name: 'BackupService');
      final response = await DioClient.dio.delete('/backup/clear/$userId');

      developer.log('서버 응답 수신: ${response.statusCode}', name: 'BackupService');

      if (response.statusCode == 200) {
        developer.log('모든 데이터 삭제 성공 완료', name: 'BackupService');
        return {
          'success': true,
          'data': response.data,
          'message': '모든 데이터가 삭제되었습니다.',
        };
      } else {
        developer.log(
          '서버 데이터 삭제 실패: ${response.statusCode}',
          name: 'BackupService',
        );
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
          'message': '서버 데이터 삭제에 실패했습니다. 로컬 데이터는 삭제되었습니다.',
        };
      }
    } catch (e) {
      developer.log('데이터 삭제 중 예외 발생: $e', name: 'BackupService');
      return {
        'success': false,
        'error': e.toString(),
        'message': '데이터 삭제 중 오류가 발생했습니다.',
      };
    }
  }
}
