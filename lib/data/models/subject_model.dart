import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─── Subject Color Palette ─────────────────────────────────────────────────────

/// Fixed 12-color palette for auto-assigning subject colors.
/// Colors are mid-saturation hues that look good as cell fills.
const kSubjectColorPalette = [
  '#E57373', // Red
  '#FF8A65', // Deep Orange
  '#FFB74D', // Orange
  '#FFD54F', // Amber
  '#81C784', // Green
  '#4DB6AC', // Teal
  '#4FC3F7', // Light Blue
  '#7986CB', // Indigo
  '#BA68C8', // Purple
  '#F06292', // Pink
  '#A1887F', // Brown
  '#90A4AE', // Blue Grey
];

/// Returns the next unused color from the palette given existing colors.
/// Cycles through the palette if all are used.
String nextSubjectColor(List<String> usedColors) {
  for (final c in kSubjectColorPalette) {
    if (!usedColors.contains(c)) return c;
  }
  return kSubjectColorPalette[usedColors.length % kSubjectColorPalette.length];
}

/// Auto-generates a short name from a full subject name.
/// Examples: "Data Structures" → "DS", "Operating System" → "OS", "Maths" → "MTH"
String generateSubjectShortName(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return words
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join()
        .substring(0, words.length.clamp(1, 4));
  }
  final upper = name.toUpperCase();
  return upper.length <= 4 ? upper : upper.substring(0, 4);
}

// ─── SubjectModel ──────────────────────────────────────────────────────────────

class SubjectModel extends Equatable {
  final String id;
  final String name;
  final int attendedClasses;
  final int totalClasses;
  final String? faculty;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Per-subject attendance target percentage (0–100).
  /// If null, the global [UserModel.attendanceGoal] is used instead.
  /// Set during onboarding Subject Setup and editable afterwards.
  final double? attendanceTarget;

  /// Hex color string from [kSubjectColorPalette], e.g. "#E57373".
  /// Auto-assigned on creation if not provided.
  final String? colorHex;

  /// Short display name shown in timetable grid cells, e.g. "DS", "OS".
  /// Auto-generated from [name] if not provided.
  final String? shortName;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.attendedClasses,
    required this.totalClasses,
    this.faculty,
    required this.createdAt,
    required this.updatedAt,
    this.attendanceTarget,
    this.colorHex,
    this.shortName,
  });

  double get attendancePercentage =>
      totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

  /// The effective color hex — falls back to the first palette color if unset.
  String get effectiveColorHex => colorHex ?? kSubjectColorPalette[0];

  /// The effective short name — falls back to auto-generated if unset.
  String get effectiveShortName => shortName ?? generateSubjectShortName(name);

  factory SubjectModel.fromJson(Map<String, dynamic> json, String docId) {
    return SubjectModel(
      id: docId,
      name: json['name'] as String? ?? '',
      attendedClasses: (json['attendedClasses'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      faculty: json['faculty'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendanceTarget: (json['attendanceTarget'] as num?)?.toDouble(),
      colorHex: json['colorHex'] as String?,
      shortName: json['shortName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'attendedClasses': attendedClasses,
      'totalClasses': totalClasses,
      'faculty': faculty,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (attendanceTarget != null) 'attendanceTarget': attendanceTarget,
      if (colorHex != null) 'colorHex': colorHex,
      if (shortName != null) 'shortName': shortName,
    };
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    int? attendedClasses,
    int? totalClasses,
    String? faculty,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? attendanceTarget = _sentinel,
    Object? colorHex = _sentinel,
    Object? shortName = _sentinel,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      totalClasses: totalClasses ?? this.totalClasses,
      faculty: faculty ?? this.faculty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendanceTarget: attendanceTarget == _sentinel
          ? this.attendanceTarget
          : attendanceTarget as double?,
      colorHex: colorHex == _sentinel ? this.colorHex : colorHex as String?,
      shortName: shortName == _sentinel ? this.shortName : shortName as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
        id,
        name,
        attendedClasses,
        totalClasses,
        faculty,
        createdAt,
        updatedAt,
        attendanceTarget,
        colorHex,
        shortName,
      ];
}
