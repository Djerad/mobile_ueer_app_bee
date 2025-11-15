import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'loginpage.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController wilayaCodeController = TextEditingController();
  final TextEditingController wilayaNameController = TextEditingController();

  final Color mainColor = Color(0xFFFBAD04);

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    wilayaCodeController.dispose();
    wilayaNameController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, String> body = {
      "username": usernameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "password_confirm": confirmPasswordController.text.trim(),
      "phone": phoneController.text.trim(),
      "wilaya_code": wilayaCodeController.text.trim(),
      "wilaya_name": wilayaNameController.text.trim(),
    };

    final Uri url = Uri.parse("http://192.168.15.125:8000/api/auth/register/"); // Replace with your local IP

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء الحساب بنجاح!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        final Map<String, dynamic> res = jsonDecode(response.body);
        String error = res['error'] ?? res.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  image: DecorationImage(
                    image: AssetImage("assets/A.jpg"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      mainColor.withOpacity(0.6),
                      BlendMode.srcATop,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'مرحباً بك! الرجاء إنشاء حساب للمتابعة',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
                      ),
                      SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الالكتروني',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) return 'يرجى إدخال البريد الالكتروني';
                          final regex = RegExp(r'\S+@\S+\.\S+');
                          if (!regex.hasMatch(value)) return 'البريد الالكتروني غير صالح';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة السر',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) =>
                            value!.length < 6 ? 'كلمة السر يجب أن تكون 6 أحرف على الأقل' : null,
                      ),
                      SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة السر',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != passwordController.text) return 'كلمة السر غير متطابقة';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Phone
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                      ),
                      SizedBox(height: 20),

                      // Wilaya Code
                      TextFormField(
                        controller: wilayaCodeController,
                        decoration: InputDecoration(
                          labelText: 'رمز الولاية',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'يرجى إدخال رمز الولاية' : null,
                      ),
                      SizedBox(height: 20),

                      // Wilaya Name
                      TextFormField(
                        controller: wilayaNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الولاية',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'يرجى إدخال اسم الولاية' : null,
                      ),
                      SizedBox(height: 30),

                      // Signup button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _signup,
                          child: Text(
                            'إنشاء الحساب',
                            style: GoogleFonts.cairo(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Login redirect
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        child: Text(
                          'لديك حساب؟ تسجيل الدخول',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
