import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../../../services/notifikasi_service.dart';

// Model helper untuk menampung state setiap baris siswa di UI
class SiswaMassGradingModel {
  final SiswaSimpleModel siswa;
  final Map<String, dynamic> progresData;
  
  // Setiap siswa punya state form-nya sendiri
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final Rx<String> status = "Lancar".obs; // Default status 'Lancar'

  SiswaMassGradingModel({required this.siswa, required this.progresData});

  // Method untuk membersihkan controller saat tidak lagi digunakan
  void dispose() {
    nilaiC.dispose();
    catatanC.dispose();
  }
}

class HalaqahUmmiGradingMassalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  late HalaqahGroupUmmiModel group;
  final RxBool isLoading = true.obs;
  final isSaving = false.obs;

  // Daftar utama yang akan ditampilkan di UI
  final RxList<SiswaMassGradingModel> listSiswaForGrading = <SiswaMassGradingModel>[].obs;
  final lokasiC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    group = Get.arguments as HalaqahGroupUmmiModel;
    lokasiC.text = group.lokasiDefault;
    loadSiswaForMassGrading();
  }

  @override
  void onClose() {
    // Pastikan semua controller di-dispose untuk mencegah memory leak
    for (var siswaModel in listSiswaForGrading) {
      siswaModel.dispose();
    }
    lokasiC.dispose();
    super.onClose();
  }

  Future<void> loadSiswaForMassGrading() async {
    isLoading.value = true;
    try {
      final anggotaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
          .collection('halaqah_grup_ummi').doc(group.id).collection('anggota').get();

      final anggotaIds = anggotaSnapshot.docs.map((doc) => doc.id).toList();
      if (anggotaIds.isEmpty) {
        listSiswaForGrading.clear();
        return;
      }
      
      final siswaSnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').where(FieldPath.documentId, whereIn: anggotaIds).get();

      final List<SiswaMassGradingModel> tempList = [];
      for (var doc in siswaSnapshot.docs) {
        final siswa = SiswaSimpleModel.fromFirestore(doc);
        final progresData = (doc.data()['halaqahUmmi']?['progres'] as Map<String, dynamic>?) ??
                            {'tingkat': 'Jilid', 'detailTingkat': '1', 'halaman': 1};
        tempList.add(SiswaMassGradingModel(siswa: siswa, progresData: progresData));
      }
      tempList.sort((a,b) => a.siswa.nama.compareTo(b.siswa.nama));
      listSiswaForGrading.assignAll(tempList);

    } catch(e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveMassGrading() async {
    isSaving.value = true;
    try {
      final batch = _firestore.batch();
      final penilaiInfo = configC.infoUser;
      final String namaPenilai = (penilaiInfo['alias'] != null && penilaiInfo['alias'].isNotEmpty)
                                 ? penilaiInfo['alias'] : penilaiInfo['nama'];
      int processedCount = 0;
      final List<Map<String, dynamic>> notificationsToSend = [];

      for (var siswaModel in listSiswaForGrading) {
        // Hanya proses siswa yang nilainya diisi
        if (siswaModel.nilaiC.text.trim().isNotEmpty) {
          processedCount++;
          final int nilaiAngka = int.parse(siswaModel.nilaiC.text);
          final String nilaiHuruf = _getNilaiHuruf(nilaiAngka);
          final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaModel.siswa.uid);
          final setoranRef = siswaRef.collection('halaqah_setoran_ummi').doc();

          batch.set(setoranRef, {
            'tanggalSetor': FieldValue.serverTimestamp(),
            'idGrup': group.id, 'idPengampu': group.idPengampu, 'namaPengampu': group.namaPengampu,
            'isDinilaiPengganti': group.isPengganti, 'idPenilai': authC.auth.currentUser!.uid,
            'namaPenilai': namaPenilai, 'lokasiAktual': lokasiC.text,
            'materi': siswaModel.progresData, 'kelasAsal': siswaModel.siswa.kelasId,
            'penilaian': {'status': siswaModel.status.value, 'nilaiAngka': nilaiAngka, 'nilaiHuruf': nilaiHuruf},
            'catatanPengampu': siswaModel.catatanC.text.trim(), 'catatanOrangTua': '',
          });

          batch.update(siswaRef, {'halaqahUmmi.tanggalSetoranTerakhir': FieldValue.serverTimestamp()});

          if (siswaModel.status.value == 'Lancar') {
            final newProgres = Map<String, dynamic>.from(siswaModel.progresData);
            newProgres['halaman'] = (newProgres['halaman'] as int) + 1;
            batch.update(siswaRef, {'halaqahUmmi.progres': newProgres});
          }

          notificationsToSend.add({
            'uid': siswaModel.siswa.uid, 'nama': siswaModel.siswa.nama,
            'status': siswaModel.status.value, 'nilaiHuruf': nilaiHuruf, 'penilai': namaPenilai
          });
        }
      }

      if (processedCount == 0) {
        throw Exception("Tidak ada nilai yang diisi. Silakan isi minimal satu nilai siswa.");
      }

      await batch.commit();

      // Kirim notifikasi setelah batch berhasil
      for (var notif in notificationsToSend) {
        await NotifikasiService.kirimNotifikasi(
          uidPenerima: notif['uid'], judul: "Hasil Setoran Halaqah Ummi",
          isi: "Ananda ${notif['nama']} telah dinilai oleh ${notif['penilai']}: ${notif['status']} (${notif['nilaiHuruf']}).",
          tipe: "HALAQAH_UMMI"
        );
      }

      Get.back();
      Get.snackbar("Berhasil", "$processedCount penilaian siswa berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  String _getNilaiHuruf(int nilai) {
    if (nilai >= 90) return "A";
    if (nilai >= 85) return "B+";
    if (nilai >= 80) return "B";
    if (nilai >= 75) return "B-";
    if (nilai >= 70) return "C+";
    if (nilai >= 65) return "C";
    if (nilai >= 60) return "C-";
    return "D";
  }
}