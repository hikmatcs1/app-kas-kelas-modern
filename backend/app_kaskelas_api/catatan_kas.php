<?php
header('Content-Type:application/json');
header('Access-Control-Allow-Origin:*');
header('Access-Control-Allow-Methods:GET,POST,PUT,DELETE');

// Koneksi ke database
$connect = mysqli_connect('localhost', 'root', '', 'kaskelas');

if (!$connect) {
    echo json_encode(array('status' => 'gagal', 'message' => 'Koneksi database gagal'));
    exit();
}

// ── GET: Mengambil Data Transaksi ──────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $sql = 'SELECT * FROM transaksi ORDER BY id DESC';
    $result = mysqli_query($connect, $sql);
    
    $data = array();
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
    echo json_encode($data);

} 
// ── POST: Login, Registrasi, Tambah Data ──────────────────────────────────
elseif ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = isset($input['action']) ? $input['action'] : '';

    // A. PROSES LOGIN
    if ($action == 'login') {
        $username = mysqli_real_escape_string($connect, $input['username']);
        $password = mysqli_real_escape_string($connect, $input['password']);

        $sql = "SELECT id, username, role FROM users WHERE username = '$username' AND password = '$password'";
        $result = mysqli_query($connect, $sql);

        if ($result && mysqli_num_rows($result) > 0) {
            $user = mysqli_fetch_assoc($result);
            echo json_encode(array('status' => 'sukses', 'message' => 'Login Berhasil', 'data' => $user));
        } else {
            echo json_encode(array('status' => 'gagal', 'message' => 'Username atau Password Salah'));
        }

    // B. PROSES REGISTRASI
    } elseif ($action == 'register') {
        $username = mysqli_real_escape_string($connect, $input['username']);
        $password = mysqli_real_escape_string($connect, $input['password']);
        $kode_akses = isset($input['kode_akses']) ? $input['kode_akses'] : '';
        
        $role = 'mahasiswa'; // Default
        // Kode Rahasia untuk menjadi Admin
        if ($kode_akses == 'BENDA123') {
            $role = 'admin';
        }

        $cek = mysqli_query($connect, "SELECT * FROM users WHERE username = '$username'");
        if (mysqli_num_rows($cek) > 0) {
            echo json_encode(array('status' => 'gagal', 'message' => 'Username sudah terdaftar!'));
        } else {
            $sql = "INSERT INTO users (username, password, role) VALUES ('$username', '$password', '$role')";
            if (mysqli_query($connect, $sql)) {
                echo json_encode(array('status' => 'sukses', 'message' => 'Registrasi Berhasil'));
            } else {
                echo json_encode(array('status' => 'gagal', 'message' => mysqli_error($connect)));
            }
        }

    // C. PROSES TAMBAH TRANSAKSI (Default)
    // Catatan: kolom user_id sudah tidak dipakai lagi karena hanya
    // admin/bendahara yang boleh menginput data kas.
    } else {
        $tanggal = $input['tanggal'];
        $jenis = $input['jenis'];
        $jumlah = $input['jumlah'];
        $keterangan = $input['keterangan'];

        $sql = "INSERT INTO transaksi (tanggal, jenis, jumlah, keterangan) VALUES ('$tanggal','$jenis','$jumlah','$keterangan')";
        if (mysqli_query($connect, $sql)) {
            echo json_encode(array('status' => 'sukses', 'message' => 'Data Berhasil Ditambahkan'));
        } else {
            echo json_encode(array('status' => 'gagal', 'message' => mysqli_error($connect)));
        }
    }

} 
// ── PUT: Update Data ──────────────────────────────────────────────────────
elseif ($_SERVER['REQUEST_METHOD'] == 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'];
    $tanggal = $input['tanggal'];
    $jenis = $input['jenis'];
    $jumlah = $input['jumlah'];
    $keterangan = $input['keterangan'];

    $sql = "UPDATE transaksi SET tanggal='$tanggal', jenis='$jenis', jumlah='$jumlah', keterangan='$keterangan' WHERE id='$id'";
    if (mysqli_query($connect, $sql)) {
        echo json_encode(array('status' => 'sukses', 'message' => 'Data Berhasil Diubah'));
    } else {
        echo json_encode(array('status' => 'gagal', 'message' => mysqli_error($connect)));
    }
} 
// ── DELETE: Hapus Data ────────────────────────────────────────────────────
elseif ($_SERVER['REQUEST_METHOD'] == 'DELETE') {
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'];

    $sql = "DELETE FROM transaksi WHERE id='$id'";
    if (mysqli_query($connect, $sql)) {
        echo json_encode(array('status' => 'sukses', 'message' => 'Data Berhasil Dihapus'));
    } else {
        echo json_encode(array('status' => 'gagal', 'message' => mysqli_error($connect)));
    }
}
?>