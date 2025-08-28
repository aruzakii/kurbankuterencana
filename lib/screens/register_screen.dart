import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kurbanku_terencana/widgets/reusable_widgets.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final Color primaryColor = const Color(0xFF6B7280); // Hijau Zaitun
  final Color secondaryColor = const Color(0xFF8B4513); // Cokelat Tanah
  final Color accentColor = const Color(0xFFFFD700); // Emas Lembut
  final Color surfaceColor = const Color(0xFF4A4A4A); // Abu-abu Tua
  final Color backgroundColor = const Color(0xFF1A202C); // Hitam Pekat

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final userId = userCredential.user!.uid;

        // Simpan data ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi berhasil! Selamat Datang'),
            backgroundColor: secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi gagal, periksa data Anda'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, surfaceColor, primaryColor.withOpacity(0.1)],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  AnimatedLogo(
                    assetPath: 'assets/logo_kurbanku_terencana.png', // Logo baru
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'KurbankuTerencana',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buat akun baru Anda',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            labelText: 'Nama Bisnis',
                            prefixIcon: Icons.person_outline,
                            validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            validator: (value) => value!.isEmpty
                                ? 'Email wajib diisi'
                                : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)
                                ? 'Email tidak valid'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            isPassword: true,
                            validator: (value) => value!.isEmpty
                                ? 'Password wajib diisi'
                                : value.length < 6
                                ? 'Password minimal 6 karakter'
                                : null,
                            onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Konfirmasi Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            isPassword: true,
                            validator: (value) => value!.isEmpty
                                ? 'Konfirmasi password wajib diisi'
                                : value != _passwordController.text
                                ? 'Password tidak cocok'
                                : null,
                            onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            onPressed: _register,
                            text: 'Daftar',
                            isLoading: _isLoading,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah punya akun? ',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: GoogleFonts.inter(color: accentColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}