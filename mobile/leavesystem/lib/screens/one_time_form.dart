import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavesystem/screens/profile.dart';
import 'package:leavesystem/screens/home_screen.dart';

class OneTimeForm extends StatefulWidget {
  final String uid;
  const OneTimeForm({super.key, required this.uid});

  @override
  State<OneTimeForm> createState() => _OneTimeFormState();
}

class _OneTimeFormState extends State<OneTimeForm> {
  final _formKey = GlobalKey<FormState>();
  final _employeeController = TextEditingController();
  final _idController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedContract;
  String? _selectedGender;
  bool _submitting = false;
  String? _error;
  String? _token;
  Uint8List? _capturedBytes;
  html.VideoElement? _videoElement;
  bool _cameraStarted = false;

  String? userName;
  String? userSurname;
  String? userUid;
  String? userPhotoUrl;

  Color kPrimaryGreen = const Color(0xFF006400);

  static const Color _primaryColor = Color(0xFF00796B);

  final List<String> _departments = [
    "Public Finance",
    "Economic Policy and International Cooperation",
    "Tax and Financial Sector Policy",
    "Asset and Liability Management",
    "Office of the Accountant-General",
    "Intergovernmental Relations"
  ];
  final List<String> _contracts = ["Permanent", "Intern"];
  final List<String> _genders = ["Male", "Female"];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadDrawerInfo();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => _error = "User not logged in");
      return;
    }
    _token = token;
  }

  Future<void> _loadDrawerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('FirstName') ?? 'Employee';
      userSurname = prefs.getString('Surname') ?? '';
      userUid = prefs.getString('PersonnelNumber') ?? 'N/A';
      userPhotoUrl = prefs.getString('photoUrl') ?? '';
    });
  }

  void _startCamera() {
    if (_cameraStarted) return;
    _videoElement = html.VideoElement()
      ..width = 300
      ..height = 300
      ..autoplay = true;
/** 
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'videoElementVerify',
      (int viewId) => _videoElement!,
    );
    */

    html.window.navigator.mediaDevices?.getUserMedia({'video': true}).then(
      (stream) {
        _videoElement!.srcObject = stream;
        _cameraStarted = true;
        setState(() {});
      },
    ).catchError((e) {
      debugPrint("Camera error: $e");
      setState(() => _error = "Failed to start camera: $e");
    });
  }

  Future<void> _captureImage() async {
    if (_videoElement == null || _videoElement!.videoWidth == 0) return;
    final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth, height: _videoElement!.videoHeight);
    canvas.context2D.drawImage(_videoElement!, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg');
    final bytes = base64Decode(dataUrl.split(',').last);
    setState(() {
      _capturedBytes = Uint8List.fromList(bytes);
      _videoElement!.srcObject?.getTracks().forEach((track) => track.stop());
      _cameraStarted = false;
    });
  }

  void _retakeImage() {
    _videoElement?.srcObject?.getTracks().forEach((track) => track.stop());
    setState(() {
      _capturedBytes = null;
      _cameraStarted = false;
    });
    _startCamera();
  }

  Map<String, dynamic>? _parseSouthAfricanID(String id) {
    if (id.length != 13 || int.tryParse(id) == null) return null;
    final yy = int.parse(id.substring(0, 2));
    final mm = int.parse(id.substring(2, 4));
    final dd = int.parse(id.substring(4, 6));

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final century = (yy <= currentYear ? 2000 : 1900);
    DateTime dob;
    try {
      dob = DateTime(century + yy, mm, dd);
    } catch (_) {
      return null;
    }

    final age = now.year - dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);
    if (age < 18) return null;

    final genderDigits = int.parse(id.substring(6, 10));
    final gender = genderDigits >= 5000 ? "Male" : "Female";

    final citizenshipDigit = int.parse(id[10]);
    if (citizenshipDigit != 0 && citizenshipDigit != 1) return null;
    final citizenship =
        citizenshipDigit == 0 ? "Citizen" : "Permanent Resident";

    int sum = 0;
    bool alt = false;
    for (int i = id.length - 1; i >= 0; i--) {
      int n = int.parse(id[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    if (sum % 10 != 0) return null;

    return {
      "dob": dob.toIso8601String().substring(0, 10),
      "age": age,
      "gender": gender,
      "citizenship": citizenship,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) {
      setState(() => _error = "Missing authentication token");
      return;
    }
    if (_capturedBytes == null) {
      setState(() => _error = "Please capture a photo");
      return;
    }

    final idInfo = _parseSouthAfricanID(_idController.text.trim());
    if (idInfo == null) {
      setState(() => _error = "Invalid ID number or under 18");
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final payload = {
      "employeeNumber": _employeeController.text.trim(),
      "idNumber": _idController.text.trim(),
      "gender": idInfo['gender'],
      "citizenship": idInfo['citizenship'],
      "dob": idInfo['dob'],
      "age": idInfo['age'],
      "department": _selectedDepartment,
      "contract": _selectedContract,
      "ProfileImageBase64": base64Encode(_capturedBytes!),
    };

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/api/home/addlog"),
        headers: {
          "Content-Type": "application/json",
          "token": _token!,
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Home_Screen()),
        );
      } else {
        setState(() => _error =
            "Submission failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      setState(() => _error = "Submission failed: $e");
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _idController.dispose();
    _videoElement?.srcObject?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: kPrimaryGreen,
          automaticallyImplyLeading: false,
          title: const Text(
            "Verification Request",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Home_Screen()));
            },
          ),
          
        ),
        endDrawer: buildProfessionalDrawer(
          context,
          userName,
          userSurname,
          userUid,
          userPhotoUrl,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personnel Information',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(height: 20, thickness: 1),
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration(
                                    'Department', Icons.business),
                                value: _selectedDepartment,
                                items: _departments
                                    .map((d) => DropdownMenuItem(
                                        value: d, child: Text(d)))
                                    .toList(),
                                onChanged: (val) => setState(() {
                                  _selectedDepartment = val;
                                }),
                                validator: (val) =>
                                    val == null ? 'Select department' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _employeeController,
                                decoration: _inputDecoration(
                                    'Employee Number', Icons.badge),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _idController,
                                decoration: _inputDecoration(
                                    'ID Number (SA)', Icons.credit_card),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Required';
                                  if (_parseSouthAfricanID(v.trim()) == null) {
                                    return 'Invalid South African ID or under 18';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Photo capture card...
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Profile Photo Capture',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(height: 20, thickness: 1),
                              const SizedBox(height: 10),
                              if (_capturedBytes != null)
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: kPrimaryGreen, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.memory(
                                          _capturedBytes!,
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _retakeImage,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Retake Photo"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryGreen,
                                          foregroundColor: Colors.white),
                                    ),
                                  ],
                                )
                              else if (!_cameraStarted)
                                ElevatedButton.icon(
                                  onPressed: _startCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text("Start Camera"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryGreen,
                                      foregroundColor: Colors.white),
                                )
                              else
                                Column(
                                  children: [
                                    Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: _primaryColor, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8)),
                                        child: HtmlElementView(
                                            viewType: 'videoElementVerify'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _captureImage,
                                      icon: const Icon(Icons.camera),
                                      label: const Text("Capture Photo"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryGreen,
                                          foregroundColor: Colors.white),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text(
                          "Submit Verification",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.green, width: 2.0),
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

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Logged out successfully")),
  );
}


const Color kPrimaryGreen = Color(0xFF006400);
const Color kLightGreen = Color(0xFFE8F5E9);
const Color kAccentColor = Color(0xFF4CAF50);
Widget buildProfessionalDrawer(
  BuildContext context,
  String? name,
  String? surname,
  String? personnel,
  String? photoUrl,
) {
  final displayName =
      "${name ?? ''} ${surname ?? ''}".trim().isEmpty ? "Employee Name" : "${name ?? ''} ${surname ?? ''}";
  final displayId = personnel ?? 'ID: N/A';
  final displayPhotoUrl = photoUrl ?? '';

  void navigateToProfile() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Profile_Screen()),
    );
  }


  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(displayId, style: const TextStyle(color: Colors.white70)),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: (displayPhotoUrl.isNotEmpty)
                  ? Image.network(
                      displayPhotoUrl,
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: kPrimaryGreen, size: 40),
                    )
                  : const Icon(Icons.person, color: kPrimaryGreen, size: 40),
            ),
          ),
          decoration: const BoxDecoration(color: kPrimaryGreen),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline, color: kPrimaryGreen),
          title: const Text('My Profile', style: TextStyle(fontSize: 16)),
          onTap: navigateToProfile,
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: kPrimaryGreen),
          title: const Text('Help & Support', style: TextStyle(fontSize: 16)),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: kPrimaryGreen),
          title: const Text('About Us', style: TextStyle(fontSize: 16)),
          onTap: () => Navigator.pop(context),
        ),
        const Divider(color: Colors.black12, height: 30),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
  onTap: () => _logout(context),
        ),
      ],
    ),
  );
}
