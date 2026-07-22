import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:leavesystem/screens/about_us.dart';
import 'package:leavesystem/screens/help_support_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildProfessionalDrawer(BuildContext context, String? name, String? surname, String? personnel, String? photoUrl) {
 
  final displayName = "${name ?? ''} ${surname ?? ''}".trim().isEmpty ? "Employee Name" : "${name} ${surname}";
  final displayId = personnel ?? 'ID: N/A';
  final displayPhotoUrl = photoUrl ?? '';

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          accountEmail: Text(displayId, style: const TextStyle(color: Colors.white70)),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: (displayPhotoUrl.isNotEmpty) 
                  ? Image.network(displayPhotoUrl, fit: BoxFit.cover, width: 90, height: 90)
                  : const Icon(Icons.person, color: Color(0xFF006400), size: 40),
            ),
          ),
          decoration: const BoxDecoration(color: Color(0xFF006400)),
        ),
        // ... Drawer items ...
 ListTile(
              leading: const Icon(Icons.person_outline, color: kPrimaryGreen),
              title: const Text('My Profile', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
              },
            ),

            // Help Tile
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

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
                           onTap: () => _logout(context),

            ),      ],
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

const Color kPrimaryGreen = Color(0xFF006400);
const Color kAccentColor = Color(0xFF4CAF50); 

class LogProfileScreen extends StatelessWidget {
  final Map<String, dynamic> log;
  
  final String? userName;
  final String? userSurname;
  final String? userUid;
  final String? userPhotoUrl;

  const LogProfileScreen({
    Key? key, 
    required this.log,
    this.userName,
    this.userSurname,
    this.userUid,
    this.userPhotoUrl,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green.shade700;
      case 'in progress':
        return Colors.blue.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
  
  
  String _formatDate(String dateString) {
    if (dateString.toLowerCase() == 'n/a' || dateString.toLowerCase() == 'unknown') return dateString;
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return "${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final name = log['name'] ?? '';
    final surname = log['surname'] ?? '';
    final department = log['department'] ?? 'N/A';
    final status = log['status'] ?? 'Pending';
    final completedAt = log['completedAt']?.toString() ?? 'N/A';
    final image = log['verificationImageUrl'] ?? '';
        final reason = log['reason'] ?? 'N/A';

    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verification Details"),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      endDrawer: buildProfessionalDrawer(
        context,
        userName,
        userSurname,
        userUid,
        userPhotoUrl,
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: kPrimaryGreen.withOpacity(0.1),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage: (image.isNotEmpty)
                        ? NetworkImage(image)
                        : const AssetImage("images/default_profile.png") as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$name $surname".trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Log Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  _buildDetailRow(Icons.business_outlined, "Department", department),
                                    _buildDetailRow(Icons.read_more, "Reason", reason),

                  _buildDetailRow(Icons.check_circle_outline, "Completed At", completedAt.toLowerCase() == 'n/a' ? 'In Progress' : _formatDate(completedAt)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

        
        ],
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
          if (index == 0) { 
            Navigator.popUntil(context, (route) => route.isFirst); 
          } else if (index == 1) { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen()));
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryGreen.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
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
}