import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_group_ummi_model.dart';
import '../../../models/halaqah_setoran_ummi_model.dart';
import '../../../models/siswa_simple_model.dart';
import '../../../services/notifikasi_service.dart';
import '../../halaqah-ummi-riwayat-pengampu/controllers/halaqah_ummi_riwayat_pengampu_controller.dart';

// Model helper tidak berubah
class SiswaGradingModel {
  final SiswaSimpleModel siswa;
  final Map<String, dynamic> progresData;
  final String? statusUjian; // <-- TAMBAHAN BARU

  SiswaGradingModel({
    required this.siswa,
    required this.progresData,
    this.statusUjian, // <-- TAMBAHAN BARU
  });

  String get progresTingkat => progresData['tingkat'] ?? 'Jilid';
  String get progresDetailTingkat => progresData['detailTingkat'] ?? '1';
  int get progresHalaman => progresData['halaman'] ?? 1;
}

class HalaqahUmmiGradingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  late HalaqahGroupUmmiModel group;
  late Future<List<SiswaGradingModel>> listAnggotaFuture;

  final isSaving = false.obs;
  final Rx<String> selectedStatus = "Lancar".obs;
  final nilaiC = TextEditingController();
  final catatanC = TextEditingController();
  final lokasiC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Gunakan try-catch untuk handle jika arguments tidak sesuai
    try {
      group = Get.arguments as HalaqahGroupUmmiModel;
      lokasiC.text = group.lokasiDefault;
      listAnggotaFuture = fetchAnggotaWithProgres();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data grup. Silakan kembali dan coba lagi.");
      // Inisialisasi future dengan error agar view menampilkan pesan error
      listAnggotaFuture = Future.error("Data grup tidak valid.");
    }
  }

  Future<List<SiswaGradingModel>> fetchAnggotaWithProgres() async {
    final anggotaSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('halaqah_grup_ummi').doc(group.id)
        .collection('anggota').get();
  
    final List<String> anggotaIds = anggotaSnapshot.docs.map((doc) => doc.id).toList();
    if (anggotaIds.isEmpty) return [];
  
    final siswaSnapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where(FieldPath.documentId, whereIn: anggotaIds)
        .get();
        
    final List<SiswaGradingModel> listWithProgres = [];
    for (var doc in siswaSnapshot.docs) {
      final siswa = SiswaSimpleModel.fromFirestore(doc);
      final data = doc.data();
      final progresData = (data['halaqahUmmi']?['progres'] as Map<String, dynamic>?) ??
                          {'tingkat': 'Jilid', 'detailTingkat': '1', 'halaman': 1};
      final String? statusUjian = data['halaqahUmmi']?['statusUjian'];
      
      listWithProgres.add(SiswaGradingModel(
        siswa: siswa,
        progresData: progresData,
        statusUjian: statusUjian,
      ));
    }
    
    // --- PERBAIKAN SORTING DI SINI ---
    listWithProgres.sort((a, b) {
      // Prioritas 1: Siswa dengan status ujian ('Diajukan' atau 'Dijadwalkan') selalu di atas.
      final aHasStatus = a.statusUjian != null && a.statusUjian!.isNotEmpty;
      final bHasStatus = b.statusUjian != null && b.statusUjian!.isNotEmpty;
      if (aHasStatus && !bHasStatus) return -1; // a ke atas
      if (!aHasStatus && bHasStatus) return 1;  // b ke atas
  
      // Prioritas 2: Jika keduanya punya status, atau keduanya tidak, urutkan berdasarkan nama.
      return a.siswa.nama.compareTo(b.siswa.nama);
    });
    // --- AKHIR PERBAIKAN SORTING ---
    
    return listWithProgres;
  }

  void ajukanMunaqosyah(SiswaGradingModel siswaModel) {
    Get.defaultDialog(
      title: "Konfirmasi Pengajuan",
      middleText: "Anda yakin ingin mengajukan ${siswaModel.siswa.nama} untuk Munaqosyah/Ujian?",
      confirm: ElevatedButton(
        onPressed: () async {
          Get.back();
          try {
            await _firestore
                .collection('Sekolah').doc(configC.idSekolah)
                .collection('siswa').doc(siswaModel.siswa.uid)
                .update({'halaqahUmmi.statusUjian': 'Diajukan'});

            Get.snackbar("Berhasil", "${siswaModel.siswa.nama} telah diajukan untuk ujian.");
            // Reload data untuk menampilkan badge baru
            listAnggotaFuture = fetchAnggotaWithProgres();
            update();

          } catch (e) {
            Get.snackbar("Error", "Gagal mengajukan siswa: $e");
          }
        },
        child: const Text("Ya, Ajukan"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  void openGradingSheet(SiswaGradingModel siswaModel) {
    selectedStatus.value = "Lancar";
    nilaiC.clear();
    catatanC.clear();
    lokasiC.text = group.lokasiDefault;
    
    _showBottomSheet(
      title: "Penilaian: ${siswaModel.siswa.nama}",
      subtitle: "Progres Saat Ini: ${siswaModel.progresTingkat} ${siswaModel.progresDetailTingkat} Hal ${siswaModel.progresHalaman}",
      onSave: () => saveIndividualGrading(siswaModel),
      buttonText: "Simpan Penilaian",
    );
  }

  // --- [FUNGSI BARU TANPA PLACEHOLDER] ---
  void openGradingSheetForEdit(SiswaSimpleModel siswa, HalaqahSetoranUmmiModel setoran) {
    selectedStatus.value = setoran.penilaian.status;
    nilaiC.text = setoran.penilaian.nilaiAngka.toString();
    catatanC.text = setoran.catatanPengampu;
    lokasiC.text = setoran.lokasiAktual;

    _showBottomSheet(
      title: "Edit Penilaian: ${siswa.nama}",
      subtitle: "Setoran pada ${DateFormat('dd MMM yyyy').format(setoran.tanggalSetor)}",
      onSave: () => updateGrading(siswa, setoran),
      buttonText: "Update Penilaian",
    );
  }

  // --- [FUNGSI BARU TANPA PLACEHOLDER] ---
  Future<void> updateGrading(SiswaSimpleModel siswa, HalaqahSetoranUmmiModel oldSetoran) async {
    isSaving.value = true;
    try {
      final int nilaiAngka = int.tryParse(nilaiC.text) ?? 0;
      if (nilaiAngka < 0 || nilaiAngka > 100) throw Exception("Nilai harus antara 0 dan 100.");

      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      final setoranRef = siswaRef.collection('halaqah_setoran_ummi').doc(oldSetoran.id);
      final batch = _firestore.batch();

      batch.update(setoranRef, {
        'lokasiAktual': lokasiC.text.trim(),
        'penilaian.status': selectedStatus.value,
        'penilaian.nilaiAngka': nilaiAngka,
        'penilaian.nilaiHuruf': _getNilaiHuruf(nilaiAngka),
        'catatanPengampu': catatanC.text.trim(),
      });

      final bool wasLancar = oldSetoran.penilaian.status == 'Lancar';
      final bool isNowLancar = selectedStatus.value == 'Lancar';

      if (wasLancar && !isNowLancar) {
        batch.update(siswaRef, {'halaqahUmmi.progres.halaman': FieldValue.increment(-1)});
      } else if (!wasLancar && isNowLancar) {
        batch.update(siswaRef, {'halaqahUmmi.progres.halaman': FieldValue.increment(1)});
      }

      await batch.commit();
      Get.back(); // Tutup bottom sheet
      Get.snackbar("Berhasil", "Penilaian telah di-update.", backgroundColor: Colors.green, colorText: Colors.white);
      
      // Refresh halaman riwayat (jika terbuka) dan halaman grading
      if (Get.isRegistered<HalaqahUmmiRiwayatPengampuController>()) {
        Get.find<HalaqahUmmiRiwayatPengampuController>().update();
      }
      update();

    } catch (e) {
      Get.snackbar("Error", "Gagal meng-update: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  // Helper untuk UI BottomSheet agar tidak duplikasi kode
  void _showBottomSheet({required String title, required String subtitle, required VoidCallback onSave, required String buttonText}) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            Text(title, style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle, style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  const Text("Status Setoran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: ["Lancar", "Perlu Perbaikan", "Mengulang"].map((status) => _buildStatusChip(status)).toList(),
                  )),
                  const SizedBox(height: 24),
                  TextField(controller: nilaiC, decoration: const InputDecoration(labelText: "Nilai (0-100)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: lokasiC, decoration: const InputDecoration(labelText: "Lokasi Setoran", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: catatanC, decoration: const InputDecoration(labelText: "Catatan untuk Orang Tua", border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSaving.value ? null : onSave,
                  child: Text(isSaving.value ? "Menyimpan..." : buttonText),
                ),
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Helper untuk UI Chip status
  Widget _buildStatusChip(String title) {
    return Expanded(
      child: InkWell(
        onTap: () => selectedStatus.value = title,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selectedStatus.value == title ? Get.theme.primaryColor.withOpacity(0.1) : Colors.grey[200],
            border: Border.all(color: selectedStatus.value == title ? Get.theme.primaryColor : Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Radio<String>(value: title, groupValue: selectedStatus.value, onChanged: (value) => selectedStatus.value = value!),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
  
  // Method saveIndividualGrading dan _getNilaiHuruf tidak berubah...
  Future<void> saveIndividualGrading(SiswaGradingModel siswaModel) async {
    isSaving.value = true;
    try {
      final int nilaiAngka = int.tryParse(nilaiC.text) ?? 0;
      if (nilaiAngka < 0 || nilaiAngka > 100) throw Exception("Nilai harus antara 0 dan 100.");

      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaModel.siswa.uid);
      final setoranRef = siswaRef.collection('halaqah_setoran_ummi').doc();
      final batch = _firestore.batch();
      
      final penilaiInfo = configC.infoUser;
      final String namaPenilai = (penilaiInfo['alias'] != null && penilaiInfo['alias'].isNotEmpty)
                               ? penilaiInfo['alias'] : penilaiInfo['nama'];

      // 1. Buat dokumen setoran baru
      batch.set(setoranRef, {
        'tanggalSetor': FieldValue.serverTimestamp(),
        'idGrup': group.id,
        'idPengampu': group.idPengampu,
        'namaPengampu': group.namaPengampu,
        'isDinilaiPengganti': group.isPengganti,
        'idPenilai': authC.auth.currentUser!.uid,
        'namaPenilai': namaPenilai,
        'lokasiAktual': lokasiC.text,
        'materi': siswaModel.progresData, // Gunakan progres dari model
        'kelasAsal': siswaModel.siswa.kelasId, // <-- REVISI: Simpan kelasId
        'penilaian': {
          'status': selectedStatus.value,
          'nilaiAngka': nilaiAngka,
          'nilaiHuruf': _getNilaiHuruf(nilaiAngka),
        },
        'catatanPengampu': catatanC.text,
        'catatanOrangTua': '',
      });

      batch.update(siswaRef, {'halaqahUmmi.tanggalSetoranTerakhir': FieldValue.serverTimestamp()});

      // 2. Update progres utama siswa jika "Lancar"
      if (selectedStatus.value == 'Lancar') {
        final newProgres = Map<String, dynamic>.from(siswaModel.progresData);
        newProgres['halaman'] = (newProgres['halaman'] as int) + 1;
        batch.update(siswaRef, {'halaqahUmmi.progres': newProgres});
      }

      await batch.commit();
      
      await NotifikasiService.kirimNotifikasi(
        uidPenerima: siswaModel.siswa.uid, 
        judul: "Hasil Setoran Halaqah Ummi", 
        isi: "Ananda ${siswaModel.siswa.nama} telah dinilai oleh $namaPenilai: ${selectedStatus.value} (${_getNilaiHuruf(nilaiAngka)}).", 
        tipe: "HALAQAH_UMMI"
      );

      Get.back();
      Get.snackbar("Berhasil", "Penilaian untuk ${siswaModel.siswa.nama} disimpan.");
      
      listAnggotaFuture = fetchAnggotaWithProgres();
      update();

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