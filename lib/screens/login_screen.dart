import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // final _usernameController = TextEditingController();
  // final _passwordController = TextEditingController();
  // bool _isLoading = false;

  // Future<void> login() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // 여러 가능한 URL을 시도합니다
  //     final urls = [
  //       'http://211.194.70.88:8000/login', // 실제 서버
  //       'http://10.0.2.2:8000/login', // Android 에뮬레이터
  //       'http://localhost:8000/login', // 웹
  //       'http://127.0.0.1:8000/login', // 로컬 장치
  //     ];

  //     http.Response? response;
  //     String errorMsg = "";

  //     for (var url in urls) {
  //       try {
  //         response = await http.post(
  //           Uri.parse(url),
  //           headers: {'Content-Type': 'application/json'},
  //           body: jsonEncode({
  //             'username': _usernameController.text,
  //             'password': _passwordController.text,
  //           }),
  //         );
  //         // 성공하면 루프 종료
  //         break;
  //       } catch (e) {
  //         errorMsg += "$url 연결 실패: $e\n";
  //         continue;
  //       }
  //     }

  //     if (response != null && response.statusCode == 200) {
  //       if (mounted) {
  //         Navigator.pushReplacementNamed(context, '/home');
  //       }
  //     } else {
  //       if (mounted) {
  //         if (response != null) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('로그인 실패: ${response.statusCode}')),
  //           );
  //         } else {
  //           ScaffoldMessenger.of(
  //             context,
  //           ).showSnackBar(SnackBar(content: Text('서버 연결 실패\n$errorMsg')));
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('연결 오류: $e')));
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  // @override
  // void dispose() {
  //   _usernameController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (LoginProvider provider) => provider.isLoading,
    );
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true, // Enable resize when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          // Add scroll capability
          child: Padding(
            padding: EdgeInsets.only(
              top: 24.0,
              left: 24.0,
              right: 24.0,
              // Add bottom padding to account for keyboard
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
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
                  '생산적인 하루를 계획하세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 60),
                // Login form
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
                          onChanged:
                              (value) => context
                                  .read<LoginProvider>()
                                  .setUserId(value),
                          decoration: const InputDecoration(
                            labelText: '아이디',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
                          onChanged:
                              (value) => context
                                  .read<LoginProvider>()
                                  .setPassword(value),
                          decoration: const InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : context.read<LoginProvider>().login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      '로그인',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // 뒤로가기
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '로그인 없이 계속하기',
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
                // Sign up button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '계정이 없으신가요?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('회원가입'),
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
