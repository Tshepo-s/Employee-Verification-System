import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/user_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- NEW IMPORTS (for consistency) ---
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// Assume the screen files are correctly linked in your project
import 'package:leavesystem/screens/auditor_anatalystics.dart';
import 'package:leavesystem/screens/auditor_employees_screen.dart';
// -------------------------------------

// --- PLACEHOLDERS for navigation to make the code runnable ---
// NOTE: Assuming AuditorEmployeesScreen is your main 'Home' or 'Audit Logs' screen

const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccent = Color(0xFF4CAF50); // Using kAccent for consistency

class User {
  final String uid;
  final String firstName;
  final String surname;
  final String emailAddress;
  final String department;
  final String contract;
  final bool isAdmin;
  final bool isAuditor;
  final String gender;
  final String popiaConsent;
  final String profileImageUrl;
  final String personnelNumber;
  final DateTime? createdAt;

  User({
    required this.uid,
    required this.firstName,
    required this.surname,
    required this.emailAddress,
    required this.department,
    required this.contract,
    required this.isAdmin,
    required this.isAuditor,
    required this.gender,
    required this.popiaConsent,
    required this.profileImageUrl,
    required this.personnelNumber,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      firstName: json['firstName'] ?? '',
      surname: json['surname'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      department: json['department'] ?? '',
      contract: json['contract'] ?? '',
      isAdmin: json['isAdmin'] == true,
      isAuditor: json['isAuditor'] == true,
      gender: json['gender'] ?? '',
      popiaConsent: json['popiaConsent'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      personnelNumber: json['personnelNumber'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<User>> _usersFuture;
  // --- NEW STATE FOR SEARCH ---
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('http://localhost:5000/api/home/getusers');
    final response = await http.get(url, headers: {'token': token ?? ''});

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users (${response.statusCode})');
    }

    final jsonBody = jsonDecode(response.body);
    final usersJson = jsonBody['users'] as List<dynamic>? ?? [];

    // map and filter auditors out
    final users = usersJson
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .where((user) => !user.isAuditor) // exclude auditors
        .toList();

    return users;
  }

  Widget _buildUserTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kLightGreen,
          backgroundImage: user.profileImageUrl.isNotEmpty
              ? NetworkImage(user.profileImageUrl)
              : null,
          child: user.profileImageUrl.isEmpty
              ? const Icon(Icons.person, color: kPrimaryGreen)
              : null,
        ),
        title: Text('${user.firstName} ${user.surname}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.department.isNotEmpty ? user.department : 'No department'),
        trailing: user.isAdmin
            ? const Icon(Icons.shield, color: Colors.redAccent)
            : const Icon(Icons.badge, color: kPrimaryGreen),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
          );
        },
      ),
    );
  }

  // --- NEW NAVIGATION LOGIC (Consistent with AuditLogDetailScreen) ---
  void _handleCurvedNavTap(int index) {
    if (index == 0) {
      // Home (Employees/Audit Logs/Dashboard)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuditorEmployeesScreen()),
      );
    } else if (index == 1) {
      // Analytics
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
      // Current Screen - can refresh or do nothing
      setState(() {
        _usersFuture = _fetchUsers();
      });
    } else if (action == 'logout') {
      // TODO: Implement Logout Logic
      print('Logout Action');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
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
},
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- ADDED SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search user by name, email, or personnel no.',
                prefixIcon: const Icon(Icons.search, color: kPrimaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: kLightGreen,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // --- END SEARCH BAR ---

          Expanded(
            child: FutureBuilder<List<User>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kPrimaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final allUsers = snapshot.data ?? [];

                // --- APPLY SEARCH FILTERING ---
                final filteredUsers = allUsers.where((user) {
                  final query = _searchQuery.toLowerCase();
                  return user.firstName.toLowerCase().contains(query) ||
                      user.surname.toLowerCase().contains(query) ||
                      user.emailAddress.toLowerCase().contains(query) ||
                      user.personnelNumber.toLowerCase().contains(query);
                }).toList();
                // --- END FILTERING ---

                if (filteredUsers.isEmpty) {
                  final message = allUsers.isEmpty
                      ? 'No users found.'
                      : 'No users match your search criteria.';
                  return Center(
                      child: Text(message,
                          style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, i) => _buildUserTile(filteredUsers[i]),
                );
              },
            ),
          ),
        ],
      ),
      // --- CONSISTENT CURVED NAVIGATION BAR ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, 
        color: kPrimaryGreen,
        buttonBackgroundColor:kPrimaryGreen,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, // Assuming Home/Employees is index 0
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), // Home/Employees
          Icon(Icons.analytics, size: 30, color: Colors.white), // Analytics
        ],
        onTap: _handleCurvedNavTap,
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