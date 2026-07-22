import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/reports.dart';
import 'package:leavesystem/screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';


// --- EVS Theme Colors ---
const Color primaryColor = Color(0xFF006400);
const Color secondaryColor = Color(0xFF388E3C);
const Color verifiedColor = Color(0xFF4CAF50);
const Color pendingColor = Color(0xFFFFC107);
const Color rejectedColor = Color(0xFFD32F2F);
const Color lightGrey = Color(0xFFF5F5F5);

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  bool isLoading = true;
  List<dynamic> logs = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingLogs();
  }

  // --- Fetch only pending employee requests ---
  Future<void> _fetchPendingLogs() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/home/logs'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allLogs = data['logs'] ?? [];
        final pendingOnly = allLogs
            .where((log) =>
                (log['status'] ?? 'pending').toString().toLowerCase() == 'pending')
            .toList();

        setState(() {
          logs = pendingOnly;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch pending logs');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
    }
  }

  // --- Verify employee ---
  Future<void> verifyLog(String logId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse("http://localhost:5000/api/home/verifylog/$logId"),
        headers: {"Content-Type": "application/json", "token": token},
      );

      String message = "Verification completed";
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        message = data['message'] ?? message;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _fetchPendingLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error verifying log: $e")),
      );
    }
  }

  // --- Helper: Get color for status ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return verifiedColor;
      case 'pending':
        return pendingColor;
      case 'rejected':
        return rejectedColor;
      default:
        return Colors.grey;
    }
  }

  // --- Helper: Format date safely ---
  String _formatCompletedAt(dynamic completedAt) {
    try {
      if (completedAt is Map && completedAt['seconds'] != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(
            completedAt['seconds'] * 1000);
        return '${date.day}/${date.month}/${date.year}';
      } else if (completedAt is String && completedAt.isNotEmpty) {
        final date = DateTime.parse(completedAt);
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {}
    return 'N/A';
  }

  // --- MAIN UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Verifications"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : logs.isEmpty
              ? const Center(
                  child: Text(
                    "No pending verification requests.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final status =
                              (log['status'] ?? 'pending').toString().toLowerCase();
                          final logId = log['logId'] ?? log['uid'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: (log['verificationImageUrl'] != null &&
                                        log['verificationImageUrl'].isNotEmpty)
                                    ? Image.network(
                                        log['verificationImageUrl'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.person_pin,
                                                    size: 60, color: Colors.grey),
                                      )
                                    : const Icon(Icons.person_pin,
                                        size: 60, color: primaryColor),
                              ),
                              title: Text(
                                '${log['name'] ?? ''} ${log['surname'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emp No: ${log['employeeNumber'] ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black87),
                                  ),
                                  Text(
                                    'Completed: ${_formatCompletedAt(log['completedAt'])}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          _getStatusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: (status == 'verified' ||
                                        status == 'rejected' ||
                                        logId.isEmpty)
                                    ? null
                                    : () => verifyLog(logId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (status == 'verified' ||
                                          status == 'rejected')
                                      ? Colors.grey.shade400
                                      : secondaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  minimumSize: const Size(80, 36),
                                  elevation:
                                      status == 'pending' ? 3 : 0, 
                                ),
                                child: Text(
                                  status == 'verified'
                                      ? 'VERIFIED'
                                      : status == 'rejected'
                                          ? 'REJECTED'
                                          : 'VERIFY',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 55.0,
        backgroundColor: Colors.transparent,
        color: primaryColor,
        buttonBackgroundColor: primaryColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 1,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.insert_chart, size: 30, color: Colors.white),
          Icon(Icons.settings, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }
}
