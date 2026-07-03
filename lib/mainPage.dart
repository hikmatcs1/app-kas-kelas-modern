import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final box = GetStorage();
              box.remove('isLoggedIn');
              box.remove('userId');
              box.remove('nama');
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final namaUser = box.read('nama') ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC), 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, namaUser),
            const SizedBox(height: 20),
            Expanded(
              child: _buildMenuGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String nama) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0), 
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $nama!', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Dashboard SISE006',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _logout(context),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      crossAxisCount: 2, 
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9, 
      children: [
        _buildMenuCard(
          context: context,
          title: 'Laporan Kas',
          icon: Icons.account_balance_wallet_rounded,
          gradientColors: [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
          onTap: () => Navigator.pushNamed(context, '/kas'),
        ),
        _buildMenuCard(
          context: context,
          title: 'Laporan Tugas',
          icon: Icons.assignment_turned_in_rounded,
          gradientColors: [const Color(0xFFFFCA28), const Color(0xFFF9A825)],
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu Laporan Tugas belum diintegrasikan')));
          },
        ),
        _buildMenuCard(
          context: context,
          title: 'Laporan Proyek',
          icon: Icons.rocket_launch_rounded,
          gradientColors: [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)],
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu Laporan Proyek belum diintegrasikan')));
          },
        ),
        _buildMenuCard(
          context: context,
          title: 'Jadwal Kuliah',
          icon: Icons.calendar_month_rounded,
          gradientColors: [const Color(0xFF66BB6A), const Color(0xFF2E7D32)],
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu Jadwal Kuliah belum diintegrasikan')));
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: gradientColors[1].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: Colors.white, size: 36),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}