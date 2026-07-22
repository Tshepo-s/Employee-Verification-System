import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/screens/admin_profile.dart';
import 'package:leavesystem/screens/employee_details.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Professional Color Palette ---
const Color primaryColor = Color(0xFF006400); // Deep Forest Green
const Color secondaryColor = Color(0xFF388E3C); // Darker Green
const Color lightGrey = Color(0xFFF5F5F5); // Background for cards/elements

// Service to fetch employees (LOGIC UNCHANGED)
Future<List<Employees>> fetchEmployees() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) throw Exception('No access token');

  // The logic for fetching profile and checking roles is preserved, 
  // though the result of the check isn't used in the provided screen's display logic.
  final profileRes = await http.get(
    Uri.parse('http://localhost:5000/api/home/profile'),
    headers: {'token': token},
  );

  bool isAdmin = false;
  bool isAuditor = false;

  if (profileRes.statusCode == 200) {
    final profileJson = json.decode(profileRes.body);
    isAdmin = profileJson['isAdmin'] == true;
    isAuditor = profileJson['isAuditor'] == true;
  }

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
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
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

 
   

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoUrl = prefs.getString('photoUrl');
    });
  }

  @override
  void initState() {
    super.initState();
    _employeesFuture = fetchEmployees();
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile_Screen_Admin()));
              },
            ),

            // Help Tile
            ListTile(
              leading: const Icon(Icons.help_outline, color: kPrimaryGreen),
              title: const Text('Help & Support', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add help navigation logic
              },
            ),

            // About Us Tile
            ListTile(
              leading: const Icon(Icons.info_outline, color: kPrimaryGreen),
              title: const Text('About Us', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add about us navigation logic
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDetailsScreen(employee: emp),
            ),
          );
        },

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Employees'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
            endDrawer: _buildProfessionalDrawer(context),

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

          // --- Filter/Sort by Department (UPDATED) ---
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
            print('Curved Bar Tapped Index: $index');
          }
        },
      ),
    );
  }
}