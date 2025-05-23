class EmotionRecord {
  final String?
  id; // Changed to String to support UUID or other string-based IDs if needed, and nullable for new records
  final String date; // YYYY-MM-DD format
  final int hour; // 0-23
  final String emotionType; // e.g., "Happy", "Sad", "Neutral"
  final String? notes; // Optional notes for the emotion

  EmotionRecord({
    this.id,
    required this.date,
    required this.hour,
    required this.emotionType,
    this.notes,
  });

  // Method to convert EmotionRecord to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'hour': hour,
      'emotionType': emotionType,
      'notes': notes,
    };
  }

  // Method to create an EmotionRecord from a Map (from database)
  factory EmotionRecord.fromMap(Map<String, dynamic> map) {
    return EmotionRecord(
      id: map['id'] as String?,
      date: map['date'] as String,
      hour: map['hour'] as int,
      emotionType: map['emotionType'] as String,
      notes: map['notes'] as String?,
    );
  }

  EmotionRecord copyWith({
    String? id,
    String? date,
    int? hour,
    String? emotionType,
    String? notes,
    bool clearId = false, // Added to allow explicitly setting id to null
    bool clearNotes =
        false, // Renamed from setNotesToNull for consistency & clarity
  }) {
    return EmotionRecord(
      id: clearId ? null : (id ?? this.id),
      date: date ?? this.date,
      hour: hour ?? this.hour,
      emotionType: emotionType ?? this.emotionType,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
