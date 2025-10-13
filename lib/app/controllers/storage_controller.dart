// app/controllers/storage_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageController extends GetxController {
  final supabase = Supabase.instance.client;

  /// Mengupload gambar ke Supabase Storage.
  /// Menerima file gambar dan UID pengguna.
  /// Mengembalikan URL publik dari gambar yang diupload.
  Future<String?> uploadProfilePicture(File file, String uid) async {
    try {
      // [PERBAIKAN YANG SAMA, HANYA MENEKANKAN KEMBALI]
      // Hapus segmen 'profile/' di sini
      // Karena `supabase.storage.from('profile')` sudah mengacu ke bucket 'profile'.
      // Jika Anda ingin ada sub-folder 'profile' di dalam bucket 'profile',
      // maka Anda harus membuat bucket yang berbeda atau menamainya dengan cara lain.
      // Asumsi bahwa Anda ingin langsung menyimpan di root bucket 'profile' dengan nama uid.jpg
      final String imagePath = '$uid.jpg'; // <-- PASTIKAN PERUBAHAN INI SUDAH DITERAPKAN

      // Upload file dengan opsi upsert: true
      await supabase.storage.from('profile').upload(
            imagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Dapatkan URL publik dari gambar tersebut
      final String publicUrl = supabase.storage.from('profile').getPublicUrl(imagePath);

      // PENTING: Tambahkan 'cache buster' untuk memastikan gambar baru langsung tampil
      final String cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      return cacheBustedUrl;

    } catch (e) {
      Get.snackbar('Upload Error', 'Gagal mengupload gambar profil: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }
}


// // app/controllers/storage_controller.dart

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class StorageController extends GetxController {
//   final supabase = Supabase.instance.client;

//   /// Mengupload gambar ke Supabase Storage.
//   /// Menerima file gambar dan UID pengguna.
//   /// Mengembalikan URL publik dari gambar yang diupload.
//   Future<String?> uploadProfilePicture(File file, String uid) async {
//     try {
//       // Path di Supabase: profile/USER_UID.jpg
//       // Ini memastikan setiap user hanya punya satu foto profil, yang akan ditimpa jika diupload ulang.
//       final String imagePath = 'profile/$uid.jpg';

//       // Upload file dengan opsi upsert: true
//       await supabase.storage.from('profile').upload(
//             imagePath,
//             file,
//             fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
//           );

//       // Dapatkan URL publik dari gambar tersebut
//       final String publicUrl = supabase.storage.from('profile').getPublicUrl(imagePath);

//       // PENTING: Tambahkan 'cache buster' untuk memastikan gambar baru langsung tampil
//       // Ini mencegah aplikasi menampilkan gambar lama dari cache.
//       final String cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
//       return cacheBustedUrl;

//     } catch (e) {
//       Get.snackbar('Upload Error', 'Gagal mengupload gambar profil: ${e.toString()}',
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return null;
//     }
//   }
// }