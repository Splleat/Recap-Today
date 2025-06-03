import 'dart:async';
import 'package:flutter/material.dart';
import '../model/location_model.dart';
import '../api/location_service.dart';
import '../service/location_tracking_service.dart';

/// 위치/동선 전역 상태 관리 Provider
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final LocationTrackingService _trackingService;

  DailyLocationData? _locationData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  DateTime? _date;
  StreamSubscription? _locationLogSubscription;

  LocationProvider(this._locationService, this._trackingService);

  DailyLocationData? get locationData => _locationData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLocationData(String userId, DateTime date) async {
    debugPrint(
      '[LocationProvider] loadLocationData called: userId=$userId, date=$date',
    );
    _userId = userId;
    _date = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dateString = _dateString(date);
      _locationData = await _locationService.fetchLocationDataForDate(
        userId,
        dateString,
      );
      // [DEBUG] Print loaded location data
      if (_locationData != null) {
        debugPrint(
          '[LocationProvider] Loaded locations: count=${_locationData!.locations.length}',
        );
        if (_locationData!.locations.isNotEmpty) {
          final first = _locationData!.locations.first;
          debugPrint(
            '[LocationProvider] First location: lat=${first.latitude}, lng=${first.longitude}, ts=${first.timestamp}',
          );
        }
      } else {
        debugPrint('[LocationProvider] _locationData is null');
      }
      // 오늘이고 데이터가 없으면 현재 위치 저장
      if (_locationData != null &&
          _locationData!.locations.isEmpty &&
          _dateString(date) == _dateString(DateTime.now())) {
        try {
          await _trackingService.saveCurrentLocation(userId);
          _locationData = await _locationService.fetchLocationDataForDate(
            userId,
            dateString,
          );
          debugPrint(
            '[LocationProvider] After saveCurrentLocation, loaded: count=${_locationData!.locations.length}',
          );
        } catch (e) {
          debugPrint('[LocationProvider] saveCurrentLocation failed: $e');
        }
        notifyListeners();
      }
      _isLoading = false;
      notifyListeners();
      _setupLocationLogListener();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '위치 데이터를 불러오는 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }

  void _setupLocationLogListener() {
    _locationLogSubscription?.cancel();
    if (_userId != null && _date != null) {
      _locationLogSubscription = _trackingService.locationLogStream.listen((
        _,
      ) async {
        await loadLocationData(_userId!, _date!);
      });
    }
  }

  @override
  void dispose() {
    _locationLogSubscription?.cancel();
    super.dispose();
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
