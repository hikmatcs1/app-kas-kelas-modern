<?php
header("Content-Type: application/json");

$host = "localhost";
$user = "root";
$pass = "";
$db   = "kaskelas"; // Database yang benar

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    echo json_encode(["status" => "gagal", "message" => "Koneksi database gagal"]);
    exit();
}

$input = file_get_contents("php://input");
$data  = json_decode($input, true);

if (isset($data['username']) && isset($data['password'])) {
    $username = $conn->real_escape_string($data['username']);
    $password = $conn->real_escape_string($data['password']);

    // Query ke tabel 'users'. 
    // Pastikan kolom di database kamu namanya memang 'username' dan 'password'
    $sql = "SELECT id, nama, role FROM users WHERE username = '$username' AND password = '$password' LIMIT 1";
    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo json_encode([
            "status" => "sukses",
            "user_id" => $user['id'],
            "nama" => $user['nama'],
            "role" => $user['role'] // Opsional: untuk membedakan admin & mahasiswa
        ]);
    } else {
        echo json_encode(["status" => "gagal", "message" => "Username atau Password salah!"]);
    }
} else {
    echo json_encode(["status" => "gagal", "message" => "Data tidak lengkap"]);
}

$conn->close();
?>