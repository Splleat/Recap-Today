import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class MigrationDialog extends StatelessWidget {
  final int localDataCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const MigrationDialog({
    super.key,
    required this.localDataCount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync, color: Colors.blue),
          SizedBox(width: 8),
          Text('로컬 데이터 마이그레이션'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '로그인하기 전에 사용한 로컬 데이터가 발견되었습니다.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '발견된 데이터:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('• 위치 데이터: $localDataCount개'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '이 데이터를 현재 계정으로 마이그레이션하시겠습니까?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '• 마이그레이션 후 로컬 데이터는 삭제됩니다\n• 마이그레이션된 데이터는 서버에 자동 동기화됩니다',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('취소')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('마이그레이션'),
        ),
      ],
    );
  }

  /// 마이그레이션 다이얼로그 표시
  static Future<bool> show({
    required BuildContext context,
    required int localDataCount,
  }) async {
    developer.log(
      '마이그레이션 다이얼로그 표시: $localDataCount개 데이터',
      name: 'MigrationDialog',
    );

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => MigrationDialog(
                localDataCount: localDataCount,
                onConfirm: () {
                  developer.log('사용자가 마이그레이션 확인', name: 'MigrationDialog');
                  Navigator.of(context).pop(true);
                },
                onCancel: () {
                  developer.log('사용자가 마이그레이션 취소', name: 'MigrationDialog');
                  Navigator.of(context).pop(false);
                },
              ),
        ) ??
        false;
  }
}

class MigrationProgressDialog extends StatelessWidget {
  final String message;

  const MigrationProgressDialog({
    super.key,
    this.message = '데이터를 마이그레이션하고 있습니다...',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 마이그레이션 진행 다이얼로그 표시
  static void show({
    required BuildContext context,
    String message = '데이터를 마이그레이션하고 있습니다...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MigrationProgressDialog(message: message),
    );
  }

  /// 다이얼로그 닫기
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class MigrationResultDialog extends StatelessWidget {
  final bool success;
  final int migratedCount;
  final String? error;

  const MigrationResultDialog({
    super.key,
    required this.success,
    this.migratedCount = 0,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(success ? '마이그레이션 완료' : '마이그레이션 실패'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (success) ...[
            Text('$migratedCount개의 위치 데이터가 성공적으로 마이그레이션되었습니다.'),
            const SizedBox(height: 8),
            Text(
              '데이터가 서버에 동기화되었습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ] else ...[
            const Text('마이그레이션 중 오류가 발생했습니다.'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '오류: $error',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: success ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  /// 마이그레이션 결과 다이얼로그 표시
  static Future<void> show({
    required BuildContext context,
    required bool success,
    int migratedCount = 0,
    String? error,
  }) async {
    developer.log(
      '마이그레이션 결과 다이얼로그: ${success ? "성공" : "실패"} ($migratedCount개)',
      name: 'MigrationResultDialog',
    );

    return showDialog(
      context: context,
      builder:
          (context) => MigrationResultDialog(
            success: success,
            migratedCount: migratedCount,
            error: error,
          ),
    );
  }
}
