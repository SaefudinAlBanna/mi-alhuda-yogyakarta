import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_munaqosyah_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../../../services/notifikasi_service.dart';

// Model helper untuk menggabungkan data ujian dan data siswa
class UjianSiswaModel {
  final SiswaSimpleModel siswa;
  final HalaqahMunaqosyahModel ujian;
  UjianSiswaModel({required this.siswa, required this.ujian});
}

class HalaqahUmmiJadwalPengujiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  // State Form Penilaian
  final isSaving = false.obs;
  final Rx<String> selectedHasil = "Lulus".obs;
  final nilaiC = TextEditingController();
  final catatanC = TextEditingController();
  final Rx<String> selectedTingkatBerikutnya = "Jilid".obs;
  final detailTingkatC = TextEditingController(text: "1");

  final List<String> daftarTingkatan = ["Jilid", "Al-Qur'an", "Ghorib", "Tajwid", "Pasca", "Jumlah", "Ketuntasan"];

  Stream<List<UjianSiswaModel>> streamJadwalUjianSaya() {
    final uid = authC.auth.currentUser!.uid;
    // Gunakan Collection Group Query untuk mencari di semua sub-koleksi
    return _firestore
        .collectionGroup('halaqah_munaqosyah')
        .where('idPenguji', isEqualTo: uid)
        .where('hasil', isEqualTo: 'Dijadwalkan')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      // Ambil UID siswa dari path dokumen ujian
      final Map<String, HalaqahMunaqosyahModel> ujianMap = {};
      for (var doc in snapshot.docs) {
        final pathParts = doc.reference.path.split('/');
        final siswaId = pathParts[pathParts.length - 3];
        ujianMap[siswaId] = HalaqahMunaqosyahModel.fromFirestore(doc);
      }

      // Ambil data semua siswa dalam satu query
      final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where(FieldPath.documentId, whereIn: ujianMap.keys.toList())
          .get();

      final List<UjianSiswaModel> result = [];
      for (var siswaDoc in siswaSnapshot.docs) {
        result.add(UjianSiswaModel(
          siswa: SiswaSimpleModel.fromFirestore(siswaDoc),
          ujian: ujianMap[siswaDoc.id]!,
        ));
      }
      return result;
    });
  }
  
  void openGradingSheet(UjianSiswaModel ujianSiswa) {
    // Reset form
    selectedHasil.value = "Lulus";
    nilaiC.clear();
    catatanC.clear();
    _setTingkatBerikutnyaOtomatis(ujianSiswa.ujian.materiUjian);

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Penilaian Munaqosyah: ${ujianSiswa.siswa.nama}", style: Get.textTheme.titleLarge),
            Text("Materi Ujian: ${ujianSiswa.ujian.materiUjian}"),
            const Divider(height: 24),
            Obx(() => Row(
              children: ["Lulus", "Belum Lulus"].map((hasil) => Expanded(
                child: RadioListTile<String>(
                  title: Text(hasil), value: hasil, groupValue: selectedHasil.value,
                  onChanged: (val) => selectedHasil.value = val!,
                ),
              )).toList(),
            )),
            const SizedBox(height: 16),
            TextField(controller: nilaiC, decoration: const InputDecoration(labelText: "Nilai (0-100)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            const Text("Progres Berikutnya (Jika Lulus)", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                    value: selectedTingkatBerikutnya.value,
                    items: daftarTingkatan.map((tingkat) => DropdownMenuItem(value: tingkat, child: Text(tingkat))).toList(),
                    onChanged: (val) => selectedTingkatBerikutnya.value = val!,
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: detailTingkatC, decoration: const InputDecoration(labelText: "Detail (misal: No. Jilid)"))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: catatanC, decoration: const InputDecoration(labelText: "Catatan Penguji", border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: isSaving.value ? null : () => saveHasilUjian(ujianSiswa),
              child: const Text("Simpan Hasil Ujian"),
            )),
          ],
        ),
      ),
      backgroundColor: Colors.white, isScrollControlled: true,
    );
  }

  void _setTingkatBerikutnyaOtomatis(String materiUjian) {
    if (materiUjian.contains("Jilid")) {
      final parts = materiUjian.split(" ");
      final jilidNum = int.tryParse(parts.last) ?? 7;
      if (jilidNum <= 6) {
        selectedTingkatBerikutnya.value = "Jilid";
        detailTingkatC.text = jilidNum.toString();
      } else {
        selectedTingkatBerikutnya.value = "Al-Qur'an";
        detailTingkatC.clear();
      }
    } else {
        selectedTingkatBerikutnya.value = "Al-Qur'an";
        detailTingkatC.clear();
    }
  }

  Future<void> saveHasilUjian(UjianSiswaModel ujianSiswa) async {
    isSaving.value = true;
    try {
      final int nilaiAngka = int.tryParse(nilaiC.text) ?? 0;
      final batch = _firestore.batch();
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(ujianSiswa.siswa.uid);
      final munaqosyahRef = siswaRef.collection('halaqah_munaqosyah').doc(ujianSiswa.ujian.id);

      // 1. Update dokumen munaqosyah
      batch.update(munaqosyahRef, {
        'hasil': selectedHasil.value,
        'nilai': nilaiAngka,
        'catatanPenguji': catatanC.text.trim(),
      });

      // 2. Update dokumen siswa
      final Map<String, dynamic> updateData = {'halaqahUmmi.statusUjian': FieldValue.delete()};
      if (selectedHasil.value == "Lulus") {
        updateData['halaqahUmmi.progres'] = {
          'tingkat': selectedTingkatBerikutnya.value,
          'detailTingkat': detailTingkatC.text.trim(),
          'halaman': 1, // Selalu mulai dari halaman 1
        };
      }
      batch.update(siswaRef, updateData);

      await batch.commit();

      // 3. Kirim notifikasi
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: ujianSiswa.siswa.uid,
        judul: "Hasil Munaqosyah Halaqah",
        isi: "Alhamdulillah, ananda ${ujianSiswa.siswa.nama} dinyatakan ${selectedHasil.value} dalam munaqosyah.",
        tipe: "HALAQAH_UMMI",
      );

      Get.back();
      Get.snackbar("Berhasil", "Hasil ujian telah disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan hasil: $e");
    } finally {
      isSaving.value = false;
    }
  }
}