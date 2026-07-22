import 'package:flutter/material.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'users_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:leavesystem/screens/auditor_anatalystics.dart';
import 'package:leavesystem/screens/auditor_employees_screen.dart';

const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccent = Color(0xFF4CAF50); // Using kAccent for consistency



class UserDetailScreen extends StatelessWidget {
  final User user;
  const UserDetailScreen({super.key, required this.user});

  void _handleCurvedNavTap(BuildContext context, int index) {
    if (index == 0) { 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuditorEmployeesScreen()),
      );
    } else if (index == 1) { 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuditAnalyticsScreen()),
      );
    }
  }

  void _handleAppBarAction(String action, BuildContext context) {
    if (action == 'employees') {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuditorEmployeesScreen()),
      );
    } else if (action == 'users') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsersScreen()),
      );
    } else if (action == 'logout') {
      print('Logout Action');
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kPrimaryGreen)),
            ),
            Expanded(
              flex: 5,
              child: Text(value, style: const TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        // --- CONSISTENT APPBAR ACTIONS ---
        actions: [
          IconButton(
            icon: const Icon(Icons.people, semanticLabel: 'Employees'),
            onPressed: () => _handleAppBarAction('employees', context),
            tooltip: 'Employees (Home)',
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () => _handleAppBarAction('users', context),
            tooltip: 'Users',
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
 onPressed: () {             _logout(context);
},            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: kLightGreen,
              backgroundImage: user.profileImageUrl.isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
              child: user.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: kPrimaryGreen, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              '${user.firstName} ${user.surname}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryGreen),
            ),
            const SizedBox(height: 8),
            Text(user.emailAddress,
                style: const TextStyle(color: Colors.black54, fontSize: 15)),
            const Divider(height: 30, thickness: 1),
            _row('Department', user.department),
            _row('Contract', user.contract),
            _row('Personnel No.', user.personnelNumber),
            _row('Gender', user.gender),
            _row('POPIA Consent', user.popiaConsent),
            _row('Is Admin', user.isAdmin ? 'Yes' : 'No'),
            _row('Is Auditor', user.isAuditor ? 'Yes' : 'No'),
            _row('Created At', user.createdAt?.toLocal().toString() ?? 'Unknown'),
          ],
        ),
      ),
      // --- CONSISTENT CURVED NAVIGATION BAR ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, 
        color: kPrimaryGreen,
        buttonBackgroundColor: kPrimaryGreen,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, // Assuming Home/Employees is index 0
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), // Home/Employees
          Icon(Icons.analytics, size: 30, color: Colors.white), // Analytics
        ],
        onTap: (index) => _handleCurvedNavTap(context, index),
      ),
      // --- END CURVED NAVIGATION BAR ---
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