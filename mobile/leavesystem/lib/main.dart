// why: central entry point; AuthGate decides one-time form vs status page using server-side flag.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leavesystem/screens/hr_dash.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:leavesystem/screens/mainpage.dart';
import 'package:leavesystem/screens/one_time_form.dart';
import 'package:leavesystem/screens/status_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leavesystem/splash_screen/splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leave System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home:SplashScreen() ,//LoginScreen()
      //routes: {
      //  '/login': (_) => LoginScreen(),
      //},
   );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<DocumentSnapshot<Map<String, dynamic>>?>? _userDocFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDocFuture ??= FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.active) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) {
          return LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          future: _userDocFuture,
          builder: (context, docSnap) {
            if (docSnap.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = docSnap.data?.data() ?? {};
            final admin = data['isAdmin'] == true || data['isAdmin']?.toString() == 'true';
            final completed = data['profileCompleted'] == true || data['profileCompleted']?.toString() == 'true';

            if (admin) {
              return AdminDashboardScreen();
            }
            if (completed) {
              return StatusPage(uid: user.uid);
            }
            return OneTimeForm(uid: user.uid);
          },
        );
      },
    );
  }
}


