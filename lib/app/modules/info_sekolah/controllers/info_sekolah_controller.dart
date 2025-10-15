// lib/app/modules/info_sekolah/controllers/info_sekolah_controller.dart (FINAL & LENGKAP)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/config_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/controllers/dashboard_controller.dart';
import 'package:mi_alhuda_yogyakarta/app/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class InfoSekolahController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final supabase.SupabaseClient supabaseClient = supabase.Supabase.instance.client;

  late Stream<QuerySnapshot<Map<String, dynamic>>> streamInfo;
  final RxBool canPost = false.obs;

  final TextEditingController judulC = TextEditingController();
  final TextEditingController isiC = TextEditingController();
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxBool isFormLoading = false.obs;
  final RxString existingImageUrl = ''.obs;

  late final CollectionReference<Map<String, dynamic>> _infoRef;

  bool get isPimpinan {
    final user = configC.infoUser;
    if (user.isEmpty) return false;
    final role = user['role'] ?? '';
    final tugas = List<String>.from(user['tugas'] ?? []);
    final peranSistem = user['peranSistem'] ?? '';
    return ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(role) || 
           tugas.contains('Koordinator Kurikulum') || 
           peranSistem == 'superadmin';
  }

  @override
  void onInit() {
    super.onInit();
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    _infoRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran).collection('info_sekolah');
    
    streamInfo = _infoRef.orderBy('timestamp', descending: true).snapshots();
    
    final hasFlag = configC.infoUser['canPostInfoSekolah'] as bool? ?? false;
    // Pimpinan atau yang punya flag bisa posting
    canPost.value = Get.find<DashboardController>().isPimpinan || hasFlag;
  }

  @override
  void onClose() {
    judulC.dispose();
    isiC.dispose();
    super.onClose();
  }
  
  void goToForm({DocumentSnapshot? info}) {
    judulC.clear();
    isiC.clear();
    imageFile.value = null;
    existingImageUrl.value = '';

    Get.toNamed(Routes.INFO_SEKOLAH_FORM, arguments: info);
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) imageFile.value = File(pickedFile.path);
    } catch (e) { Get.snackbar('Error', 'Gagal memilih gambar: $e'); }
  }

  void removeImage() {
    imageFile.value = null;
    existingImageUrl.value = ''; // Hapus juga gambar lama
  }

  Future<String?> _uploadImage(File file, String docId) async {
    try {
      final String filePath = 'info.sekolah/$docId.jpg'; // Menggunakan path dari referensi Anda
      await supabaseClient.storage.from('info.sekolah').upload( // Menggunakan bucket 'info.sekolah'
        filePath, file,
        fileOptions: const supabase.FileOptions(cacheControl: '3600', upsert: true),
      );
      return supabaseClient.storage.from('info.sekolah').getPublicUrl(filePath);
    } catch (e) {
      Get.snackbar('Upload Gagal', 'Terjadi kesalahan saat mengupload gambar. Maksimal 200 KB mungkin.');
      print("Pesan error Supabase: $e");
      return null;
    }
  }

  Future<void> simpanInfo({String? docIdToEdit}) async {
    if (judulC.text.trim().isEmpty || isiC.text.trim().isEmpty) {
      Get.snackbar('Validasi Gagal', 'Judul dan Isi informasi tidak boleh kosong.');
      return;
    }
    
    isFormLoading.value = true;
    try {
      final user = configC.infoUser;
      final newDocId = docIdToEdit ?? '${DateTime.now().millisecondsSinceEpoch}-${user['uid']}';
      
      String? imageUrl;
      if (imageFile.value != null) {
        imageUrl = await _uploadImage(imageFile.value!, newDocId);
        if (imageUrl == null) { isFormLoading.value = false; return; }
      } else {
        imageUrl = existingImageUrl.value;
      }

      final dataToSave = {
        'judul': judulC.text.trim(),
        'isi': isiC.text.trim(),
        'penulisNama': user['alias'] ?? user['nama'],
        'penulisId': user['uid'],
        'peranPenulis': user['role'],
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      };

      if (docIdToEdit == null) {
        await _infoRef.doc(newDocId).set(dataToSave);
      } else {
        await _infoRef.doc(docIdToEdit).update(dataToSave);
      }
      
      Get.back();
      Get.snackbar('Sukses', 'Informasi berhasil dipublikasikan!');

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan informasi: $e');
    } finally {
      isFormLoading.value = false;
    }
  }

  void hapusInfo(String docId) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus informasi ini?",
      textConfirm: "Ya, Hapus", textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        try {
          // 1. Ambil dokumen untuk mendapatkan URL gambar
          final doc = await _infoRef.doc(docId).get();
          if (doc.exists) {
            final imageUrl = doc.data()?['imageUrl'] as String?;
            
            // 2. Hapus dokumen dari Firestore
            await _infoRef.doc(docId).delete();

            // 3. Jika ada URL, hapus file dari Supabase
            if (imageUrl != null && imageUrl.isNotEmpty) {
              // Ekstrak path file dari URL
              final path = Uri.parse(imageUrl).pathSegments.last;
              await supabaseClient.storage.from('info.sekolah').remove(['info.sekolah/$path']);
            }
          }
          
          Get.back(); // Tutup dialog loading
          Get.snackbar("Berhasil", "Informasi telah dihapus.");
        } catch (e) {
          Get.back(); // Tutup dialog loading
          Get.snackbar("Error", "Gagal menghapus informasi: $e");
        }
      },
    );
  }


  Future<DocumentSnapshot<Map<String, dynamic>>> getInfoById(String docId) {
    return _infoRef.doc(docId).get();
  }

  Future<void> shareInfo(Map<String, dynamic> infoData) async {
    final String judul = infoData['judul'] ?? 'Tanpa Judul';
    final String isi = infoData['isi'] ?? 'Tidak ada konten.';
    final String imageUrl = infoData['imageUrl'] ?? '';
    final String teksUntukShare = "Info Sekolah: *$judul*\n\n$isi";

    // Tampilkan dialog loading karena download mungkin butuh waktu
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      if (imageUrl.isNotEmpty) {
        // Jika ada gambar, download dulu
        final response = await http.get(Uri.parse(imageUrl));
        final bytes = response.bodyBytes;
        
        // Simpan ke direktori sementara
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/info_sekolah_image.jpg';
        await File(path).writeAsBytes(bytes);
        
        Get.back(); // Tutup dialog loading

        // Bagikan gambar beserta teks
        await Share.shareXFiles([XFile(path)], text: teksUntukShare);
      } else {
        // Jika tidak ada gambar, langsung bagikan teks
        Get.back(); // Tutup dialog loading
        await Share.share(teksUntukShare);
      }
    } catch (e) {
      Get.back(); // Pastikan dialog ditutup jika ada error
      Get.snackbar("Gagal Berbagi", "Terjadi kesalahan: $e");
    }
  }
}