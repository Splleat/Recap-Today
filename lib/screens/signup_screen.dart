import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:recap_today/screens/login_screen.dart'; // LoginScreen import 추가

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> signup() async {
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 여러 가능한 URL을 시도합니다
      final urls = [
        'http://211.194.70.88:8000/signup', // 실제 서버
        'http://10.0.2.2:8000/signup', // Android 에뮬레이터
        'http://localhost:8000/signup', // 웹
        'http://127.0.0.1:8000/signup', // 로컬 장치
      ];

      http.Response? response;
      String errorMsg = "";

      for (var url in urls) {
        try {
          response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _usernameController.text,
              'password': _passwordController.text,
            }),
          );
          // 성공하면 루프 종료
          break;
        } catch (e) {
          errorMsg += "$url 연결 실패: $e\n";
          continue;
        }
      }

      if (response != null && response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원가입 성공!')));
          Navigator.pop(context); // 로그인 화면으로 돌아가기
        }
      } else {
        if (mounted) {
          if (response != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('회원가입 실패: ${response.statusCode}')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('서버 연결 실패\n$errorMsg')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연결 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true, // Enable resize when keyboard appears
      // appBar: AppBar(
      //   title: const Text('회원가입'),
      //   backgroundColor: Color(0xFF2196F3),
      //   elevation: 0,
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Add scroll capability
          child: Padding(
            padding: EdgeInsets.only(
              top: 24.0,
              left: 24.0,
              right: 24.0,
              // Add dynamic bottom padding to account for keyboard
              // bottom: MediaQuery.of(context).viewInsets.bottom + 24.0, // Removed this line
              bottom: 24.0, // Added fixed bottom padding
            ),
            // child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo or app title
                Text(
                  'Recap Today',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '새로운 계정을 만들어주세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 60),
                // Sign up form
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '아이디',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '비밀번호 확인',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                0xFF2196F3,
                              ), // 그라데이션 제거, 단색 배경으로 변경
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      '회원가입',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16), // 간격 추가
                        SizedBox(
                          // 회원가입 없이 계속하기 버튼 추가
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigator.popUntil(context, ModalRoute.withName('/settings'));
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/settings',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300], // 다른 스타일 적용
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '회원가입 없이 계속하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Login button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigator.pop(context); // 이전 방식
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
