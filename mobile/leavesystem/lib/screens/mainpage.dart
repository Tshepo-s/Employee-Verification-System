import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String response = "";

  Future<void> getApiResponse() async {
    // Use LAN IP or localhost depending on where browser runs
final url = Uri.parse("http://localhost:5000/api/home");

    try {
      final result = await http.get(url, headers: {
        'content-type': 'application/json',
      });

      if (result.statusCode >= 200 && result.statusCode <= 299) {
        setState(() {
          response = result.body;
        });
      } else {
        setState(() {
          response = "Error: ${result.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        response = "Exception: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getApiResponse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(response)),
    );
  }
}
