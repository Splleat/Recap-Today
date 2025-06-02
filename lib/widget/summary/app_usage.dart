import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/appusage/app_usage_model.dart';
import 'package:recap_today/service/app_usage_service.dart';
import 'package:recap_today/model/appusage/app_usage_summary_model.dart';

class AppUsage extends StatefulWidget {
  final DateTime? date;
  const AppUsage({super.key, this.date});

  @override
  State<AppUsage> createState() => _AppUsageState();
}

class _AppUsageState extends State<AppUsage> {
  late AppUsageService _appUsageService;
  bool _isLoading = true;
  bool _hasPermission = false;
  AppUsageSummary? _usageSummary;

  late DateTime _displayedDate;
  late String _displayedDateString;
  bool _isDateToday = true;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    _displayedDate = widget.date ?? DateTime.now();
    _displayedDateString = DateFormat('yyyy-MM-dd').format(_displayedDate);

    final now = DateTime.now();
    _isDateToday =
        _displayedDate.year == now.year &&
        _displayedDate.month == now.month &&
        _displayedDate.day == now.day;

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    _appUsageService = AppUsageService(context.read());
    await _checkPermissionAndLoadData();
  }

  Future<void> _checkPermissionAndLoadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (Platform.isAndroid) {
        _hasPermission = await _appUsageService.hasUsageStatsPermission();

        if (_hasPermission) {
          final userId = Provider.of<String>(context, listen: false);
          final summary = await _appUsageService.getAppUsageSummaryForDate(userId, _displayedDateString);
          setState(() {
            _usageSummary = summary;
            _isLoading = false;
          });
          if (_isDateToday) await _refreshDataInBackground(userId);
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('앱 사용 통계 로드 중 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDataInBackground(String userId) async {
    if (!Platform.isAndroid || !_hasPermission || !_isDateToday || !mounted) return;
    try {
      final latest = await _appUsageService.fetchAndSaveAppUsageForDate(userId, DateTime.now());
      if (latest != null && mounted) {
        setState(() => _usageSummary = latest);
      }
    } catch (e) {
      debugPrint('백그라운드 데이터 갱신 오류: $e');
    }
  }

  Future<void> _openSettings() async {
    await _appUsageService.openUsageAccessSettings();
    if (mounted) await _checkPermissionAndLoadData();
  }

  Future<void> _refreshData() async {
    if (!Platform.isAndroid || !_hasPermission || _isRefreshing || !_isDateToday) return;

    setState(() => _isRefreshing = true);
    try {
      final userId = Provider.of<String>(context, listen: false);
      final latest = await _appUsageService.fetchAndSaveAppUsageForDate(userId, DateTime.now());
      if (latest != null && mounted) {
        setState(() {
          _usageSummary = latest;
          _isRefreshing = false;
        });
      } else {
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      debugPrint('새로고침 오류: $e');
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (!Platform.isAndroid) return _buildUnsupportedPlatformMessage();
    if (!_hasPermission) return _buildPermissionRequest();
    if (_usageSummary == null) return _buildNoDataMessage();
    return _buildUsageStats();
  }

  Widget _buildUnsupportedPlatformMessage() => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('앱 사용 통계는 안드로이드에서만 지원됩니다.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

  Widget _buildPermissionRequest() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_encryption_gmailerrorred, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('앱 사용 통계를 보려면 권한이 필요합니다.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('사용 접근 설정에서 이 앱에 권한을 부여해주세요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('권한 설정하기'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      );

  Widget _buildNoDataMessage() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isDateToday ? '오늘의 앱 사용 통계가 없습니다.' : '${DateFormat('M월 d일').format(_displayedDate)}의 앱 사용 통계가 없습니다.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_isRefreshing || !_isDateToday) ? null : _refreshData,
              icon: _isRefreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18),
              label: Text(_isRefreshing ? '갱신 중...' : '새로고침'),
            ),
          ],
        ),
      );

  Widget _buildUsageStats() => Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTotalUsageCard(),
                  const SizedBox(height: 24),
                  if (_usageSummary!.topApps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('자주 사용한 앱', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
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

  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isDateToday ? '오늘의 앱 사용 시간' : '${DateFormat('M월 d일').format(_displayedDate)} 앱 사용 시간',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: (_isRefreshing || !_isDateToday) ? null : _refreshData,
            tooltip: '새로고침',
          ),
        ],
      );

  Widget _buildTotalUsageCard() => Card(
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
                child: const Icon(Icons.access_time, size: 36, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('총 사용 시간', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      AppUsageService.formatUsageTime(_usageSummary!.totalUsageTimeInMillis),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> _buildTopAppsWidgets() => _usageSummary!.topApps.asMap().entries.map((entry) {
        final index = entry.key;
        final app = entry.value;
        final colors = [Colors.amber, Colors.blueGrey, Colors.teal];
        final color = index < colors.length ? colors[index] : Colors.grey;

        final percentage = _usageSummary!.totalUsageTimeInMillis > 0
            ? (app.usageTimeInMillis / _usageSummary!.totalUsageTimeInMillis * 100)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.apps, color: color),
            ),
            title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(AppUsageService.formatUsageTime(app.usageTimeInMillis)),
            ),
            trailing: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
              child: Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList();
}
