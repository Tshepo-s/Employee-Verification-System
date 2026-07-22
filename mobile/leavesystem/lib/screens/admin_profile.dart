import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/employeeScreen.dart';
import 'package:leavesystem/screens/home_screen.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';


const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccentColor = Color(0xFF4CAF50);

Widget buildProfessionalDrawer(
  BuildContext context,
  String? name,
  String? surname,
  String? personnel,
  String? photoUrl,
) {
  final displayName =
      "${name ?? ''} ${surname ?? ''}".trim().isEmpty ? "Employee Name" : "${name ?? ''} ${surname ?? ''}";
  final displayId = personnel ?? 'ID: N/A';
  final displayPhotoUrl = photoUrl ?? '';

  void navigateToProfile() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Profile_Screen_Admin()),
    );
  }

  void handleLogout() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out... (Placeholder)')),
    );
  }

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(displayId, style: const TextStyle(color: Colors.white70)),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: (displayPhotoUrl.isNotEmpty)
                  ? Image.network(
                      displayPhotoUrl,
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: kPrimaryGreen, size: 40),
                    )
                  : const Icon(Icons.person, color: kPrimaryGreen, size: 40),
            ),
          ),
          decoration: const BoxDecoration(color: kPrimaryGreen),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline, color: kPrimaryGreen),
          title: const Text('My Profile', style: TextStyle(fontSize: 16)),
          onTap: navigateToProfile,
        ),
         Divider(color: Colors.black12, height: 30),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
  onTap: () => _logout(context),
        ),
      ],
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

class Profile_Screen_Admin extends StatefulWidget {
  const Profile_Screen_Admin({Key? key}) : super(key: key);
  @override
  State<Profile_Screen_Admin> createState() => _Profile_Screen_AdminState();
}

class _Profile_Screen_AdminState extends State<Profile_Screen_Admin> {
  String? _token;
  String? _uid;
  String? _photoUrl;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _department;
  String? _gender;
  String? _contract;
  bool _loading = true;
  String? _error;
    int _page = 0; // State variable for CurvedNavigationBar

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uid = prefs.getString('uid');

    if (token == null || uid == null) {
      setState(() {
        _error = "Not logged in. Please restart the app.";
        _loading = false;
      });
      return;
    }

    _token = token;

    try {
      final res = await http.get(
        Uri.parse("http://localhost:5000/api/home/profile"),
        headers: {"token": token},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _photoUrl = data['ProfileImageUrl'];
          _firstName = data['FirstName'];
          _lastName = data['Surname'];
          _email = data['EmailAddress'];
          _department = data['Department'] ?? 'N/A';
          _uid = data['PersonnelNumber'] ?? 'N/A';
          _gender = data['Gender'] ?? 'N/A';
          _contract = data['Contract'] ?? 'N/A';
        });
        await prefs.setString('photoUrl', _photoUrl ?? '');
      } else if (res.statusCode == 401) {
        setState(() => _error = "Unauthorized. Please log in again.");
      } else {
        setState(() => _error = "Failed to load profile (${res.statusCode})");
      }
    } catch (e) {
      setState(() => _error = "Error loading profile: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadProfile();
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kLightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForLabel(label), color: kPrimaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Gender":
        return Icons.person_outline;
      case "Employee ID":
        return Icons.badge_outlined;
      case "Department":
        return Icons.business_outlined;
      case "Contract":
        return Icons.work_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: kPrimaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        endDrawer: buildProfessionalDrawer(context, _firstName, _lastName, _uid, _photoUrl),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 72),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _refreshProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kPrimaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      endDrawer: buildProfessionalDrawer(context, _firstName, _lastName, _uid, _photoUrl),
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: kAccentColor.withOpacity(0.2),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                          ? NetworkImage(_photoUrl!)
                          : const AssetImage("images/default_profile.png") as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {
                        setState(() => _photoUrl = null);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "${_firstName ?? ''} ${_lastName ?? ''}".trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _email ?? 'Email N/A',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                "Personal Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen,
                ),
              ),
            ),
            _buildInfoRow("Employee ID", _uid ?? 'N/A'),
            _buildInfoRow("Department", _department ?? 'N/A'),
            _buildInfoRow("Gender", _gender ?? 'N/A'),
            _buildInfoRow("Contract", _contract ?? 'N/A'),
          ],
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
