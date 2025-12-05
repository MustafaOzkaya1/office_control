enum AttendanceType { entry, exit }

class AttendanceRecord {
  final String id;
  final String userId;
  final AttendanceType type;
  final DateTime timestamp;
  final String location;
  final String? doorId;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.location,
    this.doorId,
  });

  bool get isEntry => type == AttendanceType.entry;
  bool get isExit => type == AttendanceType.exit;

  String get typeLabel => isEntry ? 'Giriş' : 'Çıkış';
  String get typeIcon => isEntry ? 'login' : 'logout';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'doorId': doorId,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: AttendanceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AttendanceType.entry,
      ),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      location: map['location'] ?? '',
      doorId: map['doorId'],
    );
  }
}

class DailyAttendance {
  final String date;
  final String userId;
  final List<AttendanceRecord> records;
  final int? totalMinutesWorked;

  DailyAttendance({
    required this.date,
    required this.userId,
    required this.records,
    this.totalMinutesWorked,
  });

  AttendanceRecord? get firstEntry {
    final entries = records.where((r) => r.isEntry).toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries.first;
  }

  AttendanceRecord? get lastExit {
    final exits = records.where((r) => r.isExit).toList();
    if (exits.isEmpty) return null;
    exits.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return exits.first;
  }

  AttendanceRecord? get latestActivity {
    if (records.isEmpty) return null;
    final sorted = List<AttendanceRecord>.from(records);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.first;
  }

  String get formattedTotalTime {
    if (totalMinutesWorked == null) return '-';
    final hours = totalMinutesWorked! ~/ 60;
    final mins = totalMinutesWorked! % 60;
    return '${hours}h ${mins}m';
  }

  int calculateTotalMinutes() {
    if (records.isEmpty) return 0;

    final sortedRecords = List<AttendanceRecord>.from(records);
    sortedRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int totalMinutes = 0;
    DateTime? lastEntry;

    for (final record in sortedRecords) {
      if (record.isEntry) {
        lastEntry = record.timestamp;
      } else if (record.isExit && lastEntry != null) {
        totalMinutes += record.timestamp.difference(lastEntry).inMinutes;
        lastEntry = null;
      }
    }

    return totalMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'userId': userId,
      'records': records.map((r) => r.toMap()).toList(),
      'totalMinutesWorked': totalMinutesWorked ?? calculateTotalMinutes(),
    };
  }

  factory DailyAttendance.fromMap(Map<String, dynamic> map) {
    final recordsList =
        (map['records'] as Map<dynamic, dynamic>?)?.values
            .map((r) => AttendanceRecord.fromMap(Map<String, dynamic>.from(r)))
            .toList() ??
        [];

    return DailyAttendance(
      date: map['date'] ?? '',
      userId: map['userId'] ?? '',
      records: recordsList,
      totalMinutesWorked: map['totalMinutesWorked'],
    );
  }
}
