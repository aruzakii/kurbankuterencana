import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kurbanku_terencana/providers/prediksi_provider.dart';
import 'package:provider/provider.dart';
import 'package:kurbanku_terencana/screens/dashboard_screen.dart';
import 'package:kurbanku_terencana/screens/register_screen.dart';
import 'package:kurbanku_terencana/screens/login_screen.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'providers/hewan_kurban_provider.dart';
import 'providers/penjualan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HewanKurbanProvider()),
        ChangeNotifierProvider(create: (_) => PenjualanProvider()),
        ChangeNotifierProvider(create: (_) => PrediksiProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KurbankuTerencana',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}