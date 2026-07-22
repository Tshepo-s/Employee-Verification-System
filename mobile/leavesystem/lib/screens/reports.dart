import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:leavesystem/screens/auditor_employees_screen.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavesystem/models/employees.dart';
import 'package:leavesystem/models/logs.dart' ;



const Color primaryColor = Color(0xFF006400);
const Color secondaryColor = Color(0xFF388E3C);
const Color lightGrey = Color(0xFFF5F5F5);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedDepartment;
  String? _selectedStatus;
  String? _selectedReportType;
  String? _userRole;

  List<Employees> _allEmployees = [];
  List<Log> _allLogs = [];
  List<String> _departments = [];
  final List<String> _statuses = ['Pending', 'Verified', 'Rejected'];
  final List<String> _reportTypes = ['Employee List', 'Audit Logs'];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchData();
  }
  // --- Data Fetching Function (UNCHANGED) ---
Future<List<Log>> _fetchAuditLogs() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return [];

  final res = await http.get(
    Uri.parse('http://localhost:5000/api/home/auditlogs'),
    headers: {'token': token},
  );

  if (res.statusCode == 200) {
    final jsonBody = jsonDecode(res.body);
    final logs = jsonBody['logs'] as List<dynamic>? ?? [];
    return logs.map((e) => Log.fromJson(e as Map<String, dynamic>)).toList();
  } else {
    debugPrint('Failed to load logs: ${res.statusCode}');
    return [];
  }
}

final directory = Directory('/storage/emulated/0/Download');


  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'employee';
    });
  }

  Future<void> _fetchData() async {
  _allEmployees = await fetchEmployees();
  _allLogs = List<Log>.from(await _fetchAuditLogs()); // fixed cast
  _departments = _allEmployees.map((e) => e.department).toSet().toList();
  _departments.sort();
  setState(() {});
}


  List<Employees> get filteredEmployees {
    return _allEmployees.where((e) {
      final matchesDept =
          _selectedDepartment == null || _selectedDepartment == 'All'
              ? true
              : e.department == _selectedDepartment;
      final matchesStatus =
          _selectedStatus == null || _selectedStatus == 'All'
              ? true
              : e.status == _selectedStatus;
      return matchesDept && matchesStatus;
    }).toList();
  }

  List<Log> get filteredLogs {
    return _allLogs.where((l) {
      final matchesStatus =
          _selectedStatus == null || _selectedStatus == 'All'
              ? true
              : l.status.toLowerCase() == _selectedStatus!.toLowerCase();
      return matchesStatus;
    }).toList();
  }

 Future<void> _downloadPDF() async {
  try {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd – HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'National Treasury – Republic of South Africa',
            style: pw.TextStyle(
                fontSize: 16, 
                fontWeight: pw.FontWeight.bold, 
                color: PdfColors.green900),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Downloaded by: $_userRole', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('Date/Time: $formattedDate', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),

          if (_selectedReportType == 'Employee List')
            pw.Table.fromTextArray(
              headers: ['Name', 'Employee No', 'Department', 'Contract', 'Status'],
              data: filteredEmployees.map((e) => [
                '${e.firstName} ${e.surname}',
                e.employeeNumber,
                e.department,
                e.contract,
                e.status,
              ]).toList(),
            ),

          if (_selectedReportType == 'Audit Logs')
            pw.Table.fromTextArray(
              headers: [
                'Verified Employee',
                'Employee No',
                'Department',
                'Verified By',
                'Verifier Role',
                'Location',
                'Date',
                'Time',
                'Status',
                'Description'
              ],
              data: filteredLogs.map((l) => [
                l.studentName ?? '',
                l.studentId ?? '',
                l.department ?? '',
                l.verifiedByName ?? '',
                l.verifiedByRole ?? '',
                l.location ?? '',
                l.date ?? '',
                l.time ?? '',
                l.status ?? '',
                l.description ?? '',
              ]).toList(),
            ),
        ],
        footer: (context) => pw.Center(
          child: pw.Text(
            'National Treasury – Republic of South Africa',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ),
    );

    // Get the download directory
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Try multiple possible download paths
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadsPath = '${directory.path}/Download';
        directory = Directory(downloadsPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }
      
      // Fallback: use documents directory
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getDownloadsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access download directory');
    }

    final fileName = '${_selectedReportType?.replaceAll(' ', '_')}_$formattedDate.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());

    // Show success message with file path
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    print('File saved to: ${file.path}');
    
  } catch (e) {
    print('Error saving PDF: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  Future<void> _downloadCSV() async {
    if (_userRole != 'auditor') return;

    List<List<String>> rows = [];
    if (_selectedReportType == 'Employee List') {
      rows.add(['Name', 'Employee No', 'Department', 'Contract', 'Status']);
      for (var e in filteredEmployees) {
        rows.add([
          '${e.firstName} ${e.surname}',
          e.employeeNumber,
          e.department,
          e.contract,
          e.status
        ]);
      }
    } else if (_selectedReportType == 'Audit Logs') {
      rows.add([
        'Verified Employee',
        'Employee No',
        'Department',
        'Verified By',
        'Verifier Role',
        'Date',
        'Time',
        'Status',
        'Description'
      ]);
      for (var l in filteredLogs) {
        rows.add([
          l.studentName,
          l.studentId,
          l.description,
          l.verifiedByName ?? '',
          l.verifiedByRole ?? '',
          l.date,
          l.time,
          l.status,
          l.description
        ]);
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Downloads'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- Filters ---
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    hint: const Text('Select Report Type'),
                    items: _reportTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedReportType = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    hint: const Text('Department'),
                    items: ['All', ..._departments]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDepartment = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    hint: const Text('Status'),
                    items: ['All', ..._statuses]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // --- Buttons ---
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed:()=> _downloadPDF(),
                ),
                const SizedBox(width: 16),
                if (_userRole == 'auditor')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_copy),
                    label: const Text('Download CSV'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                    onPressed: _downloadCSV,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
