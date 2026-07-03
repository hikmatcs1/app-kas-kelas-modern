import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'login.dart';
import 'mainPage.dart';
import 'mahasiswaPage.dart';   // ← Tambahkan import ini
import 'kasPage.dart';         // Jika masih digunakan

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final bool isLoggedIn = box.read('isLoggedIn') ?? false;
    final String? role = box.read('role');   // Ambil role user

    return MaterialApp(
      title: 'Kas Kelas SISE006',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      // Tentukan halaman awal berdasarkan status login dan role
      initialRoute: _getInitialRoute(isLoggedIn, role),
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const MainPage(),           // Untuk Admin
        '/mahasiswa': (context) => const MahasiswaPage(), // Untuk Mahasiswa
        '/kas': (context) => const KasPage(),
      },
    );
  }

  // Helper untuk menentukan halaman awal
  String _getInitialRoute(bool isLoggedIn, String? role) {
    if (!isLoggedIn) {
      return '/login';
    }
    return (role == 'admin') ? '/home' : '/mahasiswa';
  }
}