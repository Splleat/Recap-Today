import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider package import
import 'package:recap_today/provider/signup_provider.dart'; // SignupProvider import
import 'package:recap_today/screens/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupProvider = Provider.of<SignupProvider>(context);
    final isLoading = signupProvider.isLoading;
    final errorMessage = signupProvider.errorMessage;
    final successMessage = signupProvider.successMessage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        // Clear message after showing
        context.read<SignupProvider>().setUsername(signupProvider.username);
      }
      if (successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        // Clear message after showing and navigate
        context.read<SignupProvider>().setUsername(signupProvider.username);
        Navigator.pop(context);
      }
    });

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
                          // controller: _usernameController, // Remove controller
                          onChanged:
                              (value) => signupProvider.setUsername(value),
                          decoration: const InputDecoration(
                            labelText: '아이디',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          // 이름 입력 필드 추가
                          onChanged: (value) => signupProvider.setName(value),
                          decoration: const InputDecoration(
                            labelText: '닉네임',
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          // controller: _passwordController, // Remove controller
                          onChanged:
                              (value) => signupProvider.setPassword(value),
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          // controller: _confirmPasswordController, // Remove controller
                          onChanged:
                              (value) =>
                                  signupProvider.setConfirmPassword(value),
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
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      await signupProvider.signup();
                                    },
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
                                isLoading
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
                        Navigator.pushReplacement(
                          // pushReplacement to avoid stacking screens
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
