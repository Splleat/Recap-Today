import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:recap_today/provider/login_provider.dart'; // Import LoginProvider
// import 'package:recap_today/provider/sync_provider.dart'; // Comment out or remove old SyncProvider import
import 'package:recap_today/provider/sync_settings_provider.dart'; // Import SyncSettingsProvider
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/screens/login_screen.dart';
import 'package:recap_today/screens/signup_screen.dart';
import 'package:recap_today/screens/user_profile_edit_screen.dart';
import 'package:recap_today/provider/theme_provider.dart';
import 'package:recap_today/settings/setting_card.dart';
import 'package:recap_today/model/syncable_item_type.dart'; // Import SyncableItemType

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
    // final syncProvider = Provider.of<SyncProvider>(context); // Comment out or remove old SyncProvider instance
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
                  ],
                ),
                // const SizedBox(height: 10),
                // Text('데이터 동기화'),
                // SettingsCard(
                //   children: [
                //     ListTile(
                //       leading: Icon(Icons.sync),
                //       title: Text('지금 동기화'),
                //       subtitle: Text(
                //           '마지막 동기화: ${syncProvider.lastSyncTime ?? "정보 없음"}'), // Uses old syncProvider
                //       trailing: syncProvider.syncState == SyncState.syncing // Uses old syncProvider
                //           ? CircularProgressIndicator()
                //           : IconButton(
                //               icon: Icon(Icons.refresh),
                //               onPressed: () async {
                //                 await syncProvider.triggerSync(); // Uses old syncProvider
                //                 if (syncProvider.syncState == SyncState.success) { // Uses old syncProvider
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(
                //                         content: Text('동기화 성공!'),
                //                         backgroundColor: Colors.green),
                //                   );
                //                 } else if (syncProvider.syncState == SyncState.error) { // Uses old syncProvider
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(
                //                         content: Text(
                //                             '동기화 실패: ${syncProvider.errorMessage}'), // Uses old syncProvider
                //                         backgroundColor: Colors.red),
                //                   );
                //                 }
                //               },
                //             ),
                //     ),
                //     if (syncProvider.syncState == SyncState.error) // Uses old syncProvider
                //       Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                //         child: Text(
                //           '오류: ${syncProvider.errorMessage}', // Uses old syncProvider
                //           style: TextStyle(color: Colors.red),
                //         ),
                //       ),
                //   ],
                // ),
                // 다른 설정 항목들을 여기에 추가할 수 있습니다

                // New Data Synchronization & Backup Section
                if (loginProvider.isLoggedIn) ...[
                  const SizedBox(height: 20),
                  Text(
                    '데이터 동기화 및 백업',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Consumer<SyncSettingsProvider>(
                    builder: (context, provider, child) {
                      return SettingsCard(
                        children: [
                          // Replace placeholder with actual list of SwitchListTiles
                          ListView.builder(
                            shrinkWrap:
                                true, // Important to make ListView work inside Column/SettingsCard
                            physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling for the ListView itself
                            itemCount: SyncableItemType.values.length,
                            itemBuilder: (context, index) {
                              final itemType = SyncableItemType.values[index];
                              // A helper function to get a display-friendly name could be added to SyncableItemType enum or here
                              String itemDisplayName =
                                  itemType.name[0].toUpperCase() +
                                  itemType.name.substring(1);
                              if (itemType == SyncableItemType.diary)
                                itemDisplayName =
                                    "Diaries & Photos"; // Combine Diary and Photos as per previous decision
                              if (itemType == SyncableItemType.photos)
                                return const SizedBox.shrink(); // Hide separate Photos entry

                              return SwitchListTile(
                                title: Text(itemDisplayName),
                                subtitle: Text(
                                  provider.getSubtitleForItem(itemType),
                                ),
                                value:
                                    provider.selectedItems[itemType] ?? false,
                                onChanged: (bool value) {
                                  provider.toggleItemSelection(itemType);
                                },
                                // Disable switch if a sync is in progress
                                activeColor:
                                    provider.currentOverallSyncState ==
                                            SyncOverallState.syncing
                                        ? Colors.grey
                                        : null,
                                inactiveThumbColor:
                                    provider.currentOverallSyncState ==
                                            SyncOverallState.syncing
                                        ? Colors.grey
                                        : null,
                              );
                            },
                          ),
                          const Divider(),
                          // Sync/Cancel buttons and Progress Indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              children: [
                                if (provider.currentOverallSyncState ==
                                    SyncOverallState.syncing)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider
                                                  .currentSyncingItemName
                                                  .isNotEmpty
                                              ? '동기화 중: ${provider.currentSyncingItemName} (${(provider.overallProgress * 100).toStringAsFixed(0)}%)'
                                              : '동기화 중... (${(provider.overallProgress * 100).toStringAsFixed(0)}%)',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: provider.overallProgress,
                                          backgroundColor: Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          provider.currentOverallSyncState ==
                                                      SyncOverallState
                                                          .syncing ||
                                                  !provider.isAnyItemSelected
                                              ? null // Disable if already syncing or no items selected
                                              : () {
                                                provider.startSelectiveSync();
                                              },
                                      child: const Text('선택 항목 동기화'),
                                    ),
                                    if (provider.currentOverallSyncState ==
                                        SyncOverallState.syncing)
                                      TextButton(
                                        onPressed: () {
                                          provider.cancelSync();
                                        },
                                        child: const Text('취소'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Overall Status Text
                                Text(
                                  provider.getOverallSyncStatusMessage(),
                                  style:
                                      Theme.of(context)
                                          .textTheme
                                          .bodySmall, // Changed from caption to bodySmall
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
