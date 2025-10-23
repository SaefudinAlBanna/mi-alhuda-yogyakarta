import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/storage_controller.dart';

class ProfileController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();
  final StorageController storageC = Get.find<StorageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController namaController = TextEditingController();
  TextEditingController aliasController = TextEditingController();
  TextEditingController noTelpController = TextEditingController();
  TextEditingController nipController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController tglGabungController = TextEditingController();

  // --- STATE REAKTIF ---
  final RxBool isLoading = false.obs;
  final Rxn<File> pickedImage = Rxn<File>();
  final RxString jenisKelamin = "".obs;
  final Rxn<DateTime> selectedJoinDate = Rxn<DateTime>();

  

  @override
  void onInit() {
    super.onInit();
    
    // Panggil fungsi untuk mengisi data saat pertama kali controller dibuat
    _populateDataFromConfig();

    // --- [PERBAIKAN KRUSIAL] ---
    // Buat listener yang akan berjalan SETIAP KALI status di ConfigController berubah.
    ever(configC.status, (AppStatus status) {
      // Jika status berubah menjadi authenticated (misalnya setelah login berhasil),
      // panggil kembali fungsi untuk mengisi data.
      if (status == AppStatus.authenticated) {
        _populateDataFromConfig();
      }
    });
    // --- AKHIR PERBAIKAN ---
  }

  void _populateDataFromConfig() {
    final userData = configC.infoUser;

    // Jika userData masih kosong, jangan lakukan apa-apa
    if (userData.isEmpty) return;

    // 1. Inisialisasi semua field teks standar
    namaController.text = userData['nama']?.toString() ?? '';
    aliasController.text = userData['alias']?.toString() ?? '';
    noTelpController.text = userData['noTelp']?.toString() ?? '';
    nipController.text = userData['nip']?.toString() ?? '';
    alamatController.text = userData['alamat']?.toString() ?? '';

    // 2. Tangani dan normalisasi field Jenis Kelamin
    String jkFromDb = userData['jeniskelamin']?.toString().toLowerCase() ?? '';
    if (jkFromDb == 'laki-laki') {
      jenisKelamin.value = 'Laki-Laki';
    } else if (jkFromDb == 'perempuan') {
      jenisKelamin.value = 'Perempuan';
    } else {
      jenisKelamin.value = '';
    }

    // 3. Tangani field Tanggal Bergabung
    dynamic tglGabungData = userData['tglgabung'];
    selectedJoinDate.value = null; // Reset dulu untuk memastikan kebersihan data
    if (tglGabungData is Timestamp) {
      selectedJoinDate.value = tglGabungData.toDate();
    } else if (tglGabungData is String && tglGabungData.isNotEmpty) {
      try {
        selectedJoinDate.value = DateTime.parse(tglGabungData);
      } catch (e) {
        print("### Gagal parsing 'tglgabung' String di ProfileController: $e");
      }
    }

    // 4. Update controller tanggal
    if (selectedJoinDate.value != null) {
      tglGabungController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(selectedJoinDate.value!);
    } else {
      tglGabungController.text = '';
    }
  }

  @override
  void onClose() {
    namaController.dispose();
    aliasController.dispose();
    noTelpController.dispose();
    nipController.dispose();
    alamatController.dispose();
    tglGabungController.dispose();
    super.onClose();
  }

  Future<void> selectJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedJoinDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != selectedJoinDate.value) {
      selectedJoinDate.value = picked;
      tglGabungController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
    }
  }

  /// Memilih gambar dari galeri pengguna.
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        pickedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memilih gambar: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Mengompres gambar jika ukurannya melebihi batas (200 KB).
  Future<File?> _compressImage(File file) async {
    final int maxSizeInBytes = 200 * 1024; // 200 KB
    if (file.lengthSync() <= maxSizeInBytes) {
      return file; // Tidak perlu kompresi
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final String targetPath = '$path/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      img.Image? image = img.decodeImage(file.readAsBytesSync());
      if (image == null) return null;

      // Kompres dengan kualitas 85% sebagai awal
      List<int> compressedBytes = img.encodeJpg(image, quality: 85);

      // Jika masih terlalu besar, kurangi kualitas secara bertahap
      int quality = 85;
      while (compressedBytes.length > maxSizeInBytes && quality > 10) {
        quality -= 5;
        compressedBytes = img.encodeJpg(image, quality: quality);
      }

      File compressedFile = await File(targetPath).writeAsBytes(compressedBytes);
      return compressedFile;

    } catch (e) {
      Get.snackbar("Error Kompresi", "Gagal memproses gambar.", backgroundColor: Colors.orange, colorText: Colors.white);
      return null;
    }
  }

  /// Mengupdate data profil ke Firestore.
  Future<void> updateProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      String? newFotoUrl;
      if (pickedImage.value != null) {
        File? imageToUpload = await _compressImage(pickedImage.value!);
        if (imageToUpload != null) {
          newFotoUrl = await storageC.uploadProfilePicture(imageToUpload, authC.auth.currentUser!.uid);
        } else {
          throw Exception("Gagal memproses gambar.");
        }
      }

      final Map<String, dynamic> dataToUpdate = {
        'nama': namaController.text.trim(),
        'alias': aliasController.text.trim(),
        'noTelp': noTelpController.text.trim(),
        'nip': nipController.text.trim(),
        'alamat': alamatController.text.trim(),
        'jeniskelamin': jenisKelamin.value,
      };
      if (selectedJoinDate.value != null) {
        dataToUpdate['tglgabung'] = Timestamp.fromDate(selectedJoinDate.value!);
      }
      if (newFotoUrl != null) {
        // PERBAIKAN: Gunakan field 'profileImageUrl'
        dataToUpdate['profileImageUrl'] = newFotoUrl;
      }
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(authC.auth.currentUser!.uid).update(dataToUpdate);
      await configC.forceSyncProfile();
      
      Get.snackbar("Berhasil", "Profil berhasil diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Gagal", "Terjadi kesalahan: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async => await authC.logout();
}