import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('username') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _isLoadingData = false;
    });
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check password confirmation if password is being changed
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog('كلمات المرور غير متطابقة');
        return;
      }
      if (_passwordController.text.length < 6) {
        _showErrorDialog('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse("http://ip:8000/api/auth/profile/update/");
      
      Map<String, dynamic> requestData = {
        'username': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Only include password if it's not empty
      if (_passwordController.text.isNotEmpty) {
        requestData['password'] = _passwordController.text;
      }

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update SharedPreferences
        await prefs.setString('username', data['username'] ?? _fullNameController.text);
        await prefs.setString('email', data['email'] ?? _emailController.text);
        await prefs.setString('phone', data['phone'] ?? _phoneController.text);

        _showSuccessDialog('تم تحديث الملف الشخصي بنجاح');
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'فشل تحديث الملف الشخصي';
        
        if (errorData is Map) {
          // Extract first error message
          if (errorData.containsKey('username')) {
            errorMessage = 'خطأ في الاسم: ${errorData['username'][0]}';
          } else if (errorData.containsKey('email')) {
            errorMessage = 'خطأ في البريد: ${errorData['email'][0]}';
          } else if (errorData.containsKey('phone')) {
            errorMessage = 'خطأ في الهاتف: ${errorData['phone'][0]}';
          } else if (errorData.containsKey('password')) {
            errorMessage = 'خطأ في كلمة المرور: ${errorData['password'][0]}';
          } else {
            errorMessage = errorData.values.first.toString();
          }
        }
        
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('حدث خطأ في الاتصال بالخادم');
      print("Error updating profile: $e");
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text('نجح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: GoogleFonts.cairo(fontSize: 16)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Go back with success result
              },
              child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text('خطأ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: GoogleFonts.cairo(fontSize: 16)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'الاسم الكامل',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'الرجاء إدخال الاسم';
                                }
                                if (value.trim().length < 3) {
                                  return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'الرجاء إدخال البريد الإلكتروني';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'البريد الإلكتروني غير صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'رقم الهاتف',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'الرجاء إدخال رقم الهاتف';
                                }
                                if (value.trim().length < 10) {
                                  return 'رقم الهاتف غير صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            const SizedBox(height: 10),
                            Text(
                              'تغيير كلمة المرور (اختياري)',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'كلمة المرور الجديدة',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (_passwordController.text.isNotEmpty)
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'تأكيد كلمة المرور',
                                icon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (_passwordController.text.isNotEmpty &&
                                      value != _passwordController.text) {
                                    return 'كلمات المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 30),
                            _isLoading
                                ? const CircularProgressIndicator(color: Colors.orange)
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      minimumSize: const Size(double.infinity, 55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 3,
                                    ),
                                    onPressed: updateProfile,
                                    child: Text(
                                      'حفظ التغييرات',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
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

  Widget _header() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'تعديل الملف الشخصي',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // Balance the layout
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textAlign: TextAlign.right,
        validator: validator,
        style: GoogleFonts.cairo(fontSize: 16),
        onChanged: (value) {
          // Trigger rebuild to show/hide confirm password field
          if (controller == _passwordController) {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.orange),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
