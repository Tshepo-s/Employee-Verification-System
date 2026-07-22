import 'dart:convert';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/admin_profile.dart';
import 'package:leavesystem/screens/employeeScreen.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Admin_More_Screen extends StatefulWidget {
  final String docId;
  final String name;
  final String identityNumber;
  final String personnelNumber;
  final String status;
  final String gender;
  final String department;
  final String contract;
  final dynamic age;
  final String citizenship;
  final String verificationImageUrl;
  final String reason;

  const Admin_More_Screen({
    Key? key,
    required this.docId,
    required this.name,
    required this.identityNumber,
    required this.personnelNumber,
    required this.status,
    required this.gender,
    required this.department,
    required this.contract,
    required this.age,
    required this.citizenship,
    required this.verificationImageUrl,
        required this.reason,

  }) : super(key: key);

  // Define the professional color palette
  static const Color primaryColor = Color(0xFF006400); // Deep Forest Green
  static const Color secondaryColor = Color(0xFF4CAF50); // Light Green Accent
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color verifiedColor = Color(0xFF1B5E20); // Darker Green for status
  static const Color pendingColor = Color(0xFFFF9800); 
  @override
  State<Admin_More_Screen> createState() => _Admin_More_ScreenState();
}

class _Admin_More_ScreenState extends State<Admin_More_Screen> {
 // Orange for pending status
String? _token;
  String? _uid;
    String? _personnel;
    

  String? _currentName;
  String? _currentSURNName;
  String? _photoUrl;
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;
     String?    userName;
          String?    usersurName;
               String?    employeeNo;



  int _page = 0; 

 
   

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoUrl = prefs.getString('photoUrl');
    });
  }

  @override
  void initState() {
    super.initState();
      _loadData();
    _loadProfileImage();
  }
   Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uid = prefs.getString('uid');

    if (token == null || uid == null) {
      setState(() {
        _error = "Not logged in";
        _loading = false;
      });
      return;
    }

    _token = token;
    _uid = uid;

    try {
      final profileRes = await http.get(
        Uri.parse("http://localhost:5000/api/home/profile"),
        headers: {"token": token},
      );

      if (profileRes.statusCode == 200) {
        final profile = jsonDecode(profileRes.body);
        setState(() {
          _currentName = profile['FirstName'] ?? profile['EmailAddress'] ?? "Unknown";
          _currentSURNName = profile['Surname'] ?? profile['EmailAddress'] ?? "Unknown";
                     _personnel = profile['PersonnelNumber'] ?? profile['EmailAddress'] ?? "Unknown";

          _photoUrl = profile['ProfileImageUrl']?.toString();
                    userName = profile['FirstName'] ?? profile['EmailAddress'] ?? "Unknown";
                              usersurName = profile['Surname'] ?? profile['EmailAddress'] ?? "Unknown";
                                                     employeeNo = profile['PersonnelNumber'] ?? profile['EmailAddress'] ?? "Unknown";


        });
        await prefs.setString('photoUrl', _photoUrl ?? '');
        await prefs.setString('FirstName',userName ?? '');
        await prefs.setString('Surname',usersurName ?? '');
        await prefs.setString('PersonnelNumber',employeeNo ?? '');




      }

      final logsRes = await http.get(
        Uri.parse("http://localhost:5000/api/home/logs"),
        headers: {"token": token},
      );

      if (logsRes.statusCode == 200) {
        final body = jsonDecode(logsRes.body);
        final allLogs = (body['logs'] is List) ? body['logs'] : [];

        final userLogs = allLogs.where((log) {
          final logUid = log['uid']?.toString();
          return logUid == _uid;
        }).toList();

        setState(() {
          _logs = userLogs;
        });
      } else if (logsRes.statusCode == 401) {
        setState(() {
          _error = "Unauthorized. Please log in again.";
        });
      } else {
        setState(() {
          _error = "Failed to load logs (${logsRes.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error loading data: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green.shade700;
    
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }


  Widget _buildProfessionalDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                "${_currentName ?? 'Employee'} ${_currentSURNName ?? 'Name'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                _personnel ?? 'ID: N/A',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: kPrimaryGreen, size: 40),
                        )
                      : const Icon(Icons.person, color: kPrimaryGreen, size: 40),
                ),
              ),
              decoration: const BoxDecoration(
                color: kPrimaryGreen,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person_outline, color: kPrimaryGreen),
              title: const Text('My Profile', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen_Admin()));
              },
            ),

           

            const Divider(color: Colors.black12, height: 30),

            // Logout (Example of a separate action)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
             onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
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

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Logged out successfully")),
  );
}


  // UI Helper to build a clean detail row
  Widget _buildDetailRow(String label, String value, {bool isID = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: isID ? Admin_More_Screen.lightGrey : Colors.white, // Highlight sensitive/unique rows
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isID ? FontWeight.w500 : FontWeight.normal,
                color: isID ? Admin_More_Screen.primaryColor : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Helper to build a Section Header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Admin_More_Screen.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Admin_More_Screen.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Original helper function - re-styled for professional use
  Widget _buildRow(String label, String value) {
    // This is the implementation for the original `_buildRow` helper.
    // To integrate with the new design, I'll call the new helper `_buildDetailRow`.
    // The original flex ratio is 2:3, which is 40%:60% (close to 5:5 or 50:50).
    return _buildDetailRow(label, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Details"),
        backgroundColor: Admin_More_Screen.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
            endDrawer: _buildProfessionalDrawer(context),

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Profile Image and Name Section
          Center(
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Admin_More_Screen.primaryColor, width: 4),
                    color: Admin_More_Screen.lightGrey,
                  ),
                  child: ClipOval(
                    child: widget.verificationImageUrl.isNotEmpty
                        ? Image.network(
                            widget.verificationImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 80, color: Colors.grey),
                          )
                        : const Icon(Icons.person, size: 80, color: Admin_More_Screen.secondaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(widget.status), width: 1),
                  ),
                  child: Text(
                    'STATUS: ${widget.status.toUpperCase()}',
                    style: TextStyle(
                      color: _getStatusColor(widget.status),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 2. Personal Information Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Personal Information", Icons.badge),
                _buildDetailRow("Gender", widget.gender),
                _buildDetailRow("Age", widget.age.toString()),
                _buildDetailRow("Citizenship", widget.citizenship),
                _buildDetailRow("ID Number", widget.identityNumber, isID: true),

                // The original method call is preserved, using the new internal implementation
                _buildRow("Full Name", widget.name),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Employment Details Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Employment Details", Icons.business_center),
                _buildDetailRow("Personnel Number", widget.personnelNumber, isID: true),
                _buildDetailRow("Department", widget.department),
                _buildDetailRow("Contract Type", widget.contract),
                // The original method call is preserved, using the new internal implementation
                _buildRow("Document ID", widget.docId),
                                _buildDetailRow("Reason", widget.reason),

              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent,
        color: Color(0xFF006400),
        buttonBackgroundColor: Color(0xFF006400),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, // Set index to 1 to signify this is the Analytics screen
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), 
          Icon(Icons.people, size: 30, color: Colors.white), // Current Screen
        ],
        onTap: (index) {
            if (index == 0) { // Index 1 is the Analytics icon
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardScreen(),
              ),
            );
          } else {
 Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmployeesScreen(),
              ),
            );          }
        },
      ),
    );
  }
}