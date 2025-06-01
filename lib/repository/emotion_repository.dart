import 'package:recap_today/data/abstract_database.dart'; // Import AbstractDatabase
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';
import 'package:recap_today/model/sync_status.dart'
    as model_sync_status; // Added import

class EmotionRepository implements AbstractEmotionRepository {
  final AbstractDatabase _database; // Use AbstractDatabase

  EmotionRepository(this._database); // Constructor updated

  @override
  Future<void> addEmotionRecord(EmotionRecord record) async {
    try {
      // Updated to use the new saveEmotion method from AbstractDatabase
      await _database.saveEmotion(record);
    } catch (e) {
      print('Error adding emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmotionRecord(EmotionRecord record) async {
    try {
      // Updated to use the new saveEmotion method from AbstractDatabase
      await _database.saveEmotion(record);
    } catch (e) {
      print('Error updating emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour) async {
    try {
      // Updated to use the new getEmotionForHour method from AbstractDatabase
      return await _database.getEmotionForHour(date, hour);
    } catch (e) {
      print('Error getting emotion record for hour via repository: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date) async {
    try {
      // Updated to use the new getEmotionsForDate method from AbstractDatabase
      return await _database.getEmotionsForDate(date);
    } catch (e) {
      print('Error getting emotion records for day via repository: $e');
      return [];
    }
  }

  @override
  Future<void> deleteEmotionRecord(String id) async {
    try {
      // Updated to use the new deleteEmotion method from AbstractDatabase
      await _database.deleteEmotion(id);
    } catch (e) {
      print('Error deleting emotion record via repository: $e');
      rethrow;
    }
  }

  // Add new methods to align with AbstractEmotionRepository and AbstractDatabase
  @override
  Future<EmotionRecord?> getEmotionById(String id) async {
    try {
      return await _database.getEmotionById(id);
    } catch (e) {
      print('Error getting emotion by id via repository: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getUnsyncedEmotions() async {
    try {
      return await _database.getUnsyncedEmotions();
    } catch (e) {
      print('Error getting unsynced emotions via repository: $e');
      return [];
    }
  }

  @override
  Future<void> markEmotionsAsSynced(List<String> ids, DateTime syncTime) async {
    try {
      await _database.markEmotionsAsSynced(
        ids,
        syncTime, // Corrected: Pass the syncTime DateTime object directly
      );
    } catch (e) {
      print('Error marking emotions as synced via repository: $e');
      rethrow;
    }
  }

  // Method to handle synchronization of emotion data from a server source
  // This method demonstrates the fix for the String to DateTime conversion error
  Future<void> consolidateServerEmotions(
    List<Map<String, dynamic>> serverEmotionsData,
  ) async {
    for (var serverEmotionMap in serverEmotionsData) {
      final clientTempId = serverEmotionMap['clientTempId'] as String?;
      final serverId = serverEmotionMap['id'] as String?;

      EmotionRecord? localEmotion;
      if (serverId != null) {
        localEmotion = await _database.getEmotionById(serverId);
      }
      // If not found by serverId, try clientTempId (in case it was a newly created item)
      if (localEmotion == null && clientTempId != null) {
        // This assumes getEmotionById can also fetch by a client-generated temporary ID
        // or that another mechanism exists to map clientTempId to a stored record.
        // For simplicity, we'll assume getEmotionById might handle this or it's a new record.
        // A more robust solution might involve a specific query for clientTempId if it's stored.
      }

      DateTime? processedDateTime;
      final dateStringFromServer = serverEmotionMap['date'] as String?;

      if (dateStringFromServer != null) {
        // Correctly parse the string date from the server to a DateTime object.
        // This addresses the "String to DateTime conversion error".
        processedDateTime = DateTime.tryParse(dateStringFromServer);
      } else {
        processedDateTime = null;
      }

      // Format the parsed DateTime object back to 'YYYY-MM-DD' string for EmotionRecord.date
      String? finalDateStringForRecord;
      if (processedDateTime != null) {
        finalDateStringForRecord =
            "${processedDateTime.year.toString().padLeft(4, '0')}-${processedDateTime.month.toString().padLeft(2, '0')}-${processedDateTime.day.toString().padLeft(2, '0')}";
      }

      final hourFromServer = serverEmotionMap['hour'] as int?;
      final emotionTypeFromServer = serverEmotionMap['emotionType'] as String?;

      // Ensure essential data (like hour and emotionType) is present before creating/updating.
      if (hourFromServer == null || emotionTypeFromServer == null) {
        print(
          "Skipping emotion record due to missing hour or emotionType: ${serverEmotionMap['id']}",
        );
        continue;
      }

      if (localEmotion != null) {
        // Update existing emotion
        await _database.saveEmotion(
          localEmotion.copyWith(
            date:
                finalDateStringForRecord ??
                localEmotion.date, // Use parsed date if available
            hour: hourFromServer, // Use server hour
            emotionType: emotionTypeFromServer, // Use server emotionType
            notes:
                serverEmotionMap['notes'] as String? ??
                localEmotion.notes, // Preserve local notes if server's is null
            isDeleted:
                serverEmotionMap['isDeleted'] as bool? ??
                localEmotion.isDeleted,
            syncStatus: model_sync_status.SyncStatus.synced, // Mark as synced
            updatedAt: DateTime.now(), // Update timestamp
            lastSynced: DateTime.now(),
          ),
        );
      } else {
        // Create new emotion if we have a serverId and a valid formatted date string
        if (serverId != null && finalDateStringForRecord != null) {
          await _database.saveEmotion(
            EmotionRecord(
              id: serverId,
              date: finalDateStringForRecord,
              hour: hourFromServer,
              emotionType: emotionTypeFromServer,
              notes: serverEmotionMap['notes'] as String?,
              isDeleted: serverEmotionMap['isDeleted'] as bool? ?? false,
              syncStatus: model_sync_status.SyncStatus.synced,
              updatedAt: DateTime.now(),
              lastSynced: DateTime.now(),
            ),
          );
        } else {
          print(
            "Skipping creation of new emotion from server due to missing serverId or unparsable date: ${serverEmotionMap}",
          );
        }
      }
    }
  }
}
