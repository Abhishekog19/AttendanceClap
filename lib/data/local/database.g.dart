// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, Semester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
      'start_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
      'end_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
      'is_active', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, startDate, endDate, createdAt, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(Insertable<Semester> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Semester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Semester(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class Semester extends DataClass implements Insertable<Semester> {
  /// UUID primary key.
  final String id;

  /// Human-readable label e.g. "Semester 3". NULL is allowed.
  final String? name;

  /// Start date — Unix timestamp (ms), midnight UTC.
  final int startDate;

  /// End date — Unix timestamp (ms), midnight UTC.
  final int endDate;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;

  /// BOOLEAN (0/1). Only one semester should be active at a time;
  /// managed via app_settings.active_semester_id.
  final int isActive;
  const Semester(
      {required this.id,
      this.name,
      required this.startDate,
      required this.endDate,
      required this.createdAt,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    map['created_at'] = Variable<int>(createdAt);
    map['is_active'] = Variable<int>(isActive);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory Semester.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Semester(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isActive: serializer.fromJson<int>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'isActive': serializer.toJson<int>(isActive),
    };
  }

  Semester copyWith(
          {String? id,
          Value<String?> name = const Value.absent(),
          int? startDate,
          int? endDate,
          int? createdAt,
          int? isActive}) =>
      Semester(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );
  Semester copyWithCompanion(SemestersCompanion data) {
    return Semester(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Semester(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, startDate, endDate, createdAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class SemestersCompanion extends UpdateCompanion<Semester> {
  final Value<String> id;
  final Value<String?> name;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<int> createdAt;
  final Value<int> isActive;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required int startDate,
    required int endDate,
    required int createdAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startDate = Value(startDate),
        endDate = Value(endDate),
        createdAt = Value(createdAt);
  static Insertable<Semester> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<int>? createdAt,
    Expression<int>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? name,
      Value<int>? startDate,
      Value<int>? endDate,
      Value<int>? createdAt,
      Value<int>? isActive,
      Value<int>? rowid}) {
    return SemestersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SemesterHolidaysTable extends SemesterHolidays
    with TableInfo<$SemesterHolidaysTable, SemesterHoliday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemesterHolidaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _semesterIdMeta =
      const VerificationMeta('semesterId');
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
      'semester_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES semesters (id) ON DELETE CASCADE'));
  static const VerificationMeta _holidayDateMeta =
      const VerificationMeta('holidayDate');
  @override
  late final GeneratedColumn<int> holidayDate = GeneratedColumn<int>(
      'holiday_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, semesterId, holidayDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semester_holidays';
  @override
  VerificationContext validateIntegrity(Insertable<SemesterHoliday> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
          _semesterIdMeta,
          semesterId.isAcceptableOrUnknown(
              data['semester_id']!, _semesterIdMeta));
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('holiday_date')) {
      context.handle(
          _holidayDateMeta,
          holidayDate.isAcceptableOrUnknown(
              data['holiday_date']!, _holidayDateMeta));
    } else if (isInserting) {
      context.missing(_holidayDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {semesterId, holidayDate},
      ];
  @override
  SemesterHoliday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterHoliday(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      semesterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester_id'])!,
      holidayDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}holiday_date'])!,
    );
  }

  @override
  $SemesterHolidaysTable createAlias(String alias) {
    return $SemesterHolidaysTable(attachedDatabase, alias);
  }
}

class SemesterHoliday extends DataClass implements Insertable<SemesterHoliday> {
  /// Auto-increment surrogate PK. No UUID needed for this join table.
  final int id;

  /// FK → semesters.id, ON DELETE CASCADE.
  final String semesterId;

  /// Holiday date — Unix timestamp (ms), midnight UTC.
  final int holidayDate;
  const SemesterHoliday(
      {required this.id, required this.semesterId, required this.holidayDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<String>(semesterId);
    map['holiday_date'] = Variable<int>(holidayDate);
    return map;
  }

  SemesterHolidaysCompanion toCompanion(bool nullToAbsent) {
    return SemesterHolidaysCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      holidayDate: Value(holidayDate),
    );
  }

  factory SemesterHoliday.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterHoliday(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      holidayDate: serializer.fromJson<int>(json['holidayDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<String>(semesterId),
      'holidayDate': serializer.toJson<int>(holidayDate),
    };
  }

  SemesterHoliday copyWith({int? id, String? semesterId, int? holidayDate}) =>
      SemesterHoliday(
        id: id ?? this.id,
        semesterId: semesterId ?? this.semesterId,
        holidayDate: holidayDate ?? this.holidayDate,
      );
  SemesterHoliday copyWithCompanion(SemesterHolidaysCompanion data) {
    return SemesterHoliday(
      id: data.id.present ? data.id.value : this.id,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      holidayDate:
          data.holidayDate.present ? data.holidayDate.value : this.holidayDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemesterHoliday(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('holidayDate: $holidayDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, semesterId, holidayDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterHoliday &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.holidayDate == this.holidayDate);
}

class SemesterHolidaysCompanion extends UpdateCompanion<SemesterHoliday> {
  final Value<int> id;
  final Value<String> semesterId;
  final Value<int> holidayDate;
  const SemesterHolidaysCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.holidayDate = const Value.absent(),
  });
  SemesterHolidaysCompanion.insert({
    this.id = const Value.absent(),
    required String semesterId,
    required int holidayDate,
  })  : semesterId = Value(semesterId),
        holidayDate = Value(holidayDate);
  static Insertable<SemesterHoliday> custom({
    Expression<int>? id,
    Expression<String>? semesterId,
    Expression<int>? holidayDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (holidayDate != null) 'holiday_date': holidayDate,
    });
  }

  SemesterHolidaysCompanion copyWith(
      {Value<int>? id, Value<String>? semesterId, Value<int>? holidayDate}) {
    return SemesterHolidaysCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      holidayDate: holidayDate ?? this.holidayDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (holidayDate.present) {
      map['holiday_date'] = Variable<int>(holidayDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemesterHolidaysCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('holidayDate: $holidayDate')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attendedClassesMeta =
      const VerificationMeta('attendedClasses');
  @override
  late final GeneratedColumn<int> attendedClasses = GeneratedColumn<int>(
      'attended_classes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalClassesMeta =
      const VerificationMeta('totalClasses');
  @override
  late final GeneratedColumn<int> totalClasses = GeneratedColumn<int>(
      'total_classes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _facultyMeta =
      const VerificationMeta('faculty');
  @override
  late final GeneratedColumn<String> faculty = GeneratedColumn<String>(
      'faculty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attendanceTargetMeta =
      const VerificationMeta('attendanceTarget');
  @override
  late final GeneratedColumn<double> attendanceTarget = GeneratedColumn<double>(
      'attendance_target', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _shortNameMeta =
      const VerificationMeta('shortName');
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
      'short_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        attendedClasses,
        totalClasses,
        faculty,
        attendanceTarget,
        colorHex,
        shortName,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<Subject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('attended_classes')) {
      context.handle(
          _attendedClassesMeta,
          attendedClasses.isAcceptableOrUnknown(
              data['attended_classes']!, _attendedClassesMeta));
    }
    if (data.containsKey('total_classes')) {
      context.handle(
          _totalClassesMeta,
          totalClasses.isAcceptableOrUnknown(
              data['total_classes']!, _totalClassesMeta));
    }
    if (data.containsKey('faculty')) {
      context.handle(_facultyMeta,
          faculty.isAcceptableOrUnknown(data['faculty']!, _facultyMeta));
    }
    if (data.containsKey('attendance_target')) {
      context.handle(
          _attendanceTargetMeta,
          attendanceTarget.isAcceptableOrUnknown(
              data['attendance_target']!, _attendanceTargetMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('short_name')) {
      context.handle(_shortNameMeta,
          shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      attendedClasses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attended_classes'])!,
      totalClasses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_classes'])!,
      faculty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faculty']),
      attendanceTarget: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}attendance_target']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      shortName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}short_name']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  /// UUID primary key.
  final String id;

  /// Full subject name, e.g. "Data Structures".
  final String name;

  /// Running count of attended classes (present + late).
  final int attendedClasses;

  /// Running count of all classes held (excludes cancelled).
  final int totalClasses;

  /// Optional faculty/professor name.
  final String? faculty;

  /// Per-subject attendance target override.
  /// NULL means use AppSettings.attendance_goal.
  final double? attendanceTarget;

  /// Hex color string e.g. "#E57373".
  /// NULL means use auto-assigned from palette.
  final String? colorHex;

  /// Short display name e.g. "DS".
  /// NULL means auto-derive from name at read time.
  final String? shortName;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;

  /// Last-modified timestamp — Unix timestamp (ms).
  /// Must be updated on every write.
  final int updatedAt;
  const Subject(
      {required this.id,
      required this.name,
      required this.attendedClasses,
      required this.totalClasses,
      this.faculty,
      this.attendanceTarget,
      this.colorHex,
      this.shortName,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['attended_classes'] = Variable<int>(attendedClasses);
    map['total_classes'] = Variable<int>(totalClasses);
    if (!nullToAbsent || faculty != null) {
      map['faculty'] = Variable<String>(faculty);
    }
    if (!nullToAbsent || attendanceTarget != null) {
      map['attendance_target'] = Variable<double>(attendanceTarget);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || shortName != null) {
      map['short_name'] = Variable<String>(shortName);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      attendedClasses: Value(attendedClasses),
      totalClasses: Value(totalClasses),
      faculty: faculty == null && nullToAbsent
          ? const Value.absent()
          : Value(faculty),
      attendanceTarget: attendanceTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(attendanceTarget),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      shortName: shortName == null && nullToAbsent
          ? const Value.absent()
          : Value(shortName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      attendedClasses: serializer.fromJson<int>(json['attendedClasses']),
      totalClasses: serializer.fromJson<int>(json['totalClasses']),
      faculty: serializer.fromJson<String?>(json['faculty']),
      attendanceTarget: serializer.fromJson<double?>(json['attendanceTarget']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      shortName: serializer.fromJson<String?>(json['shortName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'attendedClasses': serializer.toJson<int>(attendedClasses),
      'totalClasses': serializer.toJson<int>(totalClasses),
      'faculty': serializer.toJson<String?>(faculty),
      'attendanceTarget': serializer.toJson<double?>(attendanceTarget),
      'colorHex': serializer.toJson<String?>(colorHex),
      'shortName': serializer.toJson<String?>(shortName),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Subject copyWith(
          {String? id,
          String? name,
          int? attendedClasses,
          int? totalClasses,
          Value<String?> faculty = const Value.absent(),
          Value<double?> attendanceTarget = const Value.absent(),
          Value<String?> colorHex = const Value.absent(),
          Value<String?> shortName = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      Subject(
        id: id ?? this.id,
        name: name ?? this.name,
        attendedClasses: attendedClasses ?? this.attendedClasses,
        totalClasses: totalClasses ?? this.totalClasses,
        faculty: faculty.present ? faculty.value : this.faculty,
        attendanceTarget: attendanceTarget.present
            ? attendanceTarget.value
            : this.attendanceTarget,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        shortName: shortName.present ? shortName.value : this.shortName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      attendedClasses: data.attendedClasses.present
          ? data.attendedClasses.value
          : this.attendedClasses,
      totalClasses: data.totalClasses.present
          ? data.totalClasses.value
          : this.totalClasses,
      faculty: data.faculty.present ? data.faculty.value : this.faculty,
      attendanceTarget: data.attendanceTarget.present
          ? data.attendanceTarget.value
          : this.attendanceTarget,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('attendedClasses: $attendedClasses, ')
          ..write('totalClasses: $totalClasses, ')
          ..write('faculty: $faculty, ')
          ..write('attendanceTarget: $attendanceTarget, ')
          ..write('colorHex: $colorHex, ')
          ..write('shortName: $shortName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, attendedClasses, totalClasses,
      faculty, attendanceTarget, colorHex, shortName, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.name == this.name &&
          other.attendedClasses == this.attendedClasses &&
          other.totalClasses == this.totalClasses &&
          other.faculty == this.faculty &&
          other.attendanceTarget == this.attendanceTarget &&
          other.colorHex == this.colorHex &&
          other.shortName == this.shortName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> attendedClasses;
  final Value<int> totalClasses;
  final Value<String?> faculty;
  final Value<double?> attendanceTarget;
  final Value<String?> colorHex;
  final Value<String?> shortName;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.attendedClasses = const Value.absent(),
    this.totalClasses = const Value.absent(),
    this.faculty = const Value.absent(),
    this.attendanceTarget = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.shortName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String name,
    this.attendedClasses = const Value.absent(),
    this.totalClasses = const Value.absent(),
    this.faculty = const Value.absent(),
    this.attendanceTarget = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.shortName = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Subject> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? attendedClasses,
    Expression<int>? totalClasses,
    Expression<String>? faculty,
    Expression<double>? attendanceTarget,
    Expression<String>? colorHex,
    Expression<String>? shortName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (attendedClasses != null) 'attended_classes': attendedClasses,
      if (totalClasses != null) 'total_classes': totalClasses,
      if (faculty != null) 'faculty': faculty,
      if (attendanceTarget != null) 'attendance_target': attendanceTarget,
      if (colorHex != null) 'color_hex': colorHex,
      if (shortName != null) 'short_name': shortName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? attendedClasses,
      Value<int>? totalClasses,
      Value<String?>? faculty,
      Value<double?>? attendanceTarget,
      Value<String?>? colorHex,
      Value<String?>? shortName,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      totalClasses: totalClasses ?? this.totalClasses,
      faculty: faculty ?? this.faculty,
      attendanceTarget: attendanceTarget ?? this.attendanceTarget,
      colorHex: colorHex ?? this.colorHex,
      shortName: shortName ?? this.shortName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (attendedClasses.present) {
      map['attended_classes'] = Variable<int>(attendedClasses.value);
    }
    if (totalClasses.present) {
      map['total_classes'] = Variable<int>(totalClasses.value);
    }
    if (faculty.present) {
      map['faculty'] = Variable<String>(faculty.value);
    }
    if (attendanceTarget.present) {
      map['attendance_target'] = Variable<double>(attendanceTarget.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('attendedClasses: $attendedClasses, ')
          ..write('totalClasses: $totalClasses, ')
          ..write('faculty: $faculty, ')
          ..write('attendanceTarget: $attendanceTarget, ')
          ..write('colorHex: $colorHex, ')
          ..write('shortName: $shortName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimetableEntriesTable extends TimetableEntries
    with TableInfo<$TimetableEntriesTable, TimetableEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimetableEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subjects (id) ON DELETE CASCADE'));
  static const VerificationMeta _semesterIdMeta =
      const VerificationMeta('semesterId');
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
      'semester_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES semesters (id) ON DELETE RESTRICT'));
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _facultyMeta =
      const VerificationMeta('faculty');
  @override
  late final GeneratedColumn<String> faculty = GeneratedColumn<String>(
      'faculty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
      'room', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        semesterId,
        dayOfWeek,
        startTime,
        endTime,
        faculty,
        room,
        confidence,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timetable_entries';
  @override
  VerificationContext validateIntegrity(Insertable<TimetableEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
          _semesterIdMeta,
          semesterId.isAcceptableOrUnknown(
              data['semester_id']!, _semesterIdMeta));
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('faculty')) {
      context.handle(_facultyMeta,
          faculty.isAcceptableOrUnknown(data['faculty']!, _facultyMeta));
    }
    if (data.containsKey('room')) {
      context.handle(
          _roomMeta, room.isAcceptableOrUnknown(data['room']!, _roomMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimetableEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimetableEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      semesterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester_id'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_week'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      faculty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faculty']),
      room: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TimetableEntriesTable createAlias(String alias) {
    return $TimetableEntriesTable(attachedDatabase, alias);
  }
}

class TimetableEntry extends DataClass implements Insertable<TimetableEntry> {
  /// UUID primary key.
  final String id;

  /// FK → subjects.id, ON DELETE CASCADE.
  final String subjectId;

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2/OQ-4).
  final String semesterId;

  /// ISO weekday: 1=Monday … 7=Sunday. Replaces the string "Monday" field.
  final int dayOfWeek;

  /// "HH:MM" 24-hour format.
  final String startTime;

  /// "HH:MM" 24-hour format.
  final String endTime;

  /// Faculty name — may differ from subject-level faculty.
  final String? faculty;

  /// Room/location.
  final String? room;

  /// OCR confidence score. Values below 0.7 are flagged as low-confidence.
  final double confidence;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;
  const TimetableEntry(
      {required this.id,
      required this.subjectId,
      required this.semesterId,
      required this.dayOfWeek,
      required this.startTime,
      required this.endTime,
      this.faculty,
      this.room,
      required this.confidence,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['semester_id'] = Variable<String>(semesterId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    if (!nullToAbsent || faculty != null) {
      map['faculty'] = Variable<String>(faculty);
    }
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    map['confidence'] = Variable<double>(confidence);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TimetableEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimetableEntriesCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      semesterId: Value(semesterId),
      dayOfWeek: Value(dayOfWeek),
      startTime: Value(startTime),
      endTime: Value(endTime),
      faculty: faculty == null && nullToAbsent
          ? const Value.absent()
          : Value(faculty),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      confidence: Value(confidence),
      createdAt: Value(createdAt),
    );
  }

  factory TimetableEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimetableEntry(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      faculty: serializer.fromJson<String?>(json['faculty']),
      room: serializer.fromJson<String?>(json['room']),
      confidence: serializer.fromJson<double>(json['confidence']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'semesterId': serializer.toJson<String>(semesterId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'faculty': serializer.toJson<String?>(faculty),
      'room': serializer.toJson<String?>(room),
      'confidence': serializer.toJson<double>(confidence),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  TimetableEntry copyWith(
          {String? id,
          String? subjectId,
          String? semesterId,
          int? dayOfWeek,
          String? startTime,
          String? endTime,
          Value<String?> faculty = const Value.absent(),
          Value<String?> room = const Value.absent(),
          double? confidence,
          int? createdAt}) =>
      TimetableEntry(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        semesterId: semesterId ?? this.semesterId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        faculty: faculty.present ? faculty.value : this.faculty,
        room: room.present ? room.value : this.room,
        confidence: confidence ?? this.confidence,
        createdAt: createdAt ?? this.createdAt,
      );
  TimetableEntry copyWithCompanion(TimetableEntriesCompanion data) {
    return TimetableEntry(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      faculty: data.faculty.present ? data.faculty.value : this.faculty,
      room: data.room.present ? data.room.value : this.room,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntry(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('faculty: $faculty, ')
          ..write('room: $room, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subjectId, semesterId, dayOfWeek,
      startTime, endTime, faculty, room, confidence, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimetableEntry &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.semesterId == this.semesterId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.faculty == this.faculty &&
          other.room == this.room &&
          other.confidence == this.confidence &&
          other.createdAt == this.createdAt);
}

class TimetableEntriesCompanion extends UpdateCompanion<TimetableEntry> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> semesterId;
  final Value<int> dayOfWeek;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String?> faculty;
  final Value<String?> room;
  final Value<double> confidence;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TimetableEntriesCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.faculty = const Value.absent(),
    this.room = const Value.absent(),
    this.confidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimetableEntriesCompanion.insert({
    required String id,
    required String subjectId,
    required String semesterId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    this.faculty = const Value.absent(),
    this.room = const Value.absent(),
    this.confidence = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId),
        semesterId = Value(semesterId),
        dayOfWeek = Value(dayOfWeek),
        startTime = Value(startTime),
        endTime = Value(endTime),
        createdAt = Value(createdAt);
  static Insertable<TimetableEntry> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? semesterId,
    Expression<int>? dayOfWeek,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? faculty,
    Expression<String>? room,
    Expression<double>? confidence,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (semesterId != null) 'semester_id': semesterId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (faculty != null) 'faculty': faculty,
      if (room != null) 'room': room,
      if (confidence != null) 'confidence': confidence,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimetableEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<String>? semesterId,
      Value<int>? dayOfWeek,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<String?>? faculty,
      Value<String?>? room,
      Value<double>? confidence,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TimetableEntriesCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      faculty: faculty ?? this.faculty,
      room: room ?? this.room,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (faculty.present) {
      map['faculty'] = Variable<String>(faculty.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntriesCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('faculty: $faculty, ')
          ..write('room: $room, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassSessionsTable extends ClassSessions
    with TableInfo<$ClassSessionsTable, ClassSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subjects (id) ON DELETE CASCADE'));
  static const VerificationMeta _semesterIdMeta =
      const VerificationMeta('semesterId');
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
      'semester_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES semesters (id) ON DELETE RESTRICT'));
  static const VerificationMeta _timetableEntryIdMeta =
      const VerificationMeta('timetableEntryId');
  @override
  late final GeneratedColumn<String> timetableEntryId = GeneratedColumn<String>(
      'timetable_entry_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES timetable_entries (id) ON DELETE SET NULL'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _facultyMeta =
      const VerificationMeta('faculty');
  @override
  late final GeneratedColumn<String> faculty = GeneratedColumn<String>(
      'faculty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
      'room', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('notMarked'));
  static const VerificationMeta _isCancelledMeta =
      const VerificationMeta('isCancelled');
  @override
  late final GeneratedColumn<int> isCancelled = GeneratedColumn<int>(
      'is_cancelled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isExtraPeriodMeta =
      const VerificationMeta('isExtraPeriod');
  @override
  late final GeneratedColumn<int> isExtraPeriod = GeneratedColumn<int>(
      'is_extra_period', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        semesterId,
        timetableEntryId,
        date,
        startTime,
        endTime,
        faculty,
        room,
        status,
        isCancelled,
        isExtraPeriod,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ClassSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
          _semesterIdMeta,
          semesterId.isAcceptableOrUnknown(
              data['semester_id']!, _semesterIdMeta));
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('timetable_entry_id')) {
      context.handle(
          _timetableEntryIdMeta,
          timetableEntryId.isAcceptableOrUnknown(
              data['timetable_entry_id']!, _timetableEntryIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('faculty')) {
      context.handle(_facultyMeta,
          faculty.isAcceptableOrUnknown(data['faculty']!, _facultyMeta));
    }
    if (data.containsKey('room')) {
      context.handle(
          _roomMeta, room.isAcceptableOrUnknown(data['room']!, _roomMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_cancelled')) {
      context.handle(
          _isCancelledMeta,
          isCancelled.isAcceptableOrUnknown(
              data['is_cancelled']!, _isCancelledMeta));
    }
    if (data.containsKey('is_extra_period')) {
      context.handle(
          _isExtraPeriodMeta,
          isExtraPeriod.isAcceptableOrUnknown(
              data['is_extra_period']!, _isExtraPeriodMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {timetableEntryId, date},
      ];
  @override
  ClassSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      semesterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester_id'])!,
      timetableEntryId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}timetable_entry_id']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      faculty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faculty']),
      room: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isCancelled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_cancelled'])!,
      isExtraPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_extra_period'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ClassSessionsTable createAlias(String alias) {
    return $ClassSessionsTable(attachedDatabase, alias);
  }
}

class ClassSession extends DataClass implements Insertable<ClassSession> {
  /// UUID. May be pre-generated at session expansion time for stability.
  final String id;

  /// FK → subjects.id, ON DELETE CASCADE.
  final String subjectId;

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2).
  final String semesterId;

  /// FK → timetable_entries.id, ON DELETE SET NULL.
  /// NULL for extra periods added outside the timetable.
  final String? timetableEntryId;

  /// Date — Unix timestamp (ms), normalized to midnight UTC.
  final int date;

  /// "HH:MM" from timetable entry (base time, before any override).
  final String startTime;

  /// "HH:MM" from timetable entry (base time, before any override).
  final String endTime;

  /// Faculty copied from timetable entry at expansion time.
  final String? faculty;

  /// Room copied from timetable entry at expansion time.
  final String? room;

  /// Enum string: present / absent / late / cancelled / notMarked.
  final String status;

  /// BOOLEAN (0/1). True when this session was cancelled for the day.
  final int isCancelled;

  /// BOOLEAN (0/1). True when added outside the timetable pattern.
  final int isExtraPeriod;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;
  const ClassSession(
      {required this.id,
      required this.subjectId,
      required this.semesterId,
      this.timetableEntryId,
      required this.date,
      required this.startTime,
      required this.endTime,
      this.faculty,
      this.room,
      required this.status,
      required this.isCancelled,
      required this.isExtraPeriod,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['semester_id'] = Variable<String>(semesterId);
    if (!nullToAbsent || timetableEntryId != null) {
      map['timetable_entry_id'] = Variable<String>(timetableEntryId);
    }
    map['date'] = Variable<int>(date);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    if (!nullToAbsent || faculty != null) {
      map['faculty'] = Variable<String>(faculty);
    }
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    map['status'] = Variable<String>(status);
    map['is_cancelled'] = Variable<int>(isCancelled);
    map['is_extra_period'] = Variable<int>(isExtraPeriod);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ClassSessionsCompanion toCompanion(bool nullToAbsent) {
    return ClassSessionsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      semesterId: Value(semesterId),
      timetableEntryId: timetableEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(timetableEntryId),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      faculty: faculty == null && nullToAbsent
          ? const Value.absent()
          : Value(faculty),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      status: Value(status),
      isCancelled: Value(isCancelled),
      isExtraPeriod: Value(isExtraPeriod),
      createdAt: Value(createdAt),
    );
  }

  factory ClassSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassSession(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      timetableEntryId: serializer.fromJson<String?>(json['timetableEntryId']),
      date: serializer.fromJson<int>(json['date']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      faculty: serializer.fromJson<String?>(json['faculty']),
      room: serializer.fromJson<String?>(json['room']),
      status: serializer.fromJson<String>(json['status']),
      isCancelled: serializer.fromJson<int>(json['isCancelled']),
      isExtraPeriod: serializer.fromJson<int>(json['isExtraPeriod']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'semesterId': serializer.toJson<String>(semesterId),
      'timetableEntryId': serializer.toJson<String?>(timetableEntryId),
      'date': serializer.toJson<int>(date),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'faculty': serializer.toJson<String?>(faculty),
      'room': serializer.toJson<String?>(room),
      'status': serializer.toJson<String>(status),
      'isCancelled': serializer.toJson<int>(isCancelled),
      'isExtraPeriod': serializer.toJson<int>(isExtraPeriod),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ClassSession copyWith(
          {String? id,
          String? subjectId,
          String? semesterId,
          Value<String?> timetableEntryId = const Value.absent(),
          int? date,
          String? startTime,
          String? endTime,
          Value<String?> faculty = const Value.absent(),
          Value<String?> room = const Value.absent(),
          String? status,
          int? isCancelled,
          int? isExtraPeriod,
          int? createdAt}) =>
      ClassSession(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        semesterId: semesterId ?? this.semesterId,
        timetableEntryId: timetableEntryId.present
            ? timetableEntryId.value
            : this.timetableEntryId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        faculty: faculty.present ? faculty.value : this.faculty,
        room: room.present ? room.value : this.room,
        status: status ?? this.status,
        isCancelled: isCancelled ?? this.isCancelled,
        isExtraPeriod: isExtraPeriod ?? this.isExtraPeriod,
        createdAt: createdAt ?? this.createdAt,
      );
  ClassSession copyWithCompanion(ClassSessionsCompanion data) {
    return ClassSession(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      timetableEntryId: data.timetableEntryId.present
          ? data.timetableEntryId.value
          : this.timetableEntryId,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      faculty: data.faculty.present ? data.faculty.value : this.faculty,
      room: data.room.present ? data.room.value : this.room,
      status: data.status.present ? data.status.value : this.status,
      isCancelled:
          data.isCancelled.present ? data.isCancelled.value : this.isCancelled,
      isExtraPeriod: data.isExtraPeriod.present
          ? data.isExtraPeriod.value
          : this.isExtraPeriod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassSession(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('faculty: $faculty, ')
          ..write('room: $room, ')
          ..write('status: $status, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('isExtraPeriod: $isExtraPeriod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      subjectId,
      semesterId,
      timetableEntryId,
      date,
      startTime,
      endTime,
      faculty,
      room,
      status,
      isCancelled,
      isExtraPeriod,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassSession &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.semesterId == this.semesterId &&
          other.timetableEntryId == this.timetableEntryId &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.faculty == this.faculty &&
          other.room == this.room &&
          other.status == this.status &&
          other.isCancelled == this.isCancelled &&
          other.isExtraPeriod == this.isExtraPeriod &&
          other.createdAt == this.createdAt);
}

class ClassSessionsCompanion extends UpdateCompanion<ClassSession> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> semesterId;
  final Value<String?> timetableEntryId;
  final Value<int> date;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String?> faculty;
  final Value<String?> room;
  final Value<String> status;
  final Value<int> isCancelled;
  final Value<int> isExtraPeriod;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ClassSessionsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.timetableEntryId = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.faculty = const Value.absent(),
    this.room = const Value.absent(),
    this.status = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.isExtraPeriod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassSessionsCompanion.insert({
    required String id,
    required String subjectId,
    required String semesterId,
    this.timetableEntryId = const Value.absent(),
    required int date,
    required String startTime,
    required String endTime,
    this.faculty = const Value.absent(),
    this.room = const Value.absent(),
    this.status = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.isExtraPeriod = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId),
        semesterId = Value(semesterId),
        date = Value(date),
        startTime = Value(startTime),
        endTime = Value(endTime),
        createdAt = Value(createdAt);
  static Insertable<ClassSession> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? semesterId,
    Expression<String>? timetableEntryId,
    Expression<int>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? faculty,
    Expression<String>? room,
    Expression<String>? status,
    Expression<int>? isCancelled,
    Expression<int>? isExtraPeriod,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (semesterId != null) 'semester_id': semesterId,
      if (timetableEntryId != null) 'timetable_entry_id': timetableEntryId,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (faculty != null) 'faculty': faculty,
      if (room != null) 'room': room,
      if (status != null) 'status': status,
      if (isCancelled != null) 'is_cancelled': isCancelled,
      if (isExtraPeriod != null) 'is_extra_period': isExtraPeriod,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<String>? semesterId,
      Value<String?>? timetableEntryId,
      Value<int>? date,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<String?>? faculty,
      Value<String?>? room,
      Value<String>? status,
      Value<int>? isCancelled,
      Value<int>? isExtraPeriod,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ClassSessionsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      faculty: faculty ?? this.faculty,
      room: room ?? this.room,
      status: status ?? this.status,
      isCancelled: isCancelled ?? this.isCancelled,
      isExtraPeriod: isExtraPeriod ?? this.isExtraPeriod,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (timetableEntryId.present) {
      map['timetable_entry_id'] = Variable<String>(timetableEntryId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (faculty.present) {
      map['faculty'] = Variable<String>(faculty.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isCancelled.present) {
      map['is_cancelled'] = Variable<int>(isCancelled.value);
    }
    if (isExtraPeriod.present) {
      map['is_extra_period'] = Variable<int>(isExtraPeriod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassSessionsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('faculty: $faculty, ')
          ..write('room: $room, ')
          ..write('status: $status, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('isExtraPeriod: $isExtraPeriod, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyScheduleOverridesTable extends DailyScheduleOverrides
    with TableInfo<$DailyScheduleOverridesTable, DailyScheduleOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyScheduleOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES class_sessions (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _overrideTypeMeta =
      const VerificationMeta('overrideType');
  @override
  late final GeneratedColumn<String> overrideType = GeneratedColumn<String>(
      'override_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newSubjectIdMeta =
      const VerificationMeta('newSubjectId');
  @override
  late final GeneratedColumn<String> newSubjectId = GeneratedColumn<String>(
      'new_subject_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subjects (id) ON DELETE SET NULL'));
  static const VerificationMeta _newStartTimeMeta =
      const VerificationMeta('newStartTime');
  @override
  late final GeneratedColumn<String> newStartTime = GeneratedColumn<String>(
      'new_start_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newEndTimeMeta =
      const VerificationMeta('newEndTime');
  @override
  late final GeneratedColumn<String> newEndTime = GeneratedColumn<String>(
      'new_end_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCancelledMeta =
      const VerificationMeta('isCancelled');
  @override
  late final GeneratedColumn<int> isCancelled = GeneratedColumn<int>(
      'is_cancelled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isExtraPeriodMeta =
      const VerificationMeta('isExtraPeriod');
  @override
  late final GeneratedColumn<int> isExtraPeriod = GeneratedColumn<int>(
      'is_extra_period', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        date,
        overrideType,
        newSubjectId,
        newStartTime,
        newEndTime,
        isCancelled,
        isExtraPeriod,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_schedule_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyScheduleOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('override_type')) {
      context.handle(
          _overrideTypeMeta,
          overrideType.isAcceptableOrUnknown(
              data['override_type']!, _overrideTypeMeta));
    } else if (isInserting) {
      context.missing(_overrideTypeMeta);
    }
    if (data.containsKey('new_subject_id')) {
      context.handle(
          _newSubjectIdMeta,
          newSubjectId.isAcceptableOrUnknown(
              data['new_subject_id']!, _newSubjectIdMeta));
    }
    if (data.containsKey('new_start_time')) {
      context.handle(
          _newStartTimeMeta,
          newStartTime.isAcceptableOrUnknown(
              data['new_start_time']!, _newStartTimeMeta));
    }
    if (data.containsKey('new_end_time')) {
      context.handle(
          _newEndTimeMeta,
          newEndTime.isAcceptableOrUnknown(
              data['new_end_time']!, _newEndTimeMeta));
    }
    if (data.containsKey('is_cancelled')) {
      context.handle(
          _isCancelledMeta,
          isCancelled.isAcceptableOrUnknown(
              data['is_cancelled']!, _isCancelledMeta));
    }
    if (data.containsKey('is_extra_period')) {
      context.handle(
          _isExtraPeriodMeta,
          isExtraPeriod.isAcceptableOrUnknown(
              data['is_extra_period']!, _isExtraPeriodMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sessionId},
      ];
  @override
  DailyScheduleOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyScheduleOverride(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      overrideType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}override_type'])!,
      newSubjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_subject_id']),
      newStartTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_start_time']),
      newEndTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_end_time']),
      isCancelled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_cancelled'])!,
      isExtraPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_extra_period'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DailyScheduleOverridesTable createAlias(String alias) {
    return $DailyScheduleOverridesTable(attachedDatabase, alias);
  }
}

class DailyScheduleOverride extends DataClass
    implements Insertable<DailyScheduleOverride> {
  /// UUID primary key.
  final String id;

  /// FK → class_sessions.id, ON DELETE CASCADE.
  final String sessionId;

  /// Date — Unix timestamp (ms), midnight UTC. Must match the session's date.
  final int date;

  /// Enum string: changeSubject / reschedule / cancel / addExtra.
  final String overrideType;

  /// FK → subjects.id, ON DELETE SET NULL.
  /// Set when override_type = changeSubject.
  final String? newSubjectId;

  /// "HH:MM". Set when override_type = reschedule.
  final String? newStartTime;

  /// "HH:MM". Set when override_type = reschedule.
  final String? newEndTime;

  /// BOOLEAN. True when override_type = cancel.
  final int isCancelled;

  /// BOOLEAN. True when override_type = addExtra.
  final int isExtraPeriod;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;
  const DailyScheduleOverride(
      {required this.id,
      required this.sessionId,
      required this.date,
      required this.overrideType,
      this.newSubjectId,
      this.newStartTime,
      this.newEndTime,
      required this.isCancelled,
      required this.isExtraPeriod,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['date'] = Variable<int>(date);
    map['override_type'] = Variable<String>(overrideType);
    if (!nullToAbsent || newSubjectId != null) {
      map['new_subject_id'] = Variable<String>(newSubjectId);
    }
    if (!nullToAbsent || newStartTime != null) {
      map['new_start_time'] = Variable<String>(newStartTime);
    }
    if (!nullToAbsent || newEndTime != null) {
      map['new_end_time'] = Variable<String>(newEndTime);
    }
    map['is_cancelled'] = Variable<int>(isCancelled);
    map['is_extra_period'] = Variable<int>(isExtraPeriod);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DailyScheduleOverridesCompanion toCompanion(bool nullToAbsent) {
    return DailyScheduleOverridesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      date: Value(date),
      overrideType: Value(overrideType),
      newSubjectId: newSubjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(newSubjectId),
      newStartTime: newStartTime == null && nullToAbsent
          ? const Value.absent()
          : Value(newStartTime),
      newEndTime: newEndTime == null && nullToAbsent
          ? const Value.absent()
          : Value(newEndTime),
      isCancelled: Value(isCancelled),
      isExtraPeriod: Value(isExtraPeriod),
      createdAt: Value(createdAt),
    );
  }

  factory DailyScheduleOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyScheduleOverride(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      date: serializer.fromJson<int>(json['date']),
      overrideType: serializer.fromJson<String>(json['overrideType']),
      newSubjectId: serializer.fromJson<String?>(json['newSubjectId']),
      newStartTime: serializer.fromJson<String?>(json['newStartTime']),
      newEndTime: serializer.fromJson<String?>(json['newEndTime']),
      isCancelled: serializer.fromJson<int>(json['isCancelled']),
      isExtraPeriod: serializer.fromJson<int>(json['isExtraPeriod']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'date': serializer.toJson<int>(date),
      'overrideType': serializer.toJson<String>(overrideType),
      'newSubjectId': serializer.toJson<String?>(newSubjectId),
      'newStartTime': serializer.toJson<String?>(newStartTime),
      'newEndTime': serializer.toJson<String?>(newEndTime),
      'isCancelled': serializer.toJson<int>(isCancelled),
      'isExtraPeriod': serializer.toJson<int>(isExtraPeriod),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DailyScheduleOverride copyWith(
          {String? id,
          String? sessionId,
          int? date,
          String? overrideType,
          Value<String?> newSubjectId = const Value.absent(),
          Value<String?> newStartTime = const Value.absent(),
          Value<String?> newEndTime = const Value.absent(),
          int? isCancelled,
          int? isExtraPeriod,
          int? createdAt}) =>
      DailyScheduleOverride(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        date: date ?? this.date,
        overrideType: overrideType ?? this.overrideType,
        newSubjectId:
            newSubjectId.present ? newSubjectId.value : this.newSubjectId,
        newStartTime:
            newStartTime.present ? newStartTime.value : this.newStartTime,
        newEndTime: newEndTime.present ? newEndTime.value : this.newEndTime,
        isCancelled: isCancelled ?? this.isCancelled,
        isExtraPeriod: isExtraPeriod ?? this.isExtraPeriod,
        createdAt: createdAt ?? this.createdAt,
      );
  DailyScheduleOverride copyWithCompanion(
      DailyScheduleOverridesCompanion data) {
    return DailyScheduleOverride(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      date: data.date.present ? data.date.value : this.date,
      overrideType: data.overrideType.present
          ? data.overrideType.value
          : this.overrideType,
      newSubjectId: data.newSubjectId.present
          ? data.newSubjectId.value
          : this.newSubjectId,
      newStartTime: data.newStartTime.present
          ? data.newStartTime.value
          : this.newStartTime,
      newEndTime:
          data.newEndTime.present ? data.newEndTime.value : this.newEndTime,
      isCancelled:
          data.isCancelled.present ? data.isCancelled.value : this.isCancelled,
      isExtraPeriod: data.isExtraPeriod.present
          ? data.isExtraPeriod.value
          : this.isExtraPeriod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyScheduleOverride(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('date: $date, ')
          ..write('overrideType: $overrideType, ')
          ..write('newSubjectId: $newSubjectId, ')
          ..write('newStartTime: $newStartTime, ')
          ..write('newEndTime: $newEndTime, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('isExtraPeriod: $isExtraPeriod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sessionId,
      date,
      overrideType,
      newSubjectId,
      newStartTime,
      newEndTime,
      isCancelled,
      isExtraPeriod,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyScheduleOverride &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.date == this.date &&
          other.overrideType == this.overrideType &&
          other.newSubjectId == this.newSubjectId &&
          other.newStartTime == this.newStartTime &&
          other.newEndTime == this.newEndTime &&
          other.isCancelled == this.isCancelled &&
          other.isExtraPeriod == this.isExtraPeriod &&
          other.createdAt == this.createdAt);
}

class DailyScheduleOverridesCompanion
    extends UpdateCompanion<DailyScheduleOverride> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> date;
  final Value<String> overrideType;
  final Value<String?> newSubjectId;
  final Value<String?> newStartTime;
  final Value<String?> newEndTime;
  final Value<int> isCancelled;
  final Value<int> isExtraPeriod;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DailyScheduleOverridesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.date = const Value.absent(),
    this.overrideType = const Value.absent(),
    this.newSubjectId = const Value.absent(),
    this.newStartTime = const Value.absent(),
    this.newEndTime = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.isExtraPeriod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyScheduleOverridesCompanion.insert({
    required String id,
    required String sessionId,
    required int date,
    required String overrideType,
    this.newSubjectId = const Value.absent(),
    this.newStartTime = const Value.absent(),
    this.newEndTime = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.isExtraPeriod = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        date = Value(date),
        overrideType = Value(overrideType),
        createdAt = Value(createdAt);
  static Insertable<DailyScheduleOverride> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? date,
    Expression<String>? overrideType,
    Expression<String>? newSubjectId,
    Expression<String>? newStartTime,
    Expression<String>? newEndTime,
    Expression<int>? isCancelled,
    Expression<int>? isExtraPeriod,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (date != null) 'date': date,
      if (overrideType != null) 'override_type': overrideType,
      if (newSubjectId != null) 'new_subject_id': newSubjectId,
      if (newStartTime != null) 'new_start_time': newStartTime,
      if (newEndTime != null) 'new_end_time': newEndTime,
      if (isCancelled != null) 'is_cancelled': isCancelled,
      if (isExtraPeriod != null) 'is_extra_period': isExtraPeriod,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyScheduleOverridesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<int>? date,
      Value<String>? overrideType,
      Value<String?>? newSubjectId,
      Value<String?>? newStartTime,
      Value<String?>? newEndTime,
      Value<int>? isCancelled,
      Value<int>? isExtraPeriod,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return DailyScheduleOverridesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      overrideType: overrideType ?? this.overrideType,
      newSubjectId: newSubjectId ?? this.newSubjectId,
      newStartTime: newStartTime ?? this.newStartTime,
      newEndTime: newEndTime ?? this.newEndTime,
      isCancelled: isCancelled ?? this.isCancelled,
      isExtraPeriod: isExtraPeriod ?? this.isExtraPeriod,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (overrideType.present) {
      map['override_type'] = Variable<String>(overrideType.value);
    }
    if (newSubjectId.present) {
      map['new_subject_id'] = Variable<String>(newSubjectId.value);
    }
    if (newStartTime.present) {
      map['new_start_time'] = Variable<String>(newStartTime.value);
    }
    if (newEndTime.present) {
      map['new_end_time'] = Variable<String>(newEndTime.value);
    }
    if (isCancelled.present) {
      map['is_cancelled'] = Variable<int>(isCancelled.value);
    }
    if (isExtraPeriod.present) {
      map['is_extra_period'] = Variable<int>(isExtraPeriod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyScheduleOverridesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('date: $date, ')
          ..write('overrideType: $overrideType, ')
          ..write('newSubjectId: $newSubjectId, ')
          ..write('newStartTime: $newStartTime, ')
          ..write('newEndTime: $newEndTime, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('isExtraPeriod: $isExtraPeriod, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceLogsTable extends AttendanceLogs
    with TableInfo<$AttendanceLogsTable, AttendanceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subjects (id) ON DELETE RESTRICT'));
  static const VerificationMeta _semesterIdMeta =
      const VerificationMeta('semesterId');
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
      'semester_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES semesters (id) ON DELETE RESTRICT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES class_sessions (id) ON DELETE SET NULL'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        semesterId,
        sessionId,
        status,
        date,
        startTime,
        endTime,
        isArchived,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AttendanceLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
          _semesterIdMeta,
          semesterId.isAcceptableOrUnknown(
              data['semester_id']!, _semesterIdMeta));
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      semesterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time']),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AttendanceLogsTable createAlias(String alias) {
    return $AttendanceLogsTable(attachedDatabase, alias);
  }
}

class AttendanceLog extends DataClass implements Insertable<AttendanceLog> {
  /// UUID primary key.
  final String id;

  /// FK → subjects.id, ON DELETE RESTRICT.
  final String subjectId;

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2).
  final String semesterId;

  /// FK → class_sessions.id, ON DELETE SET NULL.
  /// NULL for manually entered historical logs.
  final String? sessionId;

  /// Enum string: present / absent / late / cancelled.
  /// NOTE: 'notMarked' is NEVER stored here.
  final String status;

  /// Date — Unix timestamp (ms), normalized to midnight UTC.
  final int date;

  /// "HH:MM"; copied from session at write time. NULL for manual entries.
  final String? startTime;

  /// "HH:MM"; copied from session at write time. NULL for manual entries.
  final String? endTime;

  /// BOOLEAN (0/1). 1 = soft-deleted when parent subject is deleted;
  /// log row is preserved for audit.
  final int isArchived;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;
  const AttendanceLog(
      {required this.id,
      required this.subjectId,
      required this.semesterId,
      this.sessionId,
      required this.status,
      required this.date,
      this.startTime,
      this.endTime,
      required this.isArchived,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['semester_id'] = Variable<String>(semesterId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['status'] = Variable<String>(status);
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['is_archived'] = Variable<int>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AttendanceLogsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceLogsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      semesterId: Value(semesterId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      status: Value(status),
      date: Value(date),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceLog(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      status: serializer.fromJson<String>(json['status']),
      date: serializer.fromJson<int>(json['date']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'semesterId': serializer.toJson<String>(semesterId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'status': serializer.toJson<String>(status),
      'date': serializer.toJson<int>(date),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'isArchived': serializer.toJson<int>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AttendanceLog copyWith(
          {String? id,
          String? subjectId,
          String? semesterId,
          Value<String?> sessionId = const Value.absent(),
          String? status,
          int? date,
          Value<String?> startTime = const Value.absent(),
          Value<String?> endTime = const Value.absent(),
          int? isArchived,
          int? createdAt}) =>
      AttendanceLog(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        semesterId: semesterId ?? this.semesterId,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        status: status ?? this.status,
        date: date ?? this.date,
        startTime: startTime.present ? startTime.value : this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
  AttendanceLog copyWithCompanion(AttendanceLogsCompanion data) {
    return AttendanceLog(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      semesterId:
          data.semesterId.present ? data.semesterId.value : this.semesterId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      status: data.status.present ? data.status.value : this.status,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLog(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subjectId, semesterId, sessionId, status,
      date, startTime, endTime, isArchived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceLog &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.semesterId == this.semesterId &&
          other.sessionId == this.sessionId &&
          other.status == this.status &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class AttendanceLogsCompanion extends UpdateCompanion<AttendanceLog> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> semesterId;
  final Value<String?> sessionId;
  final Value<String> status;
  final Value<int> date;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<int> isArchived;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AttendanceLogsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceLogsCompanion.insert({
    required String id,
    required String subjectId,
    required String semesterId,
    this.sessionId = const Value.absent(),
    required String status,
    required int date,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId),
        semesterId = Value(semesterId),
        status = Value(status),
        date = Value(date),
        createdAt = Value(createdAt);
  static Insertable<AttendanceLog> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? semesterId,
    Expression<String>? sessionId,
    Expression<String>? status,
    Expression<int>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (semesterId != null) 'semester_id': semesterId,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<String>? semesterId,
      Value<String?>? sessionId,
      Value<String>? status,
      Value<int>? date,
      Value<String?>? startTime,
      Value<String?>? endTime,
      Value<int>? isArchived,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AttendanceLogsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationPreferencesTable extends NotificationPreferences
    with TableInfo<$NotificationPreferencesTable, NotificationPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<int> notificationsEnabled = GeneratedColumn<int>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _soundEnabledMeta =
      const VerificationMeta('soundEnabled');
  @override
  late final GeneratedColumn<int> soundEnabled = GeneratedColumn<int>(
      'sound_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _vibrationEnabledMeta =
      const VerificationMeta('vibrationEnabled');
  @override
  late final GeneratedColumn<int> vibrationEnabled = GeneratedColumn<int>(
      'vibration_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _badgeCountMeta =
      const VerificationMeta('badgeCount');
  @override
  late final GeneratedColumn<int> badgeCount = GeneratedColumn<int>(
      'badge_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quietHoursStartHourMeta =
      const VerificationMeta('quietHoursStartHour');
  @override
  late final GeneratedColumn<int> quietHoursStartHour = GeneratedColumn<int>(
      'quiet_hours_start_hour', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _quietHoursStartMinuteMeta =
      const VerificationMeta('quietHoursStartMinute');
  @override
  late final GeneratedColumn<int> quietHoursStartMinute = GeneratedColumn<int>(
      'quiet_hours_start_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _quietHoursEndHourMeta =
      const VerificationMeta('quietHoursEndHour');
  @override
  late final GeneratedColumn<int> quietHoursEndHour = GeneratedColumn<int>(
      'quiet_hours_end_hour', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _quietHoursEndMinuteMeta =
      const VerificationMeta('quietHoursEndMinute');
  @override
  late final GeneratedColumn<int> quietHoursEndMinute = GeneratedColumn<int>(
      'quiet_hours_end_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _classRemindersEnabledMeta =
      const VerificationMeta('classRemindersEnabled');
  @override
  late final GeneratedColumn<int> classRemindersEnabled = GeneratedColumn<int>(
      'class_reminders_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _reminderMinutesMeta =
      const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
      'reminder_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _onlyFirstClassReminderMeta =
      const VerificationMeta('onlyFirstClassReminder');
  @override
  late final GeneratedColumn<int> onlyFirstClassReminder = GeneratedColumn<int>(
      'only_first_class_reminder', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _gapClassRemindersEnabledMeta =
      const VerificationMeta('gapClassRemindersEnabled');
  @override
  late final GeneratedColumn<int> gapClassRemindersEnabled =
      GeneratedColumn<int>('gap_class_reminders_enabled', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _gapMinutesMeta =
      const VerificationMeta('gapMinutes');
  @override
  late final GeneratedColumn<int> gapMinutes = GeneratedColumn<int>(
      'gap_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _attendanceRemindersEnabledMeta =
      const VerificationMeta('attendanceRemindersEnabled');
  @override
  late final GeneratedColumn<int> attendanceRemindersEnabled =
      GeneratedColumn<int>('attendance_reminders_enabled', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _attendanceDelayMinutesMeta =
      const VerificationMeta('attendanceDelayMinutes');
  @override
  late final GeneratedColumn<int> attendanceDelayMinutes = GeneratedColumn<int>(
      'attendance_delay_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _absentRestOfDayEnabledMeta =
      const VerificationMeta('absentRestOfDayEnabled');
  @override
  late final GeneratedColumn<int> absentRestOfDayEnabled = GeneratedColumn<int>(
      'absent_rest_of_day_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _autoDismissMinutesMeta =
      const VerificationMeta('autoDismissMinutes');
  @override
  late final GeneratedColumn<int> autoDismissMinutes = GeneratedColumn<int>(
      'auto_dismiss_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lowAttendanceAlertsEnabledMeta =
      const VerificationMeta('lowAttendanceAlertsEnabled');
  @override
  late final GeneratedColumn<int> lowAttendanceAlertsEnabled =
      GeneratedColumn<int>('low_attendance_alerts_enabled', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _recoverySuggestionsEnabledMeta =
      const VerificationMeta('recoverySuggestionsEnabled');
  @override
  late final GeneratedColumn<int> recoverySuggestionsEnabled =
      GeneratedColumn<int>('recovery_suggestions_enabled', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _criticalAttendanceEnabledMeta =
      const VerificationMeta('criticalAttendanceEnabled');
  @override
  late final GeneratedColumn<int> criticalAttendanceEnabled =
      GeneratedColumn<int>('critical_attendance_enabled', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _criticalThresholdMeta =
      const VerificationMeta('criticalThreshold');
  @override
  late final GeneratedColumn<double> criticalThreshold =
      GeneratedColumn<double>('critical_threshold', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(65.0));
  static const VerificationMeta _safeBunkPlannerEnabledMeta =
      const VerificationMeta('safeBunkPlannerEnabled');
  @override
  late final GeneratedColumn<int> safeBunkPlannerEnabled = GeneratedColumn<int>(
      'safe_bunk_planner_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _plannerTimeHourMeta =
      const VerificationMeta('plannerTimeHour');
  @override
  late final GeneratedColumn<int> plannerTimeHour = GeneratedColumn<int>(
      'planner_time_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(22));
  static const VerificationMeta _plannerTimeMinuteMeta =
      const VerificationMeta('plannerTimeMinute');
  @override
  late final GeneratedColumn<int> plannerTimeMinute = GeneratedColumn<int>(
      'planner_time_minute', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _includeSafeBunksMeta =
      const VerificationMeta('includeSafeBunks');
  @override
  late final GeneratedColumn<int> includeSafeBunks = GeneratedColumn<int>(
      'include_safe_bunks', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _plannerIncludeRecoverySuggestionsMeta =
      const VerificationMeta('plannerIncludeRecoverySuggestions');
  @override
  late final GeneratedColumn<int> plannerIncludeRecoverySuggestions =
      GeneratedColumn<int>(
          'planner_include_recovery_suggestions', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _includeRiskSubjectsMeta =
      const VerificationMeta('includeRiskSubjects');
  @override
  late final GeneratedColumn<int> includeRiskSubjects = GeneratedColumn<int>(
      'include_risk_subjects', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dailySummaryEnabledMeta =
      const VerificationMeta('dailySummaryEnabled');
  @override
  late final GeneratedColumn<int> dailySummaryEnabled = GeneratedColumn<int>(
      'daily_summary_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _summaryTimeHourMeta =
      const VerificationMeta('summaryTimeHour');
  @override
  late final GeneratedColumn<int> summaryTimeHour = GeneratedColumn<int>(
      'summary_time_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(21));
  static const VerificationMeta _summaryTimeMinuteMeta =
      const VerificationMeta('summaryTimeMinute');
  @override
  late final GeneratedColumn<int> summaryTimeMinute = GeneratedColumn<int>(
      'summary_time_minute', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _includeClassesAttendedMeta =
      const VerificationMeta('includeClassesAttended');
  @override
  late final GeneratedColumn<int> includeClassesAttended = GeneratedColumn<int>(
      'include_classes_attended', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _includeClassesMissedMeta =
      const VerificationMeta('includeClassesMissed');
  @override
  late final GeneratedColumn<int> includeClassesMissed = GeneratedColumn<int>(
      'include_classes_missed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _includeSubjectBreakdownMeta =
      const VerificationMeta('includeSubjectBreakdown');
  @override
  late final GeneratedColumn<int> includeSubjectBreakdown =
      GeneratedColumn<int>('include_subject_breakdown', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _includeOverallAttendanceMeta =
      const VerificationMeta('includeOverallAttendance');
  @override
  late final GeneratedColumn<int> includeOverallAttendance =
      GeneratedColumn<int>('include_overall_attendance', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        badgeCount,
        quietHoursStartHour,
        quietHoursStartMinute,
        quietHoursEndHour,
        quietHoursEndMinute,
        classRemindersEnabled,
        reminderMinutes,
        onlyFirstClassReminder,
        gapClassRemindersEnabled,
        gapMinutes,
        attendanceRemindersEnabled,
        attendanceDelayMinutes,
        absentRestOfDayEnabled,
        autoDismissMinutes,
        lowAttendanceAlertsEnabled,
        recoverySuggestionsEnabled,
        criticalAttendanceEnabled,
        criticalThreshold,
        safeBunkPlannerEnabled,
        plannerTimeHour,
        plannerTimeMinute,
        includeSafeBunks,
        plannerIncludeRecoverySuggestions,
        includeRiskSubjects,
        dailySummaryEnabled,
        summaryTimeHour,
        summaryTimeMinute,
        includeClassesAttended,
        includeClassesMissed,
        includeSubjectBreakdown,
        includeOverallAttendance,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_preferences';
  @override
  VerificationContext validateIntegrity(
      Insertable<NotificationPreference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    if (data.containsKey('sound_enabled')) {
      context.handle(
          _soundEnabledMeta,
          soundEnabled.isAcceptableOrUnknown(
              data['sound_enabled']!, _soundEnabledMeta));
    }
    if (data.containsKey('vibration_enabled')) {
      context.handle(
          _vibrationEnabledMeta,
          vibrationEnabled.isAcceptableOrUnknown(
              data['vibration_enabled']!, _vibrationEnabledMeta));
    }
    if (data.containsKey('badge_count')) {
      context.handle(
          _badgeCountMeta,
          badgeCount.isAcceptableOrUnknown(
              data['badge_count']!, _badgeCountMeta));
    }
    if (data.containsKey('quiet_hours_start_hour')) {
      context.handle(
          _quietHoursStartHourMeta,
          quietHoursStartHour.isAcceptableOrUnknown(
              data['quiet_hours_start_hour']!, _quietHoursStartHourMeta));
    }
    if (data.containsKey('quiet_hours_start_minute')) {
      context.handle(
          _quietHoursStartMinuteMeta,
          quietHoursStartMinute.isAcceptableOrUnknown(
              data['quiet_hours_start_minute']!, _quietHoursStartMinuteMeta));
    }
    if (data.containsKey('quiet_hours_end_hour')) {
      context.handle(
          _quietHoursEndHourMeta,
          quietHoursEndHour.isAcceptableOrUnknown(
              data['quiet_hours_end_hour']!, _quietHoursEndHourMeta));
    }
    if (data.containsKey('quiet_hours_end_minute')) {
      context.handle(
          _quietHoursEndMinuteMeta,
          quietHoursEndMinute.isAcceptableOrUnknown(
              data['quiet_hours_end_minute']!, _quietHoursEndMinuteMeta));
    }
    if (data.containsKey('class_reminders_enabled')) {
      context.handle(
          _classRemindersEnabledMeta,
          classRemindersEnabled.isAcceptableOrUnknown(
              data['class_reminders_enabled']!, _classRemindersEnabledMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
          _reminderMinutesMeta,
          reminderMinutes.isAcceptableOrUnknown(
              data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('only_first_class_reminder')) {
      context.handle(
          _onlyFirstClassReminderMeta,
          onlyFirstClassReminder.isAcceptableOrUnknown(
              data['only_first_class_reminder']!, _onlyFirstClassReminderMeta));
    }
    if (data.containsKey('gap_class_reminders_enabled')) {
      context.handle(
          _gapClassRemindersEnabledMeta,
          gapClassRemindersEnabled.isAcceptableOrUnknown(
              data['gap_class_reminders_enabled']!,
              _gapClassRemindersEnabledMeta));
    }
    if (data.containsKey('gap_minutes')) {
      context.handle(
          _gapMinutesMeta,
          gapMinutes.isAcceptableOrUnknown(
              data['gap_minutes']!, _gapMinutesMeta));
    }
    if (data.containsKey('attendance_reminders_enabled')) {
      context.handle(
          _attendanceRemindersEnabledMeta,
          attendanceRemindersEnabled.isAcceptableOrUnknown(
              data['attendance_reminders_enabled']!,
              _attendanceRemindersEnabledMeta));
    }
    if (data.containsKey('attendance_delay_minutes')) {
      context.handle(
          _attendanceDelayMinutesMeta,
          attendanceDelayMinutes.isAcceptableOrUnknown(
              data['attendance_delay_minutes']!, _attendanceDelayMinutesMeta));
    }
    if (data.containsKey('absent_rest_of_day_enabled')) {
      context.handle(
          _absentRestOfDayEnabledMeta,
          absentRestOfDayEnabled.isAcceptableOrUnknown(
              data['absent_rest_of_day_enabled']!,
              _absentRestOfDayEnabledMeta));
    }
    if (data.containsKey('auto_dismiss_minutes')) {
      context.handle(
          _autoDismissMinutesMeta,
          autoDismissMinutes.isAcceptableOrUnknown(
              data['auto_dismiss_minutes']!, _autoDismissMinutesMeta));
    }
    if (data.containsKey('low_attendance_alerts_enabled')) {
      context.handle(
          _lowAttendanceAlertsEnabledMeta,
          lowAttendanceAlertsEnabled.isAcceptableOrUnknown(
              data['low_attendance_alerts_enabled']!,
              _lowAttendanceAlertsEnabledMeta));
    }
    if (data.containsKey('recovery_suggestions_enabled')) {
      context.handle(
          _recoverySuggestionsEnabledMeta,
          recoverySuggestionsEnabled.isAcceptableOrUnknown(
              data['recovery_suggestions_enabled']!,
              _recoverySuggestionsEnabledMeta));
    }
    if (data.containsKey('critical_attendance_enabled')) {
      context.handle(
          _criticalAttendanceEnabledMeta,
          criticalAttendanceEnabled.isAcceptableOrUnknown(
              data['critical_attendance_enabled']!,
              _criticalAttendanceEnabledMeta));
    }
    if (data.containsKey('critical_threshold')) {
      context.handle(
          _criticalThresholdMeta,
          criticalThreshold.isAcceptableOrUnknown(
              data['critical_threshold']!, _criticalThresholdMeta));
    }
    if (data.containsKey('safe_bunk_planner_enabled')) {
      context.handle(
          _safeBunkPlannerEnabledMeta,
          safeBunkPlannerEnabled.isAcceptableOrUnknown(
              data['safe_bunk_planner_enabled']!, _safeBunkPlannerEnabledMeta));
    }
    if (data.containsKey('planner_time_hour')) {
      context.handle(
          _plannerTimeHourMeta,
          plannerTimeHour.isAcceptableOrUnknown(
              data['planner_time_hour']!, _plannerTimeHourMeta));
    }
    if (data.containsKey('planner_time_minute')) {
      context.handle(
          _plannerTimeMinuteMeta,
          plannerTimeMinute.isAcceptableOrUnknown(
              data['planner_time_minute']!, _plannerTimeMinuteMeta));
    }
    if (data.containsKey('include_safe_bunks')) {
      context.handle(
          _includeSafeBunksMeta,
          includeSafeBunks.isAcceptableOrUnknown(
              data['include_safe_bunks']!, _includeSafeBunksMeta));
    }
    if (data.containsKey('planner_include_recovery_suggestions')) {
      context.handle(
          _plannerIncludeRecoverySuggestionsMeta,
          plannerIncludeRecoverySuggestions.isAcceptableOrUnknown(
              data['planner_include_recovery_suggestions']!,
              _plannerIncludeRecoverySuggestionsMeta));
    }
    if (data.containsKey('include_risk_subjects')) {
      context.handle(
          _includeRiskSubjectsMeta,
          includeRiskSubjects.isAcceptableOrUnknown(
              data['include_risk_subjects']!, _includeRiskSubjectsMeta));
    }
    if (data.containsKey('daily_summary_enabled')) {
      context.handle(
          _dailySummaryEnabledMeta,
          dailySummaryEnabled.isAcceptableOrUnknown(
              data['daily_summary_enabled']!, _dailySummaryEnabledMeta));
    }
    if (data.containsKey('summary_time_hour')) {
      context.handle(
          _summaryTimeHourMeta,
          summaryTimeHour.isAcceptableOrUnknown(
              data['summary_time_hour']!, _summaryTimeHourMeta));
    }
    if (data.containsKey('summary_time_minute')) {
      context.handle(
          _summaryTimeMinuteMeta,
          summaryTimeMinute.isAcceptableOrUnknown(
              data['summary_time_minute']!, _summaryTimeMinuteMeta));
    }
    if (data.containsKey('include_classes_attended')) {
      context.handle(
          _includeClassesAttendedMeta,
          includeClassesAttended.isAcceptableOrUnknown(
              data['include_classes_attended']!, _includeClassesAttendedMeta));
    }
    if (data.containsKey('include_classes_missed')) {
      context.handle(
          _includeClassesMissedMeta,
          includeClassesMissed.isAcceptableOrUnknown(
              data['include_classes_missed']!, _includeClassesMissedMeta));
    }
    if (data.containsKey('include_subject_breakdown')) {
      context.handle(
          _includeSubjectBreakdownMeta,
          includeSubjectBreakdown.isAcceptableOrUnknown(
              data['include_subject_breakdown']!,
              _includeSubjectBreakdownMeta));
    }
    if (data.containsKey('include_overall_attendance')) {
      context.handle(
          _includeOverallAttendanceMeta,
          includeOverallAttendance.isAcceptableOrUnknown(
              data['include_overall_attendance']!,
              _includeOverallAttendanceMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationPreference(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}notifications_enabled'])!,
      soundEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sound_enabled'])!,
      vibrationEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vibration_enabled'])!,
      badgeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}badge_count'])!,
      quietHoursStartHour: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}quiet_hours_start_hour']),
      quietHoursStartMinute: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}quiet_hours_start_minute']),
      quietHoursEndHour: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}quiet_hours_end_hour']),
      quietHoursEndMinute: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}quiet_hours_end_minute']),
      classRemindersEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}class_reminders_enabled'])!,
      reminderMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes'])!,
      onlyFirstClassReminder: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}only_first_class_reminder'])!,
      gapClassRemindersEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}gap_class_reminders_enabled'])!,
      gapMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gap_minutes'])!,
      attendanceRemindersEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}attendance_reminders_enabled'])!,
      attendanceDelayMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}attendance_delay_minutes'])!,
      absentRestOfDayEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}absent_rest_of_day_enabled'])!,
      autoDismissMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}auto_dismiss_minutes'])!,
      lowAttendanceAlertsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}low_attendance_alerts_enabled'])!,
      recoverySuggestionsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recovery_suggestions_enabled'])!,
      criticalAttendanceEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}critical_attendance_enabled'])!,
      criticalThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}critical_threshold'])!,
      safeBunkPlannerEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}safe_bunk_planner_enabled'])!,
      plannerTimeHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planner_time_hour'])!,
      plannerTimeMinute: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}planner_time_minute'])!,
      includeSafeBunks: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}include_safe_bunks'])!,
      plannerIncludeRecoverySuggestions: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}planner_include_recovery_suggestions'])!,
      includeRiskSubjects: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}include_risk_subjects'])!,
      dailySummaryEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_summary_enabled'])!,
      summaryTimeHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}summary_time_hour'])!,
      summaryTimeMinute: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}summary_time_minute'])!,
      includeClassesAttended: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}include_classes_attended'])!,
      includeClassesMissed: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}include_classes_missed'])!,
      includeSubjectBreakdown: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}include_subject_breakdown'])!,
      includeOverallAttendance: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}include_overall_attendance'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NotificationPreferencesTable createAlias(String alias) {
    return $NotificationPreferencesTable(attachedDatabase, alias);
  }
}

class NotificationPreference extends DataClass
    implements Insertable<NotificationPreference> {
  /// Singleton PK — always 1.
  final int id;
  final int notificationsEnabled;
  final int soundEnabled;
  final int vibrationEnabled;
  final int badgeCount;
  final int? quietHoursStartHour;
  final int? quietHoursStartMinute;
  final int? quietHoursEndHour;
  final int? quietHoursEndMinute;
  final int classRemindersEnabled;

  /// Lead time before class: 5 / 10 / 15 / 30 minutes.
  final int reminderMinutes;

  /// If 1, only the first class of the day gets a reminder.
  final int onlyFirstClassReminder;
  final int gapClassRemindersEnabled;

  /// Minimum gap (minutes) to trigger a gap reminder: 30 / 45 / 60.
  final int gapMinutes;
  final int attendanceRemindersEnabled;

  /// Minutes after class end to fire marking reminder: 0 / 5 / 10.
  final int attendanceDelayMinutes;

  /// Show "Absent rest of day" action button.
  final int absentRestOfDayEnabled;

  /// 0 = never; positive = dismiss after N minutes; -1 = end of day.
  final int autoDismissMinutes;

  /// Danger alert (attendance below attendanceGoal).
  final int lowAttendanceAlertsEnabled;

  /// Include recovery suggestions in danger alert.
  final int recoverySuggestionsEnabled;

  /// Separate alert for attendance below criticalThreshold.
  final int criticalAttendanceEnabled;

  /// User-configurable critical threshold (0–100). Default 65.0.
  final double criticalThreshold;
  final int safeBunkPlannerEnabled;

  /// Hour for nightly bunk planner notification (0–23).
  final int plannerTimeHour;

  /// Minute for nightly bunk planner notification (0–59).
  final int plannerTimeMinute;

  /// Include safe-bunk subjects in planner notification.
  final int includeSafeBunks;
  final int plannerIncludeRecoverySuggestions;

  /// Include at-risk subjects in planner.
  final int includeRiskSubjects;

  /// Disabled by default.
  final int dailySummaryEnabled;

  /// Hour for daily summary (0–23).
  final int summaryTimeHour;

  /// Minute for daily summary (0–59).
  final int summaryTimeMinute;
  final int includeClassesAttended;
  final int includeClassesMissed;
  final int includeSubjectBreakdown;
  final int includeOverallAttendance;

  /// Last-modified timestamp — Unix timestamp (ms). Client-side clock.
  final int updatedAt;
  const NotificationPreference(
      {required this.id,
      required this.notificationsEnabled,
      required this.soundEnabled,
      required this.vibrationEnabled,
      required this.badgeCount,
      this.quietHoursStartHour,
      this.quietHoursStartMinute,
      this.quietHoursEndHour,
      this.quietHoursEndMinute,
      required this.classRemindersEnabled,
      required this.reminderMinutes,
      required this.onlyFirstClassReminder,
      required this.gapClassRemindersEnabled,
      required this.gapMinutes,
      required this.attendanceRemindersEnabled,
      required this.attendanceDelayMinutes,
      required this.absentRestOfDayEnabled,
      required this.autoDismissMinutes,
      required this.lowAttendanceAlertsEnabled,
      required this.recoverySuggestionsEnabled,
      required this.criticalAttendanceEnabled,
      required this.criticalThreshold,
      required this.safeBunkPlannerEnabled,
      required this.plannerTimeHour,
      required this.plannerTimeMinute,
      required this.includeSafeBunks,
      required this.plannerIncludeRecoverySuggestions,
      required this.includeRiskSubjects,
      required this.dailySummaryEnabled,
      required this.summaryTimeHour,
      required this.summaryTimeMinute,
      required this.includeClassesAttended,
      required this.includeClassesMissed,
      required this.includeSubjectBreakdown,
      required this.includeOverallAttendance,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notifications_enabled'] = Variable<int>(notificationsEnabled);
    map['sound_enabled'] = Variable<int>(soundEnabled);
    map['vibration_enabled'] = Variable<int>(vibrationEnabled);
    map['badge_count'] = Variable<int>(badgeCount);
    if (!nullToAbsent || quietHoursStartHour != null) {
      map['quiet_hours_start_hour'] = Variable<int>(quietHoursStartHour);
    }
    if (!nullToAbsent || quietHoursStartMinute != null) {
      map['quiet_hours_start_minute'] = Variable<int>(quietHoursStartMinute);
    }
    if (!nullToAbsent || quietHoursEndHour != null) {
      map['quiet_hours_end_hour'] = Variable<int>(quietHoursEndHour);
    }
    if (!nullToAbsent || quietHoursEndMinute != null) {
      map['quiet_hours_end_minute'] = Variable<int>(quietHoursEndMinute);
    }
    map['class_reminders_enabled'] = Variable<int>(classRemindersEnabled);
    map['reminder_minutes'] = Variable<int>(reminderMinutes);
    map['only_first_class_reminder'] = Variable<int>(onlyFirstClassReminder);
    map['gap_class_reminders_enabled'] =
        Variable<int>(gapClassRemindersEnabled);
    map['gap_minutes'] = Variable<int>(gapMinutes);
    map['attendance_reminders_enabled'] =
        Variable<int>(attendanceRemindersEnabled);
    map['attendance_delay_minutes'] = Variable<int>(attendanceDelayMinutes);
    map['absent_rest_of_day_enabled'] = Variable<int>(absentRestOfDayEnabled);
    map['auto_dismiss_minutes'] = Variable<int>(autoDismissMinutes);
    map['low_attendance_alerts_enabled'] =
        Variable<int>(lowAttendanceAlertsEnabled);
    map['recovery_suggestions_enabled'] =
        Variable<int>(recoverySuggestionsEnabled);
    map['critical_attendance_enabled'] =
        Variable<int>(criticalAttendanceEnabled);
    map['critical_threshold'] = Variable<double>(criticalThreshold);
    map['safe_bunk_planner_enabled'] = Variable<int>(safeBunkPlannerEnabled);
    map['planner_time_hour'] = Variable<int>(plannerTimeHour);
    map['planner_time_minute'] = Variable<int>(plannerTimeMinute);
    map['include_safe_bunks'] = Variable<int>(includeSafeBunks);
    map['planner_include_recovery_suggestions'] =
        Variable<int>(plannerIncludeRecoverySuggestions);
    map['include_risk_subjects'] = Variable<int>(includeRiskSubjects);
    map['daily_summary_enabled'] = Variable<int>(dailySummaryEnabled);
    map['summary_time_hour'] = Variable<int>(summaryTimeHour);
    map['summary_time_minute'] = Variable<int>(summaryTimeMinute);
    map['include_classes_attended'] = Variable<int>(includeClassesAttended);
    map['include_classes_missed'] = Variable<int>(includeClassesMissed);
    map['include_subject_breakdown'] = Variable<int>(includeSubjectBreakdown);
    map['include_overall_attendance'] = Variable<int>(includeOverallAttendance);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotificationPreferencesCompanion toCompanion(bool nullToAbsent) {
    return NotificationPreferencesCompanion(
      id: Value(id),
      notificationsEnabled: Value(notificationsEnabled),
      soundEnabled: Value(soundEnabled),
      vibrationEnabled: Value(vibrationEnabled),
      badgeCount: Value(badgeCount),
      quietHoursStartHour: quietHoursStartHour == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursStartHour),
      quietHoursStartMinute: quietHoursStartMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursStartMinute),
      quietHoursEndHour: quietHoursEndHour == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursEndHour),
      quietHoursEndMinute: quietHoursEndMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursEndMinute),
      classRemindersEnabled: Value(classRemindersEnabled),
      reminderMinutes: Value(reminderMinutes),
      onlyFirstClassReminder: Value(onlyFirstClassReminder),
      gapClassRemindersEnabled: Value(gapClassRemindersEnabled),
      gapMinutes: Value(gapMinutes),
      attendanceRemindersEnabled: Value(attendanceRemindersEnabled),
      attendanceDelayMinutes: Value(attendanceDelayMinutes),
      absentRestOfDayEnabled: Value(absentRestOfDayEnabled),
      autoDismissMinutes: Value(autoDismissMinutes),
      lowAttendanceAlertsEnabled: Value(lowAttendanceAlertsEnabled),
      recoverySuggestionsEnabled: Value(recoverySuggestionsEnabled),
      criticalAttendanceEnabled: Value(criticalAttendanceEnabled),
      criticalThreshold: Value(criticalThreshold),
      safeBunkPlannerEnabled: Value(safeBunkPlannerEnabled),
      plannerTimeHour: Value(plannerTimeHour),
      plannerTimeMinute: Value(plannerTimeMinute),
      includeSafeBunks: Value(includeSafeBunks),
      plannerIncludeRecoverySuggestions:
          Value(plannerIncludeRecoverySuggestions),
      includeRiskSubjects: Value(includeRiskSubjects),
      dailySummaryEnabled: Value(dailySummaryEnabled),
      summaryTimeHour: Value(summaryTimeHour),
      summaryTimeMinute: Value(summaryTimeMinute),
      includeClassesAttended: Value(includeClassesAttended),
      includeClassesMissed: Value(includeClassesMissed),
      includeSubjectBreakdown: Value(includeSubjectBreakdown),
      includeOverallAttendance: Value(includeOverallAttendance),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationPreference(
      id: serializer.fromJson<int>(json['id']),
      notificationsEnabled:
          serializer.fromJson<int>(json['notificationsEnabled']),
      soundEnabled: serializer.fromJson<int>(json['soundEnabled']),
      vibrationEnabled: serializer.fromJson<int>(json['vibrationEnabled']),
      badgeCount: serializer.fromJson<int>(json['badgeCount']),
      quietHoursStartHour:
          serializer.fromJson<int?>(json['quietHoursStartHour']),
      quietHoursStartMinute:
          serializer.fromJson<int?>(json['quietHoursStartMinute']),
      quietHoursEndHour: serializer.fromJson<int?>(json['quietHoursEndHour']),
      quietHoursEndMinute:
          serializer.fromJson<int?>(json['quietHoursEndMinute']),
      classRemindersEnabled:
          serializer.fromJson<int>(json['classRemindersEnabled']),
      reminderMinutes: serializer.fromJson<int>(json['reminderMinutes']),
      onlyFirstClassReminder:
          serializer.fromJson<int>(json['onlyFirstClassReminder']),
      gapClassRemindersEnabled:
          serializer.fromJson<int>(json['gapClassRemindersEnabled']),
      gapMinutes: serializer.fromJson<int>(json['gapMinutes']),
      attendanceRemindersEnabled:
          serializer.fromJson<int>(json['attendanceRemindersEnabled']),
      attendanceDelayMinutes:
          serializer.fromJson<int>(json['attendanceDelayMinutes']),
      absentRestOfDayEnabled:
          serializer.fromJson<int>(json['absentRestOfDayEnabled']),
      autoDismissMinutes: serializer.fromJson<int>(json['autoDismissMinutes']),
      lowAttendanceAlertsEnabled:
          serializer.fromJson<int>(json['lowAttendanceAlertsEnabled']),
      recoverySuggestionsEnabled:
          serializer.fromJson<int>(json['recoverySuggestionsEnabled']),
      criticalAttendanceEnabled:
          serializer.fromJson<int>(json['criticalAttendanceEnabled']),
      criticalThreshold: serializer.fromJson<double>(json['criticalThreshold']),
      safeBunkPlannerEnabled:
          serializer.fromJson<int>(json['safeBunkPlannerEnabled']),
      plannerTimeHour: serializer.fromJson<int>(json['plannerTimeHour']),
      plannerTimeMinute: serializer.fromJson<int>(json['plannerTimeMinute']),
      includeSafeBunks: serializer.fromJson<int>(json['includeSafeBunks']),
      plannerIncludeRecoverySuggestions:
          serializer.fromJson<int>(json['plannerIncludeRecoverySuggestions']),
      includeRiskSubjects:
          serializer.fromJson<int>(json['includeRiskSubjects']),
      dailySummaryEnabled:
          serializer.fromJson<int>(json['dailySummaryEnabled']),
      summaryTimeHour: serializer.fromJson<int>(json['summaryTimeHour']),
      summaryTimeMinute: serializer.fromJson<int>(json['summaryTimeMinute']),
      includeClassesAttended:
          serializer.fromJson<int>(json['includeClassesAttended']),
      includeClassesMissed:
          serializer.fromJson<int>(json['includeClassesMissed']),
      includeSubjectBreakdown:
          serializer.fromJson<int>(json['includeSubjectBreakdown']),
      includeOverallAttendance:
          serializer.fromJson<int>(json['includeOverallAttendance']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notificationsEnabled': serializer.toJson<int>(notificationsEnabled),
      'soundEnabled': serializer.toJson<int>(soundEnabled),
      'vibrationEnabled': serializer.toJson<int>(vibrationEnabled),
      'badgeCount': serializer.toJson<int>(badgeCount),
      'quietHoursStartHour': serializer.toJson<int?>(quietHoursStartHour),
      'quietHoursStartMinute': serializer.toJson<int?>(quietHoursStartMinute),
      'quietHoursEndHour': serializer.toJson<int?>(quietHoursEndHour),
      'quietHoursEndMinute': serializer.toJson<int?>(quietHoursEndMinute),
      'classRemindersEnabled': serializer.toJson<int>(classRemindersEnabled),
      'reminderMinutes': serializer.toJson<int>(reminderMinutes),
      'onlyFirstClassReminder': serializer.toJson<int>(onlyFirstClassReminder),
      'gapClassRemindersEnabled':
          serializer.toJson<int>(gapClassRemindersEnabled),
      'gapMinutes': serializer.toJson<int>(gapMinutes),
      'attendanceRemindersEnabled':
          serializer.toJson<int>(attendanceRemindersEnabled),
      'attendanceDelayMinutes': serializer.toJson<int>(attendanceDelayMinutes),
      'absentRestOfDayEnabled': serializer.toJson<int>(absentRestOfDayEnabled),
      'autoDismissMinutes': serializer.toJson<int>(autoDismissMinutes),
      'lowAttendanceAlertsEnabled':
          serializer.toJson<int>(lowAttendanceAlertsEnabled),
      'recoverySuggestionsEnabled':
          serializer.toJson<int>(recoverySuggestionsEnabled),
      'criticalAttendanceEnabled':
          serializer.toJson<int>(criticalAttendanceEnabled),
      'criticalThreshold': serializer.toJson<double>(criticalThreshold),
      'safeBunkPlannerEnabled': serializer.toJson<int>(safeBunkPlannerEnabled),
      'plannerTimeHour': serializer.toJson<int>(plannerTimeHour),
      'plannerTimeMinute': serializer.toJson<int>(plannerTimeMinute),
      'includeSafeBunks': serializer.toJson<int>(includeSafeBunks),
      'plannerIncludeRecoverySuggestions':
          serializer.toJson<int>(plannerIncludeRecoverySuggestions),
      'includeRiskSubjects': serializer.toJson<int>(includeRiskSubjects),
      'dailySummaryEnabled': serializer.toJson<int>(dailySummaryEnabled),
      'summaryTimeHour': serializer.toJson<int>(summaryTimeHour),
      'summaryTimeMinute': serializer.toJson<int>(summaryTimeMinute),
      'includeClassesAttended': serializer.toJson<int>(includeClassesAttended),
      'includeClassesMissed': serializer.toJson<int>(includeClassesMissed),
      'includeSubjectBreakdown':
          serializer.toJson<int>(includeSubjectBreakdown),
      'includeOverallAttendance':
          serializer.toJson<int>(includeOverallAttendance),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotificationPreference copyWith(
          {int? id,
          int? notificationsEnabled,
          int? soundEnabled,
          int? vibrationEnabled,
          int? badgeCount,
          Value<int?> quietHoursStartHour = const Value.absent(),
          Value<int?> quietHoursStartMinute = const Value.absent(),
          Value<int?> quietHoursEndHour = const Value.absent(),
          Value<int?> quietHoursEndMinute = const Value.absent(),
          int? classRemindersEnabled,
          int? reminderMinutes,
          int? onlyFirstClassReminder,
          int? gapClassRemindersEnabled,
          int? gapMinutes,
          int? attendanceRemindersEnabled,
          int? attendanceDelayMinutes,
          int? absentRestOfDayEnabled,
          int? autoDismissMinutes,
          int? lowAttendanceAlertsEnabled,
          int? recoverySuggestionsEnabled,
          int? criticalAttendanceEnabled,
          double? criticalThreshold,
          int? safeBunkPlannerEnabled,
          int? plannerTimeHour,
          int? plannerTimeMinute,
          int? includeSafeBunks,
          int? plannerIncludeRecoverySuggestions,
          int? includeRiskSubjects,
          int? dailySummaryEnabled,
          int? summaryTimeHour,
          int? summaryTimeMinute,
          int? includeClassesAttended,
          int? includeClassesMissed,
          int? includeSubjectBreakdown,
          int? includeOverallAttendance,
          int? updatedAt}) =>
      NotificationPreference(
        id: id ?? this.id,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        badgeCount: badgeCount ?? this.badgeCount,
        quietHoursStartHour: quietHoursStartHour.present
            ? quietHoursStartHour.value
            : this.quietHoursStartHour,
        quietHoursStartMinute: quietHoursStartMinute.present
            ? quietHoursStartMinute.value
            : this.quietHoursStartMinute,
        quietHoursEndHour: quietHoursEndHour.present
            ? quietHoursEndHour.value
            : this.quietHoursEndHour,
        quietHoursEndMinute: quietHoursEndMinute.present
            ? quietHoursEndMinute.value
            : this.quietHoursEndMinute,
        classRemindersEnabled:
            classRemindersEnabled ?? this.classRemindersEnabled,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        onlyFirstClassReminder:
            onlyFirstClassReminder ?? this.onlyFirstClassReminder,
        gapClassRemindersEnabled:
            gapClassRemindersEnabled ?? this.gapClassRemindersEnabled,
        gapMinutes: gapMinutes ?? this.gapMinutes,
        attendanceRemindersEnabled:
            attendanceRemindersEnabled ?? this.attendanceRemindersEnabled,
        attendanceDelayMinutes:
            attendanceDelayMinutes ?? this.attendanceDelayMinutes,
        absentRestOfDayEnabled:
            absentRestOfDayEnabled ?? this.absentRestOfDayEnabled,
        autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
        lowAttendanceAlertsEnabled:
            lowAttendanceAlertsEnabled ?? this.lowAttendanceAlertsEnabled,
        recoverySuggestionsEnabled:
            recoverySuggestionsEnabled ?? this.recoverySuggestionsEnabled,
        criticalAttendanceEnabled:
            criticalAttendanceEnabled ?? this.criticalAttendanceEnabled,
        criticalThreshold: criticalThreshold ?? this.criticalThreshold,
        safeBunkPlannerEnabled:
            safeBunkPlannerEnabled ?? this.safeBunkPlannerEnabled,
        plannerTimeHour: plannerTimeHour ?? this.plannerTimeHour,
        plannerTimeMinute: plannerTimeMinute ?? this.plannerTimeMinute,
        includeSafeBunks: includeSafeBunks ?? this.includeSafeBunks,
        plannerIncludeRecoverySuggestions: plannerIncludeRecoverySuggestions ??
            this.plannerIncludeRecoverySuggestions,
        includeRiskSubjects: includeRiskSubjects ?? this.includeRiskSubjects,
        dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
        summaryTimeHour: summaryTimeHour ?? this.summaryTimeHour,
        summaryTimeMinute: summaryTimeMinute ?? this.summaryTimeMinute,
        includeClassesAttended:
            includeClassesAttended ?? this.includeClassesAttended,
        includeClassesMissed: includeClassesMissed ?? this.includeClassesMissed,
        includeSubjectBreakdown:
            includeSubjectBreakdown ?? this.includeSubjectBreakdown,
        includeOverallAttendance:
            includeOverallAttendance ?? this.includeOverallAttendance,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  NotificationPreference copyWithCompanion(
      NotificationPreferencesCompanion data) {
    return NotificationPreference(
      id: data.id.present ? data.id.value : this.id,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      soundEnabled: data.soundEnabled.present
          ? data.soundEnabled.value
          : this.soundEnabled,
      vibrationEnabled: data.vibrationEnabled.present
          ? data.vibrationEnabled.value
          : this.vibrationEnabled,
      badgeCount:
          data.badgeCount.present ? data.badgeCount.value : this.badgeCount,
      quietHoursStartHour: data.quietHoursStartHour.present
          ? data.quietHoursStartHour.value
          : this.quietHoursStartHour,
      quietHoursStartMinute: data.quietHoursStartMinute.present
          ? data.quietHoursStartMinute.value
          : this.quietHoursStartMinute,
      quietHoursEndHour: data.quietHoursEndHour.present
          ? data.quietHoursEndHour.value
          : this.quietHoursEndHour,
      quietHoursEndMinute: data.quietHoursEndMinute.present
          ? data.quietHoursEndMinute.value
          : this.quietHoursEndMinute,
      classRemindersEnabled: data.classRemindersEnabled.present
          ? data.classRemindersEnabled.value
          : this.classRemindersEnabled,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      onlyFirstClassReminder: data.onlyFirstClassReminder.present
          ? data.onlyFirstClassReminder.value
          : this.onlyFirstClassReminder,
      gapClassRemindersEnabled: data.gapClassRemindersEnabled.present
          ? data.gapClassRemindersEnabled.value
          : this.gapClassRemindersEnabled,
      gapMinutes:
          data.gapMinutes.present ? data.gapMinutes.value : this.gapMinutes,
      attendanceRemindersEnabled: data.attendanceRemindersEnabled.present
          ? data.attendanceRemindersEnabled.value
          : this.attendanceRemindersEnabled,
      attendanceDelayMinutes: data.attendanceDelayMinutes.present
          ? data.attendanceDelayMinutes.value
          : this.attendanceDelayMinutes,
      absentRestOfDayEnabled: data.absentRestOfDayEnabled.present
          ? data.absentRestOfDayEnabled.value
          : this.absentRestOfDayEnabled,
      autoDismissMinutes: data.autoDismissMinutes.present
          ? data.autoDismissMinutes.value
          : this.autoDismissMinutes,
      lowAttendanceAlertsEnabled: data.lowAttendanceAlertsEnabled.present
          ? data.lowAttendanceAlertsEnabled.value
          : this.lowAttendanceAlertsEnabled,
      recoverySuggestionsEnabled: data.recoverySuggestionsEnabled.present
          ? data.recoverySuggestionsEnabled.value
          : this.recoverySuggestionsEnabled,
      criticalAttendanceEnabled: data.criticalAttendanceEnabled.present
          ? data.criticalAttendanceEnabled.value
          : this.criticalAttendanceEnabled,
      criticalThreshold: data.criticalThreshold.present
          ? data.criticalThreshold.value
          : this.criticalThreshold,
      safeBunkPlannerEnabled: data.safeBunkPlannerEnabled.present
          ? data.safeBunkPlannerEnabled.value
          : this.safeBunkPlannerEnabled,
      plannerTimeHour: data.plannerTimeHour.present
          ? data.plannerTimeHour.value
          : this.plannerTimeHour,
      plannerTimeMinute: data.plannerTimeMinute.present
          ? data.plannerTimeMinute.value
          : this.plannerTimeMinute,
      includeSafeBunks: data.includeSafeBunks.present
          ? data.includeSafeBunks.value
          : this.includeSafeBunks,
      plannerIncludeRecoverySuggestions:
          data.plannerIncludeRecoverySuggestions.present
              ? data.plannerIncludeRecoverySuggestions.value
              : this.plannerIncludeRecoverySuggestions,
      includeRiskSubjects: data.includeRiskSubjects.present
          ? data.includeRiskSubjects.value
          : this.includeRiskSubjects,
      dailySummaryEnabled: data.dailySummaryEnabled.present
          ? data.dailySummaryEnabled.value
          : this.dailySummaryEnabled,
      summaryTimeHour: data.summaryTimeHour.present
          ? data.summaryTimeHour.value
          : this.summaryTimeHour,
      summaryTimeMinute: data.summaryTimeMinute.present
          ? data.summaryTimeMinute.value
          : this.summaryTimeMinute,
      includeClassesAttended: data.includeClassesAttended.present
          ? data.includeClassesAttended.value
          : this.includeClassesAttended,
      includeClassesMissed: data.includeClassesMissed.present
          ? data.includeClassesMissed.value
          : this.includeClassesMissed,
      includeSubjectBreakdown: data.includeSubjectBreakdown.present
          ? data.includeSubjectBreakdown.value
          : this.includeSubjectBreakdown,
      includeOverallAttendance: data.includeOverallAttendance.present
          ? data.includeOverallAttendance.value
          : this.includeOverallAttendance,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreference(')
          ..write('id: $id, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('vibrationEnabled: $vibrationEnabled, ')
          ..write('badgeCount: $badgeCount, ')
          ..write('quietHoursStartHour: $quietHoursStartHour, ')
          ..write('quietHoursStartMinute: $quietHoursStartMinute, ')
          ..write('quietHoursEndHour: $quietHoursEndHour, ')
          ..write('quietHoursEndMinute: $quietHoursEndMinute, ')
          ..write('classRemindersEnabled: $classRemindersEnabled, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('onlyFirstClassReminder: $onlyFirstClassReminder, ')
          ..write('gapClassRemindersEnabled: $gapClassRemindersEnabled, ')
          ..write('gapMinutes: $gapMinutes, ')
          ..write('attendanceRemindersEnabled: $attendanceRemindersEnabled, ')
          ..write('attendanceDelayMinutes: $attendanceDelayMinutes, ')
          ..write('absentRestOfDayEnabled: $absentRestOfDayEnabled, ')
          ..write('autoDismissMinutes: $autoDismissMinutes, ')
          ..write('lowAttendanceAlertsEnabled: $lowAttendanceAlertsEnabled, ')
          ..write('recoverySuggestionsEnabled: $recoverySuggestionsEnabled, ')
          ..write('criticalAttendanceEnabled: $criticalAttendanceEnabled, ')
          ..write('criticalThreshold: $criticalThreshold, ')
          ..write('safeBunkPlannerEnabled: $safeBunkPlannerEnabled, ')
          ..write('plannerTimeHour: $plannerTimeHour, ')
          ..write('plannerTimeMinute: $plannerTimeMinute, ')
          ..write('includeSafeBunks: $includeSafeBunks, ')
          ..write(
              'plannerIncludeRecoverySuggestions: $plannerIncludeRecoverySuggestions, ')
          ..write('includeRiskSubjects: $includeRiskSubjects, ')
          ..write('dailySummaryEnabled: $dailySummaryEnabled, ')
          ..write('summaryTimeHour: $summaryTimeHour, ')
          ..write('summaryTimeMinute: $summaryTimeMinute, ')
          ..write('includeClassesAttended: $includeClassesAttended, ')
          ..write('includeClassesMissed: $includeClassesMissed, ')
          ..write('includeSubjectBreakdown: $includeSubjectBreakdown, ')
          ..write('includeOverallAttendance: $includeOverallAttendance, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        badgeCount,
        quietHoursStartHour,
        quietHoursStartMinute,
        quietHoursEndHour,
        quietHoursEndMinute,
        classRemindersEnabled,
        reminderMinutes,
        onlyFirstClassReminder,
        gapClassRemindersEnabled,
        gapMinutes,
        attendanceRemindersEnabled,
        attendanceDelayMinutes,
        absentRestOfDayEnabled,
        autoDismissMinutes,
        lowAttendanceAlertsEnabled,
        recoverySuggestionsEnabled,
        criticalAttendanceEnabled,
        criticalThreshold,
        safeBunkPlannerEnabled,
        plannerTimeHour,
        plannerTimeMinute,
        includeSafeBunks,
        plannerIncludeRecoverySuggestions,
        includeRiskSubjects,
        dailySummaryEnabled,
        summaryTimeHour,
        summaryTimeMinute,
        includeClassesAttended,
        includeClassesMissed,
        includeSubjectBreakdown,
        includeOverallAttendance,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPreference &&
          other.id == this.id &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.soundEnabled == this.soundEnabled &&
          other.vibrationEnabled == this.vibrationEnabled &&
          other.badgeCount == this.badgeCount &&
          other.quietHoursStartHour == this.quietHoursStartHour &&
          other.quietHoursStartMinute == this.quietHoursStartMinute &&
          other.quietHoursEndHour == this.quietHoursEndHour &&
          other.quietHoursEndMinute == this.quietHoursEndMinute &&
          other.classRemindersEnabled == this.classRemindersEnabled &&
          other.reminderMinutes == this.reminderMinutes &&
          other.onlyFirstClassReminder == this.onlyFirstClassReminder &&
          other.gapClassRemindersEnabled == this.gapClassRemindersEnabled &&
          other.gapMinutes == this.gapMinutes &&
          other.attendanceRemindersEnabled == this.attendanceRemindersEnabled &&
          other.attendanceDelayMinutes == this.attendanceDelayMinutes &&
          other.absentRestOfDayEnabled == this.absentRestOfDayEnabled &&
          other.autoDismissMinutes == this.autoDismissMinutes &&
          other.lowAttendanceAlertsEnabled == this.lowAttendanceAlertsEnabled &&
          other.recoverySuggestionsEnabled == this.recoverySuggestionsEnabled &&
          other.criticalAttendanceEnabled == this.criticalAttendanceEnabled &&
          other.criticalThreshold == this.criticalThreshold &&
          other.safeBunkPlannerEnabled == this.safeBunkPlannerEnabled &&
          other.plannerTimeHour == this.plannerTimeHour &&
          other.plannerTimeMinute == this.plannerTimeMinute &&
          other.includeSafeBunks == this.includeSafeBunks &&
          other.plannerIncludeRecoverySuggestions ==
              this.plannerIncludeRecoverySuggestions &&
          other.includeRiskSubjects == this.includeRiskSubjects &&
          other.dailySummaryEnabled == this.dailySummaryEnabled &&
          other.summaryTimeHour == this.summaryTimeHour &&
          other.summaryTimeMinute == this.summaryTimeMinute &&
          other.includeClassesAttended == this.includeClassesAttended &&
          other.includeClassesMissed == this.includeClassesMissed &&
          other.includeSubjectBreakdown == this.includeSubjectBreakdown &&
          other.includeOverallAttendance == this.includeOverallAttendance &&
          other.updatedAt == this.updatedAt);
}

class NotificationPreferencesCompanion
    extends UpdateCompanion<NotificationPreference> {
  final Value<int> id;
  final Value<int> notificationsEnabled;
  final Value<int> soundEnabled;
  final Value<int> vibrationEnabled;
  final Value<int> badgeCount;
  final Value<int?> quietHoursStartHour;
  final Value<int?> quietHoursStartMinute;
  final Value<int?> quietHoursEndHour;
  final Value<int?> quietHoursEndMinute;
  final Value<int> classRemindersEnabled;
  final Value<int> reminderMinutes;
  final Value<int> onlyFirstClassReminder;
  final Value<int> gapClassRemindersEnabled;
  final Value<int> gapMinutes;
  final Value<int> attendanceRemindersEnabled;
  final Value<int> attendanceDelayMinutes;
  final Value<int> absentRestOfDayEnabled;
  final Value<int> autoDismissMinutes;
  final Value<int> lowAttendanceAlertsEnabled;
  final Value<int> recoverySuggestionsEnabled;
  final Value<int> criticalAttendanceEnabled;
  final Value<double> criticalThreshold;
  final Value<int> safeBunkPlannerEnabled;
  final Value<int> plannerTimeHour;
  final Value<int> plannerTimeMinute;
  final Value<int> includeSafeBunks;
  final Value<int> plannerIncludeRecoverySuggestions;
  final Value<int> includeRiskSubjects;
  final Value<int> dailySummaryEnabled;
  final Value<int> summaryTimeHour;
  final Value<int> summaryTimeMinute;
  final Value<int> includeClassesAttended;
  final Value<int> includeClassesMissed;
  final Value<int> includeSubjectBreakdown;
  final Value<int> includeOverallAttendance;
  final Value<int> updatedAt;
  const NotificationPreferencesCompanion({
    this.id = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.vibrationEnabled = const Value.absent(),
    this.badgeCount = const Value.absent(),
    this.quietHoursStartHour = const Value.absent(),
    this.quietHoursStartMinute = const Value.absent(),
    this.quietHoursEndHour = const Value.absent(),
    this.quietHoursEndMinute = const Value.absent(),
    this.classRemindersEnabled = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.onlyFirstClassReminder = const Value.absent(),
    this.gapClassRemindersEnabled = const Value.absent(),
    this.gapMinutes = const Value.absent(),
    this.attendanceRemindersEnabled = const Value.absent(),
    this.attendanceDelayMinutes = const Value.absent(),
    this.absentRestOfDayEnabled = const Value.absent(),
    this.autoDismissMinutes = const Value.absent(),
    this.lowAttendanceAlertsEnabled = const Value.absent(),
    this.recoverySuggestionsEnabled = const Value.absent(),
    this.criticalAttendanceEnabled = const Value.absent(),
    this.criticalThreshold = const Value.absent(),
    this.safeBunkPlannerEnabled = const Value.absent(),
    this.plannerTimeHour = const Value.absent(),
    this.plannerTimeMinute = const Value.absent(),
    this.includeSafeBunks = const Value.absent(),
    this.plannerIncludeRecoverySuggestions = const Value.absent(),
    this.includeRiskSubjects = const Value.absent(),
    this.dailySummaryEnabled = const Value.absent(),
    this.summaryTimeHour = const Value.absent(),
    this.summaryTimeMinute = const Value.absent(),
    this.includeClassesAttended = const Value.absent(),
    this.includeClassesMissed = const Value.absent(),
    this.includeSubjectBreakdown = const Value.absent(),
    this.includeOverallAttendance = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotificationPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.vibrationEnabled = const Value.absent(),
    this.badgeCount = const Value.absent(),
    this.quietHoursStartHour = const Value.absent(),
    this.quietHoursStartMinute = const Value.absent(),
    this.quietHoursEndHour = const Value.absent(),
    this.quietHoursEndMinute = const Value.absent(),
    this.classRemindersEnabled = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.onlyFirstClassReminder = const Value.absent(),
    this.gapClassRemindersEnabled = const Value.absent(),
    this.gapMinutes = const Value.absent(),
    this.attendanceRemindersEnabled = const Value.absent(),
    this.attendanceDelayMinutes = const Value.absent(),
    this.absentRestOfDayEnabled = const Value.absent(),
    this.autoDismissMinutes = const Value.absent(),
    this.lowAttendanceAlertsEnabled = const Value.absent(),
    this.recoverySuggestionsEnabled = const Value.absent(),
    this.criticalAttendanceEnabled = const Value.absent(),
    this.criticalThreshold = const Value.absent(),
    this.safeBunkPlannerEnabled = const Value.absent(),
    this.plannerTimeHour = const Value.absent(),
    this.plannerTimeMinute = const Value.absent(),
    this.includeSafeBunks = const Value.absent(),
    this.plannerIncludeRecoverySuggestions = const Value.absent(),
    this.includeRiskSubjects = const Value.absent(),
    this.dailySummaryEnabled = const Value.absent(),
    this.summaryTimeHour = const Value.absent(),
    this.summaryTimeMinute = const Value.absent(),
    this.includeClassesAttended = const Value.absent(),
    this.includeClassesMissed = const Value.absent(),
    this.includeSubjectBreakdown = const Value.absent(),
    this.includeOverallAttendance = const Value.absent(),
    required int updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<NotificationPreference> custom({
    Expression<int>? id,
    Expression<int>? notificationsEnabled,
    Expression<int>? soundEnabled,
    Expression<int>? vibrationEnabled,
    Expression<int>? badgeCount,
    Expression<int>? quietHoursStartHour,
    Expression<int>? quietHoursStartMinute,
    Expression<int>? quietHoursEndHour,
    Expression<int>? quietHoursEndMinute,
    Expression<int>? classRemindersEnabled,
    Expression<int>? reminderMinutes,
    Expression<int>? onlyFirstClassReminder,
    Expression<int>? gapClassRemindersEnabled,
    Expression<int>? gapMinutes,
    Expression<int>? attendanceRemindersEnabled,
    Expression<int>? attendanceDelayMinutes,
    Expression<int>? absentRestOfDayEnabled,
    Expression<int>? autoDismissMinutes,
    Expression<int>? lowAttendanceAlertsEnabled,
    Expression<int>? recoverySuggestionsEnabled,
    Expression<int>? criticalAttendanceEnabled,
    Expression<double>? criticalThreshold,
    Expression<int>? safeBunkPlannerEnabled,
    Expression<int>? plannerTimeHour,
    Expression<int>? plannerTimeMinute,
    Expression<int>? includeSafeBunks,
    Expression<int>? plannerIncludeRecoverySuggestions,
    Expression<int>? includeRiskSubjects,
    Expression<int>? dailySummaryEnabled,
    Expression<int>? summaryTimeHour,
    Expression<int>? summaryTimeMinute,
    Expression<int>? includeClassesAttended,
    Expression<int>? includeClassesMissed,
    Expression<int>? includeSubjectBreakdown,
    Expression<int>? includeOverallAttendance,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (soundEnabled != null) 'sound_enabled': soundEnabled,
      if (vibrationEnabled != null) 'vibration_enabled': vibrationEnabled,
      if (badgeCount != null) 'badge_count': badgeCount,
      if (quietHoursStartHour != null)
        'quiet_hours_start_hour': quietHoursStartHour,
      if (quietHoursStartMinute != null)
        'quiet_hours_start_minute': quietHoursStartMinute,
      if (quietHoursEndHour != null) 'quiet_hours_end_hour': quietHoursEndHour,
      if (quietHoursEndMinute != null)
        'quiet_hours_end_minute': quietHoursEndMinute,
      if (classRemindersEnabled != null)
        'class_reminders_enabled': classRemindersEnabled,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (onlyFirstClassReminder != null)
        'only_first_class_reminder': onlyFirstClassReminder,
      if (gapClassRemindersEnabled != null)
        'gap_class_reminders_enabled': gapClassRemindersEnabled,
      if (gapMinutes != null) 'gap_minutes': gapMinutes,
      if (attendanceRemindersEnabled != null)
        'attendance_reminders_enabled': attendanceRemindersEnabled,
      if (attendanceDelayMinutes != null)
        'attendance_delay_minutes': attendanceDelayMinutes,
      if (absentRestOfDayEnabled != null)
        'absent_rest_of_day_enabled': absentRestOfDayEnabled,
      if (autoDismissMinutes != null)
        'auto_dismiss_minutes': autoDismissMinutes,
      if (lowAttendanceAlertsEnabled != null)
        'low_attendance_alerts_enabled': lowAttendanceAlertsEnabled,
      if (recoverySuggestionsEnabled != null)
        'recovery_suggestions_enabled': recoverySuggestionsEnabled,
      if (criticalAttendanceEnabled != null)
        'critical_attendance_enabled': criticalAttendanceEnabled,
      if (criticalThreshold != null) 'critical_threshold': criticalThreshold,
      if (safeBunkPlannerEnabled != null)
        'safe_bunk_planner_enabled': safeBunkPlannerEnabled,
      if (plannerTimeHour != null) 'planner_time_hour': plannerTimeHour,
      if (plannerTimeMinute != null) 'planner_time_minute': plannerTimeMinute,
      if (includeSafeBunks != null) 'include_safe_bunks': includeSafeBunks,
      if (plannerIncludeRecoverySuggestions != null)
        'planner_include_recovery_suggestions':
            plannerIncludeRecoverySuggestions,
      if (includeRiskSubjects != null)
        'include_risk_subjects': includeRiskSubjects,
      if (dailySummaryEnabled != null)
        'daily_summary_enabled': dailySummaryEnabled,
      if (summaryTimeHour != null) 'summary_time_hour': summaryTimeHour,
      if (summaryTimeMinute != null) 'summary_time_minute': summaryTimeMinute,
      if (includeClassesAttended != null)
        'include_classes_attended': includeClassesAttended,
      if (includeClassesMissed != null)
        'include_classes_missed': includeClassesMissed,
      if (includeSubjectBreakdown != null)
        'include_subject_breakdown': includeSubjectBreakdown,
      if (includeOverallAttendance != null)
        'include_overall_attendance': includeOverallAttendance,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotificationPreferencesCompanion copyWith(
      {Value<int>? id,
      Value<int>? notificationsEnabled,
      Value<int>? soundEnabled,
      Value<int>? vibrationEnabled,
      Value<int>? badgeCount,
      Value<int?>? quietHoursStartHour,
      Value<int?>? quietHoursStartMinute,
      Value<int?>? quietHoursEndHour,
      Value<int?>? quietHoursEndMinute,
      Value<int>? classRemindersEnabled,
      Value<int>? reminderMinutes,
      Value<int>? onlyFirstClassReminder,
      Value<int>? gapClassRemindersEnabled,
      Value<int>? gapMinutes,
      Value<int>? attendanceRemindersEnabled,
      Value<int>? attendanceDelayMinutes,
      Value<int>? absentRestOfDayEnabled,
      Value<int>? autoDismissMinutes,
      Value<int>? lowAttendanceAlertsEnabled,
      Value<int>? recoverySuggestionsEnabled,
      Value<int>? criticalAttendanceEnabled,
      Value<double>? criticalThreshold,
      Value<int>? safeBunkPlannerEnabled,
      Value<int>? plannerTimeHour,
      Value<int>? plannerTimeMinute,
      Value<int>? includeSafeBunks,
      Value<int>? plannerIncludeRecoverySuggestions,
      Value<int>? includeRiskSubjects,
      Value<int>? dailySummaryEnabled,
      Value<int>? summaryTimeHour,
      Value<int>? summaryTimeMinute,
      Value<int>? includeClassesAttended,
      Value<int>? includeClassesMissed,
      Value<int>? includeSubjectBreakdown,
      Value<int>? includeOverallAttendance,
      Value<int>? updatedAt}) {
    return NotificationPreferencesCompanion(
      id: id ?? this.id,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeCount: badgeCount ?? this.badgeCount,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      classRemindersEnabled:
          classRemindersEnabled ?? this.classRemindersEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      onlyFirstClassReminder:
          onlyFirstClassReminder ?? this.onlyFirstClassReminder,
      gapClassRemindersEnabled:
          gapClassRemindersEnabled ?? this.gapClassRemindersEnabled,
      gapMinutes: gapMinutes ?? this.gapMinutes,
      attendanceRemindersEnabled:
          attendanceRemindersEnabled ?? this.attendanceRemindersEnabled,
      attendanceDelayMinutes:
          attendanceDelayMinutes ?? this.attendanceDelayMinutes,
      absentRestOfDayEnabled:
          absentRestOfDayEnabled ?? this.absentRestOfDayEnabled,
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
      lowAttendanceAlertsEnabled:
          lowAttendanceAlertsEnabled ?? this.lowAttendanceAlertsEnabled,
      recoverySuggestionsEnabled:
          recoverySuggestionsEnabled ?? this.recoverySuggestionsEnabled,
      criticalAttendanceEnabled:
          criticalAttendanceEnabled ?? this.criticalAttendanceEnabled,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      safeBunkPlannerEnabled:
          safeBunkPlannerEnabled ?? this.safeBunkPlannerEnabled,
      plannerTimeHour: plannerTimeHour ?? this.plannerTimeHour,
      plannerTimeMinute: plannerTimeMinute ?? this.plannerTimeMinute,
      includeSafeBunks: includeSafeBunks ?? this.includeSafeBunks,
      plannerIncludeRecoverySuggestions: plannerIncludeRecoverySuggestions ??
          this.plannerIncludeRecoverySuggestions,
      includeRiskSubjects: includeRiskSubjects ?? this.includeRiskSubjects,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      summaryTimeHour: summaryTimeHour ?? this.summaryTimeHour,
      summaryTimeMinute: summaryTimeMinute ?? this.summaryTimeMinute,
      includeClassesAttended:
          includeClassesAttended ?? this.includeClassesAttended,
      includeClassesMissed: includeClassesMissed ?? this.includeClassesMissed,
      includeSubjectBreakdown:
          includeSubjectBreakdown ?? this.includeSubjectBreakdown,
      includeOverallAttendance:
          includeOverallAttendance ?? this.includeOverallAttendance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<int>(notificationsEnabled.value);
    }
    if (soundEnabled.present) {
      map['sound_enabled'] = Variable<int>(soundEnabled.value);
    }
    if (vibrationEnabled.present) {
      map['vibration_enabled'] = Variable<int>(vibrationEnabled.value);
    }
    if (badgeCount.present) {
      map['badge_count'] = Variable<int>(badgeCount.value);
    }
    if (quietHoursStartHour.present) {
      map['quiet_hours_start_hour'] = Variable<int>(quietHoursStartHour.value);
    }
    if (quietHoursStartMinute.present) {
      map['quiet_hours_start_minute'] =
          Variable<int>(quietHoursStartMinute.value);
    }
    if (quietHoursEndHour.present) {
      map['quiet_hours_end_hour'] = Variable<int>(quietHoursEndHour.value);
    }
    if (quietHoursEndMinute.present) {
      map['quiet_hours_end_minute'] = Variable<int>(quietHoursEndMinute.value);
    }
    if (classRemindersEnabled.present) {
      map['class_reminders_enabled'] =
          Variable<int>(classRemindersEnabled.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (onlyFirstClassReminder.present) {
      map['only_first_class_reminder'] =
          Variable<int>(onlyFirstClassReminder.value);
    }
    if (gapClassRemindersEnabled.present) {
      map['gap_class_reminders_enabled'] =
          Variable<int>(gapClassRemindersEnabled.value);
    }
    if (gapMinutes.present) {
      map['gap_minutes'] = Variable<int>(gapMinutes.value);
    }
    if (attendanceRemindersEnabled.present) {
      map['attendance_reminders_enabled'] =
          Variable<int>(attendanceRemindersEnabled.value);
    }
    if (attendanceDelayMinutes.present) {
      map['attendance_delay_minutes'] =
          Variable<int>(attendanceDelayMinutes.value);
    }
    if (absentRestOfDayEnabled.present) {
      map['absent_rest_of_day_enabled'] =
          Variable<int>(absentRestOfDayEnabled.value);
    }
    if (autoDismissMinutes.present) {
      map['auto_dismiss_minutes'] = Variable<int>(autoDismissMinutes.value);
    }
    if (lowAttendanceAlertsEnabled.present) {
      map['low_attendance_alerts_enabled'] =
          Variable<int>(lowAttendanceAlertsEnabled.value);
    }
    if (recoverySuggestionsEnabled.present) {
      map['recovery_suggestions_enabled'] =
          Variable<int>(recoverySuggestionsEnabled.value);
    }
    if (criticalAttendanceEnabled.present) {
      map['critical_attendance_enabled'] =
          Variable<int>(criticalAttendanceEnabled.value);
    }
    if (criticalThreshold.present) {
      map['critical_threshold'] = Variable<double>(criticalThreshold.value);
    }
    if (safeBunkPlannerEnabled.present) {
      map['safe_bunk_planner_enabled'] =
          Variable<int>(safeBunkPlannerEnabled.value);
    }
    if (plannerTimeHour.present) {
      map['planner_time_hour'] = Variable<int>(plannerTimeHour.value);
    }
    if (plannerTimeMinute.present) {
      map['planner_time_minute'] = Variable<int>(plannerTimeMinute.value);
    }
    if (includeSafeBunks.present) {
      map['include_safe_bunks'] = Variable<int>(includeSafeBunks.value);
    }
    if (plannerIncludeRecoverySuggestions.present) {
      map['planner_include_recovery_suggestions'] =
          Variable<int>(plannerIncludeRecoverySuggestions.value);
    }
    if (includeRiskSubjects.present) {
      map['include_risk_subjects'] = Variable<int>(includeRiskSubjects.value);
    }
    if (dailySummaryEnabled.present) {
      map['daily_summary_enabled'] = Variable<int>(dailySummaryEnabled.value);
    }
    if (summaryTimeHour.present) {
      map['summary_time_hour'] = Variable<int>(summaryTimeHour.value);
    }
    if (summaryTimeMinute.present) {
      map['summary_time_minute'] = Variable<int>(summaryTimeMinute.value);
    }
    if (includeClassesAttended.present) {
      map['include_classes_attended'] =
          Variable<int>(includeClassesAttended.value);
    }
    if (includeClassesMissed.present) {
      map['include_classes_missed'] = Variable<int>(includeClassesMissed.value);
    }
    if (includeSubjectBreakdown.present) {
      map['include_subject_breakdown'] =
          Variable<int>(includeSubjectBreakdown.value);
    }
    if (includeOverallAttendance.present) {
      map['include_overall_attendance'] =
          Variable<int>(includeOverallAttendance.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('vibrationEnabled: $vibrationEnabled, ')
          ..write('badgeCount: $badgeCount, ')
          ..write('quietHoursStartHour: $quietHoursStartHour, ')
          ..write('quietHoursStartMinute: $quietHoursStartMinute, ')
          ..write('quietHoursEndHour: $quietHoursEndHour, ')
          ..write('quietHoursEndMinute: $quietHoursEndMinute, ')
          ..write('classRemindersEnabled: $classRemindersEnabled, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('onlyFirstClassReminder: $onlyFirstClassReminder, ')
          ..write('gapClassRemindersEnabled: $gapClassRemindersEnabled, ')
          ..write('gapMinutes: $gapMinutes, ')
          ..write('attendanceRemindersEnabled: $attendanceRemindersEnabled, ')
          ..write('attendanceDelayMinutes: $attendanceDelayMinutes, ')
          ..write('absentRestOfDayEnabled: $absentRestOfDayEnabled, ')
          ..write('autoDismissMinutes: $autoDismissMinutes, ')
          ..write('lowAttendanceAlertsEnabled: $lowAttendanceAlertsEnabled, ')
          ..write('recoverySuggestionsEnabled: $recoverySuggestionsEnabled, ')
          ..write('criticalAttendanceEnabled: $criticalAttendanceEnabled, ')
          ..write('criticalThreshold: $criticalThreshold, ')
          ..write('safeBunkPlannerEnabled: $safeBunkPlannerEnabled, ')
          ..write('plannerTimeHour: $plannerTimeHour, ')
          ..write('plannerTimeMinute: $plannerTimeMinute, ')
          ..write('includeSafeBunks: $includeSafeBunks, ')
          ..write(
              'plannerIncludeRecoverySuggestions: $plannerIncludeRecoverySuggestions, ')
          ..write('includeRiskSubjects: $includeRiskSubjects, ')
          ..write('dailySummaryEnabled: $dailySummaryEnabled, ')
          ..write('summaryTimeHour: $summaryTimeHour, ')
          ..write('summaryTimeMinute: $summaryTimeMinute, ')
          ..write('includeClassesAttended: $includeClassesAttended, ')
          ..write('includeClassesMissed: $includeClassesMissed, ')
          ..write('includeSubjectBreakdown: $includeSubjectBreakdown, ')
          ..write('includeOverallAttendance: $includeOverallAttendance, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotificationDedupTable extends NotificationDedup
    with TableInfo<$NotificationDedupTable, NotificationDedupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationDedupTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastFiredDateMeta =
      const VerificationMeta('lastFiredDate');
  @override
  late final GeneratedColumn<String> lastFiredDate = GeneratedColumn<String>(
      'last_fired_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firedAtMeta =
      const VerificationMeta('firedAt');
  @override
  late final GeneratedColumn<int> firedAt = GeneratedColumn<int>(
      'fired_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resolvedAtMeta =
      const VerificationMeta('resolvedAt');
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
      'resolved_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [key, lastFiredDate, firedAt, resolvedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_dedup';
  @override
  VerificationContext validateIntegrity(
      Insertable<NotificationDedupData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('last_fired_date')) {
      context.handle(
          _lastFiredDateMeta,
          lastFiredDate.isAcceptableOrUnknown(
              data['last_fired_date']!, _lastFiredDateMeta));
    } else if (isInserting) {
      context.missing(_lastFiredDateMeta);
    }
    if (data.containsKey('fired_at')) {
      context.handle(_firedAtMeta,
          firedAt.isAcceptableOrUnknown(data['fired_at']!, _firedAtMeta));
    } else if (isInserting) {
      context.missing(_firedAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
          _resolvedAtMeta,
          resolvedAt.isAcceptableOrUnknown(
              data['resolved_at']!, _resolvedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  NotificationDedupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationDedupData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      lastFiredDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_fired_date'])!,
      firedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fired_at'])!,
      resolvedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}resolved_at']),
    );
  }

  @override
  $NotificationDedupTable createAlias(String alias) {
    return $NotificationDedupTable(attachedDatabase, alias);
  }
}

class NotificationDedupData extends DataClass
    implements Insertable<NotificationDedupData> {
  /// Dedup key.
  ///   Daily fixed keys: 'daily_warning' | 'daily_critical'
  ///   Per-subject: the subject UUID string.
  final String key;

  /// ISO date string "YYYY-MM-DD" of the last fire date.
  final String lastFiredDate;

  /// Unix timestamp (ms) of when the notification was fired.
  final int firedAt;

  /// Unix timestamp (ms) when the condition was resolved.
  /// NULL means the alert is still unresolved (for per-subject alerts).
  final int? resolvedAt;
  const NotificationDedupData(
      {required this.key,
      required this.lastFiredDate,
      required this.firedAt,
      this.resolvedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['last_fired_date'] = Variable<String>(lastFiredDate);
    map['fired_at'] = Variable<int>(firedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    return map;
  }

  NotificationDedupCompanion toCompanion(bool nullToAbsent) {
    return NotificationDedupCompanion(
      key: Value(key),
      lastFiredDate: Value(lastFiredDate),
      firedAt: Value(firedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory NotificationDedupData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationDedupData(
      key: serializer.fromJson<String>(json['key']),
      lastFiredDate: serializer.fromJson<String>(json['lastFiredDate']),
      firedAt: serializer.fromJson<int>(json['firedAt']),
      resolvedAt: serializer.fromJson<int?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'lastFiredDate': serializer.toJson<String>(lastFiredDate),
      'firedAt': serializer.toJson<int>(firedAt),
      'resolvedAt': serializer.toJson<int?>(resolvedAt),
    };
  }

  NotificationDedupData copyWith(
          {String? key,
          String? lastFiredDate,
          int? firedAt,
          Value<int?> resolvedAt = const Value.absent()}) =>
      NotificationDedupData(
        key: key ?? this.key,
        lastFiredDate: lastFiredDate ?? this.lastFiredDate,
        firedAt: firedAt ?? this.firedAt,
        resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
      );
  NotificationDedupData copyWithCompanion(NotificationDedupCompanion data) {
    return NotificationDedupData(
      key: data.key.present ? data.key.value : this.key,
      lastFiredDate: data.lastFiredDate.present
          ? data.lastFiredDate.value
          : this.lastFiredDate,
      firedAt: data.firedAt.present ? data.firedAt.value : this.firedAt,
      resolvedAt:
          data.resolvedAt.present ? data.resolvedAt.value : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDedupData(')
          ..write('key: $key, ')
          ..write('lastFiredDate: $lastFiredDate, ')
          ..write('firedAt: $firedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, lastFiredDate, firedAt, resolvedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationDedupData &&
          other.key == this.key &&
          other.lastFiredDate == this.lastFiredDate &&
          other.firedAt == this.firedAt &&
          other.resolvedAt == this.resolvedAt);
}

class NotificationDedupCompanion
    extends UpdateCompanion<NotificationDedupData> {
  final Value<String> key;
  final Value<String> lastFiredDate;
  final Value<int> firedAt;
  final Value<int?> resolvedAt;
  final Value<int> rowid;
  const NotificationDedupCompanion({
    this.key = const Value.absent(),
    this.lastFiredDate = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationDedupCompanion.insert({
    required String key,
    required String lastFiredDate,
    required int firedAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        lastFiredDate = Value(lastFiredDate),
        firedAt = Value(firedAt);
  static Insertable<NotificationDedupData> custom({
    Expression<String>? key,
    Expression<String>? lastFiredDate,
    Expression<int>? firedAt,
    Expression<int>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (lastFiredDate != null) 'last_fired_date': lastFiredDate,
      if (firedAt != null) 'fired_at': firedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationDedupCompanion copyWith(
      {Value<String>? key,
      Value<String>? lastFiredDate,
      Value<int>? firedAt,
      Value<int?>? resolvedAt,
      Value<int>? rowid}) {
    return NotificationDedupCompanion(
      key: key ?? this.key,
      lastFiredDate: lastFiredDate ?? this.lastFiredDate,
      firedAt: firedAt ?? this.firedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (lastFiredDate.present) {
      map['last_fired_date'] = Variable<String>(lastFiredDate.value);
    }
    if (firedAt.present) {
      map['fired_at'] = Variable<int>(firedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDedupCompanion(')
          ..write('key: $key, ')
          ..write('lastFiredDate: $lastFiredDate, ')
          ..write('firedAt: $firedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<int> isRead = GeneratedColumn<int>(
      'is_read', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, message, type, priority, isRead, payload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<AppNotification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_read'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }
}

class AppNotification extends DataClass implements Insertable<AppNotification> {
  /// Stable string ID, e.g. 'attendanceDanger_2026-07-22'.
  final String id;

  /// Notification title.
  final String title;

  /// Full notification body text.
  final String message;

  /// Enum string: attendanceDanger / criticalAttendance /
  ///              nightlyBunkPlanner / system.
  final String type;

  /// Enum string: low / normal / high / critical.
  final String priority;

  /// BOOLEAN (0/1). Whether the user has read this notification.
  final int isRead;

  /// Optional JSON payload for tap handling.
  final String? payload;

  /// Creation timestamp — Unix timestamp (ms).
  final int createdAt;
  const AppNotification(
      {required this.id,
      required this.title,
      required this.message,
      required this.type,
      required this.priority,
      required this.isRead,
      this.payload,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['type'] = Variable<String>(type);
    map['priority'] = Variable<String>(priority);
    map['is_read'] = Variable<int>(isRead);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      title: Value(title),
      message: Value(message),
      type: Value(type),
      priority: Value(priority),
      isRead: Value(isRead),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotification(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      type: serializer.fromJson<String>(json['type']),
      priority: serializer.fromJson<String>(json['priority']),
      isRead: serializer.fromJson<int>(json['isRead']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'type': serializer.toJson<String>(type),
      'priority': serializer.toJson<String>(priority),
      'isRead': serializer.toJson<int>(isRead),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AppNotification copyWith(
          {String? id,
          String? title,
          String? message,
          String? type,
          String? priority,
          int? isRead,
          Value<String?> payload = const Value.absent(),
          int? createdAt}) =>
      AppNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        isRead: isRead ?? this.isRead,
        payload: payload.present ? payload.value : this.payload,
        createdAt: createdAt ?? this.createdAt,
      );
  AppNotification copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotification(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      type: data.type.present ? data.type.value : this.type,
      priority: data.priority.present ? data.priority.value : this.priority,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotification(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('isRead: $isRead, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, message, type, priority, isRead, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification &&
          other.id == this.id &&
          other.title == this.title &&
          other.message == this.message &&
          other.type == this.type &&
          other.priority == this.priority &&
          other.isRead == this.isRead &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotification> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> message;
  final Value<String> type;
  final Value<String> priority;
  final Value<int> isRead;
  final Value<String?> payload;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.type = const Value.absent(),
    this.priority = const Value.absent(),
    this.isRead = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    required String id,
    required String title,
    required String message,
    required String type,
    this.priority = const Value.absent(),
    this.isRead = const Value.absent(),
    this.payload = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        message = Value(message),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<AppNotification> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? type,
    Expression<String>? priority,
    Expression<int>? isRead,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (isRead != null) 'is_read': isRead,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppNotificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? message,
      Value<String>? type,
      Value<String>? priority,
      Value<int>? isRead,
      Value<String?>? payload,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<int>(isRead.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('isRead: $isRead, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<int> onboardingComplete = GeneratedColumn<int>(
      'onboarding_complete', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _onboardingStepMeta =
      const VerificationMeta('onboardingStep');
  @override
  late final GeneratedColumn<String> onboardingStep = GeneratedColumn<String>(
      'onboarding_step', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _attendanceGoalMeta =
      const VerificationMeta('attendanceGoal');
  @override
  late final GeneratedColumn<double> attendanceGoal = GeneratedColumn<double>(
      'attendance_goal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(75.0));
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<int> notificationsEnabled = GeneratedColumn<int>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _collegeNameMeta =
      const VerificationMeta('collegeName');
  @override
  late final GeneratedColumn<String> collegeName = GeneratedColumn<String>(
      'college_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _courseNameMeta =
      const VerificationMeta('courseName');
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
      'course_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeSemesterIdMeta =
      const VerificationMeta('activeSemesterId');
  @override
  late final GeneratedColumn<String> activeSemesterId = GeneratedColumn<String>(
      'active_semester_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES semesters (id) ON DELETE SET NULL'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        onboardingComplete,
        onboardingStep,
        themeMode,
        attendanceGoal,
        notificationsEnabled,
        collegeName,
        courseName,
        activeSemesterId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
          _onboardingCompleteMeta,
          onboardingComplete.isAcceptableOrUnknown(
              data['onboarding_complete']!, _onboardingCompleteMeta));
    }
    if (data.containsKey('onboarding_step')) {
      context.handle(
          _onboardingStepMeta,
          onboardingStep.isAcceptableOrUnknown(
              data['onboarding_step']!, _onboardingStepMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('attendance_goal')) {
      context.handle(
          _attendanceGoalMeta,
          attendanceGoal.isAcceptableOrUnknown(
              data['attendance_goal']!, _attendanceGoalMeta));
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    if (data.containsKey('college_name')) {
      context.handle(
          _collegeNameMeta,
          collegeName.isAcceptableOrUnknown(
              data['college_name']!, _collegeNameMeta));
    }
    if (data.containsKey('course_name')) {
      context.handle(
          _courseNameMeta,
          courseName.isAcceptableOrUnknown(
              data['course_name']!, _courseNameMeta));
    }
    if (data.containsKey('active_semester_id')) {
      context.handle(
          _activeSemesterIdMeta,
          activeSemesterId.isAcceptableOrUnknown(
              data['active_semester_id']!, _activeSemesterIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      onboardingComplete: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}onboarding_complete'])!,
      onboardingStep: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}onboarding_step']),
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      attendanceGoal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}attendance_goal'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}notifications_enabled'])!,
      collegeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}college_name']),
      courseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course_name']),
      activeSemesterId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_semester_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// Singleton PK — always 1.
  final int id;

  /// BOOLEAN (0/1). Router gates main app behind this.
  final int onboardingComplete;

  /// Onboarding resume key:
  ///   welcome / college / semester / subjects / timetable /
  ///   holidays / import / review / complete
  final String? onboardingStep;

  /// Theme mode: 'system' / 'light' / 'dark'.
  final String themeMode;

  /// Global attendance goal percentage (0–100).
  /// Per-subject override lives on subjects.attendance_target.
  final double attendanceGoal;

  /// BOOLEAN (0/1). Global notification on/off switch.
  /// Mirrors NotificationPreferences.notificationsEnabled for quick access.
  final int notificationsEnabled;

  /// College name entered during onboarding.
  final String? collegeName;

  /// Course name entered during onboarding.
  final String? courseName;

  /// FK → semesters.id, ON DELETE SET NULL.
  /// NULL means no active semester is set.
  final String? activeSemesterId;

  /// Last-modified timestamp — Unix timestamp (ms).
  final int updatedAt;
  const AppSetting(
      {required this.id,
      required this.onboardingComplete,
      this.onboardingStep,
      required this.themeMode,
      required this.attendanceGoal,
      required this.notificationsEnabled,
      this.collegeName,
      this.courseName,
      this.activeSemesterId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['onboarding_complete'] = Variable<int>(onboardingComplete);
    if (!nullToAbsent || onboardingStep != null) {
      map['onboarding_step'] = Variable<String>(onboardingStep);
    }
    map['theme_mode'] = Variable<String>(themeMode);
    map['attendance_goal'] = Variable<double>(attendanceGoal);
    map['notifications_enabled'] = Variable<int>(notificationsEnabled);
    if (!nullToAbsent || collegeName != null) {
      map['college_name'] = Variable<String>(collegeName);
    }
    if (!nullToAbsent || courseName != null) {
      map['course_name'] = Variable<String>(courseName);
    }
    if (!nullToAbsent || activeSemesterId != null) {
      map['active_semester_id'] = Variable<String>(activeSemesterId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      onboardingComplete: Value(onboardingComplete),
      onboardingStep: onboardingStep == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingStep),
      themeMode: Value(themeMode),
      attendanceGoal: Value(attendanceGoal),
      notificationsEnabled: Value(notificationsEnabled),
      collegeName: collegeName == null && nullToAbsent
          ? const Value.absent()
          : Value(collegeName),
      courseName: courseName == null && nullToAbsent
          ? const Value.absent()
          : Value(courseName),
      activeSemesterId: activeSemesterId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSemesterId),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      onboardingComplete: serializer.fromJson<int>(json['onboardingComplete']),
      onboardingStep: serializer.fromJson<String?>(json['onboardingStep']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      attendanceGoal: serializer.fromJson<double>(json['attendanceGoal']),
      notificationsEnabled:
          serializer.fromJson<int>(json['notificationsEnabled']),
      collegeName: serializer.fromJson<String?>(json['collegeName']),
      courseName: serializer.fromJson<String?>(json['courseName']),
      activeSemesterId: serializer.fromJson<String?>(json['activeSemesterId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'onboardingComplete': serializer.toJson<int>(onboardingComplete),
      'onboardingStep': serializer.toJson<String?>(onboardingStep),
      'themeMode': serializer.toJson<String>(themeMode),
      'attendanceGoal': serializer.toJson<double>(attendanceGoal),
      'notificationsEnabled': serializer.toJson<int>(notificationsEnabled),
      'collegeName': serializer.toJson<String?>(collegeName),
      'courseName': serializer.toJson<String?>(courseName),
      'activeSemesterId': serializer.toJson<String?>(activeSemesterId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith(
          {int? id,
          int? onboardingComplete,
          Value<String?> onboardingStep = const Value.absent(),
          String? themeMode,
          double? attendanceGoal,
          int? notificationsEnabled,
          Value<String?> collegeName = const Value.absent(),
          Value<String?> courseName = const Value.absent(),
          Value<String?> activeSemesterId = const Value.absent(),
          int? updatedAt}) =>
      AppSetting(
        id: id ?? this.id,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        onboardingStep:
            onboardingStep.present ? onboardingStep.value : this.onboardingStep,
        themeMode: themeMode ?? this.themeMode,
        attendanceGoal: attendanceGoal ?? this.attendanceGoal,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        collegeName: collegeName.present ? collegeName.value : this.collegeName,
        courseName: courseName.present ? courseName.value : this.courseName,
        activeSemesterId: activeSemesterId.present
            ? activeSemesterId.value
            : this.activeSemesterId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      onboardingStep: data.onboardingStep.present
          ? data.onboardingStep.value
          : this.onboardingStep,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      attendanceGoal: data.attendanceGoal.present
          ? data.attendanceGoal.value
          : this.attendanceGoal,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      collegeName:
          data.collegeName.present ? data.collegeName.value : this.collegeName,
      courseName:
          data.courseName.present ? data.courseName.value : this.courseName,
      activeSemesterId: data.activeSemesterId.present
          ? data.activeSemesterId.value
          : this.activeSemesterId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('onboardingStep: $onboardingStep, ')
          ..write('themeMode: $themeMode, ')
          ..write('attendanceGoal: $attendanceGoal, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('collegeName: $collegeName, ')
          ..write('courseName: $courseName, ')
          ..write('activeSemesterId: $activeSemesterId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      onboardingComplete,
      onboardingStep,
      themeMode,
      attendanceGoal,
      notificationsEnabled,
      collegeName,
      courseName,
      activeSemesterId,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.onboardingComplete == this.onboardingComplete &&
          other.onboardingStep == this.onboardingStep &&
          other.themeMode == this.themeMode &&
          other.attendanceGoal == this.attendanceGoal &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.collegeName == this.collegeName &&
          other.courseName == this.courseName &&
          other.activeSemesterId == this.activeSemesterId &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<int> onboardingComplete;
  final Value<String?> onboardingStep;
  final Value<String> themeMode;
  final Value<double> attendanceGoal;
  final Value<int> notificationsEnabled;
  final Value<String?> collegeName;
  final Value<String?> courseName;
  final Value<String?> activeSemesterId;
  final Value<int> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.onboardingStep = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.attendanceGoal = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.collegeName = const Value.absent(),
    this.courseName = const Value.absent(),
    this.activeSemesterId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.onboardingStep = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.attendanceGoal = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.collegeName = const Value.absent(),
    this.courseName = const Value.absent(),
    this.activeSemesterId = const Value.absent(),
    required int updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<int>? onboardingComplete,
    Expression<String>? onboardingStep,
    Expression<String>? themeMode,
    Expression<double>? attendanceGoal,
    Expression<int>? notificationsEnabled,
    Expression<String>? collegeName,
    Expression<String>? courseName,
    Expression<String>? activeSemesterId,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (onboardingStep != null) 'onboarding_step': onboardingStep,
      if (themeMode != null) 'theme_mode': themeMode,
      if (attendanceGoal != null) 'attendance_goal': attendanceGoal,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (collegeName != null) 'college_name': collegeName,
      if (courseName != null) 'course_name': courseName,
      if (activeSemesterId != null) 'active_semester_id': activeSemesterId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? onboardingComplete,
      Value<String?>? onboardingStep,
      Value<String>? themeMode,
      Value<double>? attendanceGoal,
      Value<int>? notificationsEnabled,
      Value<String?>? collegeName,
      Value<String?>? courseName,
      Value<String?>? activeSemesterId,
      Value<int>? updatedAt}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      themeMode: themeMode ?? this.themeMode,
      attendanceGoal: attendanceGoal ?? this.attendanceGoal,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      collegeName: collegeName ?? this.collegeName,
      courseName: courseName ?? this.courseName,
      activeSemesterId: activeSemesterId ?? this.activeSemesterId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<int>(onboardingComplete.value);
    }
    if (onboardingStep.present) {
      map['onboarding_step'] = Variable<String>(onboardingStep.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (attendanceGoal.present) {
      map['attendance_goal'] = Variable<double>(attendanceGoal.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<int>(notificationsEnabled.value);
    }
    if (collegeName.present) {
      map['college_name'] = Variable<String>(collegeName.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (activeSemesterId.present) {
      map['active_semester_id'] = Variable<String>(activeSemesterId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('onboardingStep: $onboardingStep, ')
          ..write('themeMode: $themeMode, ')
          ..write('attendanceGoal: $attendanceGoal, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('collegeName: $collegeName, ')
          ..write('courseName: $courseName, ')
          ..write('activeSemesterId: $activeSemesterId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $SemesterHolidaysTable semesterHolidays =
      $SemesterHolidaysTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $TimetableEntriesTable timetableEntries =
      $TimetableEntriesTable(this);
  late final $ClassSessionsTable classSessions = $ClassSessionsTable(this);
  late final $DailyScheduleOverridesTable dailyScheduleOverrides =
      $DailyScheduleOverridesTable(this);
  late final $AttendanceLogsTable attendanceLogs = $AttendanceLogsTable(this);
  late final $NotificationPreferencesTable notificationPreferences =
      $NotificationPreferencesTable(this);
  late final $NotificationDedupTable notificationDedup =
      $NotificationDedupTable(this);
  late final $AppNotificationsTable appNotifications =
      $AppNotificationsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxShSemesterDate = Index('idx_sh_semester_date',
      'CREATE INDEX idx_sh_semester_date ON semester_holidays (semester_id, holiday_date)');
  late final Index idxSubjectsUpdatedAt = Index('idx_subjects_updated_at',
      'CREATE INDEX idx_subjects_updated_at ON subjects (updated_at)');
  late final Index idxSubjectsName = Index(
      'idx_subjects_name', 'CREATE INDEX idx_subjects_name ON subjects (name)');
  late final Index idxTeSubjectId = Index('idx_te_subject_id',
      'CREATE INDEX idx_te_subject_id ON timetable_entries (subject_id)');
  late final Index idxTeSemesterId = Index('idx_te_semester_id',
      'CREATE INDEX idx_te_semester_id ON timetable_entries (semester_id)');
  late final Index idxTeDayOfWeek = Index('idx_te_day_of_week',
      'CREATE INDEX idx_te_day_of_week ON timetable_entries (day_of_week)');
  late final Index idxTeDayStart = Index('idx_te_day_start',
      'CREATE INDEX idx_te_day_start ON timetable_entries (day_of_week, start_time)');
  late final Index idxCsDate =
      Index('idx_cs_date', 'CREATE INDEX idx_cs_date ON class_sessions (date)');
  late final Index idxCsSemesterId = Index('idx_cs_semester_id',
      'CREATE INDEX idx_cs_semester_id ON class_sessions (semester_id)');
  late final Index idxCsSubjectDate = Index('idx_cs_subject_date',
      'CREATE INDEX idx_cs_subject_date ON class_sessions (subject_id, date)');
  late final Index idxCsDateStatus = Index('idx_cs_date_status',
      'CREATE INDEX idx_cs_date_status ON class_sessions (date, status)');
  late final Index idxCsTimetableEntryId = Index('idx_cs_timetable_entry_id',
      'CREATE INDEX idx_cs_timetable_entry_id ON class_sessions (timetable_entry_id)');
  late final Index idxDsoSessionId = Index('idx_dso_session_id',
      'CREATE INDEX idx_dso_session_id ON daily_schedule_overrides (session_id)');
  late final Index idxDsoDate = Index('idx_dso_date',
      'CREATE INDEX idx_dso_date ON daily_schedule_overrides (date)');
  late final Index idxAlSubjectId = Index('idx_al_subject_id',
      'CREATE INDEX idx_al_subject_id ON attendance_logs (subject_id)');
  late final Index idxAlSemesterId = Index('idx_al_semester_id',
      'CREATE INDEX idx_al_semester_id ON attendance_logs (semester_id)');
  late final Index idxAlDate = Index(
      'idx_al_date', 'CREATE INDEX idx_al_date ON attendance_logs (date)');
  late final Index idxAlSubjectDate = Index('idx_al_subject_date',
      'CREATE INDEX idx_al_subject_date ON attendance_logs (subject_id, date)');
  late final Index idxAlSessionId = Index('idx_al_session_id',
      'CREATE INDEX idx_al_session_id ON attendance_logs (session_id)');
  late final Index idxAlArchived = Index('idx_al_archived',
      'CREATE INDEX idx_al_archived ON attendance_logs (is_archived, date)');
  late final Index idxAnCreatedAt = Index('idx_an_created_at',
      'CREATE INDEX idx_an_created_at ON app_notifications (created_at)');
  late final Index idxAnIsRead = Index('idx_an_is_read',
      'CREATE INDEX idx_an_is_read ON app_notifications (is_read)');
  late final Index idxAnType = Index(
      'idx_an_type', 'CREATE INDEX idx_an_type ON app_notifications (type)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        semesters,
        semesterHolidays,
        subjects,
        timetableEntries,
        classSessions,
        dailyScheduleOverrides,
        attendanceLogs,
        notificationPreferences,
        notificationDedup,
        appNotifications,
        appSettings,
        idxShSemesterDate,
        idxSubjectsUpdatedAt,
        idxSubjectsName,
        idxTeSubjectId,
        idxTeSemesterId,
        idxTeDayOfWeek,
        idxTeDayStart,
        idxCsDate,
        idxCsSemesterId,
        idxCsSubjectDate,
        idxCsDateStatus,
        idxCsTimetableEntryId,
        idxDsoSessionId,
        idxDsoDate,
        idxAlSubjectId,
        idxAlSemesterId,
        idxAlDate,
        idxAlSubjectDate,
        idxAlSessionId,
        idxAlArchived,
        idxAnCreatedAt,
        idxAnIsRead,
        idxAnType
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('semesters',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('semester_holidays', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('subjects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('timetable_entries', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('subjects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('class_sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('timetable_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('class_sessions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('class_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_schedule_overrides', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('subjects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_schedule_overrides', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('class_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('attendance_logs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('semesters',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('app_settings', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $$SemestersTableCreateCompanionBuilder = SemestersCompanion Function({
  required String id,
  Value<String?> name,
  required int startDate,
  required int endDate,
  required int createdAt,
  Value<int> isActive,
  Value<int> rowid,
});
typedef $$SemestersTableUpdateCompanionBuilder = SemestersCompanion Function({
  Value<String> id,
  Value<String?> name,
  Value<int> startDate,
  Value<int> endDate,
  Value<int> createdAt,
  Value<int> isActive,
  Value<int> rowid,
});

final class $$SemestersTableReferences
    extends BaseReferences<_$AppDatabase, $SemestersTable, Semester> {
  $$SemestersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SemesterHolidaysTable, List<SemesterHoliday>>
      _semesterHolidaysRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.semesterHolidays,
              aliasName: $_aliasNameGenerator(
                  db.semesters.id, db.semesterHolidays.semesterId));

  $$SemesterHolidaysTableProcessedTableManager get semesterHolidaysRefs {
    final manager = $$SemesterHolidaysTableTableManager(
            $_db, $_db.semesterHolidays)
        .filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_semesterHolidaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TimetableEntriesTable, List<TimetableEntry>>
      _timetableEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.timetableEntries,
              aliasName: $_aliasNameGenerator(
                  db.semesters.id, db.timetableEntries.semesterId));

  $$TimetableEntriesTableProcessedTableManager get timetableEntriesRefs {
    final manager = $$TimetableEntriesTableTableManager(
            $_db, $_db.timetableEntries)
        .filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_timetableEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ClassSessionsTable, List<ClassSession>>
      _classSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.classSessions,
              aliasName: $_aliasNameGenerator(
                  db.semesters.id, db.classSessions.semesterId));

  $$ClassSessionsTableProcessedTableManager get classSessionsRefs {
    final manager = $$ClassSessionsTableTableManager($_db, $_db.classSessions)
        .filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendanceLogsTable, List<AttendanceLog>>
      _attendanceLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendanceLogs,
              aliasName: $_aliasNameGenerator(
                  db.semesters.id, db.attendanceLogs.semesterId));

  $$AttendanceLogsTableProcessedTableManager get attendanceLogsRefs {
    final manager = $$AttendanceLogsTableTableManager($_db, $_db.attendanceLogs)
        .filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendanceLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AppSettingsTable, List<AppSetting>>
      _appSettingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.appSettings,
              aliasName: $_aliasNameGenerator(
                  db.semesters.id, db.appSettings.activeSemesterId));

  $$AppSettingsTableProcessedTableManager get appSettingsRefs {
    final manager = $$AppSettingsTableTableManager($_db, $_db.appSettings)
        .filter((f) =>
            f.activeSemesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  Expression<bool> semesterHolidaysRefs(
      Expression<bool> Function($$SemesterHolidaysTableFilterComposer f) f) {
    final $$SemesterHolidaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.semesterHolidays,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemesterHolidaysTableFilterComposer(
              $db: $db,
              $table: $db.semesterHolidays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> timetableEntriesRefs(
      Expression<bool> Function($$TimetableEntriesTableFilterComposer f) f) {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableFilterComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> classSessionsRefs(
      Expression<bool> Function($$ClassSessionsTableFilterComposer f) f) {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableFilterComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attendanceLogsRefs(
      Expression<bool> Function($$AttendanceLogsTableFilterComposer f) f) {
    final $$AttendanceLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableFilterComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> appSettingsRefs(
      Expression<bool> Function($$AppSettingsTableFilterComposer f) f) {
    final $$AppSettingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appSettings,
        getReferencedColumn: (t) => t.activeSemesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppSettingsTableFilterComposer(
              $db: $db,
              $table: $db.appSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> semesterHolidaysRefs<T extends Object>(
      Expression<T> Function($$SemesterHolidaysTableAnnotationComposer a) f) {
    final $$SemesterHolidaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.semesterHolidays,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemesterHolidaysTableAnnotationComposer(
              $db: $db,
              $table: $db.semesterHolidays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> timetableEntriesRefs<T extends Object>(
      Expression<T> Function($$TimetableEntriesTableAnnotationComposer a) f) {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> classSessionsRefs<T extends Object>(
      Expression<T> Function($$ClassSessionsTableAnnotationComposer a) f) {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attendanceLogsRefs<T extends Object>(
      Expression<T> Function($$AttendanceLogsTableAnnotationComposer a) f) {
    final $$AttendanceLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.semesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> appSettingsRefs<T extends Object>(
      Expression<T> Function($$AppSettingsTableAnnotationComposer a) f) {
    final $$AppSettingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appSettings,
        getReferencedColumn: (t) => t.activeSemesterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppSettingsTableAnnotationComposer(
              $db: $db,
              $table: $db.appSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SemestersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SemestersTable,
    Semester,
    $$SemestersTableFilterComposer,
    $$SemestersTableOrderingComposer,
    $$SemestersTableAnnotationComposer,
    $$SemestersTableCreateCompanionBuilder,
    $$SemestersTableUpdateCompanionBuilder,
    (Semester, $$SemestersTableReferences),
    Semester,
    PrefetchHooks Function(
        {bool semesterHolidaysRefs,
        bool timetableEntriesRefs,
        bool classSessionsRefs,
        bool attendanceLogsRefs,
        bool appSettingsRefs})> {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<int> startDate = const Value.absent(),
            Value<int> endDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SemestersCompanion(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> name = const Value.absent(),
            required int startDate,
            required int endDate,
            required int createdAt,
            Value<int> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SemestersCompanion.insert(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SemestersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {semesterHolidaysRefs = false,
              timetableEntriesRefs = false,
              classSessionsRefs = false,
              attendanceLogsRefs = false,
              appSettingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (semesterHolidaysRefs) db.semesterHolidays,
                if (timetableEntriesRefs) db.timetableEntries,
                if (classSessionsRefs) db.classSessions,
                if (attendanceLogsRefs) db.attendanceLogs,
                if (appSettingsRefs) db.appSettings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (semesterHolidaysRefs)
                    await $_getPrefetchedData<Semester, $SemestersTable,
                            SemesterHoliday>(
                        currentTable: table,
                        referencedTable: $$SemestersTableReferences
                            ._semesterHolidaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SemestersTableReferences(db, table, p0)
                                .semesterHolidaysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.semesterId == item.id),
                        typedResults: items),
                  if (timetableEntriesRefs)
                    await $_getPrefetchedData<Semester, $SemestersTable,
                            TimetableEntry>(
                        currentTable: table,
                        referencedTable: $$SemestersTableReferences
                            ._timetableEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SemestersTableReferences(db, table, p0)
                                .timetableEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.semesterId == item.id),
                        typedResults: items),
                  if (classSessionsRefs)
                    await $_getPrefetchedData<Semester, $SemestersTable,
                            ClassSession>(
                        currentTable: table,
                        referencedTable: $$SemestersTableReferences
                            ._classSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SemestersTableReferences(db, table, p0)
                                .classSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.semesterId == item.id),
                        typedResults: items),
                  if (attendanceLogsRefs)
                    await $_getPrefetchedData<Semester, $SemestersTable,
                            AttendanceLog>(
                        currentTable: table,
                        referencedTable: $$SemestersTableReferences
                            ._attendanceLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SemestersTableReferences(db, table, p0)
                                .attendanceLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.semesterId == item.id),
                        typedResults: items),
                  if (appSettingsRefs)
                    await $_getPrefetchedData<Semester, $SemestersTable,
                            AppSetting>(
                        currentTable: table,
                        referencedTable: $$SemestersTableReferences
                            ._appSettingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SemestersTableReferences(db, table, p0)
                                .appSettingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.activeSemesterId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SemestersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SemestersTable,
    Semester,
    $$SemestersTableFilterComposer,
    $$SemestersTableOrderingComposer,
    $$SemestersTableAnnotationComposer,
    $$SemestersTableCreateCompanionBuilder,
    $$SemestersTableUpdateCompanionBuilder,
    (Semester, $$SemestersTableReferences),
    Semester,
    PrefetchHooks Function(
        {bool semesterHolidaysRefs,
        bool timetableEntriesRefs,
        bool classSessionsRefs,
        bool attendanceLogsRefs,
        bool appSettingsRefs})>;
typedef $$SemesterHolidaysTableCreateCompanionBuilder
    = SemesterHolidaysCompanion Function({
  Value<int> id,
  required String semesterId,
  required int holidayDate,
});
typedef $$SemesterHolidaysTableUpdateCompanionBuilder
    = SemesterHolidaysCompanion Function({
  Value<int> id,
  Value<String> semesterId,
  Value<int> holidayDate,
});

final class $$SemesterHolidaysTableReferences extends BaseReferences<
    _$AppDatabase, $SemesterHolidaysTable, SemesterHoliday> {
  $$SemesterHolidaysTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias($_aliasNameGenerator(
          db.semesterHolidays.semesterId, db.semesters.id));

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager($_db, $_db.semesters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SemesterHolidaysTableFilterComposer
    extends Composer<_$AppDatabase, $SemesterHolidaysTable> {
  $$SemesterHolidaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get holidayDate => $composableBuilder(
      column: $table.holidayDate, builder: (column) => ColumnFilters(column));

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableFilterComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SemesterHolidaysTableOrderingComposer
    extends Composer<_$AppDatabase, $SemesterHolidaysTable> {
  $$SemesterHolidaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get holidayDate => $composableBuilder(
      column: $table.holidayDate, builder: (column) => ColumnOrderings(column));

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableOrderingComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SemesterHolidaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemesterHolidaysTable> {
  $$SemesterHolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get holidayDate => $composableBuilder(
      column: $table.holidayDate, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableAnnotationComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SemesterHolidaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SemesterHolidaysTable,
    SemesterHoliday,
    $$SemesterHolidaysTableFilterComposer,
    $$SemesterHolidaysTableOrderingComposer,
    $$SemesterHolidaysTableAnnotationComposer,
    $$SemesterHolidaysTableCreateCompanionBuilder,
    $$SemesterHolidaysTableUpdateCompanionBuilder,
    (SemesterHoliday, $$SemesterHolidaysTableReferences),
    SemesterHoliday,
    PrefetchHooks Function({bool semesterId})> {
  $$SemesterHolidaysTableTableManager(
      _$AppDatabase db, $SemesterHolidaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemesterHolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemesterHolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemesterHolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> semesterId = const Value.absent(),
            Value<int> holidayDate = const Value.absent(),
          }) =>
              SemesterHolidaysCompanion(
            id: id,
            semesterId: semesterId,
            holidayDate: holidayDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String semesterId,
            required int holidayDate,
          }) =>
              SemesterHolidaysCompanion.insert(
            id: id,
            semesterId: semesterId,
            holidayDate: holidayDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SemesterHolidaysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (semesterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.semesterId,
                    referencedTable:
                        $$SemesterHolidaysTableReferences._semesterIdTable(db),
                    referencedColumn: $$SemesterHolidaysTableReferences
                        ._semesterIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SemesterHolidaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SemesterHolidaysTable,
    SemesterHoliday,
    $$SemesterHolidaysTableFilterComposer,
    $$SemesterHolidaysTableOrderingComposer,
    $$SemesterHolidaysTableAnnotationComposer,
    $$SemesterHolidaysTableCreateCompanionBuilder,
    $$SemesterHolidaysTableUpdateCompanionBuilder,
    (SemesterHoliday, $$SemesterHolidaysTableReferences),
    SemesterHoliday,
    PrefetchHooks Function({bool semesterId})>;
typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String name,
  Value<int> attendedClasses,
  Value<int> totalClasses,
  Value<String?> faculty,
  Value<double?> attendanceTarget,
  Value<String?> colorHex,
  Value<String?> shortName,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> attendedClasses,
  Value<int> totalClasses,
  Value<String?> faculty,
  Value<double?> attendanceTarget,
  Value<String?> colorHex,
  Value<String?> shortName,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TimetableEntriesTable, List<TimetableEntry>>
      _timetableEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.timetableEntries,
              aliasName: $_aliasNameGenerator(
                  db.subjects.id, db.timetableEntries.subjectId));

  $$TimetableEntriesTableProcessedTableManager get timetableEntriesRefs {
    final manager = $$TimetableEntriesTableTableManager(
            $_db, $_db.timetableEntries)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_timetableEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ClassSessionsTable, List<ClassSession>>
      _classSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.classSessions,
              aliasName: $_aliasNameGenerator(
                  db.subjects.id, db.classSessions.subjectId));

  $$ClassSessionsTableProcessedTableManager get classSessionsRefs {
    final manager = $$ClassSessionsTableTableManager($_db, $_db.classSessions)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DailyScheduleOverridesTable,
      List<DailyScheduleOverride>> _dailyScheduleOverridesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.dailyScheduleOverrides,
          aliasName: $_aliasNameGenerator(
              db.subjects.id, db.dailyScheduleOverrides.newSubjectId));

  $$DailyScheduleOverridesTableProcessedTableManager
      get dailyScheduleOverridesRefs {
    final manager = $$DailyScheduleOverridesTableTableManager(
            $_db, $_db.dailyScheduleOverrides)
        .filter(
            (f) => f.newSubjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_dailyScheduleOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendanceLogsTable, List<AttendanceLog>>
      _attendanceLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendanceLogs,
              aliasName: $_aliasNameGenerator(
                  db.subjects.id, db.attendanceLogs.subjectId));

  $$AttendanceLogsTableProcessedTableManager get attendanceLogsRefs {
    final manager = $$AttendanceLogsTableTableManager($_db, $_db.attendanceLogs)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendanceLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attendedClasses => $composableBuilder(
      column: $table.attendedClasses,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalClasses => $composableBuilder(
      column: $table.totalClasses, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get attendanceTarget => $composableBuilder(
      column: $table.attendanceTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> timetableEntriesRefs(
      Expression<bool> Function($$TimetableEntriesTableFilterComposer f) f) {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableFilterComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> classSessionsRefs(
      Expression<bool> Function($$ClassSessionsTableFilterComposer f) f) {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableFilterComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> dailyScheduleOverridesRefs(
      Expression<bool> Function($$DailyScheduleOverridesTableFilterComposer f)
          f) {
    final $$DailyScheduleOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.dailyScheduleOverrides,
            getReferencedColumn: (t) => t.newSubjectId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DailyScheduleOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.dailyScheduleOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> attendanceLogsRefs(
      Expression<bool> Function($$AttendanceLogsTableFilterComposer f) f) {
    final $$AttendanceLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableFilterComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attendedClasses => $composableBuilder(
      column: $table.attendedClasses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalClasses => $composableBuilder(
      column: $table.totalClasses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get attendanceTarget => $composableBuilder(
      column: $table.attendanceTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get attendedClasses => $composableBuilder(
      column: $table.attendedClasses, builder: (column) => column);

  GeneratedColumn<int> get totalClasses => $composableBuilder(
      column: $table.totalClasses, builder: (column) => column);

  GeneratedColumn<String> get faculty =>
      $composableBuilder(column: $table.faculty, builder: (column) => column);

  GeneratedColumn<double> get attendanceTarget => $composableBuilder(
      column: $table.attendanceTarget, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> timetableEntriesRefs<T extends Object>(
      Expression<T> Function($$TimetableEntriesTableAnnotationComposer a) f) {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> classSessionsRefs<T extends Object>(
      Expression<T> Function($$ClassSessionsTableAnnotationComposer a) f) {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> dailyScheduleOverridesRefs<T extends Object>(
      Expression<T> Function($$DailyScheduleOverridesTableAnnotationComposer a)
          f) {
    final $$DailyScheduleOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.dailyScheduleOverrides,
            getReferencedColumn: (t) => t.newSubjectId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DailyScheduleOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.dailyScheduleOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> attendanceLogsRefs<T extends Object>(
      Expression<T> Function($$AttendanceLogsTableAnnotationComposer a) f) {
    final $$AttendanceLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function(
        {bool timetableEntriesRefs,
        bool classSessionsRefs,
        bool dailyScheduleOverridesRefs,
        bool attendanceLogsRefs})> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> attendedClasses = const Value.absent(),
            Value<int> totalClasses = const Value.absent(),
            Value<String?> faculty = const Value.absent(),
            Value<double?> attendanceTarget = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> shortName = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            id: id,
            name: name,
            attendedClasses: attendedClasses,
            totalClasses: totalClasses,
            faculty: faculty,
            attendanceTarget: attendanceTarget,
            colorHex: colorHex,
            shortName: shortName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> attendedClasses = const Value.absent(),
            Value<int> totalClasses = const Value.absent(),
            Value<String?> faculty = const Value.absent(),
            Value<double?> attendanceTarget = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> shortName = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            id: id,
            name: name,
            attendedClasses: attendedClasses,
            totalClasses: totalClasses,
            faculty: faculty,
            attendanceTarget: attendanceTarget,
            colorHex: colorHex,
            shortName: shortName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SubjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {timetableEntriesRefs = false,
              classSessionsRefs = false,
              dailyScheduleOverridesRefs = false,
              attendanceLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (timetableEntriesRefs) db.timetableEntries,
                if (classSessionsRefs) db.classSessions,
                if (dailyScheduleOverridesRefs) db.dailyScheduleOverrides,
                if (attendanceLogsRefs) db.attendanceLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (timetableEntriesRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable,
                            TimetableEntry>(
                        currentTable: table,
                        referencedTable: $$SubjectsTableReferences
                            ._timetableEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .timetableEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items),
                  if (classSessionsRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable,
                            ClassSession>(
                        currentTable: table,
                        referencedTable: $$SubjectsTableReferences
                            ._classSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .classSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items),
                  if (dailyScheduleOverridesRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable,
                            DailyScheduleOverride>(
                        currentTable: table,
                        referencedTable: $$SubjectsTableReferences
                            ._dailyScheduleOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .dailyScheduleOverridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.newSubjectId == item.id),
                        typedResults: items),
                  if (attendanceLogsRefs)
                    await $_getPrefetchedData<Subject, $SubjectsTable,
                            AttendanceLog>(
                        currentTable: table,
                        referencedTable: $$SubjectsTableReferences
                            ._attendanceLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .attendanceLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function(
        {bool timetableEntriesRefs,
        bool classSessionsRefs,
        bool dailyScheduleOverridesRefs,
        bool attendanceLogsRefs})>;
typedef $$TimetableEntriesTableCreateCompanionBuilder
    = TimetableEntriesCompanion Function({
  required String id,
  required String subjectId,
  required String semesterId,
  required int dayOfWeek,
  required String startTime,
  required String endTime,
  Value<String?> faculty,
  Value<String?> room,
  Value<double> confidence,
  required int createdAt,
  Value<int> rowid,
});
typedef $$TimetableEntriesTableUpdateCompanionBuilder
    = TimetableEntriesCompanion Function({
  Value<String> id,
  Value<String> subjectId,
  Value<String> semesterId,
  Value<int> dayOfWeek,
  Value<String> startTime,
  Value<String> endTime,
  Value<String?> faculty,
  Value<String?> room,
  Value<double> confidence,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$TimetableEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $TimetableEntriesTable, TimetableEntry> {
  $$TimetableEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias(
          $_aliasNameGenerator(db.timetableEntries.subjectId, db.subjects.id));

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias($_aliasNameGenerator(
          db.timetableEntries.semesterId, db.semesters.id));

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager($_db, $_db.semesters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ClassSessionsTable, List<ClassSession>>
      _classSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.classSessions,
              aliasName: $_aliasNameGenerator(
                  db.timetableEntries.id, db.classSessions.timetableEntryId));

  $$ClassSessionsTableProcessedTableManager get classSessionsRefs {
    final manager = $$ClassSessionsTableTableManager($_db, $_db.classSessions)
        .filter((f) =>
            f.timetableEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TimetableEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get room => $composableBuilder(
      column: $table.room, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableFilterComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> classSessionsRefs(
      Expression<bool> Function($$ClassSessionsTableFilterComposer f) f) {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.timetableEntryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableFilterComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TimetableEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get room => $composableBuilder(
      column: $table.room, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableOrderingComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimetableEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get faculty =>
      $composableBuilder(column: $table.faculty, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableAnnotationComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> classSessionsRefs<T extends Object>(
      Expression<T> Function($$ClassSessionsTableAnnotationComposer a) f) {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.timetableEntryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TimetableEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimetableEntriesTable,
    TimetableEntry,
    $$TimetableEntriesTableFilterComposer,
    $$TimetableEntriesTableOrderingComposer,
    $$TimetableEntriesTableAnnotationComposer,
    $$TimetableEntriesTableCreateCompanionBuilder,
    $$TimetableEntriesTableUpdateCompanionBuilder,
    (TimetableEntry, $$TimetableEntriesTableReferences),
    TimetableEntry,
    PrefetchHooks Function(
        {bool subjectId, bool semesterId, bool classSessionsRefs})> {
  $$TimetableEntriesTableTableManager(
      _$AppDatabase db, $TimetableEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimetableEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimetableEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimetableEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String> semesterId = const Value.absent(),
            Value<int> dayOfWeek = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String> endTime = const Value.absent(),
            Value<String?> faculty = const Value.absent(),
            Value<String?> room = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimetableEntriesCompanion(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            endTime: endTime,
            faculty: faculty,
            room: room,
            confidence: confidence,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            required String semesterId,
            required int dayOfWeek,
            required String startTime,
            required String endTime,
            Value<String?> faculty = const Value.absent(),
            Value<String?> room = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimetableEntriesCompanion.insert(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            endTime: endTime,
            faculty: faculty,
            room: room,
            confidence: confidence,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TimetableEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false,
              semesterId = false,
              classSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classSessionsRefs) db.classSessions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$TimetableEntriesTableReferences._subjectIdTable(db),
                    referencedColumn: $$TimetableEntriesTableReferences
                        ._subjectIdTable(db)
                        .id,
                  ) as T;
                }
                if (semesterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.semesterId,
                    referencedTable:
                        $$TimetableEntriesTableReferences._semesterIdTable(db),
                    referencedColumn: $$TimetableEntriesTableReferences
                        ._semesterIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classSessionsRefs)
                    await $_getPrefetchedData<TimetableEntry,
                            $TimetableEntriesTable, ClassSession>(
                        currentTable: table,
                        referencedTable: $$TimetableEntriesTableReferences
                            ._classSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TimetableEntriesTableReferences(db, table, p0)
                                .classSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.timetableEntryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TimetableEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimetableEntriesTable,
    TimetableEntry,
    $$TimetableEntriesTableFilterComposer,
    $$TimetableEntriesTableOrderingComposer,
    $$TimetableEntriesTableAnnotationComposer,
    $$TimetableEntriesTableCreateCompanionBuilder,
    $$TimetableEntriesTableUpdateCompanionBuilder,
    (TimetableEntry, $$TimetableEntriesTableReferences),
    TimetableEntry,
    PrefetchHooks Function(
        {bool subjectId, bool semesterId, bool classSessionsRefs})>;
typedef $$ClassSessionsTableCreateCompanionBuilder = ClassSessionsCompanion
    Function({
  required String id,
  required String subjectId,
  required String semesterId,
  Value<String?> timetableEntryId,
  required int date,
  required String startTime,
  required String endTime,
  Value<String?> faculty,
  Value<String?> room,
  Value<String> status,
  Value<int> isCancelled,
  Value<int> isExtraPeriod,
  required int createdAt,
  Value<int> rowid,
});
typedef $$ClassSessionsTableUpdateCompanionBuilder = ClassSessionsCompanion
    Function({
  Value<String> id,
  Value<String> subjectId,
  Value<String> semesterId,
  Value<String?> timetableEntryId,
  Value<int> date,
  Value<String> startTime,
  Value<String> endTime,
  Value<String?> faculty,
  Value<String?> room,
  Value<String> status,
  Value<int> isCancelled,
  Value<int> isExtraPeriod,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$ClassSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ClassSessionsTable, ClassSession> {
  $$ClassSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias(
          $_aliasNameGenerator(db.classSessions.subjectId, db.subjects.id));

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias(
          $_aliasNameGenerator(db.classSessions.semesterId, db.semesters.id));

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager($_db, $_db.semesters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TimetableEntriesTable _timetableEntryIdTable(_$AppDatabase db) =>
      db.timetableEntries.createAlias($_aliasNameGenerator(
          db.classSessions.timetableEntryId, db.timetableEntries.id));

  $$TimetableEntriesTableProcessedTableManager? get timetableEntryId {
    final $_column = $_itemColumn<String>('timetable_entry_id');
    if ($_column == null) return null;
    final manager =
        $$TimetableEntriesTableTableManager($_db, $_db.timetableEntries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timetableEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DailyScheduleOverridesTable,
      List<DailyScheduleOverride>> _dailyScheduleOverridesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.dailyScheduleOverrides,
          aliasName: $_aliasNameGenerator(
              db.classSessions.id, db.dailyScheduleOverrides.sessionId));

  $$DailyScheduleOverridesTableProcessedTableManager
      get dailyScheduleOverridesRefs {
    final manager = $$DailyScheduleOverridesTableTableManager(
            $_db, $_db.dailyScheduleOverrides)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_dailyScheduleOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendanceLogsTable, List<AttendanceLog>>
      _attendanceLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendanceLogs,
              aliasName: $_aliasNameGenerator(
                  db.classSessions.id, db.attendanceLogs.sessionId));

  $$AttendanceLogsTableProcessedTableManager get attendanceLogsRefs {
    final manager = $$AttendanceLogsTableTableManager($_db, $_db.attendanceLogs)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendanceLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClassSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get room => $composableBuilder(
      column: $table.room, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableFilterComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TimetableEntriesTableFilterComposer get timetableEntryId {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.timetableEntryId,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableFilterComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> dailyScheduleOverridesRefs(
      Expression<bool> Function($$DailyScheduleOverridesTableFilterComposer f)
          f) {
    final $$DailyScheduleOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.dailyScheduleOverrides,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DailyScheduleOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.dailyScheduleOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> attendanceLogsRefs(
      Expression<bool> Function($$AttendanceLogsTableFilterComposer f) f) {
    final $$AttendanceLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableFilterComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClassSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get faculty => $composableBuilder(
      column: $table.faculty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get room => $composableBuilder(
      column: $table.room, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableOrderingComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TimetableEntriesTableOrderingComposer get timetableEntryId {
    final $$TimetableEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.timetableEntryId,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClassSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get faculty =>
      $composableBuilder(column: $table.faculty, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => column);

  GeneratedColumn<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableAnnotationComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TimetableEntriesTableAnnotationComposer get timetableEntryId {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.timetableEntryId,
        referencedTable: $db.timetableEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimetableEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.timetableEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> dailyScheduleOverridesRefs<T extends Object>(
      Expression<T> Function($$DailyScheduleOverridesTableAnnotationComposer a)
          f) {
    final $$DailyScheduleOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.dailyScheduleOverrides,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DailyScheduleOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.dailyScheduleOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> attendanceLogsRefs<T extends Object>(
      Expression<T> Function($$AttendanceLogsTableAnnotationComposer a) f) {
    final $$AttendanceLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendanceLogs,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendanceLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.attendanceLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClassSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClassSessionsTable,
    ClassSession,
    $$ClassSessionsTableFilterComposer,
    $$ClassSessionsTableOrderingComposer,
    $$ClassSessionsTableAnnotationComposer,
    $$ClassSessionsTableCreateCompanionBuilder,
    $$ClassSessionsTableUpdateCompanionBuilder,
    (ClassSession, $$ClassSessionsTableReferences),
    ClassSession,
    PrefetchHooks Function(
        {bool subjectId,
        bool semesterId,
        bool timetableEntryId,
        bool dailyScheduleOverridesRefs,
        bool attendanceLogsRefs})> {
  $$ClassSessionsTableTableManager(_$AppDatabase db, $ClassSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String> semesterId = const Value.absent(),
            Value<String?> timetableEntryId = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String> endTime = const Value.absent(),
            Value<String?> faculty = const Value.absent(),
            Value<String?> room = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> isCancelled = const Value.absent(),
            Value<int> isExtraPeriod = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassSessionsCompanion(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            timetableEntryId: timetableEntryId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            faculty: faculty,
            room: room,
            status: status,
            isCancelled: isCancelled,
            isExtraPeriod: isExtraPeriod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            required String semesterId,
            Value<String?> timetableEntryId = const Value.absent(),
            required int date,
            required String startTime,
            required String endTime,
            Value<String?> faculty = const Value.absent(),
            Value<String?> room = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> isCancelled = const Value.absent(),
            Value<int> isExtraPeriod = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassSessionsCompanion.insert(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            timetableEntryId: timetableEntryId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            faculty: faculty,
            room: room,
            status: status,
            isCancelled: isCancelled,
            isExtraPeriod: isExtraPeriod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ClassSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false,
              semesterId = false,
              timetableEntryId = false,
              dailyScheduleOverridesRefs = false,
              attendanceLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dailyScheduleOverridesRefs) db.dailyScheduleOverrides,
                if (attendanceLogsRefs) db.attendanceLogs
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$ClassSessionsTableReferences._subjectIdTable(db),
                    referencedColumn:
                        $$ClassSessionsTableReferences._subjectIdTable(db).id,
                  ) as T;
                }
                if (semesterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.semesterId,
                    referencedTable:
                        $$ClassSessionsTableReferences._semesterIdTable(db),
                    referencedColumn:
                        $$ClassSessionsTableReferences._semesterIdTable(db).id,
                  ) as T;
                }
                if (timetableEntryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.timetableEntryId,
                    referencedTable: $$ClassSessionsTableReferences
                        ._timetableEntryIdTable(db),
                    referencedColumn: $$ClassSessionsTableReferences
                        ._timetableEntryIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyScheduleOverridesRefs)
                    await $_getPrefetchedData<ClassSession, $ClassSessionsTable,
                            DailyScheduleOverride>(
                        currentTable: table,
                        referencedTable: $$ClassSessionsTableReferences
                            ._dailyScheduleOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassSessionsTableReferences(db, table, p0)
                                .dailyScheduleOverridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items),
                  if (attendanceLogsRefs)
                    await $_getPrefetchedData<ClassSession, $ClassSessionsTable,
                            AttendanceLog>(
                        currentTable: table,
                        referencedTable: $$ClassSessionsTableReferences
                            ._attendanceLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassSessionsTableReferences(db, table, p0)
                                .attendanceLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ClassSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClassSessionsTable,
    ClassSession,
    $$ClassSessionsTableFilterComposer,
    $$ClassSessionsTableOrderingComposer,
    $$ClassSessionsTableAnnotationComposer,
    $$ClassSessionsTableCreateCompanionBuilder,
    $$ClassSessionsTableUpdateCompanionBuilder,
    (ClassSession, $$ClassSessionsTableReferences),
    ClassSession,
    PrefetchHooks Function(
        {bool subjectId,
        bool semesterId,
        bool timetableEntryId,
        bool dailyScheduleOverridesRefs,
        bool attendanceLogsRefs})>;
typedef $$DailyScheduleOverridesTableCreateCompanionBuilder
    = DailyScheduleOverridesCompanion Function({
  required String id,
  required String sessionId,
  required int date,
  required String overrideType,
  Value<String?> newSubjectId,
  Value<String?> newStartTime,
  Value<String?> newEndTime,
  Value<int> isCancelled,
  Value<int> isExtraPeriod,
  required int createdAt,
  Value<int> rowid,
});
typedef $$DailyScheduleOverridesTableUpdateCompanionBuilder
    = DailyScheduleOverridesCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<int> date,
  Value<String> overrideType,
  Value<String?> newSubjectId,
  Value<String?> newStartTime,
  Value<String?> newEndTime,
  Value<int> isCancelled,
  Value<int> isExtraPeriod,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$DailyScheduleOverridesTableReferences extends BaseReferences<
    _$AppDatabase, $DailyScheduleOverridesTable, DailyScheduleOverride> {
  $$DailyScheduleOverridesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ClassSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.classSessions.createAlias($_aliasNameGenerator(
          db.dailyScheduleOverrides.sessionId, db.classSessions.id));

  $$ClassSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ClassSessionsTableTableManager($_db, $_db.classSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SubjectsTable _newSubjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias($_aliasNameGenerator(
          db.dailyScheduleOverrides.newSubjectId, db.subjects.id));

  $$SubjectsTableProcessedTableManager? get newSubjectId {
    final $_column = $_itemColumn<String>('new_subject_id');
    if ($_column == null) return null;
    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_newSubjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DailyScheduleOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyScheduleOverridesTable> {
  $$DailyScheduleOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overrideType => $composableBuilder(
      column: $table.overrideType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newStartTime => $composableBuilder(
      column: $table.newStartTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newEndTime => $composableBuilder(
      column: $table.newEndTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ClassSessionsTableFilterComposer get sessionId {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableFilterComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SubjectsTableFilterComposer get newSubjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.newSubjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyScheduleOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyScheduleOverridesTable> {
  $$DailyScheduleOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideType => $composableBuilder(
      column: $table.overrideType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newStartTime => $composableBuilder(
      column: $table.newStartTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newEndTime => $composableBuilder(
      column: $table.newEndTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ClassSessionsTableOrderingComposer get sessionId {
    final $$ClassSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SubjectsTableOrderingComposer get newSubjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.newSubjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyScheduleOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyScheduleOverridesTable> {
  $$DailyScheduleOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get overrideType => $composableBuilder(
      column: $table.overrideType, builder: (column) => column);

  GeneratedColumn<String> get newStartTime => $composableBuilder(
      column: $table.newStartTime, builder: (column) => column);

  GeneratedColumn<String> get newEndTime => $composableBuilder(
      column: $table.newEndTime, builder: (column) => column);

  GeneratedColumn<int> get isCancelled => $composableBuilder(
      column: $table.isCancelled, builder: (column) => column);

  GeneratedColumn<int> get isExtraPeriod => $composableBuilder(
      column: $table.isExtraPeriod, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ClassSessionsTableAnnotationComposer get sessionId {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SubjectsTableAnnotationComposer get newSubjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.newSubjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyScheduleOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyScheduleOverridesTable,
    DailyScheduleOverride,
    $$DailyScheduleOverridesTableFilterComposer,
    $$DailyScheduleOverridesTableOrderingComposer,
    $$DailyScheduleOverridesTableAnnotationComposer,
    $$DailyScheduleOverridesTableCreateCompanionBuilder,
    $$DailyScheduleOverridesTableUpdateCompanionBuilder,
    (DailyScheduleOverride, $$DailyScheduleOverridesTableReferences),
    DailyScheduleOverride,
    PrefetchHooks Function({bool sessionId, bool newSubjectId})> {
  $$DailyScheduleOverridesTableTableManager(
      _$AppDatabase db, $DailyScheduleOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyScheduleOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyScheduleOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyScheduleOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<String> overrideType = const Value.absent(),
            Value<String?> newSubjectId = const Value.absent(),
            Value<String?> newStartTime = const Value.absent(),
            Value<String?> newEndTime = const Value.absent(),
            Value<int> isCancelled = const Value.absent(),
            Value<int> isExtraPeriod = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyScheduleOverridesCompanion(
            id: id,
            sessionId: sessionId,
            date: date,
            overrideType: overrideType,
            newSubjectId: newSubjectId,
            newStartTime: newStartTime,
            newEndTime: newEndTime,
            isCancelled: isCancelled,
            isExtraPeriod: isExtraPeriod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required int date,
            required String overrideType,
            Value<String?> newSubjectId = const Value.absent(),
            Value<String?> newStartTime = const Value.absent(),
            Value<String?> newEndTime = const Value.absent(),
            Value<int> isCancelled = const Value.absent(),
            Value<int> isExtraPeriod = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyScheduleOverridesCompanion.insert(
            id: id,
            sessionId: sessionId,
            date: date,
            overrideType: overrideType,
            newSubjectId: newSubjectId,
            newStartTime: newStartTime,
            newEndTime: newEndTime,
            isCancelled: isCancelled,
            isExtraPeriod: isExtraPeriod,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DailyScheduleOverridesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false, newSubjectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable: $$DailyScheduleOverridesTableReferences
                        ._sessionIdTable(db),
                    referencedColumn: $$DailyScheduleOverridesTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }
                if (newSubjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.newSubjectId,
                    referencedTable: $$DailyScheduleOverridesTableReferences
                        ._newSubjectIdTable(db),
                    referencedColumn: $$DailyScheduleOverridesTableReferences
                        ._newSubjectIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DailyScheduleOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DailyScheduleOverridesTable,
        DailyScheduleOverride,
        $$DailyScheduleOverridesTableFilterComposer,
        $$DailyScheduleOverridesTableOrderingComposer,
        $$DailyScheduleOverridesTableAnnotationComposer,
        $$DailyScheduleOverridesTableCreateCompanionBuilder,
        $$DailyScheduleOverridesTableUpdateCompanionBuilder,
        (DailyScheduleOverride, $$DailyScheduleOverridesTableReferences),
        DailyScheduleOverride,
        PrefetchHooks Function({bool sessionId, bool newSubjectId})>;
typedef $$AttendanceLogsTableCreateCompanionBuilder = AttendanceLogsCompanion
    Function({
  required String id,
  required String subjectId,
  required String semesterId,
  Value<String?> sessionId,
  required String status,
  required int date,
  Value<String?> startTime,
  Value<String?> endTime,
  Value<int> isArchived,
  required int createdAt,
  Value<int> rowid,
});
typedef $$AttendanceLogsTableUpdateCompanionBuilder = AttendanceLogsCompanion
    Function({
  Value<String> id,
  Value<String> subjectId,
  Value<String> semesterId,
  Value<String?> sessionId,
  Value<String> status,
  Value<int> date,
  Value<String?> startTime,
  Value<String?> endTime,
  Value<int> isArchived,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$AttendanceLogsTableReferences
    extends BaseReferences<_$AppDatabase, $AttendanceLogsTable, AttendanceLog> {
  $$AttendanceLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias(
          $_aliasNameGenerator(db.attendanceLogs.subjectId, db.subjects.id));

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias(
          $_aliasNameGenerator(db.attendanceLogs.semesterId, db.semesters.id));

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager($_db, $_db.semesters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ClassSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.classSessions.createAlias($_aliasNameGenerator(
          db.attendanceLogs.sessionId, db.classSessions.id));

  $$ClassSessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<String>('session_id');
    if ($_column == null) return null;
    final manager = $$ClassSessionsTableTableManager($_db, $_db.classSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AttendanceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableFilterComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassSessionsTableFilterComposer get sessionId {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableFilterComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableOrderingComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassSessionsTableOrderingComposer get sessionId {
    final $$ClassSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.semesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableAnnotationComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassSessionsTableAnnotationComposer get sessionId {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.classSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendanceLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendanceLogsTable,
    AttendanceLog,
    $$AttendanceLogsTableFilterComposer,
    $$AttendanceLogsTableOrderingComposer,
    $$AttendanceLogsTableAnnotationComposer,
    $$AttendanceLogsTableCreateCompanionBuilder,
    $$AttendanceLogsTableUpdateCompanionBuilder,
    (AttendanceLog, $$AttendanceLogsTableReferences),
    AttendanceLog,
    PrefetchHooks Function({bool subjectId, bool semesterId, bool sessionId})> {
  $$AttendanceLogsTableTableManager(
      _$AppDatabase db, $AttendanceLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String> semesterId = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<String?> startTime = const Value.absent(),
            Value<String?> endTime = const Value.absent(),
            Value<int> isArchived = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceLogsCompanion(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            sessionId: sessionId,
            status: status,
            date: date,
            startTime: startTime,
            endTime: endTime,
            isArchived: isArchived,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            required String semesterId,
            Value<String?> sessionId = const Value.absent(),
            required String status,
            required int date,
            Value<String?> startTime = const Value.absent(),
            Value<String?> endTime = const Value.absent(),
            Value<int> isArchived = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceLogsCompanion.insert(
            id: id,
            subjectId: subjectId,
            semesterId: semesterId,
            sessionId: sessionId,
            status: status,
            date: date,
            startTime: startTime,
            endTime: endTime,
            isArchived: isArchived,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AttendanceLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false, semesterId = false, sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$AttendanceLogsTableReferences._subjectIdTable(db),
                    referencedColumn:
                        $$AttendanceLogsTableReferences._subjectIdTable(db).id,
                  ) as T;
                }
                if (semesterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.semesterId,
                    referencedTable:
                        $$AttendanceLogsTableReferences._semesterIdTable(db),
                    referencedColumn:
                        $$AttendanceLogsTableReferences._semesterIdTable(db).id,
                  ) as T;
                }
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$AttendanceLogsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$AttendanceLogsTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AttendanceLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendanceLogsTable,
    AttendanceLog,
    $$AttendanceLogsTableFilterComposer,
    $$AttendanceLogsTableOrderingComposer,
    $$AttendanceLogsTableAnnotationComposer,
    $$AttendanceLogsTableCreateCompanionBuilder,
    $$AttendanceLogsTableUpdateCompanionBuilder,
    (AttendanceLog, $$AttendanceLogsTableReferences),
    AttendanceLog,
    PrefetchHooks Function({bool subjectId, bool semesterId, bool sessionId})>;
typedef $$NotificationPreferencesTableCreateCompanionBuilder
    = NotificationPreferencesCompanion Function({
  Value<int> id,
  Value<int> notificationsEnabled,
  Value<int> soundEnabled,
  Value<int> vibrationEnabled,
  Value<int> badgeCount,
  Value<int?> quietHoursStartHour,
  Value<int?> quietHoursStartMinute,
  Value<int?> quietHoursEndHour,
  Value<int?> quietHoursEndMinute,
  Value<int> classRemindersEnabled,
  Value<int> reminderMinutes,
  Value<int> onlyFirstClassReminder,
  Value<int> gapClassRemindersEnabled,
  Value<int> gapMinutes,
  Value<int> attendanceRemindersEnabled,
  Value<int> attendanceDelayMinutes,
  Value<int> absentRestOfDayEnabled,
  Value<int> autoDismissMinutes,
  Value<int> lowAttendanceAlertsEnabled,
  Value<int> recoverySuggestionsEnabled,
  Value<int> criticalAttendanceEnabled,
  Value<double> criticalThreshold,
  Value<int> safeBunkPlannerEnabled,
  Value<int> plannerTimeHour,
  Value<int> plannerTimeMinute,
  Value<int> includeSafeBunks,
  Value<int> plannerIncludeRecoverySuggestions,
  Value<int> includeRiskSubjects,
  Value<int> dailySummaryEnabled,
  Value<int> summaryTimeHour,
  Value<int> summaryTimeMinute,
  Value<int> includeClassesAttended,
  Value<int> includeClassesMissed,
  Value<int> includeSubjectBreakdown,
  Value<int> includeOverallAttendance,
  required int updatedAt,
});
typedef $$NotificationPreferencesTableUpdateCompanionBuilder
    = NotificationPreferencesCompanion Function({
  Value<int> id,
  Value<int> notificationsEnabled,
  Value<int> soundEnabled,
  Value<int> vibrationEnabled,
  Value<int> badgeCount,
  Value<int?> quietHoursStartHour,
  Value<int?> quietHoursStartMinute,
  Value<int?> quietHoursEndHour,
  Value<int?> quietHoursEndMinute,
  Value<int> classRemindersEnabled,
  Value<int> reminderMinutes,
  Value<int> onlyFirstClassReminder,
  Value<int> gapClassRemindersEnabled,
  Value<int> gapMinutes,
  Value<int> attendanceRemindersEnabled,
  Value<int> attendanceDelayMinutes,
  Value<int> absentRestOfDayEnabled,
  Value<int> autoDismissMinutes,
  Value<int> lowAttendanceAlertsEnabled,
  Value<int> recoverySuggestionsEnabled,
  Value<int> criticalAttendanceEnabled,
  Value<double> criticalThreshold,
  Value<int> safeBunkPlannerEnabled,
  Value<int> plannerTimeHour,
  Value<int> plannerTimeMinute,
  Value<int> includeSafeBunks,
  Value<int> plannerIncludeRecoverySuggestions,
  Value<int> includeRiskSubjects,
  Value<int> dailySummaryEnabled,
  Value<int> summaryTimeHour,
  Value<int> summaryTimeMinute,
  Value<int> includeClassesAttended,
  Value<int> includeClassesMissed,
  Value<int> includeSubjectBreakdown,
  Value<int> includeOverallAttendance,
  Value<int> updatedAt,
});

class $$NotificationPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get soundEnabled => $composableBuilder(
      column: $table.soundEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vibrationEnabled => $composableBuilder(
      column: $table.vibrationEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get badgeCount => $composableBuilder(
      column: $table.badgeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quietHoursStartHour => $composableBuilder(
      column: $table.quietHoursStartHour,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quietHoursStartMinute => $composableBuilder(
      column: $table.quietHoursStartMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quietHoursEndHour => $composableBuilder(
      column: $table.quietHoursEndHour,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quietHoursEndMinute => $composableBuilder(
      column: $table.quietHoursEndMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get classRemindersEnabled => $composableBuilder(
      column: $table.classRemindersEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get onlyFirstClassReminder => $composableBuilder(
      column: $table.onlyFirstClassReminder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gapClassRemindersEnabled => $composableBuilder(
      column: $table.gapClassRemindersEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gapMinutes => $composableBuilder(
      column: $table.gapMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attendanceRemindersEnabled => $composableBuilder(
      column: $table.attendanceRemindersEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attendanceDelayMinutes => $composableBuilder(
      column: $table.attendanceDelayMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get absentRestOfDayEnabled => $composableBuilder(
      column: $table.absentRestOfDayEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get autoDismissMinutes => $composableBuilder(
      column: $table.autoDismissMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lowAttendanceAlertsEnabled => $composableBuilder(
      column: $table.lowAttendanceAlertsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recoverySuggestionsEnabled => $composableBuilder(
      column: $table.recoverySuggestionsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get criticalAttendanceEnabled => $composableBuilder(
      column: $table.criticalAttendanceEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get criticalThreshold => $composableBuilder(
      column: $table.criticalThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get safeBunkPlannerEnabled => $composableBuilder(
      column: $table.safeBunkPlannerEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannerTimeHour => $composableBuilder(
      column: $table.plannerTimeHour,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannerTimeMinute => $composableBuilder(
      column: $table.plannerTimeMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeSafeBunks => $composableBuilder(
      column: $table.includeSafeBunks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannerIncludeRecoverySuggestions =>
      $composableBuilder(
          column: $table.plannerIncludeRecoverySuggestions,
          builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeRiskSubjects => $composableBuilder(
      column: $table.includeRiskSubjects,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailySummaryEnabled => $composableBuilder(
      column: $table.dailySummaryEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get summaryTimeHour => $composableBuilder(
      column: $table.summaryTimeHour,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get summaryTimeMinute => $composableBuilder(
      column: $table.summaryTimeMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeClassesAttended => $composableBuilder(
      column: $table.includeClassesAttended,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeClassesMissed => $composableBuilder(
      column: $table.includeClassesMissed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeSubjectBreakdown => $composableBuilder(
      column: $table.includeSubjectBreakdown,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get includeOverallAttendance => $composableBuilder(
      column: $table.includeOverallAttendance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NotificationPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get soundEnabled => $composableBuilder(
      column: $table.soundEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vibrationEnabled => $composableBuilder(
      column: $table.vibrationEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get badgeCount => $composableBuilder(
      column: $table.badgeCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quietHoursStartHour => $composableBuilder(
      column: $table.quietHoursStartHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quietHoursStartMinute => $composableBuilder(
      column: $table.quietHoursStartMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quietHoursEndHour => $composableBuilder(
      column: $table.quietHoursEndHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quietHoursEndMinute => $composableBuilder(
      column: $table.quietHoursEndMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get classRemindersEnabled => $composableBuilder(
      column: $table.classRemindersEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get onlyFirstClassReminder => $composableBuilder(
      column: $table.onlyFirstClassReminder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gapClassRemindersEnabled => $composableBuilder(
      column: $table.gapClassRemindersEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gapMinutes => $composableBuilder(
      column: $table.gapMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attendanceRemindersEnabled => $composableBuilder(
      column: $table.attendanceRemindersEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attendanceDelayMinutes => $composableBuilder(
      column: $table.attendanceDelayMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get absentRestOfDayEnabled => $composableBuilder(
      column: $table.absentRestOfDayEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get autoDismissMinutes => $composableBuilder(
      column: $table.autoDismissMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lowAttendanceAlertsEnabled => $composableBuilder(
      column: $table.lowAttendanceAlertsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recoverySuggestionsEnabled => $composableBuilder(
      column: $table.recoverySuggestionsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get criticalAttendanceEnabled => $composableBuilder(
      column: $table.criticalAttendanceEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get criticalThreshold => $composableBuilder(
      column: $table.criticalThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get safeBunkPlannerEnabled => $composableBuilder(
      column: $table.safeBunkPlannerEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannerTimeHour => $composableBuilder(
      column: $table.plannerTimeHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannerTimeMinute => $composableBuilder(
      column: $table.plannerTimeMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeSafeBunks => $composableBuilder(
      column: $table.includeSafeBunks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannerIncludeRecoverySuggestions =>
      $composableBuilder(
          column: $table.plannerIncludeRecoverySuggestions,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeRiskSubjects => $composableBuilder(
      column: $table.includeRiskSubjects,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailySummaryEnabled => $composableBuilder(
      column: $table.dailySummaryEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get summaryTimeHour => $composableBuilder(
      column: $table.summaryTimeHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get summaryTimeMinute => $composableBuilder(
      column: $table.summaryTimeMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeClassesAttended => $composableBuilder(
      column: $table.includeClassesAttended,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeClassesMissed => $composableBuilder(
      column: $table.includeClassesMissed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeSubjectBreakdown => $composableBuilder(
      column: $table.includeSubjectBreakdown,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get includeOverallAttendance => $composableBuilder(
      column: $table.includeOverallAttendance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotificationPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<int> get soundEnabled => $composableBuilder(
      column: $table.soundEnabled, builder: (column) => column);

  GeneratedColumn<int> get vibrationEnabled => $composableBuilder(
      column: $table.vibrationEnabled, builder: (column) => column);

  GeneratedColumn<int> get badgeCount => $composableBuilder(
      column: $table.badgeCount, builder: (column) => column);

  GeneratedColumn<int> get quietHoursStartHour => $composableBuilder(
      column: $table.quietHoursStartHour, builder: (column) => column);

  GeneratedColumn<int> get quietHoursStartMinute => $composableBuilder(
      column: $table.quietHoursStartMinute, builder: (column) => column);

  GeneratedColumn<int> get quietHoursEndHour => $composableBuilder(
      column: $table.quietHoursEndHour, builder: (column) => column);

  GeneratedColumn<int> get quietHoursEndMinute => $composableBuilder(
      column: $table.quietHoursEndMinute, builder: (column) => column);

  GeneratedColumn<int> get classRemindersEnabled => $composableBuilder(
      column: $table.classRemindersEnabled, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<int> get onlyFirstClassReminder => $composableBuilder(
      column: $table.onlyFirstClassReminder, builder: (column) => column);

  GeneratedColumn<int> get gapClassRemindersEnabled => $composableBuilder(
      column: $table.gapClassRemindersEnabled, builder: (column) => column);

  GeneratedColumn<int> get gapMinutes => $composableBuilder(
      column: $table.gapMinutes, builder: (column) => column);

  GeneratedColumn<int> get attendanceRemindersEnabled => $composableBuilder(
      column: $table.attendanceRemindersEnabled, builder: (column) => column);

  GeneratedColumn<int> get attendanceDelayMinutes => $composableBuilder(
      column: $table.attendanceDelayMinutes, builder: (column) => column);

  GeneratedColumn<int> get absentRestOfDayEnabled => $composableBuilder(
      column: $table.absentRestOfDayEnabled, builder: (column) => column);

  GeneratedColumn<int> get autoDismissMinutes => $composableBuilder(
      column: $table.autoDismissMinutes, builder: (column) => column);

  GeneratedColumn<int> get lowAttendanceAlertsEnabled => $composableBuilder(
      column: $table.lowAttendanceAlertsEnabled, builder: (column) => column);

  GeneratedColumn<int> get recoverySuggestionsEnabled => $composableBuilder(
      column: $table.recoverySuggestionsEnabled, builder: (column) => column);

  GeneratedColumn<int> get criticalAttendanceEnabled => $composableBuilder(
      column: $table.criticalAttendanceEnabled, builder: (column) => column);

  GeneratedColumn<double> get criticalThreshold => $composableBuilder(
      column: $table.criticalThreshold, builder: (column) => column);

  GeneratedColumn<int> get safeBunkPlannerEnabled => $composableBuilder(
      column: $table.safeBunkPlannerEnabled, builder: (column) => column);

  GeneratedColumn<int> get plannerTimeHour => $composableBuilder(
      column: $table.plannerTimeHour, builder: (column) => column);

  GeneratedColumn<int> get plannerTimeMinute => $composableBuilder(
      column: $table.plannerTimeMinute, builder: (column) => column);

  GeneratedColumn<int> get includeSafeBunks => $composableBuilder(
      column: $table.includeSafeBunks, builder: (column) => column);

  GeneratedColumn<int> get plannerIncludeRecoverySuggestions =>
      $composableBuilder(
          column: $table.plannerIncludeRecoverySuggestions,
          builder: (column) => column);

  GeneratedColumn<int> get includeRiskSubjects => $composableBuilder(
      column: $table.includeRiskSubjects, builder: (column) => column);

  GeneratedColumn<int> get dailySummaryEnabled => $composableBuilder(
      column: $table.dailySummaryEnabled, builder: (column) => column);

  GeneratedColumn<int> get summaryTimeHour => $composableBuilder(
      column: $table.summaryTimeHour, builder: (column) => column);

  GeneratedColumn<int> get summaryTimeMinute => $composableBuilder(
      column: $table.summaryTimeMinute, builder: (column) => column);

  GeneratedColumn<int> get includeClassesAttended => $composableBuilder(
      column: $table.includeClassesAttended, builder: (column) => column);

  GeneratedColumn<int> get includeClassesMissed => $composableBuilder(
      column: $table.includeClassesMissed, builder: (column) => column);

  GeneratedColumn<int> get includeSubjectBreakdown => $composableBuilder(
      column: $table.includeSubjectBreakdown, builder: (column) => column);

  GeneratedColumn<int> get includeOverallAttendance => $composableBuilder(
      column: $table.includeOverallAttendance, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotificationPreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotificationPreferencesTable,
    NotificationPreference,
    $$NotificationPreferencesTableFilterComposer,
    $$NotificationPreferencesTableOrderingComposer,
    $$NotificationPreferencesTableAnnotationComposer,
    $$NotificationPreferencesTableCreateCompanionBuilder,
    $$NotificationPreferencesTableUpdateCompanionBuilder,
    (
      NotificationPreference,
      BaseReferences<_$AppDatabase, $NotificationPreferencesTable,
          NotificationPreference>
    ),
    NotificationPreference,
    PrefetchHooks Function()> {
  $$NotificationPreferencesTableTableManager(
      _$AppDatabase db, $NotificationPreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationPreferencesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationPreferencesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationPreferencesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> notificationsEnabled = const Value.absent(),
            Value<int> soundEnabled = const Value.absent(),
            Value<int> vibrationEnabled = const Value.absent(),
            Value<int> badgeCount = const Value.absent(),
            Value<int?> quietHoursStartHour = const Value.absent(),
            Value<int?> quietHoursStartMinute = const Value.absent(),
            Value<int?> quietHoursEndHour = const Value.absent(),
            Value<int?> quietHoursEndMinute = const Value.absent(),
            Value<int> classRemindersEnabled = const Value.absent(),
            Value<int> reminderMinutes = const Value.absent(),
            Value<int> onlyFirstClassReminder = const Value.absent(),
            Value<int> gapClassRemindersEnabled = const Value.absent(),
            Value<int> gapMinutes = const Value.absent(),
            Value<int> attendanceRemindersEnabled = const Value.absent(),
            Value<int> attendanceDelayMinutes = const Value.absent(),
            Value<int> absentRestOfDayEnabled = const Value.absent(),
            Value<int> autoDismissMinutes = const Value.absent(),
            Value<int> lowAttendanceAlertsEnabled = const Value.absent(),
            Value<int> recoverySuggestionsEnabled = const Value.absent(),
            Value<int> criticalAttendanceEnabled = const Value.absent(),
            Value<double> criticalThreshold = const Value.absent(),
            Value<int> safeBunkPlannerEnabled = const Value.absent(),
            Value<int> plannerTimeHour = const Value.absent(),
            Value<int> plannerTimeMinute = const Value.absent(),
            Value<int> includeSafeBunks = const Value.absent(),
            Value<int> plannerIncludeRecoverySuggestions = const Value.absent(),
            Value<int> includeRiskSubjects = const Value.absent(),
            Value<int> dailySummaryEnabled = const Value.absent(),
            Value<int> summaryTimeHour = const Value.absent(),
            Value<int> summaryTimeMinute = const Value.absent(),
            Value<int> includeClassesAttended = const Value.absent(),
            Value<int> includeClassesMissed = const Value.absent(),
            Value<int> includeSubjectBreakdown = const Value.absent(),
            Value<int> includeOverallAttendance = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              NotificationPreferencesCompanion(
            id: id,
            notificationsEnabled: notificationsEnabled,
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled,
            badgeCount: badgeCount,
            quietHoursStartHour: quietHoursStartHour,
            quietHoursStartMinute: quietHoursStartMinute,
            quietHoursEndHour: quietHoursEndHour,
            quietHoursEndMinute: quietHoursEndMinute,
            classRemindersEnabled: classRemindersEnabled,
            reminderMinutes: reminderMinutes,
            onlyFirstClassReminder: onlyFirstClassReminder,
            gapClassRemindersEnabled: gapClassRemindersEnabled,
            gapMinutes: gapMinutes,
            attendanceRemindersEnabled: attendanceRemindersEnabled,
            attendanceDelayMinutes: attendanceDelayMinutes,
            absentRestOfDayEnabled: absentRestOfDayEnabled,
            autoDismissMinutes: autoDismissMinutes,
            lowAttendanceAlertsEnabled: lowAttendanceAlertsEnabled,
            recoverySuggestionsEnabled: recoverySuggestionsEnabled,
            criticalAttendanceEnabled: criticalAttendanceEnabled,
            criticalThreshold: criticalThreshold,
            safeBunkPlannerEnabled: safeBunkPlannerEnabled,
            plannerTimeHour: plannerTimeHour,
            plannerTimeMinute: plannerTimeMinute,
            includeSafeBunks: includeSafeBunks,
            plannerIncludeRecoverySuggestions:
                plannerIncludeRecoverySuggestions,
            includeRiskSubjects: includeRiskSubjects,
            dailySummaryEnabled: dailySummaryEnabled,
            summaryTimeHour: summaryTimeHour,
            summaryTimeMinute: summaryTimeMinute,
            includeClassesAttended: includeClassesAttended,
            includeClassesMissed: includeClassesMissed,
            includeSubjectBreakdown: includeSubjectBreakdown,
            includeOverallAttendance: includeOverallAttendance,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> notificationsEnabled = const Value.absent(),
            Value<int> soundEnabled = const Value.absent(),
            Value<int> vibrationEnabled = const Value.absent(),
            Value<int> badgeCount = const Value.absent(),
            Value<int?> quietHoursStartHour = const Value.absent(),
            Value<int?> quietHoursStartMinute = const Value.absent(),
            Value<int?> quietHoursEndHour = const Value.absent(),
            Value<int?> quietHoursEndMinute = const Value.absent(),
            Value<int> classRemindersEnabled = const Value.absent(),
            Value<int> reminderMinutes = const Value.absent(),
            Value<int> onlyFirstClassReminder = const Value.absent(),
            Value<int> gapClassRemindersEnabled = const Value.absent(),
            Value<int> gapMinutes = const Value.absent(),
            Value<int> attendanceRemindersEnabled = const Value.absent(),
            Value<int> attendanceDelayMinutes = const Value.absent(),
            Value<int> absentRestOfDayEnabled = const Value.absent(),
            Value<int> autoDismissMinutes = const Value.absent(),
            Value<int> lowAttendanceAlertsEnabled = const Value.absent(),
            Value<int> recoverySuggestionsEnabled = const Value.absent(),
            Value<int> criticalAttendanceEnabled = const Value.absent(),
            Value<double> criticalThreshold = const Value.absent(),
            Value<int> safeBunkPlannerEnabled = const Value.absent(),
            Value<int> plannerTimeHour = const Value.absent(),
            Value<int> plannerTimeMinute = const Value.absent(),
            Value<int> includeSafeBunks = const Value.absent(),
            Value<int> plannerIncludeRecoverySuggestions = const Value.absent(),
            Value<int> includeRiskSubjects = const Value.absent(),
            Value<int> dailySummaryEnabled = const Value.absent(),
            Value<int> summaryTimeHour = const Value.absent(),
            Value<int> summaryTimeMinute = const Value.absent(),
            Value<int> includeClassesAttended = const Value.absent(),
            Value<int> includeClassesMissed = const Value.absent(),
            Value<int> includeSubjectBreakdown = const Value.absent(),
            Value<int> includeOverallAttendance = const Value.absent(),
            required int updatedAt,
          }) =>
              NotificationPreferencesCompanion.insert(
            id: id,
            notificationsEnabled: notificationsEnabled,
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled,
            badgeCount: badgeCount,
            quietHoursStartHour: quietHoursStartHour,
            quietHoursStartMinute: quietHoursStartMinute,
            quietHoursEndHour: quietHoursEndHour,
            quietHoursEndMinute: quietHoursEndMinute,
            classRemindersEnabled: classRemindersEnabled,
            reminderMinutes: reminderMinutes,
            onlyFirstClassReminder: onlyFirstClassReminder,
            gapClassRemindersEnabled: gapClassRemindersEnabled,
            gapMinutes: gapMinutes,
            attendanceRemindersEnabled: attendanceRemindersEnabled,
            attendanceDelayMinutes: attendanceDelayMinutes,
            absentRestOfDayEnabled: absentRestOfDayEnabled,
            autoDismissMinutes: autoDismissMinutes,
            lowAttendanceAlertsEnabled: lowAttendanceAlertsEnabled,
            recoverySuggestionsEnabled: recoverySuggestionsEnabled,
            criticalAttendanceEnabled: criticalAttendanceEnabled,
            criticalThreshold: criticalThreshold,
            safeBunkPlannerEnabled: safeBunkPlannerEnabled,
            plannerTimeHour: plannerTimeHour,
            plannerTimeMinute: plannerTimeMinute,
            includeSafeBunks: includeSafeBunks,
            plannerIncludeRecoverySuggestions:
                plannerIncludeRecoverySuggestions,
            includeRiskSubjects: includeRiskSubjects,
            dailySummaryEnabled: dailySummaryEnabled,
            summaryTimeHour: summaryTimeHour,
            summaryTimeMinute: summaryTimeMinute,
            includeClassesAttended: includeClassesAttended,
            includeClassesMissed: includeClassesMissed,
            includeSubjectBreakdown: includeSubjectBreakdown,
            includeOverallAttendance: includeOverallAttendance,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotificationPreferencesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $NotificationPreferencesTable,
        NotificationPreference,
        $$NotificationPreferencesTableFilterComposer,
        $$NotificationPreferencesTableOrderingComposer,
        $$NotificationPreferencesTableAnnotationComposer,
        $$NotificationPreferencesTableCreateCompanionBuilder,
        $$NotificationPreferencesTableUpdateCompanionBuilder,
        (
          NotificationPreference,
          BaseReferences<_$AppDatabase, $NotificationPreferencesTable,
              NotificationPreference>
        ),
        NotificationPreference,
        PrefetchHooks Function()>;
typedef $$NotificationDedupTableCreateCompanionBuilder
    = NotificationDedupCompanion Function({
  required String key,
  required String lastFiredDate,
  required int firedAt,
  Value<int?> resolvedAt,
  Value<int> rowid,
});
typedef $$NotificationDedupTableUpdateCompanionBuilder
    = NotificationDedupCompanion Function({
  Value<String> key,
  Value<String> lastFiredDate,
  Value<int> firedAt,
  Value<int?> resolvedAt,
  Value<int> rowid,
});

class $$NotificationDedupTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationDedupTable> {
  $$NotificationDedupTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastFiredDate => $composableBuilder(
      column: $table.lastFiredDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get firedAt => $composableBuilder(
      column: $table.firedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => ColumnFilters(column));
}

class $$NotificationDedupTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationDedupTable> {
  $$NotificationDedupTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastFiredDate => $composableBuilder(
      column: $table.lastFiredDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get firedAt => $composableBuilder(
      column: $table.firedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotificationDedupTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationDedupTable> {
  $$NotificationDedupTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get lastFiredDate => $composableBuilder(
      column: $table.lastFiredDate, builder: (column) => column);

  GeneratedColumn<int> get firedAt =>
      $composableBuilder(column: $table.firedAt, builder: (column) => column);

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
      column: $table.resolvedAt, builder: (column) => column);
}

class $$NotificationDedupTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotificationDedupTable,
    NotificationDedupData,
    $$NotificationDedupTableFilterComposer,
    $$NotificationDedupTableOrderingComposer,
    $$NotificationDedupTableAnnotationComposer,
    $$NotificationDedupTableCreateCompanionBuilder,
    $$NotificationDedupTableUpdateCompanionBuilder,
    (
      NotificationDedupData,
      BaseReferences<_$AppDatabase, $NotificationDedupTable,
          NotificationDedupData>
    ),
    NotificationDedupData,
    PrefetchHooks Function()> {
  $$NotificationDedupTableTableManager(
      _$AppDatabase db, $NotificationDedupTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationDedupTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationDedupTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationDedupTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> lastFiredDate = const Value.absent(),
            Value<int> firedAt = const Value.absent(),
            Value<int?> resolvedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationDedupCompanion(
            key: key,
            lastFiredDate: lastFiredDate,
            firedAt: firedAt,
            resolvedAt: resolvedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String lastFiredDate,
            required int firedAt,
            Value<int?> resolvedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationDedupCompanion.insert(
            key: key,
            lastFiredDate: lastFiredDate,
            firedAt: firedAt,
            resolvedAt: resolvedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotificationDedupTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotificationDedupTable,
    NotificationDedupData,
    $$NotificationDedupTableFilterComposer,
    $$NotificationDedupTableOrderingComposer,
    $$NotificationDedupTableAnnotationComposer,
    $$NotificationDedupTableCreateCompanionBuilder,
    $$NotificationDedupTableUpdateCompanionBuilder,
    (
      NotificationDedupData,
      BaseReferences<_$AppDatabase, $NotificationDedupTable,
          NotificationDedupData>
    ),
    NotificationDedupData,
    PrefetchHooks Function()>;
typedef $$AppNotificationsTableCreateCompanionBuilder
    = AppNotificationsCompanion Function({
  required String id,
  required String title,
  required String message,
  required String type,
  Value<String> priority,
  Value<int> isRead,
  Value<String?> payload,
  required int createdAt,
  Value<int> rowid,
});
typedef $$AppNotificationsTableUpdateCompanionBuilder
    = AppNotificationsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> message,
  Value<String> type,
  Value<String> priority,
  Value<int> isRead,
  Value<String?> payload,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$AppNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AppNotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppNotificationsTable,
    AppNotification,
    $$AppNotificationsTableFilterComposer,
    $$AppNotificationsTableOrderingComposer,
    $$AppNotificationsTableAnnotationComposer,
    $$AppNotificationsTableCreateCompanionBuilder,
    $$AppNotificationsTableUpdateCompanionBuilder,
    (
      AppNotification,
      BaseReferences<_$AppDatabase, $AppNotificationsTable, AppNotification>
    ),
    AppNotification,
    PrefetchHooks Function()> {
  $$AppNotificationsTableTableManager(
      _$AppDatabase db, $AppNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<int> isRead = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppNotificationsCompanion(
            id: id,
            title: title,
            message: message,
            type: type,
            priority: priority,
            isRead: isRead,
            payload: payload,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String message,
            required String type,
            Value<String> priority = const Value.absent(),
            Value<int> isRead = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppNotificationsCompanion.insert(
            id: id,
            title: title,
            message: message,
            type: type,
            priority: priority,
            isRead: isRead,
            payload: payload,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppNotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppNotificationsTable,
    AppNotification,
    $$AppNotificationsTableFilterComposer,
    $$AppNotificationsTableOrderingComposer,
    $$AppNotificationsTableAnnotationComposer,
    $$AppNotificationsTableCreateCompanionBuilder,
    $$AppNotificationsTableUpdateCompanionBuilder,
    (
      AppNotification,
      BaseReferences<_$AppDatabase, $AppNotificationsTable, AppNotification>
    ),
    AppNotification,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<int> onboardingComplete,
  Value<String?> onboardingStep,
  Value<String> themeMode,
  Value<double> attendanceGoal,
  Value<int> notificationsEnabled,
  Value<String?> collegeName,
  Value<String?> courseName,
  Value<String?> activeSemesterId,
  required int updatedAt,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<int> onboardingComplete,
  Value<String?> onboardingStep,
  Value<String> themeMode,
  Value<double> attendanceGoal,
  Value<int> notificationsEnabled,
  Value<String?> collegeName,
  Value<String?> courseName,
  Value<String?> activeSemesterId,
  Value<int> updatedAt,
});

final class $$AppSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting> {
  $$AppSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _activeSemesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias($_aliasNameGenerator(
          db.appSettings.activeSemesterId, db.semesters.id));

  $$SemestersTableProcessedTableManager? get activeSemesterId {
    final $_column = $_itemColumn<String>('active_semester_id');
    if ($_column == null) return null;
    final manager = $$SemestersTableTableManager($_db, $_db.semesters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activeSemesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get onboardingStep => $composableBuilder(
      column: $table.onboardingStep,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get attendanceGoal => $composableBuilder(
      column: $table.attendanceGoal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get collegeName => $composableBuilder(
      column: $table.collegeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courseName => $composableBuilder(
      column: $table.courseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$SemestersTableFilterComposer get activeSemesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.activeSemesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableFilterComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get onboardingStep => $composableBuilder(
      column: $table.onboardingStep,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get attendanceGoal => $composableBuilder(
      column: $table.attendanceGoal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get collegeName => $composableBuilder(
      column: $table.collegeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courseName => $composableBuilder(
      column: $table.courseName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$SemestersTableOrderingComposer get activeSemesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.activeSemesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableOrderingComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get onboardingComplete => $composableBuilder(
      column: $table.onboardingComplete, builder: (column) => column);

  GeneratedColumn<String> get onboardingStep => $composableBuilder(
      column: $table.onboardingStep, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<double> get attendanceGoal => $composableBuilder(
      column: $table.attendanceGoal, builder: (column) => column);

  GeneratedColumn<int> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<String> get collegeName => $composableBuilder(
      column: $table.collegeName, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
      column: $table.courseName, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get activeSemesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.activeSemesterId,
        referencedTable: $db.semesters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SemestersTableAnnotationComposer(
              $db: $db,
              $table: $db.semesters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, $$AppSettingsTableReferences),
    AppSetting,
    PrefetchHooks Function({bool activeSemesterId})> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> onboardingComplete = const Value.absent(),
            Value<String?> onboardingStep = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<double> attendanceGoal = const Value.absent(),
            Value<int> notificationsEnabled = const Value.absent(),
            Value<String?> collegeName = const Value.absent(),
            Value<String?> courseName = const Value.absent(),
            Value<String?> activeSemesterId = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            onboardingComplete: onboardingComplete,
            onboardingStep: onboardingStep,
            themeMode: themeMode,
            attendanceGoal: attendanceGoal,
            notificationsEnabled: notificationsEnabled,
            collegeName: collegeName,
            courseName: courseName,
            activeSemesterId: activeSemesterId,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> onboardingComplete = const Value.absent(),
            Value<String?> onboardingStep = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<double> attendanceGoal = const Value.absent(),
            Value<int> notificationsEnabled = const Value.absent(),
            Value<String?> collegeName = const Value.absent(),
            Value<String?> courseName = const Value.absent(),
            Value<String?> activeSemesterId = const Value.absent(),
            required int updatedAt,
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            onboardingComplete: onboardingComplete,
            onboardingStep: onboardingStep,
            themeMode: themeMode,
            attendanceGoal: attendanceGoal,
            notificationsEnabled: notificationsEnabled,
            collegeName: collegeName,
            courseName: courseName,
            activeSemesterId: activeSemesterId,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AppSettingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({activeSemesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (activeSemesterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.activeSemesterId,
                    referencedTable:
                        $$AppSettingsTableReferences._activeSemesterIdTable(db),
                    referencedColumn: $$AppSettingsTableReferences
                        ._activeSemesterIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, $$AppSettingsTableReferences),
    AppSetting,
    PrefetchHooks Function({bool activeSemesterId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$SemesterHolidaysTableTableManager get semesterHolidays =>
      $$SemesterHolidaysTableTableManager(_db, _db.semesterHolidays);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(_db, _db.timetableEntries);
  $$ClassSessionsTableTableManager get classSessions =>
      $$ClassSessionsTableTableManager(_db, _db.classSessions);
  $$DailyScheduleOverridesTableTableManager get dailyScheduleOverrides =>
      $$DailyScheduleOverridesTableTableManager(
          _db, _db.dailyScheduleOverrides);
  $$AttendanceLogsTableTableManager get attendanceLogs =>
      $$AttendanceLogsTableTableManager(_db, _db.attendanceLogs);
  $$NotificationPreferencesTableTableManager get notificationPreferences =>
      $$NotificationPreferencesTableTableManager(
          _db, _db.notificationPreferences);
  $$NotificationDedupTableTableManager get notificationDedup =>
      $$NotificationDedupTableTableManager(_db, _db.notificationDedup);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
