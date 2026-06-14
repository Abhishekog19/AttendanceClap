class TimetableEntry {
  /// Firestore document ID — null for in-memory / OCR-created entries.
  final String? id;
  final String subject;
  final String day; // "Monday", "Tuesday", etc.
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final String? faculty;
  final String? room;
  final double confidence;

  const TimetableEntry({
    this.id,
    required this.subject,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.faculty,
    this.room,
    this.confidence = 1.0,
  });

  bool get isLowConfidence => confidence < 0.7;

  TimetableEntry copyWith({
    String? id,
    String? subject,
    String? day,
    String? startTime,
    String? endTime,
    String? faculty,
    String? room,
    double? confidence,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      faculty: faculty ?? this.faculty,
      room: room ?? this.room,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Serialise to Firestore — does NOT include the doc ID.
  Map<String, dynamic> toMap() => {
        'subject': subject,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'faculty': faculty,
        'room': room,
        'confidence': confidence,
      };

  /// Deserialise from a raw map (no doc ID — used for OCR / review).
  factory TimetableEntry.fromMap(Map<String, dynamic> map) => TimetableEntry(
        subject: map['subject'] as String,
        day: map['day'] as String,
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
        faculty: map['faculty'] as String?,
        room: map['room'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  /// Deserialise from Firestore — includes the document ID.
  factory TimetableEntry.fromFirestore(
          Map<String, dynamic> map, String docId) =>
      TimetableEntry(
        id: docId,
        subject: map['subject'] as String? ?? '',
        day: map['day'] as String? ?? 'Monday',
        startTime: map['startTime'] as String? ?? '00:00',
        endTime: map['endTime'] as String? ?? '00:00',
        faculty: map['faculty'] as String?,
        room: map['room'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  /// Parse from Groq API response: `{ "subject": ..., ... }` inside a day key.
  factory TimetableEntry.fromApiEntry(Map<String, dynamic> entry, String day) =>
      TimetableEntry(
        subject: entry['subject'] as String,
        day: day,
        startTime: entry['startTime'] as String,
        endTime: entry['endTime'] as String,
        faculty: entry['faculty'] as String?,
        room: entry['room'] as String?,
        confidence: (entry['confidence'] as num?)?.toDouble() ?? 0.8,
      );
}
