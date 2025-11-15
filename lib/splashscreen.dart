import 'package:bee_care/homepage.dart';
import 'package:bee_care/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('access_token');

    await Future.delayed(const Duration(seconds: 2)); // splash duration

    if (token != null && token.isNotEmpty) {
      // User already logged in
           final prefs = await SharedPreferences.getInstance();
String username = prefs.getString("username") ?? "User";

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => HomePage(username: username),
  ),
);
    } else {
      // No token → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );
  }
}
