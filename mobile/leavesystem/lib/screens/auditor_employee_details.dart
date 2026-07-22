import 'package:flutter/material.dart';
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/screens/employeeScreen.dart'; 
// --- NEW IMPORTS (Required for Navigation Bar and Screens) ---
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; 
// Assuming the Auditor screens are located here (from your source code context)
import 'package:leavesystem/screens/auditor_anatalystics.dart'; 
import 'package:leavesystem/screens/auditor_home_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
// Assuming there's a screen for Audit Logs, I'll define a placeholder based on context


// --- DEFINED COLORS (Copied from Source Code) ---
const Color primaryColor = Color(0xFF006400); // Dark Green
const Color secondaryColor = Color(0xFF388E3C); // Darker Green (Added for consistency)
const Color lightGrey = Color(0xFFE0E0E0); // Background for cards/elements
const Color accentColor = Color(0xFF4CAF50); // Accent for Curved Nav Button (Added for consistency)
const Color accentHighlightColor = Colors.orangeAccent; // A warm contrast for highlighting


class AuditormployeeDetailsScreen extends StatelessWidget {
  final Employees employee;
  const AuditormployeeDetailsScreen({super.key, required this.employee});

  // --- Function to handle AppBar Navigation (for consistency, must be static/local) ---
  void _handleAppBarAction(BuildContext context, String action) {
    if (action == 'audit_logs') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
      );
    } else if (action == 'users') {
      // Placeholder for Users Screen Navigation (as in source code)
      print('Navigate to Users (Placeholder)');
    } else if (action == 'logout') {
      // Placeholder for Logout Logic (as in source code)
      print('Logout Action (Placeholder)');
    }
  }

  // --- Function to handle Curved Nav Bar Navigation (for consistency) ---
  void _handleCurvedNavTap(BuildContext context, int index) {
    // Assuming the bottom nav bar maps to: Home (index 0), Analytics (index 1), Settings (index 2)
    if (index == 0) { // Home/Audit Logs from your previous context
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
      );
    } else if (index == 1) { // Analytics
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuditAnalyticsScreen()),
      );
    } else if (index == 2) { // Settings/Placeholder
      print('Navigate to Settings (Placeholder)');
      // Implement navigation to Settings or other screen if needed
    }
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
      // --- APPBAR WITH ACTIONS (Copied from Source Code) ---
      appBar: AppBar(
        title: const Text('Employee Details'),
        backgroundColor: primaryColor, // Using the new Dark Green
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // The actions are now callable via the context
          IconButton(
            icon: const Icon(Icons.book, semanticLabel: 'Audit Logs'),
            onPressed: () => _handleAppBarAction(context, 'audit_logs'),
            tooltip: 'Audit Logs',
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () => _handleAppBarAction(context, 'users'),
            tooltip: 'Users',
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            onPressed: () { _logout(context);}
,
            tooltip: 'Logout',
          ),
        ],
      ),
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
                    backgroundImage: employee.profileImageUrl.isNotEmpty
                        ? NetworkImage(employee.profileImageUrl)
                        : null,
                    child: employee.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 70, color: primaryColor) // Icon uses primary color
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Name and Email
              Center(
                child: Text(
                  '${employee.firstName} ${employee.surname}',
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
                  employee.emailAddress,
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
              _buildDetailRow("Employee Number", employee.employeeNumber),
              _buildDetailRow("Department", employee.department),
              _buildDetailRow("Contract", employee.contract),
              _buildDetailRow("Gender", employee.gender),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // --- CURVED NAVIGATION BAR (Copied from Source Code) ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, // Transparent background to show Scaffold's color
        color: primaryColor,
        buttonBackgroundColor: primaryColor, // Used primaryColor as you defined in the source's bottomNavbar properties
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, // Assuming Audit Logs is the default/main page
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), // Audit Log 
          Icon(Icons.analytics, size: 30, color: Colors.white), // Analytics
        ],
        onTap: (index) => _handleCurvedNavTap(context, index),
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