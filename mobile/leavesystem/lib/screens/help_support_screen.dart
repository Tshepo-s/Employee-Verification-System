import 'dart:convert';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/about_us.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {

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
  // 📧 Email launcher

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
                endDrawer: _buildProfessionalDrawer(context),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Assistance?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'If you’re facing any issues with the Employee Verification App, try the steps below or contact our support team:',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // 💡 Troubleshooting Tips
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Common Fixes:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006400)),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Check your internet connection'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orangeAccent),
                        SizedBox(width: 10),
                        Text('Ensure your credentials are correct'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Restart the app if needed'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Contact Support:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006400)),
            ),
            const SizedBox(height: 12),

            // 📧 Email Button
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('support@employeeapp.com'),
              onTap: _launchEmail,
            ),

            // 💬 WhatsApp Button
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Chat on WhatsApp'),
              onTap: _launchWhatsApp,
            ),

            // ☎️ Call Button
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.teal),
              title: const Text('+27 11 123 4567'),
              onTap: _launchPhone,
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
        title: const Text("Help & Support"),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
                endDrawer: _buildProfessionalDrawer(context),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Assistance?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'If you’re facing any issues with the Employee Verification App, try the steps below or contact our support team:',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // 💡 Troubleshooting Tips
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Common Fixes:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006400)),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Check your internet connection'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orangeAccent),
                        SizedBox(width: 10),
                        Text('Ensure your credentials are correct'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Restart the app if needed'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Contact Support:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006400)),
            ),
            const SizedBox(height: 12),

            // 📧 Email Button
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('support@employeeapp.com'),
              onTap: _launchEmail,
            ),

            // 💬 WhatsApp Button
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Chat on WhatsApp'),
              onTap: _launchWhatsApp,
            ),

            // ☎️ Call Button
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.teal),
              title: const Text('+27 11 123 4567'),
              onTap: _launchPhone,
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
      ));
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

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@employeeapp.com',
      query: 'subject=App Support Request&body=Hi Support Team,',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // 💬 WhatsApp launcher
  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/27111234567?text=Hello%20Support%2C%20I%20need%20help%20with%20the%20Employee%20App.");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  // ☎️ Phone call launcher
  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+27 11 123 4567');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
