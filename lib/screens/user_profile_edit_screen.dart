import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/user_profile_provider.dart';
import 'package:recap_today/provider/login_provider.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      userProfileProvider.initializeWithCurrentUser(loginProvider.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        final isLoading = userProfileProvider.isLoading;
        final errorMessage = userProfileProvider.errorMessage;
        final successMessage = userProfileProvider.successMessage;

        // 성공 메시지 처리
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
              ),
            );
            userProfileProvider.clearMessages();
            // 성공 시 이전 화면으로 돌아가기
            Navigator.pop(context);
          }
          if (errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            userProfileProvider.clearMessages();
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('프로필 수정', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // 프로필 정보 카드
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '기본 정보',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // 닉네임 입력 필드
                              TextFormField(
                                initialValue: userProfileProvider.name,
                                onChanged:
                                    (value) =>
                                        userProfileProvider.setName(value),
                                decoration: const InputDecoration(
                                  labelText: '닉네임',
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '닉네임을 입력해주세요';
                                  }
                                  if (value.trim().length < 2) {
                                    return '닉네임은 2자 이상이어야 합니다';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              // 비밀번호 변경 섹션
                              ExpansionTile(
                                title: Text(
                                  '비밀번호 변경',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                initiallyExpanded: _isPasswordExpanded,
                                leading: const Icon(Icons.lock_outline),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _isPasswordExpanded = expanded;
                                  });
                                },
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        // 현재 비밀번호
                                        TextFormField(
                                          onChanged:
                                              (value) => userProfileProvider
                                                  .setCurrentPassword(value),
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: '현재 비밀번호',
                                            prefixIcon: Icon(Icons.lock),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // 새 비밀번호
                                        TextFormField(
                                          onChanged:
                                              (value) => userProfileProvider
                                                  .setNewPassword(value),
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: '새 비밀번호',
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                            ),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // 새 비밀번호 확인
                                        TextFormField(
                                          onChanged:
                                              (value) => userProfileProvider
                                                  .setConfirmPassword(value),
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: '새 비밀번호 확인',
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                            ),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              // 저장 버튼
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await userProfileProvider
                                                  .updateProfile();
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2196F3),
                                          Color(0xFF1976D2),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child:
                                          isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                              : const Text(
                                                '저장',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 참고 사항
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '참고 사항',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• 닉네임만 변경하려면 비밀번호 변경 섹션을 비워두세요\n'
                              '• 비밀번호를 변경하려면 현재 비밀번호가 필요합니다\n'
                              '• 새 비밀번호는 6자 이상이어야 합니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
