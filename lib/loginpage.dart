import 'package:bee_care/homepage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  // API: LOGIN
  Future<Map<String, dynamic>> loginRequest(String email, String password) async {
    final Uri url = Uri.parse("http://192.168.15.125:8000/api/auth/login/"); 

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Wrong email or password");
    }
  }

  // Save token + user info
  Future<void> saveLoginData(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("access_token", json["tokens"]["access"]);
    await prefs.setString("id", json["user"]["id"]);

    await prefs.setString("refresh_token", json["tokens"]["refresh"]);
    await prefs.setString("username", json["user"]["username"]);
    await prefs.setString("email", json["user"]["email"]);
    await prefs.setString("wilaya_code", json["user"]["wilaya_code"]);
    await prefs.setString("wilaya_name", json["user"]["wilaya_name"]);
    await prefs.setString("phone", json["user"]["phone"]);
  }

  // LOGIN PROCESS
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final data = await loginRequest(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      await saveLoginData(data);

      // After success → Go to home
     final prefs = await SharedPreferences.getInstance();
String username = prefs.getString("username") ?? "User";

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => HomePage(username: username),
  ),
);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Arabic
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "تسجيل الدخول",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "البريد الإلكتروني",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "البريد مطلوب";
                      if (!value.contains("@")) return "بريد غير صالح";
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "كلمة المرور",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "كلمة المرور مطلوبة" : null,
                  ),

                  const SizedBox(height: 30),

                  // Button or loader
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80, vertical: 15),
                          ),
                          child: const Text(
                            "دخول",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, "/signup"),
                    child: const Text(
                      "ليس لديك حساب؟ إنشاء حساب",
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
