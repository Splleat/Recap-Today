import 'package:flutter/material.dart';
import 'package:recap_today/service/sync_service.dart'; // Assuming SyncService is in this path
import 'package:intl/intl.dart'; // For date formatting
import 'package:recap_today/model/syncable_item_type.dart'; // Added import

enum SyncState { idle, syncing, success, error }

class SyncProvider with ChangeNotifier {
  final SyncService _syncService;

  SyncProvider(this._syncService) {
    _loadLastSyncTime();
  }

  SyncState _syncState = SyncState.idle;
  SyncState get syncState => _syncState;

  String? _lastSyncTime;
  String? get lastSyncTime => _lastSyncTime;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> _loadLastSyncTime() async {
    // final timestamp = await _syncService.getLastSyncTimestamp(); // Original incorrect call
    // For now, let's assume we want the diary's last sync time for the general display.
    // This might need to be more sophisticated later if different item types are displayed.
    final timestamp = await _syncService.getLastSyncTimestampForItem(
      SyncableItemType.diary,
    );
    if (timestamp != null) {
      _lastSyncTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
    } else {
      _lastSyncTime = 'Never synced';
    }
    notifyListeners();
  }

  Future<void> triggerSync() async {
    _syncState = SyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      await _syncService.syncAllData();
      _syncState = SyncState.success;
      await _loadLastSyncTime(); // Refresh last sync time
    } catch (e) {
      _syncState = SyncState.error;
      _errorMessage = e.toString();
      print('Error during sync: $e');
    } finally {
      notifyListeners();
      // Optionally, revert to idle state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_syncState == SyncState.success || _syncState == SyncState.error) {
          _syncState = SyncState.idle;
          notifyListeners();
        }
      });
    }
  }
}
