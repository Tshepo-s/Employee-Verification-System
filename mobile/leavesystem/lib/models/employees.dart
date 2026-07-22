class Employees {
  final String uid;
  final String firstName;
  final String surname;
  final String emailAddress;
  final String department;
  final String contract;
  final String status;
  final bool isAdmin;
  final bool isAuditor;
  final String gender;
  final String popiaConsent;
  final String profileImageUrl;
  final String employeeNumber;
  final DateTime? createdAt;

  Employees({
    required this.uid,
    required this.firstName,
    required this.surname,
    required this.emailAddress,
    required this.department,
    required this.contract,
    required this.status,
    required this.isAdmin,
    required this.isAuditor,
    required this.gender,
    required this.popiaConsent,
    required this.profileImageUrl,
    required this.employeeNumber,
    this.createdAt,
  });

  factory Employees.fromJson(Map<String, dynamic> json) {
    return Employees(
      uid: json['uid'] ?? '',
      firstName: json['firstName'] ?? '',
      surname: json['surname'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      department: json['department'] ?? '',
      contract: json['contract'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isAuditor: json['isAuditor'] ?? false,
      gender: json['gender'] ?? '',
      popiaConsent: json['popiaConsent'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      status: json['status'] ?? 'Pending', 
      employeeNumber: json['employeeNumber'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}