import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _database;

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    String sqlUsers =
        'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT, role TEXT DEFAULT "mahasiswa")';

    String sqlTransaksi =
        'CREATE TABLE transaksi (id INTEGER PRIMARY KEY AUTOINCREMENT, tanggal TEXT, jenis TEXT, jumlah REAL, keterangan TEXT, user_id INTEGER)';

    String path = join(await getDatabasesPath(), 'user_data.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(sqlUsers);
        await db.execute(sqlTransaksi);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'mahasiswa'");
        }
      },
    );
  }

  // ================= USERS (LOGIN & REGISTER) =================

  //fungsi menyimpan data ke database (register)
  //return true kalau berhasil, false kalau username sudah dipakai
  Future<bool> register(String username, String password, String role) async {
    var dbClient = await db;

    // cek dulu apakah username sudah ada
    bool sudahAda = await isUsernameExist(username);
    if (sudahAda) {
      return false;
    }

    int id = await dbClient.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });

    return id > 0;
  }

  //fungsi membaca data/select dari database (login)
  //return data user kalau username & password cocok, null kalau tidak
  Future<Map<String, dynamic>?> checkLogin(String username, String password) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  //fungsi cek apakah username sudah dipakai (dipakai di dalam register)
  Future<bool> isUsernameExist(String username) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  // ================= TRANSAKSI (CATATAN KAS) =================

  //fungsi menambah transaksi baru
  Future<int> tambahTransaksi({
    required String tanggal,
    required String jenis, // 'pemasukan' atau 'pengeluaran'
    required double jumlah,
    required String keterangan,
    required int userId,
  }) async {
    var dbClient = await db;
    return await dbClient.insert('transaksi', {
      'tanggal': tanggal,
      'jenis': jenis,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'user_id': userId,
    });
  }

  //fungsi mengambil semua data transaksi (kas kelas bersama, urut terbaru)
  Future<List<Map<String, dynamic>>> getTransaksi() async {
    var dbClient = await db;
    return await dbClient.query('transaksi', orderBy: 'tanggal DESC, id DESC');
  }

  //fungsi edit transaksi
  Future<int> editTransaksi({
    required int id,
    required String tanggal,
    required String jenis,
    required double jumlah,
    required String keterangan,
  }) async {
    var dbClient = await db;
    return await dbClient.update(
      'transaksi',
      {
        'tanggal': tanggal,
        'jenis': jenis,
        'jumlah': jumlah,
        'keterangan': keterangan,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //fungsi hapus transaksi
  Future<int> hapusTransaksi(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //fungsi ambil ringkasan saldo (total pemasukan, pengeluaran, saldo akhir)
  Future<Map<String, double>> getRingkasan() async {
    var dbClient = await db;

    var pemasukanResult = await dbClient.rawQuery(
      "SELECT SUM(jumlah) as total FROM transaksi WHERE jenis = 'pemasukan'",
    );
    var pengeluaranResult = await dbClient.rawQuery(
      "SELECT SUM(jumlah) as total FROM transaksi WHERE jenis = 'pengeluaran'",
    );

    double totalPemasukan = (pemasukanResult.first['total'] as double?) ?? 0;
    double totalPengeluaran = (pengeluaranResult.first['total'] as double?) ?? 0;

    return {
      'total_pemasukan': totalPemasukan,
      'total_pengeluaran': totalPengeluaran,
      'saldo': totalPemasukan - totalPengeluaran,
    };
  }
}