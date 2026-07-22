import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String firstName;
  final String surname;
  final String emailAddress;
  final String personnelNumber;
  final String status;
  final DateTime submissionDate;      // New field
  final String inquiry;               // Optional field if needed
  final String profileImageUrl;       // Optional profile picture

  Employee({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.emailAddress,
    required this.personnelNumber,
    required this.status,
    required this.submissionDate,
    this.inquiry = '',
    this.profileImageUrl = '',
  });

  factory Employee.fromDocumentSnapshot(String id, Map<String, dynamic> data) {
    return Employee(
      id: data['idNumber'] ?? '',
      firstName: data['name'] ?? '',
      surname: data['surname'] ?? '',
      emailAddress: data['email'] ?? '',
      personnelNumber: data['employeeNumber'] ?? '',
      status: data['status'] ?? '',
      submissionDate: (data['completedAt'] != null)
          ? (data['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
      inquiry: data['inquiry'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['idNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      surname: json['surname'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      personnelNumber: json['employeeNumber'] ?? '',
      status: json['status'] ?? '',
      submissionDate: DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      inquiry: json['inquiry'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idNumber': id,
      'firstName': firstName,
      'surname': surname,
      'emailAddress': emailAddress,
      'employeeNumber': personnelNumber,
      'status': status,
      'submissionDate': submissionDate.toIso8601String(),
      'inquiry': inquiry,
      'profileImageUrl': profileImageUrl,
    };
  }
}
