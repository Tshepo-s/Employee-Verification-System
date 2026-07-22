import 'dart:convert';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/screens/admin_profile.dart';
import 'package:leavesystem/screens/employeeScreen.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

// --- DEFINED COLORS ---
const Color primaryColor = Color(0xFF006400); // Dark Green
// Assuming lightGrey is a very light background color from your original context
const Color lightGrey = Color(0xFFE0E0E0); 
const Color accentHighlightColor = Colors.orangeAccent; // A warm contrast for highlighting

class EmployeeDetailsScreen extends StatefulWidget {
  final Employees employee;
  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  

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

            // Help Tile
            ListTile(
              leading: const Icon(Icons.help_outline, color: kPrimaryGreen),
              title: const Text('Help & Support', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add help navigation logic
              },
            ),

            // About Us Tile
            ListTile(
              leading: const Icon(Icons.info_outline, color: kPrimaryGreen),
              title: const Text('About Us', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add about us navigation logic
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


  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        // Retaining your original lightGrey color for the row background
        color: lightGrey.withOpacity(0.5), // Slightly transparent for depth
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor, // Using the new Dark Green
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              textAlign: TextAlign.end,
              style: TextStyle(
                // Using an accent color for a professional warning/highlight
                color: highlight ? accentHighlightColor : Colors.black87,
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
        backgroundColor: primaryColor, // Using the new Dark Green
        foregroundColor: Colors.white,
        elevation: 0, 
      ),
                  endDrawer: _buildProfessionalDrawer(context),

      body: SingleChildScrollView(
        // Overall background color is a subtle off-white for contrast
        child: Container(
          color: Colors.white, 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Header ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Prominent border with the new primary color
                    border: Border.all(color: primaryColor, width: 4), 
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 70, // Slightly larger avatar
                    backgroundColor: Colors.white,
                    backgroundImage: widget.employee.profileImageUrl.isNotEmpty
                        ? NetworkImage(widget.employee.profileImageUrl)
                        : null,
                    child: widget.employee.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 70, color: primaryColor) // Icon uses primary color
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Name and Email
              Center(
                child: Text(
                  '${widget.employee.firstName} ${widget.employee.surname}',
                  style: const TextStyle(
                    fontSize: 30, // Large and prominent
                    fontWeight: FontWeight.w900,
                    color: primaryColor, // New Dark Green
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.employee.emailAddress,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 35),
              
              // --- Details Section Title ---
              const Text(
                'Employment Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor, // New Dark Green
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                // Solid, distinct divider
                child: Divider(thickness: 2, color: primaryColor), 
              ),
              
              // --- Details Rows ---
              _buildDetailRow("Employee Number", widget.employee.employeeNumber),
              _buildDetailRow("Department", widget.employee.department),
              _buildDetailRow("Contract", widget.employee.contract),
              _buildDetailRow("Gender", widget.employee.gender),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent,
        color: Color(0xFF006400),
        buttonBackgroundColor: Color(0xFF006400),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 1, // Set index to 1 to signify this is the Analytics screen
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