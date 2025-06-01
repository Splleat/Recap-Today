import 'package:flutter/foundation.dart';
import 'package:recap_today/model/syncable_item_type.dart';
import 'package:recap_today/service/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncOverallState {
  idle,
  syncing,
  success,
  partialSuccess,
  error,
  cancelled,
}

class SyncSettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final SyncService _syncService;

  Map<SyncableItemType, bool> _selectedItems = {};
  Map<SyncableItemType, DateTime?> _lastSyncTimestamps = {};
  Map<SyncableItemType, bool> _unsyncedChangesStatus = {};
  SyncOverallState _currentOverallSyncState = SyncOverallState.idle;
  SyncableItemType? _currentSyncingItem;
  String _currentSyncingItemName = '';
  double _overallProgress = 0.0;
  Map<SyncableItemType, double> _itemProgress = {};
  bool _isCancelled = false;

  // Getters
  Map<SyncableItemType, bool> get selectedItems => _selectedItems;
  Map<SyncableItemType, DateTime?> get lastSyncTimestamps =>
      _lastSyncTimestamps;
  Map<SyncableItemType, bool> get unsyncedChangesStatus =>
      _unsyncedChangesStatus;
  SyncOverallState get currentOverallSyncState => _currentOverallSyncState;
  SyncableItemType? get currentSyncingItem => _currentSyncingItem;
  String get currentSyncingItemName => _currentSyncingItemName;
  double get overallProgress => _overallProgress;
  Map<SyncableItemType, double> get itemProgress => _itemProgress;
  bool get isCancelled => _isCancelled;

  bool get isAnyItemSelected =>
      _selectedItems.values.any((isSelected) => isSelected);

  SyncSettingsProvider(this._prefs, this._syncService) {
    // Initialize with default values for all syncable item types
    for (var itemType in SyncableItemType.values) {
      _selectedItems[itemType] = true; // Default to selected
      _lastSyncTimestamps[itemType] = null;
      _unsyncedChangesStatus[itemType] = false;
      _itemProgress[itemType] = 0.0;
    }
    loadSettings();
    refreshAllUnsyncedStatuses();
  }

  Future<void> loadSettings() async {
    for (var itemType in SyncableItemType.values) {
      _selectedItems[itemType] =
          _prefs.getBool('sync_selected_${itemType.name}') ?? true;
      final timestampMillis = _prefs.getInt(
        'sync_last_timestamp_${itemType.name}',
      );
      if (timestampMillis != null) {
        _lastSyncTimestamps[itemType] = DateTime.fromMillisecondsSinceEpoch(
          timestampMillis,
        );
      } else {
        _lastSyncTimestamps[itemType] = null;
      }
    }
    notifyListeners();
  }

  Future<void> saveSettings() async {
    for (var itemType in SyncableItemType.values) {
      await _prefs.setBool(
        'sync_selected_${itemType.name}',
        _selectedItems[itemType] ?? true,
      );
      final timestamp = _lastSyncTimestamps[itemType];
      if (timestamp != null) {
        await _prefs.setInt(
          'sync_last_timestamp_${itemType.name}',
          timestamp.millisecondsSinceEpoch,
        );
      } else {
        await _prefs.remove('sync_last_timestamp_${itemType.name}');
      }
    }
  }

  void toggleItemSelection(SyncableItemType item) {
    _selectedItems[item] = !(_selectedItems[item] ?? true);
    saveSettings();
    notifyListeners();
  }

  Future<void> refreshAllUnsyncedStatuses() async {
    for (var itemType in SyncableItemType.values) {
      // Use the last sync timestamp for the specific item type when checking for unsynced changes.
      _unsyncedChangesStatus[itemType] = await _syncService.hasUnsyncedChanges(
        itemType,
        lastSyncTimestamp: _lastSyncTimestamps[itemType],
      );
    }
    notifyListeners();
  }

  String getSubtitleForItem(SyncableItemType itemType) {
    final hasUnsynced = _unsyncedChangesStatus[itemType] ?? false;
    final lastSyncTime = _lastSyncTimestamps[itemType];

    if (hasUnsynced) {
      return 'Unsynced changes';
    } else if (lastSyncTime != null) {
      // Simple date formatting, consider using intl package for better formatting
      return 'Last synced: ${lastSyncTime.toLocal().toString().substring(0, 16)}';
    } else {
      return 'Not synced yet';
    }
  }

  void _calculateOverallProgress(int totalItemsToSync) {
    if (totalItemsToSync == 0) {
      _overallProgress = 0.0;
      notifyListeners();
      return;
    }
    double totalProgressSum = 0;
    // Sum progress only for items that are part of the current sync operation
    _selectedItems.forEach((itemType, isSelected) {
      if (isSelected && _itemProgress.containsKey(itemType)) {
        totalProgressSum += _itemProgress[itemType] ?? 0.0;
      }
    });
    _overallProgress = totalProgressSum / totalItemsToSync;
    notifyListeners();
  }

  Future<void> startSelectiveSync() async {
    _isCancelled = false;
    _currentOverallSyncState = SyncOverallState.syncing;
    _overallProgress = 0.0;
    _currentSyncingItem = null;
    _currentSyncingItemName = '';
    // Reset progress for all items, not just selected ones, to clear previous states
    for (var itemType in SyncableItemType.values) {
      _itemProgress[itemType] = 0.0;
    }
    notifyListeners();

    final itemsToSync =
        _selectedItems.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

    if (itemsToSync.isEmpty) {
      _currentOverallSyncState = SyncOverallState.idle;
      notifyListeners();
      return;
    }

    final totalItemsToSync = itemsToSync.length;

    Map<SyncableItemType, SyncItemResult> results = {};

    try {
      results = await _syncService.performSelectiveSync(
        itemsToSync,
        onItemProgressUpdate: (item, itemName, progress) {
          if (_isCancelled) return; // Stop updates if cancelled
          _currentSyncingItem = item;
          _currentSyncingItemName = itemName;
          _itemProgress[item] = progress;
          _calculateOverallProgress(totalItemsToSync);
          // notifyListeners() is called in _calculateOverallProgress
        },
        checkIfCancelledCallback: () => _isCancelled,
      );

      if (_isCancelled) {
        _currentOverallSyncState = SyncOverallState.cancelled;
      } else {
        bool allSuccess =
            results.isNotEmpty &&
            results.values.every((result) => result.success);
        bool anySuccess = results.values.any((result) => result.success);

        if (results.isEmpty && itemsToSync.isNotEmpty) {
          // This case implies an issue before any item could be processed or an unexpected empty result map
          _currentOverallSyncState = SyncOverallState.error;
        } else if (allSuccess) {
          _currentOverallSyncState = SyncOverallState.success;
        } else if (anySuccess) {
          _currentOverallSyncState = SyncOverallState.partialSuccess;
        } else {
          // No items succeeded or results map was empty for a reason other than cancellation
          _currentOverallSyncState = SyncOverallState.error;
        }

        // Update last sync timestamps for successfully synced items
        results.forEach((itemType, result) {
          if (result.success) {
            _lastSyncTimestamps[itemType] = DateTime.now();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during selective sync: $e');
      }
      _currentOverallSyncState = SyncOverallState.error;
    } finally {
      _currentSyncingItem =
          null; // Clear current syncing item regardless of outcome
      _currentSyncingItemName = '';

      if (!_isCancelled) {
        await refreshAllUnsyncedStatuses();
        await saveSettings(); // Save updated timestamps and potentially selections
      }
      // Ensure UI updates after all operations, especially if state changed rapidly (e.g. quick cancel)
      notifyListeners();
    }
  }

  void cancelSync() {
    if (_currentOverallSyncState == SyncOverallState.syncing) {
      _isCancelled = true;
      _currentOverallSyncState = SyncOverallState.cancelled;
      notifyListeners();
    }
  }

  String getOverallSyncStatusMessage() {
    switch (_currentOverallSyncState) {
      case SyncOverallState.idle:
        final lastOverallSync =
            _lastSyncTimestamps.values.where((d) => d != null).isNotEmpty
                ? _lastSyncTimestamps.values
                    .where((d) => d != null)
                    .map((d) => d!)
                    .reduce((a, b) => a.isAfter(b) ? a : b)
                : null;
        if (lastOverallSync != null) {
          return '마지막 동기화: ${lastOverallSync.toLocal().toString().substring(0, 16)}';
        }
        return '동기화 대기 중...';
      case SyncOverallState.syncing:
        return '';
      case SyncOverallState.success:
        return '모든 항목 동기화 성공.';
      case SyncOverallState.partialSuccess:
        return '일부 항목 동기화 성공. 자세한 내용은 각 항목을 확인하세요.';
      case SyncOverallState.error:
        return '동기화 중 오류 발생. 다시 시도해주세요.';
      case SyncOverallState.cancelled:
        return '동기화 취소됨.';
    }
  }
}
