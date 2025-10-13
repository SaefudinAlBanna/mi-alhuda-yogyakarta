// lib/app/enums/user_role_enum.dart

/// Enum untuk merepresentasikan semua kemungkinan peran pengguna dalam sistem.
/// Ini memberikan type-safety dan menghindari penggunaan "magic strings".
enum UserRole {
  // Definisikan semua peran di sini.
  // Nilai dalam kurung adalah nama yang akan ditampilkan di UI.
  admin('Admin'),
  kepalaSekolah('Kepala Sekolah'),
  operator('Operator'),
  tu('TU'),
  tataUsaha('Tata Usaha'),
  guruKelas('Guru Kelas'),
  guruMapel('Guru Mapel'),
  superAdmin('Super Admin'),
  
  // Nilai fallback jika peran tidak dikenali.
  tidakDiketahui('Tidak Diketahui');

  // Constructor untuk mengaitkan setiap enum dengan nama tampilannya.
  const UserRole(this.displayName);
  final String displayName;

  /// Factory constructor untuk mengonversi String dari Firestore menjadi nilai Enum.
  /// Ini adalah jembatan antara data mentah dan kode type-safe kita.
  static UserRole fromString(String? roleString) {
    switch (roleString) {
      case 'Admin':
        return UserRole.admin;
      case 'Kepala Sekolah':
        return UserRole.kepalaSekolah;
      case 'Operator':
        return UserRole.operator;
      case 'TU':
        return UserRole.tu;
      case 'Tata Usaha':
        return UserRole.tataUsaha;
      case 'Guru Kelas':
        return UserRole.guruKelas;
      case 'Guru Mapel':
        return UserRole.guruMapel;
      case 'superadmin': // Ini untuk peranSistem, mungkin berbeda
        return UserRole.superAdmin;
      default:
        return UserRole.tidakDiketahui;
    }
  }
}