import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavesystem/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // form controllers & state
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;
  final _idController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _personelController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedContract;
  String? _selectedGender;
  Uint8List? _capturedBytes;
  bool _popiaConsent = false;

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

  html.VideoElement? _videoElement;
  bool _cameraStarted = false;

  html.CanvasElement? _analyzeCanvas; // offscreen canvas used to sample frames
  html.ImageData? _previousFrameData;
  Timer? _motionTimer;
  bool _isLive = false; // final liveness result used on capture

  // Tuning constants; change if too sensitive/insensitive.
  final double _motionThreshold = 12.0; // average RGB diff per pixel to consider "motion"
  final int _requiredMotionFrames = 3; // consecutive samples above threshold to mark live
  final int _sampleIntervalMs = 200; // how often we sample frames (200ms → 5 FPS)
  final int _pixelStep = 8; // step over pixels for faster compute; increase for speed
  int _motionCounter = 0;
  int _stillCounter = 0;
  final int _stillLimit = 45; // if too many still samples, consider not-live

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() == true &&
          _selectedDepartment != null &&
          _selectedContract != null &&
          _selectedGender != null &&
          _capturedBytes != null &&
          _popiaConsent;
    });
  }

  void _startCamera() {
    if (_cameraStarted) return;

    // create video element; id is optional here but helpful for debugging
    _videoElement = html.VideoElement()
      ..id = 'registerVideoElement'
      ..width = 320
      ..height = 240
      ..autoplay = true
      ..style.objectFit = 'cover';
/**
    // register view so Flutter can render the video element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'registerVideoElement',
      (int viewId) => _videoElement!,
    );
    */

    // request camera
    html.window.navigator.mediaDevices?.getUserMedia({'video': true}).then(
      (stream) {
        _videoElement!.srcObject = stream;
        _cameraStarted = true;
        setState(() {});
        _startMotionDetection();
      },
    ).catchError((e) {
      debugPrint("Camera error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    });
  }

  void _stopCameraAndDetection() {
    try {
      _videoElement?.srcObject?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _motionTimer?.cancel();
    _motionTimer = null;
    _previousFrameData = null;
    _analyzeCanvas = null;
    _cameraStarted = false;
    _isLive = false;
    _motionCounter = 0;
    _stillCounter = 0;
    setState(() {});
  }

  // Start periodic sampling of video frames; compute frame-difference motion score.
  void _startMotionDetection() {
    // ensure analyzer canvas exists and matches video size
    _analyzeCanvas = html.CanvasElement(width: _videoElement!.videoWidth == 0 ? 320 : _videoElement!.videoWidth,
        height: _videoElement!.videoHeight == 0 ? 240 : _videoElement!.videoHeight);

    // safety: if width/height not ready yet, wait a short moment.
    if (_videoElement!.videoWidth == 0 || _videoElement!.videoHeight == 0) {
      Future.delayed(const Duration(milliseconds: 250), _startMotionDetection);
      return;
    }

    _analyzeCanvas!.width = _videoElement!.videoWidth;
    _analyzeCanvas!.height = _videoElement!.videoHeight;

    // sample loop
    _motionTimer?.cancel();
    _motionTimer = Timer.periodic(Duration(milliseconds: _sampleIntervalMs), (_) {
      _analyzeFrame();
    });
  }

  // Analyze a single frame; compare to previous frame using a subsampled pixel grid.
  void _analyzeFrame() {
    if (_analyzeCanvas == null || _videoElement == null) return;
    final ctx = _analyzeCanvas!.context2D;

    // draw current video frame into canvas; this makes pixel data available
    ctx.drawImageScaled(_videoElement!, 0, 0, _analyzeCanvas!.width!, _analyzeCanvas!.height!);

    // pull pixel data
    final imgData = ctx.getImageData(0, 0, _analyzeCanvas!.width!, _analyzeCanvas!.height!);

    // if no previous frame, store and wait for next sample
    if (_previousFrameData == null) {
      _previousFrameData = imgData;
      _isLive = false;
      _motionCounter = 0;
      _stillCounter = 0;
      setState(() {});
      return;
    }

    final cur = imgData.data;
    final prev = _previousFrameData!.data;
    final int width = imgData.width!;
    final int height = imgData.height!;
    double totalDiff = 0;
    int count = 0;

    // iterate with a step to reduce computation; compare RGB channels only
    final int step = _pixelStep * 4; // 4 bytes per pixel (RGBA)
    for (int i = 0; i < cur.length; i += step) {
      final int rCur = cur[i];
      final int gCur = cur[i + 1];
      final int bCur = cur[i + 2];

      final int rPrev = prev[i];
      final int gPrev = prev[i + 1];
      final int bPrev = prev[i + 2];

final double pixelDiff = ((rCur.toDouble() - rPrev.toDouble()).abs()) +
    ((gCur.toDouble() - gPrev.toDouble()).abs()) +
    ((bCur.toDouble() - bPrev.toDouble()).abs());
      totalDiff += pixelDiff / 3.0; // normalize per-channel
      count++;
    }

    final double avgDiff = count > 0 ? totalDiff / count : 0.0;

    if (avgDiff > _motionThreshold) {
      _motionCounter++;
      _stillCounter = 0;
    } else {
      _stillCounter++;
      _motionCounter = 0;
    }

    if (_motionCounter >= _requiredMotionFrames) {
      _isLive = true; 
    }

    if (_stillCounter >= _stillLimit) {
      _isLive = false; 
    }

    _previousFrameData = imgData;

    setState(() {}); 
  }

  Future<void> _captureImage() async {
    if (_videoElement == null || _videoElement!.videoWidth == 0) return;

    if (!_isLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Liveness check failed — move your head or blink then try again")),
      );
      return;
    }

    final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth, height: _videoElement!.videoHeight);
    canvas.context2D.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    final bytes = base64Decode(dataUrl.split(',').last);

    setState(() {
      _capturedBytes = Uint8List.fromList(bytes);
    });

    _stopCameraAndDetection();
    _checkFormValidity();
  }

  void _retakeImage() {
    setState(() {
      _capturedBytes = null;
    });
    _startCamera();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture a verification photo first")),
      );
      return;
    }

    final registerData = {
      "FirstName": _firstnameController.text.trim(),
      "Surname": _surnameController.text.trim(),
      "EmailAddress": _emailController.text.trim(),
      "Password": _passwordController.text.trim(),
      "EmployeeNumber": _personelController.text.trim(),
      "IdNumber": _idController.text.trim(),
      "Department": _selectedDepartment,
      "Contract": _selectedContract,
      "Gender": _selectedGender,
      "ProfileImageBase64": base64Encode(_capturedBytes!),
      "POPIAConsent": _popiaConsent.toString(),
    };

    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/api/home/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(registerData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful")),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration failed: ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
      debugPrint("Registration error: $e");
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _firstnameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _personelController.dispose();
    _passwordController.dispose();
    _stopCameraAndDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF006400);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: kPrimaryGreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70.0),
                      child: Image.asset(
                        "images/thumb_2_treasury.png",
                        width: 310.0,
                        height: 310.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Welcome to our home",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Center(
                          child: Text(
                            "Register a new account",
                            style: TextStyle(
                              color: kPrimaryGreen,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(_firstnameController, 'First Name'),
                        _buildTextField(_surnameController, 'Surname'),
                        _buildTextField(_emailController, 'Email',
                            validator: (v) => v!.contains('@') ? null : 'Invalid email'),
                        _buildTextField(_passwordController, 'Password',
                            obscure: true,
                            validator: (v) => (v!.length >= 8 && v.contains('@'))
                                ? null
                                : 'Password must be 8+ chars and include @'),
                        _buildTextField(_idController, 'ID Number'),
                        _buildTextField(_personelController, 'Employee Number'),
                        _buildDropdown('Department', _departments, _selectedDepartment,
                            (v) => setState(() => _selectedDepartment = v)),
                        _buildDropdown('Contract', _contracts, _selectedContract,
                            (v) => setState(() => _selectedContract = v)),
                        _buildDropdown('Gender', _genders, _selectedGender,
                            (v) => setState(() => _selectedGender = v)),
                        const SizedBox(height: 25),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  "Live Photo Verification",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                                ),
                                const SizedBox(height: 10),
                                // indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _isLive ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_isLive ? 'Live detected' : 'No motion detected'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_capturedBytes != null)
                                  Column(
                                    children: [
                                      Image.memory(_capturedBytes!, width: 250, height: 250, fit: BoxFit.cover),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _retakeImage,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text("Retake Photo"),
                                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                                      ),
                                    ],
                                  )
                                else if (!_cameraStarted)
                                  ElevatedButton.icon(
                                    onPressed: _startCamera,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text("Start Camera"),
                                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                                  )
                                else
                                  Column(
                                    children: [
                                      Container(
                                        width: 250,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: kPrimaryGreen, width: 2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          child: HtmlElementView(viewType: 'registerVideoElement'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _captureImage,
                                        icon: const Icon(Icons.camera),
                                        label: const Text("Capture Verification"),
                                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _popiaConsent,
                              onChanged: (val) {
                                setState(() {
                                  _popiaConsent = val ?? false;
                                  _checkFormValidity();
                                });
                              },
                            ),
                            const Expanded(child: Text("I agree to the POPIA terms and conditions")),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isFormValid ? _submitForm : null,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                          child: const Text("Register"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? Function(String?)? validator, bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? "$label is required" : null,
      onChanged: (_) => _checkFormValidity(),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: selectedValue,
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (val) {
        onChanged(val);
        _checkFormValidity();
      },
      validator: (val) => val == null ? "Select $label" : null,
    );
  }
}
