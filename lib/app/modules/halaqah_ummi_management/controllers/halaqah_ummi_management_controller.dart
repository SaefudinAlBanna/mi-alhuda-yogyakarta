// lib/app/modules/halaqah_ummi_management/controllers/halaqah_ummi_management_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/pegawai_simple_model.dart'; // [BARU] Import model pegawai
import '../../../routes/app_pages.dart';

class HalaqahUmmiManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final DashboardController dashC = Get.find<DashboardController>();

  // [BARU] State untuk proses Ganti Pengampu
  final isProcessing = false.obs;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHalaqahUmmiGroups() {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return const Stream.empty();
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('halaqah_grup_ummi').orderBy('fase').orderBy('namaGrup')
        .snapshots();
  }

  void goToCreateGroup() => Get.toNamed(Routes.CREATE_EDIT_HALAQAH_UMMI_GROUP);
  void goToEditGroup(HalaqahGroupUmmiModel group) => Get.toNamed(Routes.CREATE_EDIT_HALAQAH_UMMI_GROUP, arguments: group);
  void goToSetPengganti(HalaqahGroupUmmiModel group) => Get.toNamed(Routes.HALAQAH_UMMI_SET_PENGGANTI, arguments: group);

  // [BARU] Navigasi ke halaman Pindah Siswa (akan kita implementasikan nanti)
  void goToPindahSiswaPage(HalaqahGroupUmmiModel group) {
    // Get.snackbar("Fitur Dalam Pengembangan", "Modul untuk memindahkan anggota akan segera hadir.");
    Get.toNamed(Routes.PINDAH_SISWA_HALAQAH, arguments: group);
  }

  Future<void> deleteGroup(HalaqahGroupUmmiModel group) async {
    Get.snackbar("Fitur Dalam Pengembangan", "Fungsi hapus grup akan didiskusikan, kemudian diimplementasikan.");
  }

  Future<void> batalkanPengganti(HalaqahGroupUmmiModel group) async {
     final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Get.defaultDialog(
      title: "Konfirmasi Pembatalan",
      middleText: "Anda yakin ingin membatalkan guru pengganti untuk grup ${group.namaGrup} pada hari ini?",
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          Get.back();
          try {
            final groupRef = _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
              .collection('halaqah_grup_ummi').doc(group.id);
            await groupRef.update({
              'penggantiHarian.$todayKey': FieldValue.delete(),
              'pengampuHariIni': FieldValue.delete(),
            });
            Get.snackbar("Berhasil", "Guru pengganti telah dibatalkan.");
          } catch (e) {
            Get.snackbar("Error", "Gagal membatalkan: $e");
          }
        },
        child: const Text("Ya, Batalkan")
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Tutup")),
    );
  }

  // --- [LOGIKA BARU UNTUK GANTI PENGAMPU PERMANEN] ---

  Future<void> showGantiPengampuDialog(HalaqahGroupUmmiModel group) async {
    // 1. Ambil semua pengampu yang eligible (berperan/bertugas sebagai Pengampu)
    final allPengampuSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').get();
    final List<PegawaiSimpleModel> allEligiblePengampu = [];
    for (var doc in allPengampuSnap.docs) {
      final data = doc.data();
      if ((data['role'] == 'Pengampu') || (List<String>.from(data['tugas'] ?? [])).contains('Pengampu')) {
        allEligiblePengampu.add(PegawaiSimpleModel.fromFirestore(doc));
      }
    }
    allEligiblePengampu.sort((a,b) => a.nama.compareTo(b.nama));

    // 2. Ambil semua grup di fase yang sama untuk filtering
    final groupsInSameFaseSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup_ummi').where('fase', isEqualTo: group.fase).get();

    final Set<String> assignedPengampuIds = groupsInSameFaseSnap.docs
        .map((doc) => doc.data()['idPengampu'] as String).toSet();

    // 3. Filter untuk mendapatkan pengampu yang valid (belum mengampu di fase ini)
    final List<PegawaiSimpleModel> availablePengampu = allEligiblePengampu
        .where((p) => !assignedPengampuIds.contains(p.uid) || p.uid == group.idPengampu) // Izinkan pengampu saat ini
        .toList();
    
    final Rxn<PegawaiSimpleModel> selectedPengampu = Rxn<PegawaiSimpleModel>();

    Get.defaultDialog(
      title: "Ganti Pengampu Permanen",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Grup: ${group.namaGrup}", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Pengampu saat ini: ${group.namaPengampu}"),
          const SizedBox(height: 24),
          DropdownButtonFormField<PegawaiSimpleModel>(
            hint: const Text("Pilih Pengampu Baru"),
            isExpanded: true,
            items: availablePengampu.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => selectedPengampu.value = val,
          )
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isProcessing.value || selectedPengampu.value == null ? null : () {
          Get.back();
          _prosesGantiPengampu(group, selectedPengampu.value!);
        },
        child: isProcessing.value ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Simpan Perubahan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> _prosesGantiPengampu(HalaqahGroupUmmiModel group, PegawaiSimpleModel pengampuBaru) async {
    isProcessing.value = true;
    try {
      final WriteBatch batch = _firestore.batch();
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final groupRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran).collection('halaqah_grup_ummi').doc(group.id);

      // 1. Ambil semua anggota grup ini
      final anggotaSnap = await groupRef.collection('anggota').get();
      if (anggotaSnap.docs.isEmpty) {
        // Jika grup kosong, cukup update dokumen grup
        batch.update(groupRef, {'idPengampu': pengampuBaru.uid, 'namaPengampu': pengampuBaru.displayName});
      } else {
        // 2. Update dokumen grup utama
        batch.update(groupRef, {'idPengampu': pengampuBaru.uid, 'namaPengampu': pengampuBaru.displayName});

        // 3. Loop dan update setiap dokumen siswa
        for (var doc in anggotaSnap.docs) {
          final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(doc.id);
          batch.update(siswaRef, {'halaqahUmmi.namaPengampu': pengampuBaru.displayName});
        }
      }
      
      await batch.commit();
      Get.snackbar("Berhasil", "Pengampu untuk grup ${group.namaGrup} telah diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal mengganti pengampu: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart'; // <-- IMPORT BARU
// import '../../../controllers/config_controller.dart';
// import '../../../models/halaqah_group_ummi_model.dart';
// import '../../../routes/app_pages.dart';

// class HalaqahUmmiManagementController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();

//   Stream<QuerySnapshot<Map<String, dynamic>>> streamHalaqahUmmiGroups() {
//     final tahunAjaran = configC.tahunAjaranAktif.value;
//     if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
//       return const Stream.empty();
//     }
//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaran)
//         .collection('halaqah_grup_ummi')
//         .orderBy('fase')
//         .orderBy('namaGrup')
//         .snapshots();
//   }

//   void goToCreateGroup() {
//     Get.toNamed(Routes.CREATE_EDIT_HALAQAH_UMMI_GROUP, arguments: null);
//   }

//   void goToEditGroup(HalaqahGroupUmmiModel group) {
//     Get.toNamed(Routes.CREATE_EDIT_HALAQAH_UMMI_GROUP, arguments: group);
//   }

//   void goToSetPengganti(HalaqahGroupUmmiModel group) {
//     Get.toNamed(Routes.HALAQAH_UMMI_SET_PENGGANTI, arguments: group);
//   }

//   Future<void> deleteGroup(HalaqahGroupUmmiModel group) {
//     Get.snackbar("Fitur Dalam Pengembangan", "Fungsi hapus grup akan diimplementasikan.");
//     return Future.value(); // Return a future
//   }

//   // --- [METHOD BARU] ---
//   Future<void> batalkanPengganti(HalaqahGroupUmmiModel group) async {
//     final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     Get.defaultDialog(
//       title: "Konfirmasi Pembatalan",
//       middleText: "Anda yakin ingin membatalkan guru pengganti untuk grup ${group.namaGrup} pada hari ini?",
//       confirm: ElevatedButton(
//         style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//         onPressed: () async {
//           Get.back();
//           try {
//             final groupRef = _firestore
//               .collection('Sekolah').doc(configC.idSekolah)
//               .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
//               .collection('halaqah_grup_ummi').doc(group.id);

//             // --- [LOGIKA BARU] ---
//             // Hapus kedua field terkait pengganti
//             await groupRef.update({
//               'penggantiHarian.$todayKey': FieldValue.delete(),
//               'pengampuHariIni': FieldValue.delete(),
//             });
//             // --- [AKHIR LOGIKA BARU] ---

//             Get.snackbar("Berhasil", "Guru pengganti telah dibatalkan.");
//           } catch (e) {
//             Get.snackbar("Error", "Gagal membatalkan: $e");
//           }
//         },
//         child: const Text("Ya, Batalkan")
//       ),
//       cancel: TextButton(onPressed: Get.back, child: const Text("Tutup")),
//     );
//   }
// }