import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:recap_today/provider/login_provider.dart'; // Import LoginProvider
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/screens/login_screen.dart';
import 'package:recap_today/screens/signup_screen.dart';
import 'package:recap_today/screens/user_profile_edit_screen.dart';
import 'package:recap_today/provider/theme_provider.dart';
import 'package:recap_today/settings/setting_card.dart';
import 'package:recap_today/service/location_tracking_service.dart';
import 'package:recap_today/provider/weather_provider.dart';
import 'package:recap_today/services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 데이터 백업 메서드
  Future<void> _backupData() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 백업'),
            content: const Text(
              '현재 로컬 데이터를 서버에 백업하시겠습니까?\n기존 서버 데이터는 덮어쓰기됩니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('백업'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final userId = loginProvider.activeUserId;

      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('데이터를 백업하는 중...'),
                ],
              ),
            ),
      );

      try {
        final result = await BackupService.backupAllData(userId);
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        // 결과 다이얼로그 표시
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(result['success'] ? '백업 완료' : '백업 실패'),
                content: Text(result['message']),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('오류'),
                content: Text('백업 중 오류가 발생했습니다.\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      }
    }
  }

  // 데이터 삭제 메서드
  Future<void> _deleteAllData() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 삭제'),
            content: const Text(
              '모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.\n정말로 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final userId = loginProvider.activeUserId;

      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('데이터를 삭제하는 중...'),
                ],
              ),
            ),
      );

      try {
        final result = await BackupService.deleteAllData(userId);
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        // 결과 다이얼로그 표시
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(result['success'] ? '삭제 완료' : '삭제 실패'),
                content: Text(result['message']),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('오류'),
                content: Text('삭제 중 오류가 발생했습니다.\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access LoginProvider
    final loginProvider = Provider.of<LoginProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final currentMode = themeProvider.themeMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ); // 홈으로 이동
          },
        ),
        title: Text('설정'),
      ),
      body: Container(
        decoration: commonTabDecoration(context),
        constraints: const BoxConstraints.expand(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              // Wrap Column with SingleChildScrollView
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("계정 설정"),
                  SettingsCard(
                    children: [
                      if (!loginProvider.isLoggedIn) ...[
                        // 로그인 섹션
                        ListTile(
                          leading: const Icon(
                            Icons.login,
                            color: Colors.blueAccent,
                          ),
                          title: const Text('로그인'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                        // 회원가입 섹션
                        ListTile(
                          leading: const Icon(
                            Icons.person_add,
                            color: Colors.greenAccent,
                          ),
                          title: const Text('회원가입'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        // 로그아웃 버튼
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            '${loginProvider.currentUser?.name ?? '사용자'}님 로그아웃',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            // Show logout confirmation dialog
                            final confirmLogout = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('로그아웃'),
                                  content: const Text('로그아웃 하시겠습니까?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmLogout == true) {
                              await loginProvider.logout();
                              // Optionally, navigate to home or login screen after logout
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            }
                          },
                        ),
                        // 사용자 정보 수정 버튼
                        ListTile(
                          leading: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          title: const Text('프로필 수정'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const UserProfileEditScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('테마 설정'),
                  SettingsCard(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('라이트 모드'),
                        value: ThemeMode.light,
                        groupValue: currentMode,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            themeProvider.setTheme(mode);
                          }
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('다크 모드'),
                        value: ThemeMode.dark,
                        groupValue: currentMode,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            themeProvider.setTheme(mode);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('날씨 설정'),
                  SettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blueAccent,
                        ),
                        title: const Text('현재 위치 확인'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // 1. 로딩 다이얼로그 표시
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          try {
                            final position =
                                await LocationTrackingService.instance
                                    .getCurrentLocation();
                            final address = await LocationTrackingService
                                .instance
                                .getCurrentAddress(
                                  position.latitude,
                                  position.longitude,
                                );

                            // 2. 로딩 다이얼로그 닫기
                            Navigator.of(context).pop();

                            // 3. 결과 다이얼로그 표시
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('현재 위치'),
                                  content: Text(address),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e) {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('오류'),
                                    content: Text('위치 정보를 가져오지 못했습니다.\n$e'),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.refresh,
                          color: Colors.greenAccent,
                        ),
                        title: const Text('날씨 새로고침'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // 1. 로딩 다이얼로그 표시
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          try {
                            await weatherProvider.fetchWeather(
                              DateTime.now(),
                              force: true,
                            );

                            // 2. 로딩 다이얼로그 닫기
                            Navigator.of(context).pop();

                            // 3. 완료 스낵바 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('날씨 정보가 새로고침되었습니다.'),
                              ),
                            );
                          } catch (e) {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('오류'),
                                    content: Text('날씨 정보를 새로고침하지 못했습니다.\n$e'),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('데이터 설정'),
                  SettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.cloud_upload,
                          color: Colors.blueAccent,
                        ),
                        title: const Text('데이터 백업'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _backupData,
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        title: const Text('데이터 삭제'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _deleteAllData,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
