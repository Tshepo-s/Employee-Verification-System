import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/screens/auditor_employee_details.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/reports.dart';
import 'package:leavesystem/screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF006400); // Deep Forest Green
const Color secondaryColor = Color(0xFF388E3C); // Darker Green
const Color lightGrey = Color(0xFFF5F5F5);
const Color accentColor = Color(0xFF4CAF50);

// Service to fetch employees (LOGIC UNCHANGED)
Future<List<Employees>> fetchEmployees() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) throw Exception('No access token');

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

class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  late Future<List<Employees>> _employeesFuture;
  String _searchQuery = '';
  String? _selectedDepartment;

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

  Widget _buildEmployeeCard(Employees emp) {
    IconData roleIcon = emp.isAdmin
        ? Icons.star
        : (emp.isAuditor ? Icons.verified_user : Icons.person_outline);
    Color roleColor =
        emp.isAdmin ? Colors.orange.shade800 : (emp.isAuditor ? secondaryColor : Colors.blueGrey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: lightGrey,
              backgroundImage:
                  emp.profileImageUrl.isNotEmpty ? NetworkImage(emp.profileImageUrl) : null,
              child: emp.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: primaryColor)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(roleIcon, size: 16, color: roleColor),
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
                Text('Personnel: ${emp.employeeNumber}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Dept: ${emp.department}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.assignment, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Contract: ${emp.contract}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar simplified (no icons)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('All Employees'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 6),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search employee by name or number',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          FutureBuilder<List<Employees>>(
            future: _employeesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              final allEmployees = snapshot.data ?? [];
              final fetchedDepartments = allEmployees.map((e) => e.department).toSet();
              final combinedDepartments = <String>{
                ...fetchedDepartments,
                ..._requiredDepartments,
              };
              final departments = {'All', ...combinedDepartments.toList()..sort()};

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        onChanged: (String? newValue) {
                          setState(() {
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

          Expanded(
            child: FutureBuilder<List<Employees>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading employees: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final allEmployees = snapshot.data ?? [];
                var filteredEmployees = allEmployees.where((emp) {
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = emp.firstName.toLowerCase().contains(query) ||
                      emp.surname.toLowerCase().contains(query) ||
                      emp.employeeNumber.toLowerCase().contains(query);
                  final matchesDepartment =
                      _selectedDepartment == null || emp.department == _selectedDepartment;
                  return matchesSearch && matchesDepartment;
                }).toList();

                if (filteredEmployees.isEmpty) {
                  return const Center(
                      child: Text('No employees found.', style: TextStyle(color: Colors.grey)));
                }

                filteredEmployees.sort((a, b) => a.department.compareTo(b.department));
                return ListView.builder(
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = filteredEmployees[index];
                    return _buildEmployeeCard(emp);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Curved Bottom Navigation Bar
      bottomNavigationBar: CurvedNavigationBar(
        height: 55,
        color: primaryColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, color: Colors.white, size: 28),
          Icon(Icons.settings, color: Colors.white, size: 28),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          }  else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }
}
