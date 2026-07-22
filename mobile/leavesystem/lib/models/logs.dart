class Log {
  String docId;
  String studentId;
  String studentName;
  String date;
  String time;
  String description;
  String status;
  String? verifiedByName;
  String? verifiedByRole;
  String? department; // Added for reports
  String? location;   // Added for reports

  Log({
    this.docId = '',
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.time,
    required this.description,
    this.status = 'pending',
    this.verifiedByName,
    this.verifiedByRole,
    this.department,
    this.location,
  });

  /// Factory to create a Log from JSON
  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      docId: json['docId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      verifiedByName: json['verifiedByName'],
      verifiedByRole: json['verifiedByRole'],
      department: json['department'], // optional
      location: json['location'],     // optional
    );
  }

  /// Convert Log to JSON (optional, useful for saving/updating)
  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'time': time,
      'description': description,
      'status': status,
      'verifiedByName': verifiedByName,
      'verifiedByRole': verifiedByRole,
      'department': department,
      'location': location,
    };
  }
}
