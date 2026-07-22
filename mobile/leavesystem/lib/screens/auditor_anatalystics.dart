import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/auditor_employees_screen.dart';
import 'package:leavesystem/screens/auditor_home_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; // REQUIRED IMPORT

const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccent = Color(0xFF4CAF50);
const Color kSuccessColor = Colors.green;
const Color kFailureColor = Colors.redAccent;

// --- AuditLog Model (Re-included for completeness) ---
class AuditLog {
  final String verifierFirstName;
  final String verifierSurname;
  final String verifierEmail;
  final String verifierPersonnelNumber;
  final String verifierDepartment;
  final String verifierProfileImageUrl;
  final String department;
  final String idNumber;
  final String logId;
  final String reason;
  final String result;
  final double similarity;
  final DateTime timestamp;

  AuditLog({
    required this.verifierFirstName,
    required this.verifierSurname,
    required this.verifierEmail,
    required this.verifierPersonnelNumber,
    required this.verifierDepartment,
    required this.verifierProfileImageUrl,
    required this.department,
    required this.idNumber,
    required this.logId,
    required this.reason,
    required this.result,
    required this.similarity,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map && v.containsKey('stringValue')) return v['stringValue'];
      return v.toString();
    }

    double _asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return AuditLog(
      verifierFirstName: _asString(json['VerifierFirstName']),
      verifierSurname: _asString(json['VerifierSurname']),
      verifierEmail: _asString(json['VerifierEmail']),
      verifierPersonnelNumber: _asString(json['VerifierPersonnelNumber']),
      verifierDepartment: _asString(json['VerifierDepartment']),
      verifierProfileImageUrl: _asString(json['VerifierProfileImageUrl']),
      department: _asString(json['department']),
      idNumber: _asString(json['idNumber']),
      logId: _asString(json['logId']),
      reason: _asString(json['reason']),
      result: _asString(json['result']),
      similarity: _asDouble(json['similarity']),
      timestamp: DateTime.tryParse(_asString(json['timestamp'])) ?? DateTime.now(),
    );
  }
}

// --- Data Fetching Function (UNCHANGED) ---
Future<List<AuditLog>> _fetchAuditLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Missing token');

    final res = await http.get(
      Uri.parse('http://localhost:5000/api/home/auditlogs'),
      headers: {'token': token},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load logs (${res.statusCode})');
    }

    final jsonBody = jsonDecode(res.body);
    final logs = jsonBody['logs'] as List<dynamic>? ?? [];
    return logs.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
}


// --- AuditAnalyticsScreen ---
class AuditAnalyticsScreen extends StatefulWidget {
  const AuditAnalyticsScreen({super.key});

  @override
  State<AuditAnalyticsScreen> createState() => _AuditAnalyticsScreenState();
}

class _AuditAnalyticsScreenState extends State<AuditAnalyticsScreen> {
  late Future<List<AuditLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchAuditLogs();
  }

  // Helper function to calculate and structure analytics data
  Map<String, dynamic> _getAnalyticsData(List<AuditLog> logs) {
    final totalLogs = logs.length;
    int verifiedCount = 0;
    int failedCount = 0;
    final Map<String, int> deptCounts = {};
    final Map<String, int> verifierDeptCounts = {};

    for (var log in logs) {
      if (log.result.toLowerCase() == 'verified') {
        verifiedCount++;
      } else {
        failedCount++;
      }

      deptCounts.update(log.department, (value) => value + 1, ifAbsent: () => 1);
      verifierDeptCounts.update(log.verifierDepartment, (value) => value + 1, ifAbsent: () => 1);
    }

    final verificationRate = totalLogs > 0 ? (verifiedCount / totalLogs) * 100 : 0.0;
    
    // Sort departments by count (Top 3)
    final sortedDepts = deptCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedVerifierDepts = verifierDeptCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalLogs': totalLogs,
      'verifiedCount': verifiedCount,
      'failedCount': failedCount,
      'verificationRate': verificationRate,
      'topVerifiedDepts': sortedDepts.take(3).toList(),
      'topVerifierDepts': sortedVerifierDepts.take(3).toList(),
    };
  }

  // Card Widget for quick statistics
  Widget _buildStatCard({required String title, required String value, required Color color, required IconData icon}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartPlaceholder(int verified, int failed) {
    final total = verified + failed;
    if (total == 0) {
      return const Center(child: Text("No data available."));
    }
    
    final successRatio = verified / total;
    final failureRatio = failed / total;
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: kLightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text('Verification Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryGreen)),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: successRatio,
                  backgroundColor: kFailureColor.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(kSuccessColor),
                  strokeWidth: 15,
                ),
              ),
              Text(
                '${(successRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: kSuccessColor, size: 16),
              const SizedBox(width: 4),
              Text('Verified: ${verified} (${(successRatio * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 15),
              Icon(Icons.cancel, color: kFailureColor, size: 16),
              const SizedBox(width: 4),
              Text('Failed: ${failed} (${(failureRatio * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APPBAR (Same actions as AuditLogScreen) ---
      appBar: AppBar(
        title: const Text('Audit Analytics'),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, semanticLabel: 'Employees'),
            onPressed: () {
               Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditorEmployeesScreen(),
              ),
            );
            } ,
            tooltip: 'Employees',
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () {
               Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UsersScreen()),
      );
            },
            tooltip: 'Users',
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            onPressed: (){ _logout(context);},
            tooltip: 'Logout',
          ),
        ],
      ),
      // --- BODY CONTENT ---
      body: FutureBuilder<List<AuditLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: kFailureColor)));
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs available for analysis.', style: TextStyle(color: Colors.grey)));
          }

          final analytics = _getAnalyticsData(logs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Key Statistics
                const Text(
                  'Key Performance Indicators',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildStatCard(
                      title: 'Total Logs',
                      value: analytics['totalLogs'].toString(),
                      color: kPrimaryGreen,
                      icon: Icons.list_alt,
                    ),
                    _buildStatCard(
                      title: 'Verification Rate',
                      value: '${analytics['verificationRate'].toStringAsFixed(1)}%',
                      color: analytics['verificationRate'] >= 80 ? kSuccessColor : kFailureColor,
                      icon: Icons.speed,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // 2. Verification Breakdown (Pie Chart Placeholder)
                _buildPieChartPlaceholder(analytics['verifiedCount'], analytics['failedCount']),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // 3. Top Departments Analysed
                const Text(
                  'Top 3 Departments Verified',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                ),
                const SizedBox(height: 10),
                ...analytics['topVerifiedDepts'].map<Widget>((entry) => ListTile(
                  leading: const Icon(Icons.business, color: kAccent),
                  title: Text(entry.key),
                  trailing: Chip(label: Text('${entry.value} logs')),
                )).toList(),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // 4. Top Verifier Departments
                const Text(
                  'Top 3 Verifying Departments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                ),
                const SizedBox(height: 10),
                ...analytics['topVerifierDepts'].map<Widget>((entry) => ListTile(
                  leading: const Icon(Icons.security, color: kAccent),
                  title: Text(entry.key),
                  trailing: Chip(label: Text('${entry.value} logs')),
                )).toList(),
              ],
            ),
          );
        },
      ),
      // --- CURVED NAVIGATION BAR ADDED ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent,
        color: kPrimaryGreen,
        buttonBackgroundColor: Color(0xFF006400),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 1, // Set index to 1 to signify this is the Analytics screen
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), 
          Icon(Icons.analytics, size: 30, color: Colors.white), // Current Screen
        ],
        onTap: (index) {
            if (index == 0) { // Index 1 is the Analytics icon
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditLogsScreen(),
              ),
            );
          } else {
            print('Curved Bar Tapped Index: $index');
          }
        },
      ),
    );
  }
}
 Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // clears token, uid, email/password, etc.

  // Navigate back to login and remove all previous routes
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
 }