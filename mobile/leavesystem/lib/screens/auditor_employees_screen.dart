import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/screens/auditor_anatalystics.dart';
import 'package:leavesystem/screens/auditor_employee_details.dart';
import 'package:leavesystem/screens/auditor_home_screen.dart';
import 'package:leavesystem/screens/employee_details.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- NEW IMPORT ---
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; 

const Color primaryColor = Color(0xFF006400); // Deep Forest Green
const Color secondaryColor = Color(0xFF388E3C); // Darker Green
const Color lightGrey = Color(0xFFF5F5F5); // Background for cards/elements
const Color accentColor = Color(0xFF4CAF50); // Accent for Curved Nav Button

// Service to fetch employees (LOGIC UNCHANGED)
Future<List<Employees>> fetchEmployees() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) throw Exception('No access token');

  
  final profileRes = await http.get(
    Uri.parse('http://localhost:5000/api/home/profile'),
    headers: {'token': token},
  );

  // bool isAdmin = false;
  // bool isAuditor = false;

  // if (profileRes.statusCode == 200) {
  //   final profileJson = json.decode(profileRes.body);
  //   isAuditor = profileJson['isAuditor'] == true;
  // }

  final res = await http.get(
    Uri.parse('http://localhost:5000/api/home/getemployees'),
    headers: {'token': token},
  );

  if (res.statusCode != 200) {
    throw Exception('Unable to fetch employees');
  }

  final parsed = json.decode(res.body) as Map<String, dynamic>;
  final employeesJson = parsed['employees'] as List<dynamic>? ?? [];

  return employeesJson
      .map((json) => Employees.fromJson(json as Map<String, dynamic>))
      .toList();
}

// Flutter screen to display employees
class AuditorEmployeesScreen extends StatefulWidget {
  const AuditorEmployeesScreen({super.key});

  @override
  State<AuditorEmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<AuditorEmployeesScreen> {
  late Future<List<Employees>> _employeesFuture;
  String _searchQuery = '';
  // --- STATE FOR DEPARTMENT FILTER ---
  String? _selectedDepartment; // Null means "All Departments"

  // --- REQUIRED DEPARTMENTS ---
  final List<String> _requiredDepartments = const [
    "Economic Policy and International Cooperation",
    "Tax and Financial Sector Policy",
    "Asset and Liability Management",
    "Office of the Accountant-General",
    "Intergovernmental Relations",
  ];

  @override
  void initState() {
    super.initState();
    _employeesFuture = fetchEmployees();
  }
   Color kPrimaryGreen = Color(0xFF006400);

  // Custom Widget for Employee List Item (New Professional Design)
  Widget _buildEmployeeCard(Employees emp) {
    // Determine the role icon/color
    IconData roleIcon = emp.isAdmin ? Icons.star : (emp.isAuditor ? Icons.verified_user : Icons.person_outline);
    Color roleColor = emp.isAdmin ? Colors.orange.shade800 : (emp.isAuditor ? secondaryColor : Colors.blueGrey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            // Profile Image/Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: lightGrey,
              backgroundImage: emp.profileImageUrl.isNotEmpty
                  ? NetworkImage(emp.profileImageUrl)
                  : null,
              child: emp.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: primaryColor)
                  : null,
            ),
            // Role Badge (Bottom Right)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                roleIcon,
                size: 16,
                color: roleColor,
              ),
            ),
          ],
        ),
        title: Text(
          '${emp.firstName} ${emp.surname}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Personnel: ${emp.employeeNumber}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Dept: ${emp.department}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.assignment, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Contract: ${emp.contract}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // NOTE: Assuming EmployeeDetailsScreen is defined elsewhere
          // If you need to navigate to a User or Auditor details screen instead, adjust this.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuditormployeeDetailsScreen(employee: emp),
            ),
          );
        },

      ),
    );
  }

  // --- Function to handle AppBar Navigation ---
  void _handleAppBarAction(String action) {
    if (action == 'audit_logs') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
      );
    } else if (action == 'users') {
      // TODO: Implement navigation to Users Screen
  Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UsersScreen()),
      );    } else if (action == 'logout') {
      // TODO: Implement Logout Logic
      print('Logout Action (Placeholder)');
    } else if (action == 'employees') {
      // Do nothing, already on this screen
    }
  }

 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APPBAR WITH ACTIONS ---
      appBar: AppBar(
        title: const Text('All Employees'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.book, semanticLabel: 'Audit Logs'),
            onPressed: () => _handleAppBarAction('audit_logs'),
            tooltip: 'Audit Logs',
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () => _handleAppBarAction('users'),
            tooltip: 'Users',
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            onPressed: () {             _logout(context);
}
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0, bottom: 6.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search employee by name or number',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: lightGrey,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // --- Filter/Sort by Department (UNCHANGED LOGIC) ---
          FutureBuilder<List<Employees>>(
            future: _employeesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Hide while loading
              }

              final allEmployees = snapshot.data ?? [];
              
              // 1. Get departments from fetched data
              final fetchedDepartments = allEmployees.map((e) => e.department).toSet();

              // 2. Combine fetched departments with required departments
              final combinedDepartments = <String>{
                ...fetchedDepartments,
                ..._requiredDepartments, // Include the explicitly required list
              };

              // 3. Prepare final dropdown list: Add 'All', convert to list, and sort
              final departments = {'All', ...combinedDepartments.toList()..sort()};

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Department:',
                      style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedDepartment ?? 'All',
                        icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                        elevation: 4,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        underline: const SizedBox(), // Hide the default underline
                        onChanged: (String? newValue) {
                          setState(() {
                            // Set to null if 'All' is selected
                            _selectedDepartment = (newValue == 'All') ? null : newValue; 
                          });
                        },
                        items: departments.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(height: 1),

          // FutureBuilder (LOGIC PRESERVED, FILTERING APPLIED)
          Expanded(
            child: FutureBuilder<List<Employees>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading employees: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  );
                }

                final allEmployees = snapshot.data ?? [];
                
                // 1. Apply Search Filter
                var filteredEmployees = allEmployees.where((emp) {
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = emp.firstName.toLowerCase().contains(query) ||
                                         emp.surname.toLowerCase().contains(query) ||
                                         emp.employeeNumber.toLowerCase().contains(query);
                    // 2. Apply Department Filter
                    final matchesDepartment = _selectedDepartment == null || emp.department == _selectedDepartment;

                    return matchesSearch && matchesDepartment;
                }).toList();

                if (filteredEmployees.isEmpty && allEmployees.isNotEmpty) {
                    return const Center(child: Text('No employees found matching your criteria.', style: TextStyle(color: Colors.grey)));
                }

                if (filteredEmployees.isEmpty) {
                  return const Center(child: Text('No employee records found.', style: TextStyle(color: Colors.grey)));
                }

                // Optional: Sort by department name for a cleaner list view
                filteredEmployees.sort((a, b) => a.department.compareTo(b.department)); 


                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = filteredEmployees[index];
                    return _buildEmployeeCard(emp); // Use the new professional card widget
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, // Transparent background to show Scaffold's color
        color: Color(0xFF006400),
        buttonBackgroundColor: Color(0xFF006400),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, // Assuming Audit Logs is the default/main page
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), // Audit Log 
          Icon(Icons.analytics, size: 30, color: Colors.white), // Analytics
        ],
        onTap: (index) {
          if (index == 1) { // Index 1 is the Analytics icon
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditAnalyticsScreen(),
              ),
            );
          } else {
            print('Curved Bar Tapped Index: $index');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditLogsScreen(),
              ),
            );
          }
        },
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