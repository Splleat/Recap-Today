import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/service/app_usage_service.dart';

class AppUsage extends StatefulWidget {
  const AppUsage({super.key});

  @override
  State<AppUsage> createState() => _AppUsageState();
}

class _AppUsageState extends State<AppUsage> {
  late AppUsageService _appUsageService;
  bool _isLoading = true;
  bool _hasPermission = false;
  AppUsageSummary? _usageSummary;
  String _today = '';

  // 애니메이션 컨트롤러 추가
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 초기화 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final database = Provider.of<AbstractDatabase>(context, listen: false);
    _appUsageService = AppUsageService(database);

    await _checkPermissionAndLoadData();
  }

  Future<void> _checkPermissionAndLoadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 안드로이드에서만 권한 확인
      if (Platform.isAndroid) {
        _hasPermission = await _appUsageService.hasUsageStatsPermission();

        if (_hasPermission) {
          // 캐시된 데이터 먼저 로드
          final storedSummary = await _appUsageService
              .getAppUsageSummaryForDate(_today);

          // UI 빠르게 업데이트
          if (storedSummary != null && mounted) {
            setState(() {
              _usageSummary = storedSummary;
              _isLoading = false;
            });
          }

          // 최신 데이터로 갱신 (백그라운드)
          _refreshDataInBackground();
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('앱 사용 통계 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDataInBackground() async {
    if (!Platform.isAndroid || !_hasPermission || !mounted) return;

    try {
      final latest = await _appUsageService.getTodayAppUsage();

      if (mounted && latest != null) {
        setState(() {
          _usageSummary = latest;
        });
      }
    } catch (e) {
      debugPrint('백그라운드 데이터 갱신 중 오류: $e');
    }
  }

  Future<void> _openSettings() async {
    await _appUsageService.openUsageAccessSettings();
    // 설정에서 돌아온 후 권한 다시 확인
    if (mounted) {
      await _checkPermissionAndLoadData();
    }
  }

  Future<void> _refreshData() async {
    if (!Platform.isAndroid || !_hasPermission || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final latest = await _appUsageService.getTodayAppUsage();

      if (mounted) {
        setState(() {
          if (latest != null) {
            _usageSummary = latest;
          }
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('데이터 새로고침 중 오류: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!Platform.isAndroid) {
      return _buildUnsupportedPlatformMessage();
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_usageSummary == null) {
      return _buildNoDataMessage();
    }

    return _buildUsageStats();
  }

  Widget _buildUnsupportedPlatformMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '앱 사용 통계는 안드로이드에서만 지원됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_encryption_gmailerrorred,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              '앱 사용 통계를 보려면 권한이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '사용 접근 설정에서 이 앱에 권한을 부여해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('권한 설정하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('오늘의 앱 사용 통계가 없습니다.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
            label: Text(_isRefreshing ? '갱신 중...' : '새로고침'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // 스크롤 기능 제거
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8), // Header to TotalUsageCard 간격 조정
                _buildTotalUsageCard(),
                const SizedBox(
                  height: 16,
                ), // TotalUsageCard to "가장 많이 사용한 앱" title 간격 조정
                Text(
                  '가장 많이 사용한 앱',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(
                  height: 4,
                ), // "가장 많이 사용한 앱" title to TopAppsWidgets 간격 조정
                ..._buildTopAppsWidgets(),
              ],
            ),
          ),
        ),
        if (_isRefreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '오늘의 앱 사용 시간',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.black),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _isRefreshing ? null : _refreshData,
          tooltip: '새로고침',
        ),
      ],
    );
  }

  Widget _buildTotalUsageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time,
                size: 36,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('총 사용 시간', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    AppUsageService.formatUsageTime(
                      _usageSummary!.totalUsageTimeInMillis,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopAppsWidgets() {
    if (_usageSummary!.topApps.isEmpty) {
      return [
        const SizedBox(
          height: 120,
          child: Center(child: Text('앱 사용 기록이 없습니다.')),
        ),
      ];
    }

    return _usageSummary!.topApps.asMap().entries.map((entry) {
      final index = entry.key;
      final app = entry.value;

      // 순위별 색상
      final colors = [
        Colors.amber, // 1등
        Colors.blueGrey, // 2등
        Colors.teal, // 3등
      ];

      final color = index < colors.length ? colors[index] : Colors.grey;

      return Card(
        margin: const EdgeInsets.only(bottom: 8), // 앱 카드 간격 조정
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.apps, color: color),
          ),
          title: Text(
            app.appName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(AppUsageService.formatUsageTime(app.usageTimeInMillis)),
          ),
          trailing: _buildUsagePercentage(app, color),
        ),
      );
    }).toList();
  }

  Widget _buildUsagePercentage(AppUsageModel app, Color color) {
    final percentage =
        _usageSummary!.totalUsageTimeInMillis > 0
            ? (app.usageTimeInMillis /
                _usageSummary!.totalUsageTimeInMillis *
                100)
            : 0.0;

    final percentageStr = percentage.toStringAsFixed(1);

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: Text(
        '$percentageStr%',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
