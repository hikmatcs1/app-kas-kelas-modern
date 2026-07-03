import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class HFCColors {
  static const bluePrimary = Color(0xFF1565C0);
  static const orange      = Color(0xFFF9A825);
  static const orangeLight = Color(0xFFFFF8E1);
  static const yellow      = Color(0xFFFBC02D);
  static const yellowSoft  = Color(0xFFFFFDE7);
  static const surface     = Color(0xFFF4F8FC);
  static const white       = Color(0xFFFFFFFF);
  
  // Hijau Utama Pemasukan
  static const greenText   = Color(0xFF2E7D32);
  static const greenPill   = Color(0xE6E8F5E9);
  
  // Merah Utama Pengeluaran
  static const expenseRed      = Color(0xFFD32F2F);
  static const expenseRedLight = Color(0xFFFFEBEE);
  static const expenseRedPill  = Color(0xFFFFEBEE);
}

class Transaction {
  final String id;
  final String tanggal;
  final String jenis;
  final double jumlah;
  final String keterangan;

  Transaction({
    required this.id, required this.tanggal, required this.jenis,
    required this.jumlah, required this.keterangan,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id         : json['id'].toString(),
      tanggal    : json['tanggal'].toString(),
      jenis      : json['jenis'] ?? '',
      jumlah     : double.tryParse(json['jumlah'].toString()) ?? 0,
      keterangan : json['keterangan'] ?? '',
    );
  }
}

class KasPage extends StatefulWidget {
  const KasPage({super.key});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  // 10.0.2.2 = alias localhost laptop kalau testing pakai EMULATOR Android Studio.
  // Kalau nanti testing di HP FISIK, ganti ke IP WiFi laptop (cek via ipconfig),
  // dan pastikan HP & laptop terhubung ke WiFi yang sama.
  static const String _baseUrl = 'http://10.206.53.252/app_kaskelas_api/catatan_kas.php';
  bool _isLoading = false;
  final List<Transaction> _list = [];

  double get _totalPemasukan => _list
      .where((t) => t.jenis.toLowerCase() == 'pemasukan')
      .fold(0, (s, t) => s + t.jumlah);

  double get _totalPengeluaran => _list
      .where((t) => t.jenis.toLowerCase() == 'pengeluaran')
      .fold(0, (s, t) => s + t.jumlah);

  double get _saldo => _totalPemasukan - _totalPengeluaran;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 10));
      debugPrint('GET Kas response (${res.statusCode}): ${res.body}');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _list.clear();
          _list.addAll(data.map((e) => Transaction.fromJson(e)));
        });
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      _snack('Gagal memuat data keuangan.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tambah(Map<String, String> body) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      debugPrint('POST tambah response (${res.statusCode}): ${res.body}');
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result['status'] == 'sukses') {
          _snack('Data berhasil disimpan', success: true);
          await _fetchData();
        } else {
          _snack(result['message'] ?? 'Gagal menyimpan');
        }
      } else {
        _snack('Server merespon status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Tambah error: $e');
      _snack('Koneksi terputus: $e');
    }
  }

  Future<void> _edit(Map<String, String> body) async {
    try {
      final res = await http.put(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      debugPrint('PUT edit response (${res.statusCode}): ${res.body}');
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result['status'] == 'sukses') {
          _snack('Data berhasil diupdate', success: true);
          await _fetchData();
        } else {
          _snack(result['message'] ?? 'Gagal mengupdate');
        }
      } else {
        _snack('Server merespon status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Edit error: $e');
      _snack('Koneksi terputus: $e');
    }
  }

  Future<void> _hapus(String id) async {
    try {
      final res = await http.delete(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      ).timeout(const Duration(seconds: 10));
      debugPrint('DELETE response (${res.statusCode}): ${res.body}');
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result['status'] == 'sukses') {
          _snack('Data berhasil dihapus', success: true);
          await _fetchData();
        } else {
          _snack(result['message'] ?? 'Gagal menghapus');
        }
      } else {
        _snack('Server merespon status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Hapus error: $e');
      _snack('Koneksi terputus: $e');
    }
  }

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? HFCColors.greenText : HFCColors.expenseRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showForm({Transaction? t}) {
    final isEdit = t != null;
    String selectedJenis = t?.jenis ?? 'Pemasukan';
    final jumlahCtrl = TextEditingController(text: isEdit ? t.jumlah.toStringAsFixed(0) : '');
    final keteranganCtrl = TextEditingController(text: isEdit ? t.keterangan : '');
    DateTime selectedTanggal = isEdit ? DateTime.tryParse(t.tanggal) ?? DateTime.now() : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 20, left: 16, right: 16),
            decoration: const BoxDecoration(color: HFCColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Jenis', style: TextStyle(fontSize: 11, color: HFCColors.orange, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: ['Pemasukan', 'Pengeluaran'].map((j) {
                    final isSelected = selectedJenis == j;
                    final isPemasukan = j == 'Pemasukan';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedJenis = j),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? (isPemasukan ? HFCColors.yellowSoft : HFCColors.expenseRedLight) : HFCColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? (isPemasukan ? HFCColors.yellow : HFCColors.expenseRed) : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isPemasukan ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 14, color: isSelected ? (isPemasukan ? HFCColors.yellow : HFCColors.expenseRed) : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(j, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? (isPemasukan ? HFCColors.yellow : HFCColors.expenseRed) : Colors.grey.shade700,
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Tanggal', style: TextStyle(fontSize: 11, color: HFCColors.orange, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx, initialDate: selectedTanggal,
                      firstDate: DateTime(2020), lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: HFCColors.bluePrimary)),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModalState(() => selectedTanggal = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: HFCColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, width: 0.8)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: HFCColors.bluePrimary, size: 18),
                        const SizedBox(width: 8),
                        Text('${selectedTanggal.year}-${selectedTanggal.month.toString().padLeft(2, '0')}-${selectedTanggal.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Jumlah', style: TextStyle(fontSize: 11, color: HFCColors.orange, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: jumlahCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rp ', hintText: '0', filled: true, fillColor: HFCColors.orangeLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Keterangan', style: TextStyle(fontSize: 11, color: HFCColors.orange, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: keteranganCtrl, maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Pembelian buku...', hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true, fillColor: HFCColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HFCColors.orange, width: 1.2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (jumlahCtrl.text.trim().isEmpty || keteranganCtrl.text.trim().isEmpty) {
                        _snack('Semua bidang formulir wajib diisi'); return;
                      }
                      final tanggalStr = '${selectedTanggal.year}-${selectedTanggal.month.toString().padLeft(2, '0')}-${selectedTanggal.day.toString().padLeft(2, '0')}';
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await _edit({'id': t.id, 'tanggal': tanggalStr, 'jenis': selectedJenis, 'jumlah': jumlahCtrl.text.trim(), 'keterangan': keteranganCtrl.text.trim()});
                      } else {
                        await _tambah({'tanggal': tanggalStr, 'jenis': selectedJenis, 'jumlah': jumlahCtrl.text.trim(), 'keterangan': keteranganCtrl.text.trim()});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HFCColors.bluePrimary, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _konfirmasiHapus(Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Hapus "${t.keterangan}"?', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
          ElevatedButton(
            onPressed: () async { Navigator.pop(ctx); await _hapus(t.id); },
            style: ElevatedButton.styleFrom(backgroundColor: HFCColors.expenseRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HFCColors.surface,
      appBar: AppBar(
        backgroundColor: HFCColors.bluePrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Catatan Kas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchData),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderInfo(),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator(color: HFCColors.bluePrimary))
                  : _list.isEmpty ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Belum ada transaksi', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _fetchData, icon: const Icon(Icons.refresh, size: 16, color: HFCColors.bluePrimary),
                            label: const Text('Muat Ulang', style: TextStyle(color: HFCColors.bluePrimary)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData, color: HFCColors.bluePrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16), itemCount: _list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) => _buildTile(_list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: HFCColors.bluePrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: HFCColors.bluePrimary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_formatRupiah(_saldo), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPill('↑ Pemasukan', _totalPemasukan, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildPill('↓ Pengeluaran', _totalPengeluaran, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, double amount, bool isPemasukan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: isPemasukan ? HFCColors.greenPill : HFCColors.expenseRedPill, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isPemasukan ? HFCColors.greenText : HFCColors.expenseRed, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_formatRupiah(amount), style: TextStyle(color: isPemasukan ? HFCColors.greenText : HFCColors.expenseRed, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTile(Transaction t) {
    final isPemasukan = t.jenis.toLowerCase() == 'pemasukan';
    final color = isPemasukan ? HFCColors.greenText : HFCColors.expenseRed;
    final bgIcon = isPemasukan ? HFCColors.greenPill : HFCColors.expenseRedLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HFCColors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPemasukan ? HFCColors.greenText.withOpacity(0.1) : HFCColors.expenseRed.withOpacity(0.1), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bgIcon, borderRadius: BorderRadius.circular(10)),
            child: Icon(isPemasukan ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.keterangan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(t.tanggal, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${isPemasukan ? '+' : '-'}${_formatRupiah(t.jumlah)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showForm(t: t),
            child: Container(
              padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: HFCColors.orangeLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_outlined, size: 16, color: HFCColors.orange),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _konfirmasiHapus(t),
            child: Container(
              padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: HFCColors.expenseRedLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, size: 16, color: HFCColors.expenseRed),
            ),
          ),
        ],
      ),
    );
  }
}