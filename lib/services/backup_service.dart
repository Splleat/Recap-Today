import 'dart:developer' as developer;
import 'dart:convert';
import 'package:recap_today/data/sqflite_database.dart';
import 'package:recap_today/api/dio_client.dart';
import 'package:recap_today/utils/photo_backup_util.dart';

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
      developer.log(
        '사진 데이터는 일기의 photo_paths 필드로 백업됨',
        name: 'BackupService',
      ); // Transform data keys to match API expectations
      final mappedDiaries =
          diaries
              .map(
                (d) => {
                  'date': d['date'],
                  'title': d['title'] ?? '',
                  'content': d['content'] ?? '',
                  'photoPaths': d['photo_paths'] ?? '[]', // 빈 JSON 배열로 기본값 설정
                  'userId': d['user_id'],
                },
              )
              .toList();

      // 사진 데이터 수집 및 인코딩
      List<Map<String, dynamic>> photoBackupData = [];

      for (var diary in diaries) {
        try {
          final photoPathsJson = diary['photo_paths'] ?? '[]';
          if (photoPathsJson != '[]' && photoPathsJson.isNotEmpty) {
            final List<dynamic> photoPaths = jsonDecode(photoPathsJson);
            final photoPathsList = photoPaths.map((e) => e.toString()).toList();

            if (photoPathsList.isNotEmpty) {
              final encodedPhotos = await PhotoBackupUtil.encodePhotosForBackup(
                photoPathsList,
              );
              if (encodedPhotos.isNotEmpty) {
                photoBackupData.addAll(
                  encodedPhotos.map(
                    (photo) => {
                      ...photo,
                      'diaryDate': diary['date'], // 일기 날짜와 연결
                      'diaryUserId': diary['user_id'],
                    },
                  ),
                );
              }
            }
          }
        } catch (e) {
          developer.log('일기 사진 백업 처리 오류: $e', name: 'BackupService');
        }
      }

      developer.log(
        '사진 백업 데이터 수집 완료: ${photoBackupData.length}개',
        name: 'BackupService',
      );

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
                  'dayOfWeek': s['day_of_week'],
                  'selectedDate':
                      s['selected_date'] != null && s['selected_date'] != ''
                          ? s['selected_date']
                          : null,
                  'isRoutine': s['is_routine'] == 1,
                  'startTimeHour': s['start_time_hour'] ?? 0,
                  'startTimeMinute': s['start_time_minute'] ?? 0,
                  'endTimeHour': s['end_time_hour'] ?? 0,
                  'endTimeMinute': s['end_time_minute'] ?? 0,
                  'colorValue': _convertColorToInt32(s['color_value'] ?? 0),
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
      developer.log('로컬 데이터 수집 완료, 서버로 전송 시작', name: 'BackupService');

      // 데이터를 청크 단위로 나누어 전송
      try {
        // 1. 먼저 일반 데이터(사진 제외) 전송
        final generalData = {
          'diaries': mappedDiaries,
          'checklists': mappedChecklists,
          'schedules': mappedSchedules,
          'appUsages': mappedAppUsages,
          'emotions': mappedEmotions,
          'locations': mappedLocations,
          'steps': mappedSteps,
          'aiFeedbacks': mappedAiFeedbacks,
        };

        developer.log('일반 데이터 전송 시작', name: 'BackupService');
        final generalResponse = await DioClient.dio.post(
          '/backup/sync/$userId',
          data: generalData,
        );

        if (generalResponse.statusCode != 200 &&
            generalResponse.statusCode != 201) {
          developer.log(
            '일반 데이터 백업 실패: ${generalResponse.statusCode}',
            name: 'BackupService',
          );
          return {
            'success': false,
            'error': '일반 데이터 백업 실패: ${generalResponse.statusCode}',
            'message': '데이터 백업에 실패했습니다.',
          };
        }

        developer.log(
          '일반 데이터 백업 완료',
          name: 'BackupService',
        ); // 2. 사진 데이터를 개별적으로 전송 (청크 단위)
        if (photoBackupData.isNotEmpty) {
          developer.log(
            '사진 데이터 전송 시작: ${photoBackupData.length}개',
            name: 'BackupService',
          );

          const int photoChunkSize = 1; // 한 번에 1개씩 전송 (더 작은 청크)
          for (int i = 0; i < photoBackupData.length; i += photoChunkSize) {
            final end =
                (i + photoChunkSize < photoBackupData.length)
                    ? i + photoChunkSize
                    : photoBackupData.length;
            final photoChunk = photoBackupData.sublist(i, end);

            developer.log(
              '사진 청크 전송: ${i + 1}-${end}/${photoBackupData.length}',
              name: 'BackupService',
            );

            final photoChunkData = {
              'photoFiles': photoChunk,
              'isPhotoChunk': true, // 서버에서 사진 청크임을 인식할 수 있도록
            };

            try {
              final photoResponse = await DioClient.dio.post(
                '/backup/sync-photos/$userId',
                data: photoChunkData,
              );

              if (photoResponse.statusCode != 200 &&
                  photoResponse.statusCode != 201) {
                developer.log(
                  '사진 청크 ${i + 1}-${end} 전송 실패: ${photoResponse.statusCode}',
                  name: 'BackupService',
                );
                // 사진 전송 실패는 경고로 처리하고 계속 진행
              } else {
                developer.log(
                  '사진 청크 ${i + 1}-${end} 전송 완료',
                  name: 'BackupService',
                );
              }
            } catch (photoError) {
              developer.log(
                '사진 청크 ${i + 1}-${end} 전송 중 오류: $photoError',
                name: 'BackupService',
              );
              // 개별 사진 청크 오류는 로그만 남기고 계속 진행
            }
          }

          developer.log('모든 사진 데이터 전송 완료', name: 'BackupService');
        }

        developer.log('백업 성공 완료', name: 'BackupService');
        return {
          'success': true,
          'data': generalResponse.data,
          'message': '데이터 백업이 완료되었습니다.',
        };
      } catch (e) {
        if (e.toString().contains('413')) {
          developer.log(
            '백업 데이터 크기 초과 오류 - 청크 전송으로 재시도 필요',
            name: 'BackupService',
          );
          return {
            'success': false,
            'error': '데이터 크기가 너무 큽니다',
            'message': '백업 데이터가 너무 커서 전송에 실패했습니다.',
          };
        }

        developer.log('백업 실패 - 서버 오류: $e', name: 'BackupService');
        return {
          'success': false,
          'error': '서버 오류: $e',
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
        // 서버 응답 데이터 구조 검증
        if (response.data == null) {
          developer.log('서버 응답 데이터가 null입니다', name: 'BackupService');
          return {
            'success': false,
            'error': '서버 응답 데이터가 없습니다',
            'message': '복원할 데이터가 없습니다.',
          };
        }
        developer.log(
          '서버 응답 데이터 구조: ${response.data.keys}',
          name: 'BackupService',
        );

        developer.log('서버 응답 전체 데이터: ${response.data}', name: 'BackupService');

        // 'data' 필드가 있는지 확인, 없으면 response.data 자체를 사용
        final restoredData = response.data['data'] ?? response.data;

        if (restoredData == null) {
          developer.log('복원할 데이터가 없습니다', name: 'BackupService');
          return {
            'success': false,
            'error': '복원할 데이터가 없습니다',
            'message': '서버에 백업된 데이터가 없습니다.',
          };
        }

        developer.log('서버에서 데이터 수신 완료', name: 'BackupService');

        // 로컬 데이터베이스 초기화 및 복원된 데이터 저장
        developer.log('로컬 데이터베이스 초기화 시작', name: 'BackupService');
        final database = SqfliteDatabase();
        await database.clearAllData();
        developer.log(
          '로컬 데이터베이스 초기화 완료',
          name: 'BackupService',
        ); // 각 데이터 타입별로 복원
        int totalRestored = 0;

        // 일기 데이터 복원
        if (restoredData is Map && restoredData['diaries'] != null) {
          final diaries = restoredData['diaries'] as List;
          await database.restoreDiaries(diaries);
          totalRestored += diaries.length;
          developer.log(
            '일기 데이터 복원 완료: ${diaries.length}개',
            name: 'BackupService',
          );
        }

        // 체크리스트 데이터 복원
        if (restoredData is Map && restoredData['checklists'] != null) {
          final checklists = restoredData['checklists'] as List;
          await database.restoreChecklists(checklists);
          totalRestored += checklists.length;
          developer.log(
            '체크리스트 데이터 복원 완료: ${checklists.length}개',
            name: 'BackupService',
          );
        }

        // 일정 데이터 복원
        if (restoredData is Map && restoredData['schedules'] != null) {
          final schedules = restoredData['schedules'] as List;
          await database.restoreSchedules(schedules);
          totalRestored += schedules.length;
          developer.log(
            '일정 데이터 복원 완료: ${schedules.length}개',
            name: 'BackupService',
          );
        }

        // 앱 사용량 데이터 복원
        if (restoredData is Map && restoredData['appUsages'] != null) {
          final appUsages = restoredData['appUsages'] as List;
          await database.restoreAppUsages(appUsages);
          totalRestored += appUsages.length;
          developer.log(
            '앱 사용량 데이터 복원 완료: ${appUsages.length}개',
            name: 'BackupService',
          );
        } // 감정 기록 데이터 복원
        if (restoredData is Map && restoredData['emotions'] != null) {
          final emotions = restoredData['emotions'] as List;
          await database.restoreEmotions(emotions);
          totalRestored += emotions.length;
          developer.log(
            '감정 기록 데이터 복원 완료: ${emotions.length}개',
            name: 'BackupService',
          );
        }

        // 위치 기록 데이터 복원
        if (restoredData is Map && restoredData['locations'] != null) {
          final locations = restoredData['locations'] as List;
          await database.restoreLocations(locations);
          totalRestored += locations.length;
          developer.log(
            '위치 기록 데이터 복원 완료: ${locations.length}개',
            name: 'BackupService',
          );
        }

        // 걸음 수 데이터 복원
        if (restoredData is Map && restoredData['steps'] != null) {
          final steps = restoredData['steps'] as List;
          await database.restoreSteps(steps);
          totalRestored += steps.length;
          developer.log(
            '걸음 수 데이터 복원 완료: ${steps.length}개',
            name: 'BackupService',
          );
        }

        // AI 피드백 데이터 복원
        if (restoredData is Map && restoredData['aiFeedbacks'] != null) {
          final aiFeedbacks = restoredData['aiFeedbacks'] as List;
          await database.restoreAiFeedbacks(aiFeedbacks);
          totalRestored += aiFeedbacks.length;
          developer.log(
            'AI 피드백 데이터 복원 완료: ${aiFeedbacks.length}개',
            name: 'BackupService',
          );
        }

        // 사진 파일 데이터 복원
        if (restoredData is Map && restoredData['photoFiles'] != null) {
          final photoFiles = restoredData['photoFiles'] as List;
          developer.log(
            '사진 파일 복원 시작: ${photoFiles.length}개',
            name: 'BackupService',
          );

          try {
            // 일기별로 사진 파일들을 그룹화
            final Map<String, List<dynamic>> photosByDiary = {};
            for (var photoFile in photoFiles) {
              final diaryDate = photoFile['diaryDate'] as String;
              if (!photosByDiary.containsKey(diaryDate)) {
                photosByDiary[diaryDate] = [];
              }
              photosByDiary[diaryDate]!.add(photoFile);
            }

            // 복원된 사진 경로로 일기 데이터 업데이트
            for (var diaryEntry in photosByDiary.entries) {
              final diaryDate = diaryEntry.key;
              final diaryPhotoFiles = diaryEntry.value;

              // 사진 파일들을 실제 파일로 복원
              final restoredPaths =
                  await PhotoBackupUtil.decodePhotosFromBackup(diaryPhotoFiles);

              if (restoredPaths.isNotEmpty) {
                // 해당 날짜의 일기에 복원된 사진 경로 업데이트
                await database.updateDiaryPhotoPaths(
                  diaryDate,
                  userId,
                  restoredPaths,
                );
                developer.log(
                  '일기 사진 경로 업데이트 완료: $diaryDate (${restoredPaths.length}개)',
                  name: 'BackupService',
                );
              }
            }

            developer.log(
              '사진 파일 복원 완료: ${photoFiles.length}개 처리됨',
              name: 'BackupService',
            );
          } catch (e) {
            developer.log('사진 파일 복원 중 오류: $e', name: 'BackupService');
          }
        }

        // 사진 데이터 복원 - 일기의 photo_paths 필드로 이미 복원되므로 별도 처리 불필요
        if (restoredData is Map && restoredData['photos'] != null) {
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

      // 서버의 BigInt 직렬화 오류인 경우 특별한 메시지 제공
      String errorMessage = '데이터 복원 중 오류가 발생했습니다.';
      if (e.toString().contains('500') ||
          e.toString().contains('Server error')) {
        errorMessage = '서버에서 데이터 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        developer.log(
          '서버 내부 오류 (500) 감지 - BigInt 직렬화 문제일 가능성',
          name: 'BackupService',
        );
      }

      return {'success': false, 'error': e.toString(), 'message': errorMessage};
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

  // Helper method to convert unsigned color values to signed 32-bit integers
  static int _convertColorToInt32(dynamic colorValue) {
    if (colorValue == null) return 0;

    int color =
        colorValue is int
            ? colorValue
            : int.tryParse(colorValue.toString()) ?? 0;

    // Convert unsigned 32-bit to signed 32-bit
    if (color > 2147483647) {
      // If the value exceeds int32 max, convert to signed equivalent
      return color - 4294967296; // 2^32
    }

    return color;
  }
}
