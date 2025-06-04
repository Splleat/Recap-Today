import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/login_provider.dart';

/// Provider들 간의 의존성을 초기화하는 클래스
class ProviderInitializer {
  /// ChecklistProvider가 LoginProvider의 userId를 사용하도록 초기화
  static void initializeChecklistProvider(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    
    // LoginProvider에서 현재 userId 가져와서 설정
    checklistProvider.setUserId(loginProvider.userId);
    
    // userId 변경시 ChecklistProvider도 업데이트하도록 리스너 설정
    loginProvider.addListener(() {
      if (checklistProvider.userId != loginProvider.userId) {
        checklistProvider.setUserId(loginProvider.userId);
      }
    });
  }
}
