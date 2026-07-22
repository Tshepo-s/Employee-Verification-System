import 'dart:convert';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/help_support_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {

   String? _token;
  String? _uid;
    String? _personnel;
     int _page = 0;
 

  String? _currentName;
  String? _currentSURNName;
  String? _photoUrl;
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;
     String?    userName;
          String?    usersurName;
               String?    employeeNo;




  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfileImage();
  }
   

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoUrl = prefs.getString('photoUrl');
    });
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

      
  }
        catch(e){
          print("");
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
  // 🌐 Optional: open developer website or social link



  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Logged out successfully")),
  );
}
  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
       
        
      ),
            endDrawer: _buildProfessionalDrawer(context),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            CircleAvatar(
              radius: 50,
              backgroundColor: kPrimaryGreen.withOpacity(0.1),
              child: const Icon(Icons.verified_user, size: 60, color: kPrimaryGreen),
            ),
            const SizedBox(height: 20),

            // App Name and Version
            const Text(
              "Employee Verification System",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Mission
            const Text(
              "Our mission is to simplify and secure employee verification processes. "
              "With real-time validation, role-based access, and seamless data handling, "
              "we ensure efficient workforce management for modern organizations.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.2, color: Colors.black12),
            const SizedBox(height: 16),

            // Developer Info
            const Text(
              "Developed by:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "SoftwareDevs — Welkom Campus\nInformation Technology (3rd Year)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),

            const SizedBox(height: 24),

            // Optional links section
            ElevatedButton.icon(
              onPressed: _launchWebsite,
              icon: const Icon(Icons.link),
              label: const Text("Visit Our Website"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            const Text(
              "© 2025 Employee Verification System\nAll Rights Reserved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
         bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        index: 0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: kPrimaryGreen,
        buttonBackgroundColor: kPrimaryGreen,
        backgroundColor: Colors.transparent, 
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _page = index;
          });
          if (index == 1) { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
          }
        },
        letIndexChange: (index) => true,
      ),
      
    );
  }
}

  @override
  Widget build(BuildContext context) {
     const kPrimaryGreen = Color(0xFF006400);
   return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,

        
      ),
                  endDrawer: _buildProfessionalDrawer(context),

      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            CircleAvatar(
              radius: 50,
              backgroundColor: kPrimaryGreen.withOpacity(0.1),
              child: const Icon(Icons.verified_user, size: 60, color: kPrimaryGreen),
            ),
            const SizedBox(height: 20),

            // App Name and Version
            const Text(
              "Employee Verification System",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Mission
            const Text(
              "Our mission is to simplify and secure employee verification processes. "
              "With real-time validation, role-based access, and seamless data handling, "
              "we ensure efficient workforce management for modern organizations.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.2, color: Colors.black12),
            const SizedBox(height: 16),

            // Developer Info
            const Text(
              "Developed by:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "SoftwareDevs — Welkom Campus\nInformation Technology (3rd Year)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),

            const SizedBox(height: 24),

            // Optional links section
            ElevatedButton.icon(
              onPressed: _launchWebsite,
              icon: const Icon(Icons.link),
              label: const Text("Visit Our Website"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            const Text(
              "© 2025 Employee Verification System\nAll Rights Reserved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
         bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        index: 0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: kPrimaryGreen,
        buttonBackgroundColor: kPrimaryGreen,
        backgroundColor: Colors.transparent, 
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _page = index;
          });
          if (index == 1) { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
          }
        },
        letIndexChange: (index) => true,
      ),
      
    );
  

  
}
  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse("https://localhost:44309/"); 
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
              },
            ),
             ListTile(
  leading: const Icon(Icons.help_outline, color: kPrimaryGreen),
  title: const Text('Help & Support', style: TextStyle(fontSize: 16)),
  onTap: () {
    Navigator.pop(context); // ✅ Close the drawer first
    Future.delayed(const Duration(milliseconds: 150), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HelpSupportScreen(),
        ),
      );
    });
  },
),
              ListTile(
  leading: const Icon(Icons.info_outline, color: kPrimaryGreen),
  title: const Text('About Us', style: TextStyle(fontSize: 16)),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutUsScreen()),
    );
  },
),



            const Divider(color: Colors.black12, height: 30),

            // Logout (Example of a separate action)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
             onTap: () async {
              final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // clears token, uid, email/password, etc.

  // Navigate back to login and remove all previous routes
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
             },
            ),
          ],
        ),
      ),
    );
   }
}