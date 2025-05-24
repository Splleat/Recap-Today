import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:recap_today/provider/login_provider.dart'; // Import LoginProvider
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/screens/login_screen.dart';
import 'package:recap_today/screens/signup_screen.dart';

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
        title: Text('설정', style: TextStyle(color: Colors.black)),
      ),
      body: Container(
        decoration: commonTabDecoration(),
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
                      title: const Text('로그아웃'),
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
                ],
                const SizedBox(height: 1),
                // 캘린더 화면 위젯 선택 섹션
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_today_outlined, // Changed icon
                      color: Colors.redAccent, // Changed color
                    ),
                    title: const Text('캘린더 화면 위젯 선택'), // Changed text
                    //subtitle: const Text('캘린더 화면에 표시할 위젯을 선택하세요'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 캘린더 화면 위젯 선택 화면으로 이동
                    },
                  ),
                ),
                const SizedBox(height: 1),
                // 요약 화면 위젯 선택 섹션
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(
                      Icons.widgets_outlined,
                      color: Colors.orangeAccent,
                    ),
                    title: const Text('요약 화면 위젯 선택'),
                    //subtitle: const Text('요약 화면에 표시할 위젯을 선택하세요'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 요약 화면 위젯 선택 화면으로 이동
                    },
                  ),
                ),
                const SizedBox(height: 1),
                // AI 피드백 정보 선택 섹션
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(
                      Icons.insights,
                      color: Colors.purpleAccent,
                    ),
                    title: const Text('AI 피드백 정보 선택'),
                    //subtitle: const Text('AI 피드백에 포함될 정보를 선택하세요'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: AI 피드백 정보 선택 화면으로 이동
                    },
                  ),
                ),
                const SizedBox(height: 1),
                // 공유 기능 위젯 선택 섹션
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(
                      Icons.share_outlined,
                      color: Colors.tealAccent,
                    ),
                    title: const Text('공유 기능 위젯 선택'),
                    //subtitle: const Text('공유할 때 포함될 위젯을 선택하세요'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 공유 기능 위젯 선택 화면으로 이동
                    },
                  ),
                ),
                const SizedBox(height: 1),
                // 다른 설정 항목들을 여기에 추가할 수 있습니다
              ],
            ),
          ),
        ),
      ),
    );
  }
}
