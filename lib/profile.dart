import 'dart:convert';

import 'package:bee_care/ai_model.dart' show BeeHealthAnalyzerPage;
import 'package:bee_care/editprofile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AaccountPage extends StatefulWidget {
  const AaccountPage({super.key});

  @override
  State<AaccountPage> createState() => _AaccountPageState();
}

class _AaccountPageState extends State<AaccountPage> {
  String fullName = '';
  String email = '';
  String phone = '';
  String city = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      fullName = prefs.getString('username') ?? 'No Name';
      email = prefs.getString('email') ?? 'No Email';
      phone = prefs.getString('phone') ?? 'No Phone';
      city = prefs.getString('wilaya_name') ?? 'No City';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Text(
                  'تسجيل الدخول    Profile ',
                  style: GoogleFonts.cairo(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _profileItem(icon: Icons.person, title: 'Full Name', value: fullName),
                  _profileItem(icon: Icons.email, title: 'Email', value: email),
                  _profileItem(icon: Icons.phone, title: 'Phone', value: phone),
                  _profileItem(icon: Icons.location_city, title: 'City', value: city),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => EditProfilePage()
  ),
);
                      // Handle edit profile
                    },
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: GestureDetector(
  onTap: () async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+213697124211');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print("Cannot launch phone dialer");
    }
  },
  child: Text(
    'للدعم الفني أو حل أي تساؤل تواصل معنا من هنا',
    textAlign: TextAlign.center,
    style: GoogleFonts.cairo(
      fontSize: 18,
      decoration: TextDecoration.underline,  // Optional: makes it look clickable
    ),
  ),
) ,


                  ),
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: GestureDetector(
  onTap: () async {
   Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => BeeHealthAnalyzerPage()),
);
  },
  child: Text(
    'يمكنك استخدام الذكاء الاصطناعي في مشروعك لأتمتة المهام، وتحليل البيانات، وتحسين الأداء',
    textAlign: TextAlign.center,
    style: GoogleFonts.cairo(
      fontSize: 18,
      decoration: TextDecoration.underline,  // Optional: makes it look clickable
    ),
  ),
) ,


                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}





Future<void> logout(BuildContext context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final url = Uri.parse("http://192.168.15.125:8000/api/auth/logout/");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    // Clear tokens and user data
    await prefs.remove('access_token');
    await prefs.remove('refresh_token'); // if exists
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('phone');

    if (response.statusCode == 200) {
      // Redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'فشل تسجيل الخروج')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
    );
    print('Logout error: $e');
  }
}
