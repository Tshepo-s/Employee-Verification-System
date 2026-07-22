import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/models/employee.dart';
import 'package:leavesystem/screens/about_us.dart';
import 'package:leavesystem/screens/help_support_screen.dart';
import 'package:leavesystem/screens/log_profile_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/one_time_form.dart';
import 'package:leavesystem/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9); 

class Home_Screen extends StatefulWidget {
  const Home_Screen({super.key});

  @override
  State<Home_Screen> createState() => _Home_ScreenState();
}

class _Home_ScreenState extends State<Home_Screen> {
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
               Employee? currentEmployee;



  int _page = 0; 

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

  void showVerificationHistory(BuildContext context, Employee employee) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Verification History'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index] as Map<String, dynamic>;
                      final name = log['name'] ?? '';
                      final surname = log['surname'] ?? '';
                      final dept = log['department'] ?? 'N/A';
                      final status = log['status'] ?? 'Pending';
                      final completedAt = log['completedAt']?.toString() ?? 'In Review';
                      final image = log['verificationImageUrl']?.toString() ?? '';

                     return LogCard(
                        name: "$name $surname",
                        department: dept,
                        status: status,
                        completedAt: completedAt,
                        imageUrl: image,
                        statusColor: _getStatusColor(status),
                        userName: _currentName,
                        userSurname: _currentSURNName,
                        userUid: _personnel, 
                        userPhotoUrl: _photoUrl,
                        log: log, 
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)));
    }

    if (_error != null) {
     
      return Scaffold(
        appBar: AppBar(
          title: const Text("Employee Verification System"),
          backgroundColor: kPrimaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kPrimaryGreen,
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
        title: const Text("Verification Dashboard"),
        automaticallyImplyLeading: false,
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
      ),

      endDrawer: _buildProfessionalDrawer(context),
      

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${_currentName ?? 'Employee'} ${_currentSURNName ?? 'Employee'}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreen,
                  ),
                ),
                const SizedBox(height: 10),

              
            // Grid Menu Section
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: "QR Scan",
                  onTap: () {
                    showScanDialog(context);
                    
                  },
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.qr_code_2,
                  label: "Self Verification",
                  onTap: () {
                    if (_uid != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OneTimeForm(uid: _uid!)),
              ).then((_) {
                setState(() {
                  _loading = true;
                });
                _loadData();
              });
            }
                  },
                ),
                
                _buildDashboardCard(
                  context,
                  icon: Icons.help_outline,
                  label: "Help",
                  onTap: () {
                     showHelpDialog(context);
                    
                  },
                ),
                
              ],
            ),

                const Text(
                  "Your Recent Verification Activity",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const Divider(color: Colors.black12, height: 24),
              ],
            ),
          ),

          SizedBox(
            height: 400,
            child: _logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No verification requests found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          "Tap the 'New Request' button to start one.",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _logs.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final log = _logs[index] as Map<String, dynamic>;
                      final name = log['name'] ?? '';
                      final surname = log['surname'] ?? '';
                      final dept = log['department'] ?? 'N/A';
                      final status = log['status'] ?? 'Pending';
                      final completedAt = log['completedAt']?.toString() ?? 'In Review';
                      final image = log['verificationImageUrl']?.toString() ?? '';

                     return LogCard(
                        name: "$name $surname",
                        department: dept,
                        status: status,
                        completedAt: completedAt,
                        imageUrl: image,
                        statusColor: _getStatusColor(status),
                        userName: _currentName,
                        userSurname: _currentSURNName,
                        userUid: _personnel, 
                        userPhotoUrl: _photoUrl,
                        log: log, 
                      );
                    },
                  ),
          ),
        ],
      ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0), 
        
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



class LogCard extends StatelessWidget {
  final String name;
  final String department;
  final String status;
  final String completedAt;
  final String imageUrl;
  final Color statusColor;
  final Map<String, dynamic> log;
  
  final String? userName;
  final String? userSurname;
  final String? userUid;
  final String? userPhotoUrl;

  const LogCard({
    super.key,
    required this.name,
    required this.department,
    required this.status,
    required this.completedAt,
    required this.imageUrl,
    required this.statusColor,
    required this.log, 
    this.userName,
    this.userSurname,
    this.userUid,
    this.userPhotoUrl,
  });
  
  String _formatCompletedAt(String completedAt) {
    if (completedAt.toLowerCase() == 'in review' || completedAt == 'N/A') return completedAt;
    try {
      final dateTime = DateTime.parse(completedAt);
      return "${dateTime.month}/${dateTime.day}/${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return completedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: kPrimaryGreen.withOpacity(0.1),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: kPrimaryGreen, size: 30),
                    )
                  : const Icon(Icons.person, color: kPrimaryGreen, size: 30),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Dept: $department', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 2),
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Completed: ${_formatCompletedAt(completedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LogProfileScreen(
                  log: log, 
                  userName: userName,
                  userSurname: userSurname,
                  userUid: userUid,
                  userPhotoUrl: userPhotoUrl,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// --- Helper Widgets ---
  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height:85,
        width: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green[700]),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem({
    required String title,
    required String time,
    required String reason,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.verified, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Time: $time"),
            Text("Reason: $reason"),
          ],
        ),
      ),
    );
  }
  //qrscan
  void showScanDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('QR Scanner'),
      content: const Text(
        'For assistance with the Employee Verification System, Future Feature:\n\n'
        'The QR Scanner in Progress\n',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Help & Support'),
      content: const Text(
        'For assistance with the Employee Verification System, please contact:\n\n'
        'IT Help Desk: 012 315 5000\n'
        'Email: helpdesk@treasury.gov.za\n\n'
        'Office Hours: Mon-Fri 8:00-16:30',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}