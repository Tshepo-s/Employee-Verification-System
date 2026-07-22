import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:leavesystem/screens/admin_more_details.dart';
import 'package:leavesystem/screens/admin_profile.dart';
import 'package:leavesystem/screens/adminemployees.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/reports.dart';
import 'package:leavesystem/screens/settings.dart';
import 'package:leavesystem/screens/verify.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;
  List<dynamic> logs = [];
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

  @override
  void initState() {
    super.initState();
    _fetchLogs();
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
   Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoUrl = prefs.getString('photoUrl');
    });
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

  Future<void> _fetchLogs() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/home/logs'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          logs = data['logs'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load logs (${response.statusCode})');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  String _formatCompletedAt(dynamic completedAt) {
    if (completedAt == null) return 'N/A';

    try {
      if (completedAt is Map && completedAt['seconds'] != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(completedAt['seconds'] * 1000);
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
      if (completedAt is String) {
        final parsed = DateTime.tryParse(completedAt);
        if (parsed != null) return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
      }
    } catch (_) {}
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = logs.where((log) {
      final name = (log['name'] ?? '').toString().toLowerCase();
      final surname = (log['surname'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
          surname.contains(searchQuery.toLowerCase());

      DateTime? completedAt;
      if (log['completedAt'] is Map && log['completedAt']['seconds'] != null) {
        completedAt = DateTime.fromMillisecondsSinceEpoch(log['completedAt']['seconds'] * 1000);
      } else if (log['completedAt'] is String) {
        completedAt = DateTime.tryParse(log['completedAt']);
      }

      final inRange = (startDate == null || (completedAt != null && completedAt.isAfter(startDate!.subtract(const Duration(days: 1))))) &&
          (endDate == null || (completedAt != null && completedAt.isBefore(endDate!.add(const Duration(days: 1)))));

      return matchesSearch && inRange;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
      ),
           endDrawer: _buildProfessionalDrawer(context),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryGreen,
        onPressed: _fetchLogs,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      
bottomNavigationBar: CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: kPrimaryGreen,
      buttonBackgroundColor: kPrimaryGreen,
      height: 60,
      items: const [
        Icon(Icons.home, color: Colors.white, size: 30),

        Icon(Icons.people, color: Colors.white, size: 30),
        Icon(Icons.settings, color: Colors.white, size: 30),
      ],
      onTap: (index) {
        if (index == 0) {
          // already on Home
        }  else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEmployeesScreen()),
          );
        }
        else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }
      },
    ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    //  Summary Cards Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Total Logs', logs.length.toString(), Icons.people, Colors.blue),
                        _buildStatCard(
                            'Verified',
                            logs.where((log) => (log['status'] ?? '').toString().toLowerCase().contains('Verified')).length.toString(),
                            Icons.verified,
                            kPrimaryGreen),
                        GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerifyScreen(), // pass parameters if needed
      ),
    );
  },
  child: _buildStatCard(
    'Pending',
    logs
        .where((log) =>
            (log['status'] ?? '').toString().toLowerCase().contains('pending'))
        .length
        .toString(),
              Icons.pending_actions,
            Colors.orange,
                ),
              ),

                  ],
              ),
                    const SizedBox(height: 20),
                    //  Search + Date Range
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search employees',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (v) => setState(() => searchQuery = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.date_range, color: Colors.green),
                          onPressed: _pickDateRange,
                        ),
                        if (startDate != null && endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () => setState(() {
                              startDate = null;
                              endDate = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Logs List
                    if (filteredLogs.isEmpty)
                      const Center(child: Text('No logs found', style: TextStyle(color: Colors.grey)))
                    else
                      ListView.builder(
                        itemCount: filteredLogs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final verificationImageUrl = log['verificationImageUrl'] ?? '';
                          final completedAt = _formatCompletedAt(log['completedAt']);
                          final status = (log['status'] ?? 'Unknown').toString();
                          final statusColor = status.toLowerCase() == 'verified'
                              ? kPrimaryGreen
                              : status.toLowerCase().contains('pending')
                                  ? Colors.orange
                                  : Colors.red;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: verificationImageUrl != ''
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(verificationImageUrl, width: 50, height: 50, fit: BoxFit.cover),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: const Icon(Icons.person, color: kPrimaryGreen),
                                    ),
                              title: Text('${log['name'] ?? ''} ${log['surname'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Employee #: ${log['employeeNumber'] ?? 'N/A'}'),
                                  Text('Status: $status', style: TextStyle(color: statusColor)),
                                  Text('Completed: $completedAt'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Admin_More_Screen(
                                        docId: log['uid'] ?? '',
                                        name: '${log['name'] ?? ''} ${log['surname'] ?? ''}',
                                        identityNumber: log['idNumber'] ?? '',
                                        personnelNumber: log['employeeNumber'] ?? '',
                                        status: log['status'] ?? '', 
                                        gender: log['gender'] ?? '',
                                      department: log['department'] ?? '',
                                      contract: log['contract'] ?? '',
                                      age: log['age'] ?? '',
                                      citizenship: log['citizenship'] ?? '',
                                      verificationImageUrl: log['verificationImageUrl'] ??'',
                                       reason: log['reason'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Details', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
