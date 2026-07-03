import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class HFCColors {
  // Biru sebagai warna utama (header, tombol, aksi penting)
  static const red = Color(0xFF1565C0);
  static const redLight = Color(0xFFE3F2FD);

  // Kuning sebagai warna aksen (label, tombol edit)
  static const orange = Color(0xFFF9A825);
  static const orangeLight = Color(0xFFFFF8E1);
  static const orangeMid = Color(0xFFFFCA28);
  static const yellow = Color(0xFFFBC02D);
  static const yellowMid = Color(0xFFFFCA28);
  static const yellowSoft = Color(0xFFFFFDE7);

  // Putih sebagai warna dasar/background
  static const surface = Color(0xFFF4F8FC);
  static const white = Color(0xFFFFFFFF);

  // Hijau untuk pemasukan
  static const greenText = Color(0xFF2E7D32);
  static const greenPill = Color(0xE6E8F5E9);

  // Merah Asli untuk pengeluaran & icon hapus
  static const expenseRed = Color(0xFFD32F2F);
  static const expenseRedLight = Color(0xFFFFEBEE);
  static const expenseRedPill = Color(0xFFFFEBEE);
}

class Transaction {
  final String id;
  final String tanggal;
  final String jenis;
  final double jumlah;
  final String keterangan;

  Transaction({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.jumlah,
    required this.keterangan,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      tanggal: json['tanggal'].toString(),
      jenis: json['jenis'] ?? '',
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0,
      keterangan: json['keterangan'] ?? '',
    );
  }
}

/// Halaman Laporan Kas KHUSUS untuk role mahasiswa.
/// Read-only: tidak ada tombol tambah, edit, maupun hapus data,
/// karena hanya admin/bendahara yang boleh mengubah data kas.
class KasMhs extends StatefulWidget {
  const KasMhs({super.key});

  @override
  State<KasMhs> createState() => _KasMhsState();
}

class _KasMhsState extends State<KasMhs> {
  // 10.0.2.2 = alias localhost laptop kalau testing pakai EMULATOR Android Studio.
  // Kalau nanti testing di HP FISIK, ganti ke IP WiFi laptop (cek via ipconfig),
  // dan pastikan HP & laptop terhubung ke WiFi yang sama.
  static const String _baseUrl =
      'http://10.206.53.252/app_kaskelas_api/catatan_kas.php';

  bool _isLoading = false;
  final List<Transaction> _list = [];

  // ── Computed ──────────────────────────────────────────────────────────────

  double get _totalPemasukan => _list
      .where((t) => t.jenis.toLowerCase() == 'pemasukan')
      .fold(0, (s, t) => s + t.jumlah);

  double get _totalPengeluaran => _list
      .where((t) => t.jenis.toLowerCase() == 'pengeluaran')
      .fold(0, (s, t) => s + t.jumlah);

  double get _saldo => _totalPemasukan - _totalPengeluaran;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));
      debugPrint('Kas response (${res.statusCode}): ${res.body}');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _list.clear();
          _list.addAll(data.map((e) => Transaction.fromJson(e)));
        });
      } else {
        _snack('Gagal memuat data (status ${res.statusCode})');
      }
    } catch (e) {
      _snack('Gagal memuat data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatRupiah(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : HFCColors.expenseRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HFCColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: HFCColors.red),
                    )
                  : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _fetchData,
                            icon: const Icon(
                              Icons.refresh,
                              size: 16,
                              color: HFCColors.red,
                            ),
                            label: const Text(
                              'Muat Ulang',
                              style: TextStyle(color: HFCColors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: HFCColors.red,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildTile(_list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Tidak ada FloatingActionButton -> mahasiswa tidak bisa tambah data.
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(color: HFCColors.red),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kas Kelas SISE006 (Mahasiswa)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _fetchData,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Total Saldo',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(_saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPill('↑ Pemasukan', _totalPemasukan, true)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPill('↓ Pengeluaran', _totalPengeluaran, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, double amount, bool isPemasukan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPemasukan ? HFCColors.greenPill : HFCColors.expenseRedPill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isPemasukan ? HFCColors.greenText : HFCColors.expenseRed,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(amount),
            style: TextStyle(
              color: isPemasukan ? HFCColors.greenText : HFCColors.expenseRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tile ──────────────────────────────────────────────────────────────────
  // Catatan: tidak ada ikon edit/hapus di sini secara sengaja,
  // karena mahasiswa hanya boleh melihat (read-only), bukan mengubah data.

  Widget _buildTile(Transaction t) {
    final isPemasukan = t.jenis.toLowerCase() == 'pemasukan';

    final color = isPemasukan ? HFCColors.greenText : HFCColors.expenseRed;
    final bgIcon = isPemasukan
        ? HFCColors.greenPill
        : HFCColors.expenseRedLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HFCColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPemasukan
              ? HFCColors.greenText.withOpacity(0.1)
              : HFCColors.expenseRed.withOpacity(0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgIcon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPemasukan
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.keterangan,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  t.tanggal,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPemasukan ? '+' : '-'}${_formatRupiah(t.jumlah)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          // Ikon Edit dan Hapus sengaja tidak ada di sini.
        ],
      ),
    );
  }
}