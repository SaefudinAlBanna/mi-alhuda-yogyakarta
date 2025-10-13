import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_setoran_ummi_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../../halaqah-ummi-grading/controllers/halaqah_ummi_grading_controller.dart';

class HalaqahUmmiRiwayatPengampuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  
  late SiswaSimpleModel siswa;

  @override
  void onInit() {
    super.onInit();
    siswa = Get.arguments as SiswaSimpleModel;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayatSetoran() {
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(siswa.uid)
        .collection('halaqah_setoran_ummi')
        .orderBy('tanggalSetor', descending: true)
        .snapshots();
  }

  // Fungsi ini memanggil controller lain untuk membuka sheet edit
  void editPenilaian(HalaqahSetoranUmmiModel setoran) {
    // Pastikan grading controller sudah terdaftar
    if (Get.isRegistered<HalaqahUmmiGradingController>()) {
      final gradingController = Get.find<HalaqahUmmiGradingController>();
      gradingController.openGradingSheetForEdit(siswa, setoran);
    } else {
      Get.snackbar("Error", "Tidak dapat membuka editor. Silakan coba kembali.");
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  void hapusPenilaian(HalaqahSetoranUmmiModel setoran) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus data setoran pada tanggal ${DateFormat('dd MMM yyyy').format(setoran.tanggalSetor)}? Progres siswa akan dikembalikan jika perlu.",
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          Get.back(); // Tutup dialog
          await _prosesHapus(setoran);
        },
        child: const Text("Ya, Hapus"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Batal"),
      ),
    );
  }

  // Logika inti untuk menghapus data
  Future<void> _prosesHapus(HalaqahSetoranUmmiModel setoran) async {
    try {
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      final setoranRef = siswaRef.collection('halaqah_setoran_ummi').doc(setoran.id);
      
      final batch = _firestore.batch();

      // Hapus dokumen setoran
      batch.delete(setoranRef);

      // Jika setoran yang dihapus adalah "Lancar", kembalikan progres halaman siswa
      if (setoran.penilaian.status == 'Lancar') {
        final siswaDoc = await siswaRef.get();
        final currentHalaman = siswaDoc.data()?['halaqahUmmi']?['progres']?['halaman'] ?? 1;
        // Pastikan halaman tidak menjadi negatif
        if (currentHalaman > 1) {
          batch.update(siswaRef, {'halaqahUmmi.progres.halaman': FieldValue.increment(-1)});
        }
      }

      await batch.commit();
      Get.snackbar("Berhasil", "Data setoran telah dihapus.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus data: ${e.toString()}");
    }
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/siswa_simple_model.dart';
// import '../../../models/halaqah_setoran_ummi_model.dart';
// import '../../halaqah-ummi-grading/controllers/halaqah_ummi_grading_controller.dart';

// class HalaqahUmmiRiwayatPengampuController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
  
//   late SiswaSimpleModel siswa;

//   @override
//   void onInit() {
//     super.onInit();
//     siswa = Get.arguments as SiswaSimpleModel;
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayatSetoran() {
//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('siswa').doc(siswa.uid)
//         .collection('halaqah_setoran_ummi')
//         .orderBy('tanggalSetor', descending: true)
//         .snapshots();
//   }

//   // PR #1: Fitur Edit & Hapus (Akan diimplementasikan di iterasi berikutnya)
//   void editPenilaian(HalaqahSetoranUmmiModel setoran) {
//     // Panggil controller grading dan gunakan method barunya
//     final gradingController = Get.find<HalaqahUmmiGradingController>();
//     gradingController.openGradingSheetForEdit(siswa, setoran);
//   }

//   void hapusPenilaian(HalaqahSetoranUmmiModel setoran) {
//     Get.defaultDialog(
//       title: "Konfirmasi Hapus",
//       middleText: "Anda yakin ingin menghapus data setoran pada tanggal ${DateFormat('dd MMM yyyy').format(setoran.tanggalSetor)}?",
//       confirm: ElevatedButton(
//         style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//         onPressed: () async {
//           Get.back(); // Tutup dialog
//           _prosesHapus(setoran);
//         },
//         child: const Text("Ya, Hapus"),
//       ),
//       cancel: TextButton(
//         onPressed: () => Get.back(),
//         child: const Text("Batal"),
//       ),
//     );
//   }

//   Future<void> _prosesHapus(HalaqahSetoranUmmiModel setoran) async {
//     try {
//       final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
//       final setoranRef = siswaRef.collection('halaqah_setoran_ummi').doc(setoran.id);
      
//       final batch = _firestore.batch();

//       // 1. Hapus dokumen setoran
//       batch.delete(setoranRef);

//       // 2. Jika setoran yang dihapus adalah "Lancar", kembalikan progres siswa
//       if (setoran.penilaian.status == 'Lancar') {
//         batch.update(siswaRef, {'halaqahUmmi.progres.halaman': FieldValue.increment(-1)});
//       }

//       await batch.commit();
//       Get.snackbar("Berhasil", "Data setoran telah dihapus.");
//     } catch (e) {
//       Get.snackbar("Error", "Gagal menghapus data: ${e.toString()}");
//     }
//   }
// }