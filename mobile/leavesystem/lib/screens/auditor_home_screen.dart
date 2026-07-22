import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/auditor_anatalystics.dart';
import 'package:leavesystem/screens/auditor_employees_screen.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/users_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';


class AuditLogDetailScreen extends StatelessWidget {
  final AuditLog log;
  const AuditLogDetailScreen({super.key, required this.log});

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kPrimaryGreen)),
            ),
            Expanded(
              flex: 5,
              child: Text(value, style: const TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool isVerified = log.result.toLowerCase() == 'verified';
    return Scaffold(
      // --- APPBAR CHANGES ---
      appBar: AppBar(
        title: const Text('Audit Details'),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, semanticLabel: 'Employees'),
            onPressed: () {
                   
                   Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditorEmployeesScreen(),
              ),
            );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () {
              Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsersScreen()),
      );
            },
            tooltip: 'Users',
          ),
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            onPressed: () {
             _logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      // --- BODY CONTENT (UNCHANGED) ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: kLightGreen,
              backgroundImage: log.verifierProfileImageUrl.isNotEmpty
                  ? NetworkImage(log.verifierProfileImageUrl)
                  : null,
              child: log.verifierProfileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: kPrimaryGreen, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              '${log.verifierFirstName} ${log.verifierSurname}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen),
            ),
            const SizedBox(height: 8),
            Text(log.verifierEmail,
                style: const TextStyle(color: Colors.black54, fontSize: 15)),
            const Divider(height: 30, thickness: 1),
            _row('Verifier Personnel', log.verifierPersonnelNumber),
            _row('Verifier Department', log.verifierDepartment),
            _row('Verified Department', log.department),
            _row('ID Number', log.idNumber),
            _row('Log ID', log.logId),
            _row('Reason', log.reason),
            _row('Similarity', '${log.similarity.toStringAsFixed(2)}%'),
            _row('Result', log.result),
            _row('Timestamp', log.timestamp.toLocal().toString()),
            const SizedBox(height: 10),
            Chip(
              label: Text(
                isVerified ? 'VERIFIED' : 'FAILED',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: isVerified ? Colors.green : Colors.redAccent,
            ),
          ],
        ),
      ),
      // --- CURVED NAVIGATION BAR FIXED AND NAVIGATION ADDED ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, // Transparent background to show Scaffold's color
        color: kPrimaryGreen,
        buttonBackgroundColor: kPrimaryGreen ,
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
          }
        },
      ),
    );
  }
}


const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccent = Color(0xFF4CAF50);

// --- AuditLog Model (UNCHANGED) ---
class AuditLog {
  final String verifierFirstName;
  final String verifierSurname;
  final String verifierEmail;
  final String verifierPersonnelNumber;
  final String verifierDepartment;
  final String verifierProfileImageUrl;
  final String department;
  final String idNumber;
  final String logId;
  final String reason;
  final String result;
  final double similarity;
  final DateTime timestamp;

  AuditLog({
    required this.verifierFirstName,
    required this.verifierSurname,
    required this.verifierEmail,
    required this.verifierPersonnelNumber,
    required this.verifierDepartment,
    required this.verifierProfileImageUrl,
    required this.department,
    required this.idNumber,
    required this.logId,
    required this.reason,
    required this.result,
    required this.similarity,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    String _asString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map && v.containsKey('stringValue')) return v['stringValue'];
      return v.toString();
    }

    double _asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return AuditLog(
      verifierFirstName: _asString(json['VerifierFirstName']),
      verifierSurname: _asString(json['VerifierSurname']),
      verifierEmail: _asString(json['VerifierEmail']),
      verifierPersonnelNumber: _asString(json['VerifierPersonnelNumber']),
      verifierDepartment: _asString(json['VerifierDepartment']),
      verifierProfileImageUrl: _asString(json['VerifierProfileImageUrl']),
      department: _asString(json['department']),
      idNumber: _asString(json['idNumber']),
      logId: _asString(json['logId']),
      reason: _asString(json['reason']),
      result: _asString(json['result']),
      similarity: _asDouble(json['similarity']),
      timestamp: DateTime.tryParse(_asString(json['timestamp'])) ?? DateTime.now(),
    );
  }
}

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  late Future<List<AuditLog>> _logsFuture;
  String _searchQuery = '';
  int _currentPage = 0;
  final int _logsPerPage = 6;
  // --- NEW: Date Range Filter State ---
  DateTimeRange? _dateRange;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchAuditLogs();
  }

  // --- LOGIC UNCHANGED ---
  Future<List<AuditLog>> _fetchAuditLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Missing token');

    final res = await http.get(
      Uri.parse('http://localhost:5000/api/home/auditlogs'),
      headers: {'token': token},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load logs (${res.statusCode})');
    }

    final jsonBody = jsonDecode(res.body);
    final logs = jsonBody['logs'] as List<dynamic>? ?? [];
    return logs.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- NEW: Date Range Picker Function ---
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: kPrimaryGreen,
            colorScheme: const ColorScheme.light(primary: kPrimaryGreen),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _currentPage = 0; // Reset page on new filter
      });
    }
  }
  // ----------------------------------------

  // --- UI WIDGET UNCHANGED ---
  Widget _buildAuditCard(AuditLog log) {
    final bool isVerified = log.result.toLowerCase() == 'verified';
    final Color resultColor = isVerified ? Colors.green : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: kLightGreen,
          backgroundImage: log.verifierProfileImageUrl.isNotEmpty
              ? NetworkImage(log.verifierProfileImageUrl)
              : null,
          child: log.verifierProfileImageUrl.isEmpty
              ? const Icon(Icons.person, color: kPrimaryGreen)
              : null,
        ),
        title: Text(
          '${log.verifierFirstName} ${log.verifierSurname}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifier Dept: ${log.verifierDepartment}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text('Verified Dept: ${log.department}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text('Reason: ${log.reason}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text(
              'Similarity: ${log.similarity.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              'Time: ${log.timestamp.toLocal()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(
          isVerified ? Icons.verified : Icons.cancel,
          color: resultColor,
          size: 24,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuditLogDetailScreen(log: log),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APPBAR CHANGES (Added Date Filter Button) ---
      appBar: AppBar(
        title: const Text('Audit Trail'),
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_dateRange == null ? Icons.calendar_today : Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range Filter',
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _dateRange = null),
              tooltip: 'Clear Date Filter',
            ),
          IconButton(
            icon: const Icon(Icons.people, semanticLabel: 'Employees'),
            onPressed: () {
                                 Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditorEmployeesScreen(),
              ),
            );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_pin, semanticLabel: 'Users'),
            onPressed: () {  Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsersScreen()),
      );}
          ),
  
          IconButton(
            icon: const Icon(Icons.logout, semanticLabel: 'Logout'),
            onPressed: ()  {          _logout(context);},

            tooltip: 'Logout',
          ),
        ],
      ),
      // --- BODY CONTENT (PAGINATION, SORTING, AND DATE FILTERING LOGIC ADDED) ---
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by verifier or department',
                prefixIcon: const Icon(Icons.search, color: kPrimaryGreen),
                filled: true,
                fillColor: kLightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value;
                _currentPage = 0; // Reset page on new search
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AuditLog>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                List<AuditLog> logs = snapshot.data ?? [];
                
                // 1. Apply Search Filter
                List<AuditLog> filtered = logs.where((log) {
                  final q = _searchQuery.toLowerCase();
                  final matchesSearch = log.verifierFirstName.toLowerCase().contains(q) ||
                      log.verifierSurname.toLowerCase().contains(q) ||
                      log.verifierDepartment.toLowerCase().contains(q) ||
                      log.department.toLowerCase().contains(q);
                  
                  // 2. Apply Date Range Filter
                  if (_dateRange == null) return matchesSearch;

                  // Normalize timestamps for comparison (setting time to start/end of day)
                  final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
                  final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
                  // Add one day to the end date to include all logs from that last day
                  final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); 

                  final matchesDate = logDate.isAfter(start.subtract(const Duration(milliseconds: 1))) && logDate.isBefore(end);
                  
                  return matchesSearch && matchesDate;
                }).toList();

                // 3. Apply Recent-First Sorting
                filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));


                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No audit logs found with current filters.',
                          style: TextStyle(color: Colors.grey)));
                }
                
                // 4. Pagination Calculation
                final totalLogs = filtered.length;
                final totalPages = (totalLogs / _logsPerPage).ceil();
                // Ensure current page is valid after filtering/sorting
                _currentPage = _currentPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0); 
                
                final startIndex = _currentPage * _logsPerPage;
                final endIndex = (_currentPage * _logsPerPage + _logsPerPage)
                    .clamp(0, totalLogs);
                final pageLogs = filtered.sublist(startIndex, endIndex);

                return ListView.builder(
                  itemCount: pageLogs.length,
                  itemBuilder: (context, index) => _buildAuditCard(pageLogs[index]),
                );
              },
            ),
          ),
          // --- Pagination Controls ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: FutureBuilder<List<AuditLog>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  final logs = snapshot.data ?? [];
                  // Re-run filters to correctly calculate totalPages
                  final filtered = logs.where((log) {
                    final q = _searchQuery.toLowerCase();
                    final matchesSearch = log.verifierFirstName.toLowerCase().contains(q) ||
                        log.verifierSurname.toLowerCase().contains(q) ||
                        log.verifierDepartment.toLowerCase().contains(q) ||
                        log.department.toLowerCase().contains(q);
                    
                    if (_dateRange == null) return matchesSearch;

                    final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
                    final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
                    final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); 

                    final matchesDate = logDate.isAfter(start.subtract(const Duration(milliseconds: 1))) && logDate.isBefore(end);
                    
                    return matchesSearch && matchesDate;
                  }).toList();

                  final totalPages = (filtered.length / _logsPerPage).ceil();

                  if (totalPages <= 1) return const SizedBox.shrink();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text('Page ${_currentPage + 1} of $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      // --- CURVED NAVIGATION BAR FIXED AND NAVIGATION ADDED ---
      bottomNavigationBar: CurvedNavigationBar(
        height: 50.0,
        backgroundColor: Colors.transparent, 
        color: kPrimaryGreen,
        buttonBackgroundColor: kPrimaryGreen,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: 0, 
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white), 
          Icon(Icons.analytics, size: 30, color: Colors.white), // Navigation to Analytics
        ],
        onTap: (index) {
          if (index == 1) { 
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuditAnalyticsScreen(),
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