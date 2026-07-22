import 'package:flutter/material.dart';
import 'package:leavesystem/screens/login.dart';
import 'dart:async'; // Required for Future.delayed

// Define a consistent corporate green color
const Color kPrimaryGreen = Color(0xFF006400); 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    // Navigate using pushReplacement to prevent the user from going back to the splash screen
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      // Use a clean, light background color
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            // 1. Logo/Image with refined size and style
            Image.asset(
              // **IMPORTANT: Ensure this asset is registered in pubspec.yaml**
              "images/thumb_national_treasury.png",
              width: 250.0, // Slightly smaller for better focus
              height: 250.0,
              fit: BoxFit.contain,
            ),
            
            const SizedBox(height: 30), // Increased spacing
            
            // 2. Title Text with professional styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Employee Verification System", // Clearer, professional title
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kPrimaryGreen, // Use the corporate green
                  fontWeight: FontWeight.bold,
                  fontSize: 28, // Slightly larger
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            // 3. Subtitle for context
            const Text(
              "Your secure digital verification platform",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 50),

            // 4. Subtle Loading Indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: kPrimaryGreen, // The corporate green color
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}