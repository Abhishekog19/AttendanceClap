class TimetableEntry {
  /// Firestore document ID — null for in-memory / OCR-created entries.
  final String? id;

  /// Foreign key to the subjects collection.
  /// Null on documents created before this field was added (graceful degradation).
  /// After the sprint: ALL new entries have this populated.
  /// Rule: subjectId is the ONLY relationship key. subject (name) is display-only.
  final String? subjectId;

  /// Display name — stored for convenience but must NOT be used as a join key.
  /// Source of truth for the name is always subjects/{subjectId}.name.
  final String subject;

  final String day; // "Monday", "Tuesday", etc.
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final String? faculty;
  final String? room;
  final double confidence;

  const TimetableEntry({
    this.id,
    this.subjectId,
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
    Object? subjectId = _sentinel,
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
      subjectId: subjectId == _sentinel ? this.subjectId : subjectId as String?,
      subject: subject ?? this.subject,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      faculty: faculty ?? this.faculty,
      room: room ?? this.room,
      confidence: confidence ?? this.confidence,
    );
  }

  static const _sentinel = Object();

  /// Serialise to Firestore — does NOT include the doc ID.
  Map<String, dynamic> toMap() => {
        if (subjectId != null) 'subjectId': subjectId,
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
        subjectId: map['subjectId'] as String?,
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
        subjectId: map['subjectId'] as String?,
        subject: map['subject'] as String? ?? '',
        day: map['day'] as String? ?? 'Monday',
        startTime: map['startTime'] as String? ?? '00:00',
        endTime: map['endTime'] as String? ?? '00:00',
        faculty: map['faculty'] as String?,
        room: map['room'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  /// Parse from Groq API response: `{ "subject": ..., ... }` inside a day key.
  /// subjectId is resolved later in the save pipeline via createSubjectsFromTimetable.
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
