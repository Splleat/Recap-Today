import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:recap_today/provider/login_provider.dart'; // Import LoginProvider
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/screens/login_screen.dart';
import 'package:recap_today/screens/signup_screen.dart';
import 'package:recap_today/screens/user_profile_edit_screen.dart';
import 'package:recap_today/provider/theme_provider.dart';
import 'package:recap_today/settings/setting_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Access LoginProvider
    final loginProvider = Provider.of<LoginProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                // 로그인 섹션
                if (!loginProvider.isLoggedIn) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.login,
                        color: Colors.blueAccent,
                      ),
                      title: const Text('로그인'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 1),
                  // 회원가입 섹션
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_add,
                        color: Colors.greenAccent,
                      ),
                      title: const Text('회원가입'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // 로그아웃 버튼
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        '${loginProvider.currentUser?.name ?? '사용자'}님 로그아웃',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                                      () => Navigator.of(context).pop(false),
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
                  ),
                  const SizedBox(height: 1),
                  // 사용자 정보 수정 버튼
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.edit, color: Colors.blueAccent),
                      title: const Text('프로필 수정'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserProfileEditScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],            
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
                  ]
                ),
                // 다른 설정 항목들을 여기에 추가할 수 있습니다
              ],
            ),
          ),
        ),
      ),
    );
  }
}
