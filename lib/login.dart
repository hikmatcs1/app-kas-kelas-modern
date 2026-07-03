import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';        // Tambahkan ini
import 'package:app_kaskelas/mainPage.dart';
import 'package:app_kaskelas/mahasiswaPage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isLogin = true;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _konfirmasi_password = TextEditingController();
  final TextEditingController _kodeAkses = TextEditingController();

  // Ganti dengan endpoint login yang benar jika ada file terpisah
  final String apiUrl = 'http://10.206.53.252/app_kaskelas_api/catatan_kas.php';

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _saveUserData(Map<String, dynamic> userData) {
    final box = GetStorage();
    box.write('isLoggedIn', true);
    box.write('userId', userData['id']?.toString());
    box.write('nama', userData['nama'] ?? userData['username']);
    box.write('username', userData['username']);
    box.write('role', userData['role']);
    if (userData['nim'] != null) {
      box.write('nim', userData['nim']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
          child: Column(
            children: [
              Image.asset(
                'images/banner.png',
                width: double.infinity,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: inputBorder,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: inputBorder,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),

              if (!isLogin) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _konfirmasi_password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    border: inputBorder,
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _kodeAkses,
                  decoration: InputDecoration(
                    labelText: 'Kode Akses Admin (Opsional)',
                    border: inputBorder,
                    prefixIcon: const Icon(Icons.vpn_key),
                    hintText: 'Isi hanya jika anda bendahara',
                  ),
                ),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
                      _showErrorSnackBar('Username dan Password wajib diisi!');
                      return;
                    }

                    if (!isLogin && _konfirmasi_password.text.trim().isEmpty) {
                      _showErrorSnackBar('Konfirmasi Password wajib diisi!');
                      return;
                    }

                    try {
                      if (isLogin) {
                        // === LOGIN ===
                        final response = await http.post(
                          Uri.parse(apiUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'action': 'login',
                            'username': _username.text.trim(),
                            'password': _password.text,
                          }),
                        );

                        final result = jsonDecode(response.body);

                        if (result['status'] == 'sukses') {
                          final userData = result['data'];

                          if (userData != null) {
                            _saveUserData(userData);   // ← Simpan data ke GetStorage

                            if (userData['role'] == 'admin') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MainPage()),
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MahasiswaPage()),
                              );
                            }
                          }
                        } else {
                          _showErrorSnackBar(result['message'] ?? 'Login gagal');
                        }
                      } else {
                        // === REGISTRASI === (tetap sama)
                        if (_password.text != _konfirmasi_password.text) {
                          _showErrorSnackBar('Password tidak cocok!');
                          return;
                        }

                        final response = await http.post(
                          Uri.parse(apiUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'action': 'register',
                            'username': _username.text.trim(),
                            'password': _password.text,
                            'kode_akses': _kodeAkses.text,
                          }),
                        );

                        final result = jsonDecode(response.body);
                        if (result['status'] == 'sukses') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registrasi Berhasil! Silakan login.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() => isLogin = true);
                        } else {
                          _showErrorSnackBar(result['message'] ?? 'Registrasi gagal');
                        }
                      }
                    } catch (e) {
                      _showErrorSnackBar('Terjadi kesalahan koneksi: $e');
                    }
                  },
                  child: Text(isLogin ? 'LOGIN' : 'REGISTRASI'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? 'Belum punya akun? Registrasi'
                      : 'Sudah punya akun? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}