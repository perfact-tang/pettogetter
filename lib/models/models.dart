/// Core domain models for copaw.
///
/// These mirror the Swift models in `co-paw/copaw/Models/Models.swift`.
/// Dates are serialized as epoch milliseconds in JSON and as Firestore
/// `Timestamp`s on the wire (see the service layer).
library;

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

int? _msFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _dateFromJson(dynamic value) {
  final ms = _msFromJson(value);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

/// Serializes a [DateTime] to epoch milliseconds. Null-safe.
int? _dateToJson(DateTime? value) => value?.millisecondsSinceEpoch;

String? _stringFromJson(dynamic value) => value as String?;

int _intFromJson(dynamic value, [int fallback = 0]) =>
    value is int ? value : (value is num ? value.toInt() : fallback);

bool _boolFromJson(dynamic value, [bool fallback = false]) =>
    value is bool ? value : fallback;

List<int> _weekdaysFromJson(dynamic value) {
  if (value is List) {
    return value.whereType<num>().map((e) => e.toInt()).toList();
  }
  return List<int>.from(<int>[1, 2, 3, 4, 5, 6, 7]);
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CareTaskStatus {
  unclaimed('unclaimed'),
  claimed('claimed'),
  completed('completed');

  const CareTaskStatus(this.rawValue);
  final String rawValue;

  /// Accepts the legacy "pending" value used by older documents.
  static CareTaskStatus fromRaw(String value) {
    switch (value) {
      case 'pending':
      case 'unclaimed':
        return CareTaskStatus.unclaimed;
      case 'claimed':
        return CareTaskStatus.claimed;
      case 'completed':
        return CareTaskStatus.completed;
      default:
        throw FormatException('Unknown care task status: $value');
    }
  }
}

enum CareTaskKind {
  routine('routine'),
  oneOff('oneOff');

  const CareTaskKind(this.rawValue);
  final String rawValue;

  static CareTaskKind fromRaw(String value) => CareTaskKind.values
      .firstWhere((e) => e.rawValue == value, orElse: () => CareTaskKind.oneOff);
}

enum CarePriority {
  normal('normal'),
  urgent('urgent');

  const CarePriority(this.rawValue);
  final String rawValue;

  static CarePriority fromRaw(String value) => CarePriority.values
      .firstWhere((e) => e.rawValue == value, orElse: () => CarePriority.normal);
}

enum CareCategory {
  feeding('feeding'),
  walking('walking'),
  medication('medication'),
  grooming('grooming'),
  other('other');

  const CareCategory(this.rawValue);
  final String rawValue;

  static CareCategory fromRaw(String value) => CareCategory.values
      .firstWhere((e) => e.rawValue == value, orElse: () => CareCategory.other);
}

enum AssignmentMode {
  direct('direct'),
  open('open');

  const AssignmentMode(this.rawValue);
  final String rawValue;

  static AssignmentMode fromRaw(String value) => AssignmentMode.values
      .firstWhere((e) => e.rawValue == value, orElse: () => AssignmentMode.direct);
}

enum CareRoutineFrequency {
  daily('daily'),
  selectedDays('selectedDays');

  const CareRoutineFrequency(this.rawValue);
  final String rawValue;

  static CareRoutineFrequency fromRaw(String value) =>
      CareRoutineFrequency.values.firstWhere(
        (e) => e.rawValue == value,
        orElse: () => CareRoutineFrequency.daily,
      );
}

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.petName,
    this.timeZoneIdentifier = '',
  });

  final String id;
  final String name;
  final String inviteCode;
  final String petName;
  final String timeZoneIdentifier;

  Household copyWith({
    String? name,
    String? petName,
    String? inviteCode,
    String? timeZoneIdentifier,
  }) {
    return Household(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      petName: petName ?? this.petName,
      timeZoneIdentifier: timeZoneIdentifier ?? this.timeZoneIdentifier,
    );
  }

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['inviteCode'] as String,
        petName: json['petName'] as String,
        timeZoneIdentifier: _stringFromJson(json['timeZoneIdentifier']) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'petName': petName,
        'timeZoneIdentifier': timeZoneIdentifier,
      };
}

class Caregiver {
  const Caregiver({required this.id, required this.displayName});

  final String id;
  final String displayName;

  Caregiver copyWith({String? displayName}) =>
      Caregiver(id: id, displayName: displayName ?? this.displayName);

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'displayName': displayName};
}

class AssignmentRequest {
  const AssignmentRequest({
    required this.id,
    required this.requestedByID,
    required this.requestedByNameSnapshot,
    this.requestedToID,
    this.requestedToNameSnapshot,
    this.mode = AssignmentMode.direct,
    required this.createdAt,
  });

  final String id;
  final String requestedByID;
  final String requestedByNameSnapshot;
  final String? requestedToID;
  final String? requestedToNameSnapshot;
  final AssignmentMode mode;
  final DateTime createdAt;

  factory AssignmentRequest.fromJson(Map<String, dynamic> json) =>
      AssignmentRequest(
        id: json['id'] as String,
        requestedByID: json['requestedByID'] as String,
        requestedByNameSnapshot: json['requestedByNameSnapshot'] as String,
        requestedToID: _stringFromJson(json['requestedToID']),
        requestedToNameSnapshot: _stringFromJson(json['requestedToNameSnapshot']),
        mode: AssignmentMode.fromRaw(json['mode'] as String? ?? 'direct'),
        createdAt: _dateFromJson(json['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestedByID': requestedByID,
        'requestedByNameSnapshot': requestedByNameSnapshot,
        'requestedToID': requestedToID,
        'requestedToNameSnapshot': requestedToNameSnapshot,
        'mode': mode.rawValue,
        'createdAt': _dateToJson(createdAt),
      };
}

class CareRoutine {
  const CareRoutine({
    required this.id,
    required this.title,
    required this.category,
    this.priority = CarePriority.normal,
    this.frequency = CareRoutineFrequency.daily,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    required this.hour,
    required this.minute,
    required this.startDate,
    required this.timeZoneIdentifier,
    required this.createdByID,
    required this.createdByNameSnapshot,
    this.isActive = true,
  });

  final String id;
  final String title;
  final CareCategory category;
  final CarePriority priority;
  final CareRoutineFrequency frequency;
  final List<int> weekdays;
  final int hour;
  final int minute;
  final DateTime startDate;
  final String timeZoneIdentifier;
  final String createdByID;
  final String createdByNameSnapshot;
  final bool isActive;

  factory CareRoutine.fromJson(Map<String, dynamic> json) => CareRoutine(
        id: json['id'] as String,
        title: json['title'] as String,
        category: CareCategory.fromRaw(json['category'] as String),
        priority: CarePriority.fromRaw(json['priority'] as String? ?? 'normal'),
        frequency:
            CareRoutineFrequency.fromRaw(json['frequency'] as String? ?? 'daily'),
        weekdays: _weekdaysFromJson(json['weekdays']),
        hour: _intFromJson(json['hour']),
        minute: _intFromJson(json['minute']),
        startDate:
            _dateFromJson(json['startDate']) ?? DateTime.now(),
        timeZoneIdentifier: _stringFromJson(json['timeZoneIdentifier']) ?? '',
        createdByID: json['createdByID'] as String,
        createdByNameSnapshot: json['createdByNameSnapshot'] as String,
        isActive: _boolFromJson(json['isActive'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.rawValue,
        'priority': priority.rawValue,
        'frequency': frequency.rawValue,
        'weekdays': weekdays,
        'hour': hour,
        'minute': minute,
        'startDate': _dateToJson(startDate),
        'timeZoneIdentifier': timeZoneIdentifier,
        'createdByID': createdByID,
        'createdByNameSnapshot': createdByNameSnapshot,
        'isActive': isActive,
      };
}

class CareTask {
  const CareTask({
    required this.id,
    required this.title,
    required this.category,
    required this.dueTime,
    this.kind = CareTaskKind.oneOff,
    this.priority = CarePriority.normal,
    this.routineID,
    this.status = CareTaskStatus.unclaimed,
    this.assignmentRequest,
    this.assigneeID,
    this.assigneeNameSnapshot,
    this.claimedAt,
    this.createdByID,
    required this.createdBy,
    DateTime? createdAt,
    this.completedByID,
    this.completedBy,
    this.completedAt,
    this.revision = 0,
  }) : createdAt = createdAt ?? dueTime;

  final String id;
  final String title;
  final CareCategory category;
  final DateTime dueTime;
  final CareTaskKind kind;
  final CarePriority priority;
  final String? routineID;
  final CareTaskStatus status;
  final AssignmentRequest? assignmentRequest;
  final String? assigneeID;
  final String? assigneeNameSnapshot;
  final DateTime? claimedAt;
  final String? createdByID;
  final String createdBy;
  final DateTime createdAt;
  final String? completedByID;
  final String? completedBy;
  final DateTime? completedAt;
  final int revision;

  CareTask copyWith({
    CareTaskStatus? status,
    AssignmentRequest? assignmentRequest,
    bool clearAssignmentRequest = false,
    String? assigneeID,
    String? assigneeNameSnapshot,
    DateTime? claimedAt,
    String? completedByID,
    String? completedBy,
    DateTime? completedAt,
    int? revision,
  }) {
    return CareTask(
      id: id,
      title: title,
      category: category,
      dueTime: dueTime,
      kind: kind,
      priority: priority,
      routineID: routineID,
      status: status ?? this.status,
      assignmentRequest: clearAssignmentRequest
          ? null
          : (assignmentRequest ?? this.assignmentRequest),
      assigneeID: assigneeID ?? this.assigneeID,
      assigneeNameSnapshot: assigneeNameSnapshot ?? this.assigneeNameSnapshot,
      claimedAt: claimedAt ?? this.claimedAt,
      createdByID: createdByID,
      createdBy: createdBy,
      createdAt: createdAt,
      completedByID: completedByID ?? this.completedByID,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      revision: revision ?? this.revision,
    );
  }

  factory CareTask.fromJson(Map<String, dynamic> json) => CareTask(
        id: json['id'] as String,
        title: json['title'] as String,
        category: CareCategory.fromRaw(json['category'] as String),
        dueTime: _dateFromJson(json['dueTime']) ?? DateTime.now(),
        kind: CareTaskKind.fromRaw(json['kind'] as String? ?? 'oneOff'),
        priority: CarePriority.fromRaw(json['priority'] as String? ?? 'normal'),
        routineID: _stringFromJson(json['routineID']),
        status: CareTaskStatus.fromRaw(json['status'] as String? ?? 'unclaimed'),
        assignmentRequest: json['assignmentRequest'] == null
            ? null
            : AssignmentRequest.fromJson(
                json['assignmentRequest'] as Map<String, dynamic>),
        assigneeID: _stringFromJson(json['assigneeID']),
        assigneeNameSnapshot: _stringFromJson(json['assigneeNameSnapshot']),
        claimedAt: _dateFromJson(json['claimedAt']),
        createdByID: _stringFromJson(json['createdByID']),
        createdBy: json['createdBy'] as String,
        createdAt: _dateFromJson(json['createdAt']),
        completedByID: _stringFromJson(json['completedByID']),
        completedBy: _stringFromJson(json['completedBy']),
        completedAt: _dateFromJson(json['completedAt']),
        revision: _intFromJson(json['revision']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.rawValue,
        'dueTime': _dateToJson(dueTime),
        'kind': kind.rawValue,
        'priority': priority.rawValue,
        'routineID': routineID,
        'status': status.rawValue,
        'assignmentRequest': assignmentRequest?.toJson(),
        'assigneeID': assigneeID,
        'assigneeNameSnapshot': assigneeNameSnapshot,
        'claimedAt': _dateToJson(claimedAt),
        'createdByID': createdByID,
        'createdBy': createdBy,
        'createdAt': _dateToJson(createdAt),
        'completedByID': completedByID,
        'completedBy': completedBy,
        'completedAt': _dateToJson(completedAt),
        'revision': revision,
      };
}

class CareSession {
  const CareSession({required this.household, required this.caregiver});

  final Household household;
  final Caregiver caregiver;
}
