import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'package:recap_today/api/location_service.dart';
import 'package:recap_today/widget/migration_dialog.dart';

class MigrationService {
  /// 로그인 후 데이터 마이그레이션 프로세스 실행
  static Future<void> handlePostLoginMigration({
    required BuildContext context,
    required String realUserId,
  }) async {
    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      // 로컬 데이터 존재 여부 확인
      final hasLocalData = await locationService.hasLocalUserData();
      if (!hasLocalData) {
        developer.log('마이그레이션할 로컬 데이터가 없습니다.', name: 'MigrationService');
        return;
      }

      // 로컬 데이터 개수 조회
      final localDataList = await locationService.getAllLocationDataForUser(
        'local_user',
      );
      final localDataCount = localDataList.length;

      developer.log('로컬 데이터 $localDataCount개 발견', name: 'MigrationService');

      // 사용자에게 마이그레이션 확인 요청
      final shouldMigrate = await MigrationDialog.show(
        context: context,
        localDataCount: localDataCount,
      );

      if (!shouldMigrate) {
        developer.log('사용자가 마이그레이션을 취소했습니다.', name: 'MigrationService');
        return;
      }

      // 마이그레이션 진행 다이얼로그 표시
      if (context.mounted) {
        MigrationProgressDialog.show(context: context);
      }

      try {
        // 데이터 마이그레이션 실행
        final success = await locationService.migrateLocalUserDataToRealUser(
          realUserId,
        );

        // 진행 다이얼로그 닫기
        if (context.mounted) {
          MigrationProgressDialog.hide(context);
        }

        // 결과 다이얼로그 표시
        if (context.mounted) {
          await MigrationResultDialog.show(
            context: context,
            success: success,
            migratedCount: success ? localDataCount : 0,
          );
        }

        developer.log(
          '마이그레이션 ${success ? "완료" : "실패"}: $localDataCount개',
          name: 'MigrationService',
        );
      } catch (e) {
        // 진행 다이얼로그 닫기
        if (context.mounted) {
          MigrationProgressDialog.hide(context);
        }

        // 오류 다이얼로그 표시
        if (context.mounted) {
          await MigrationResultDialog.show(
            context: context,
            success: false,
            error: e.toString(),
          );
        }

        developer.log('마이그레이션 중 오류: $e', name: 'MigrationService');
      }
    } catch (e) {
      developer.log('마이그레이션 프로세스 실행 중 오류: $e', name: 'MigrationService');
    }
  }

  /// 백그라운드에서 자동 마이그레이션 (사용자 개입 없음)
  static Future<bool> autoMigrateInBackground({
    required LocationService locationService,
    required String realUserId,
  }) async {
    try {
      // 로컬 데이터 존재 여부 확인
      final hasLocalData = await locationService.hasLocalUserData();
      if (!hasLocalData) {
        return true; // 마이그레이션할 데이터가 없으면 성공으로 처리
      }

      developer.log(
        '백그라운드 자동 마이그레이션 시작: $realUserId',
        name: 'MigrationService',
      );

      // 마이그레이션 실행
      final success = await locationService.migrateLocalUserDataToRealUser(
        realUserId,
      );

      developer.log(
        '백그라운드 마이그레이션 ${success ? "완료" : "실패"}',
        name: 'MigrationService',
      );

      return success;
    } catch (e) {
      developer.log('백그라운드 마이그레이션 오류: $e', name: 'MigrationService');
      return false;
    }
  }

  /// 로컬 데이터 존재 여부 확인
  static Future<bool> hasLocalDataToMigrate(
    LocationService locationService,
  ) async {
    try {
      return await locationService.hasLocalUserData();
    } catch (e) {
      developer.log('로컬 데이터 확인 중 오류: $e', name: 'MigrationService');
      return false;
    }
  }

  /// 로컬 데이터 개수 조회
  static Future<int> getLocalDataCount(LocationService locationService) async {
    try {
      final localDataList = await locationService.getAllLocationDataForUser(
        'local_user',
      );
      return localDataList.length;
    } catch (e) {
      developer.log('로컬 데이터 개수 조회 중 오류: $e', name: 'MigrationService');
      return 0;
    }
  }
}
