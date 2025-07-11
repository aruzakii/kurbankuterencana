import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:kurbanku_terencana/screens/dashboard_screen.dart';
import 'package:kurbanku_terencana/screens/stok_screen.dart';
import 'package:kurbanku_terencana/screens/sales_screen.dart';
import 'package:kurbanku_terencana/screens/transaction_screen.dart';
import 'package:kurbanku_terencana/providers/hewan_kurban_provider.dart';
import 'package:kurbanku_terencana/providers/penjualan_provider.dart';
import 'package:kurbanku_terencana/providers/prediksi_provider.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF6B7280);
  final Color secondaryColor = const Color(0xFF8B4513);
  final Color accentColor = const Color(0xFFFFD700);
  final Color surfaceColor = const Color(0xFF4A4A4A);
  final Color backgroundColor = const Color(0xFF1A202C);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  bool _isInitializing = true;

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    StokScreen(),
    SalesScreen(),
    TransactionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      print('Memulai inisialisasi data...');

      final penjualanProvider = Provider.of<PenjualanProvider>(context, listen: false);
      final prediksiProvider = Provider.of<PrediksiProvider>(context, listen: false);

      await penjualanProvider.fetchPenjualan();
      print('Data penjualan diambil: ${penjualanProvider.penjualanList.length} item');
      print('Data hewan kurban diambil: ${penjualanProvider.hewanKurbanList.length} item');

      await Future.delayed(const Duration(milliseconds: 500));

      await prediksiProvider.generatePrediksi(
        penjualanProvider,
        selectedPeriode: 'tahun_depan',
        selectedJenisHewan: 'Semua',
      );
      print('Prediksi berhasil dibuat');
    } catch (e) {
      print('Error saat inisialisasi data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout gagal: $e'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'KurbankuTerencana',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
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
          child: _isInitializing ? _buildLoadingScreen() : _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Transaksi',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: backgroundColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}